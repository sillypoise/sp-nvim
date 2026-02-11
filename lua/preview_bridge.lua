local logic = require("preview_bridge.logic")
local osc52_ok, osc52 = pcall(require, "osc52")

local preview_bridge = {}

local default_config = {
  enabled = true,
  transport = "http",
  server_url = "http://localhost:3000",
  ws_url = nil,
  ws_subscribe_enabled = false,
  ws_write_enabled = true,
  ws_write_http_fallback = true,
  browser_base_url = "http://localhost:3000",
  open_fallback_mode = "notify_copy",
  open_custom_command = nil,
  ws_ping_interval_ms = 15000,
  ws_backoff_initial_ms = 250,
  ws_backoff_max_ms = 2000,
  debounce_ms = 100,
  file_filter = "^content/.*%.md$",
  workspace_root = nil,
}

local state = {
  initialized = false,
  enabled = true,
  workspace_root = nil,
  session_id = nil,
  config = nil,
  autocmd_group = nil,
  buffers = {},
  file_versions = {},
  curl_available = nil,
  websocat_available = nil,
  warning_seen = {},
  warning_last_ns = 0,
  ws = {
    connected = false,
    connecting = false,
    process = nil,
    stdin_pipe = nil,
    stdout_pipe = nil,
    stderr_pipe = nil,
    reconnect_timer = nil,
    ping_timer = nil,
    stdout_buffer = "",
    stderr_buffer = "",
    reconnect_backoff_ms = nil,
    reconnect_attempt_count = 0,
    last_pong_ns = nil,
    intentional_close = false,
    active_file_path = nil,
    subscribed_file_path = nil,
  },
  debug = {
    last_warning = nil,
    last_skip_reason = nil,
    last_transport_error = nil,
    last_http_status = nil,
    last_ws_error = nil,
    last_ws_ack_event = nil,
    last_ws_ack_applied = nil,
    last_ws_ack_version = nil,
    last_ws_ack_removed = nil,
    last_ws_message = nil,
    ws_state = "disconnected",
    last_open_result = nil,
    last_open_url = nil,
    last_open_error = nil,
    last_upsert = nil,
    last_close = nil,
  },
}

local function now_ns()
  return (vim.uv or vim.loop).hrtime()
end

local function normalize_root_path(path)
  if type(path) ~= "string" then
    return nil
  end

  local normalized_path = path:gsub("\\", "/")
  normalized_path = normalized_path:gsub("/+$", "")
  if normalized_path == "" then
    return nil
  end

  return normalized_path
end

local function warn_throttled(message_key, message_text)
  local warning_interval_ns = 5 * 1000 * 1000 * 1000
  local current_time_ns = now_ns()

  if state.warning_seen[message_key] ~= true then
    state.warning_seen[message_key] = true
    state.debug.last_warning = message_text
    vim.notify(message_text, vim.log.levels.WARN)
    state.warning_last_ns = current_time_ns
    return
  end

  if current_time_ns - state.warning_last_ns >= warning_interval_ns then
    state.debug.last_warning = message_text
    vim.notify(message_text, vim.log.levels.WARN)
    state.warning_last_ns = current_time_ns
  end
end

local function detect_workspace_root()
  local cwd = (vim.uv or vim.loop).cwd()
  local git_result = vim.system({ "git", "-C", cwd, "rev-parse", "--show-toplevel" }, { text = true }):wait(200)

  if git_result.code == 0 then
    if type(git_result.stdout) == "string" then
      local git_root = git_result.stdout:gsub("%s+$", "")
      if git_root ~= "" then
        return normalize_root_path(git_root)
      end
    end
  end

  return normalize_root_path(cwd)
end

local function find_nearest_git_root(absolute_path)
  local start_directory = vim.fs.dirname(absolute_path)
  if type(start_directory) ~= "string" then
    return nil
  end

  local git_markers = vim.fs.find(".git", {
    path = start_directory,
    upward = true,
    limit = 1,
  })

  if #git_markers == 0 then
    return nil
  end

  return normalize_root_path(vim.fs.dirname(git_markers[1]))
end

local function create_session_id()
  local seed_parts = {
    tostring(now_ns()),
    tostring(vim.fn.getpid()),
    tostring(math.random()),
    tostring(os.time()),
  }
  local seed = table.concat(seed_parts, "-")
  local digest = vim.fn.sha256(seed)

  local variant_nibble = (tonumber(digest:sub(17, 17), 16) % 4) + 8
  local uuid = string.format(
    "%s-%s-4%s-%x%s-%s",
    digest:sub(1, 8),
    digest:sub(9, 12),
    digest:sub(14, 16),
    variant_nibble,
    digest:sub(18, 20),
    digest:sub(21, 32)
  )
  return "nvim-" .. uuid
end

local function create_live_url()
  return state.config.server_url .. "/api/preview/live"
end

local function create_open_url()
  return state.config.server_url .. "/api/preview/open"
end

local function browser_base_url()
  local configured_base_url = state.config.browser_base_url
  if type(configured_base_url) ~= "string" then
    return state.config.server_url
  end

  local trimmed_base_url = configured_base_url:gsub("/+$", "")
  if trimmed_base_url == "" then
    return state.config.server_url
  end

  return trimmed_base_url
end

local function build_preview_url_for_file(file_path)
  local escaped_file_path = vim.uri_encode(file_path)
  return browser_base_url() .. "/preview?file=" .. escaped_file_path
end

local function build_preview_url_from_path(url_path)
  if type(url_path) ~= "string" then
    return nil
  end

  if url_path:sub(1, 7) == "http://" or url_path:sub(1, 8) == "https://" then
    return url_path
  end

  if url_path:sub(1, 1) ~= "/" then
    url_path = "/" .. url_path
  end

  return browser_base_url() .. url_path
end

local function ensure_curl_available()
  if state.curl_available ~= nil then
    return state.curl_available
  end

  state.curl_available = vim.fn.executable("curl") == 1

  if state.curl_available ~= true then
    warn_throttled("curl_missing", "PreviewBridge: curl is required but was not found on PATH.")
  end

  return state.curl_available
end

local function ensure_websocat_available()
  if state.websocat_available ~= nil then
    return state.websocat_available
  end

  state.websocat_available = vim.fn.executable("websocat") == 1

  if state.websocat_available ~= true then
    warn_throttled("websocat_missing", "PreviewBridge: websocat is required for WS transport.")
  end

  return state.websocat_available
end

local function copy_to_clipboard(value)
  local copy_method = "register"

  if osc52_ok == true then
    local copied_ok = pcall(osc52.copy, value)
    if copied_ok == true then
      return "osc52"
    end
  end

  pcall(vim.fn.setreg, '"', value)
  return copy_method
end

local function notify_open_fallback(url, reason)
  vim.schedule(function()
    local copy_method = copy_to_clipboard(url)
    local message = "PreviewBridge: " .. reason .. " URL copied to clipboard (" .. copy_method .. "): " .. url
    vim.notify(message, vim.log.levels.INFO)
    state.debug.last_open_result = "notify_copy"
    state.debug.last_open_url = url
  end)
end

local function open_url(url, reason)
  local fallback_mode = state.config.open_fallback_mode
  if fallback_mode == "system_open" then
    local opened = false

    if vim.ui and vim.ui.open then
      local open_ok = pcall(vim.ui.open, url)
      if open_ok == true then
        opened = true
      end
    end

    if opened ~= true then
      local open_command = nil
      if vim.fn.has("mac") == 1 then
        open_command = { "open", url }
      elseif vim.fn.has("win32") == 1 then
        open_command = { "cmd.exe", "/c", "start", "", url }
      else
        open_command = { "xdg-open", url }
      end

      local started_ok = pcall(vim.system, open_command, { text = true }, function(_) end)
      opened = started_ok
    end

    if opened == true then
      state.debug.last_open_result = "system_open"
      state.debug.last_open_url = url
      return
    end

    notify_open_fallback(url, "failed to open browser from remote environment")
    return
  end

  if fallback_mode == "custom_command" and type(state.config.open_custom_command) == "string" then
    local shell_url = vim.fn.shellescape(url)
    local command = string.gsub(state.config.open_custom_command, "%%URL%%", shell_url)
    local started_ok = pcall(vim.system, { "sh", "-lc", command }, { text = true }, function(_) end)
    if started_ok == true then
      state.debug.last_open_result = "custom_command"
      state.debug.last_open_url = url
      return
    end

    notify_open_fallback(url, "failed to run open_custom_command")
    return
  end

  notify_open_fallback(url, reason)
end

local function ws_url()
  if type(state.config.ws_url) == "string" and state.config.ws_url ~= "" then
    return state.config.ws_url
  end

  return logic.derive_ws_url(state.config.server_url)
end

local function set_ws_state(ws_state)
  state.debug.ws_state = ws_state
end

local function ws_subscription_enabled()
  if state.config.transport ~= "ws" then
    return false
  end

  return state.config.ws_subscribe_enabled ~= false
end

local function ws_write_enabled()
  if state.config.transport ~= "ws" then
    return false
  end

  return state.config.ws_write_enabled ~= false
end

local function post_live_payload_async(payload)
  if ensure_curl_available() ~= true then
    state.debug.last_transport_error = "curl_missing"
    return false
  end

  local payload_json = vim.json.encode(payload)
  local command = {
    "curl",
    "--silent",
    "--show-error",
    "--max-time",
    "2",
    "--request",
    "POST",
    "--header",
    "Content-Type: application/json",
    "--data-binary",
    payload_json,
    "--output",
    "-",
    "--write-out",
    "\n%{http_code}",
    create_live_url(),
  }

  local started_ok, started_error = pcall(vim.system, command, { text = true }, function(result)
    if result.code ~= 0 then
      local failure_message = "PreviewBridge: request failed"
      if type(result.stderr) == "string" then
        if result.stderr ~= "" then
          failure_message = failure_message .. " (" .. result.stderr:gsub("%s+$", "") .. ")"
        end
      end
      state.debug.last_transport_error = failure_message
      warn_throttled("request_failure", failure_message)
      return
    end

    local status_code = 0
    if type(result.stdout) == "string" then
      status_code = logic.parse_curl_response(result.stdout)
    end

    state.debug.last_http_status = status_code

    if status_code >= 400 then
      warn_throttled("request_status", "PreviewBridge: server returned HTTP " .. tostring(status_code) .. ".")
    end
  end)

  if started_ok ~= true then
    state.debug.last_transport_error = tostring(started_error)
    warn_throttled("request_start", "PreviewBridge: failed to start curl request (" .. tostring(started_error) .. ").")
    return false
  end

  state.debug.last_transport_error = nil
  return true
end

local function request_open_in_browser(file_path)
  local fallback_url = build_preview_url_for_file(file_path)

  if ensure_curl_available() ~= true then
    state.debug.last_open_error = "curl_missing"
    open_url(fallback_url, "cannot call /api/preview/open")
    return false
  end

  local payload_json = vim.json.encode({ filePath = file_path })
  local command = {
    "curl",
    "--silent",
    "--show-error",
    "--max-time",
    "2",
    "--request",
    "POST",
    "--header",
    "Content-Type: application/json",
    "--data-binary",
    payload_json,
    "--output",
    "-",
    "--write-out",
    "\n%{http_code}",
    create_open_url(),
  }

  local started_ok, started_error = pcall(vim.system, command, { text = true }, function(result)
    if result.code ~= 0 then
      state.debug.last_open_error = tostring(result.stderr)
      open_url(fallback_url, "preview app unavailable for open route")
      return
    end

    local status_code, response_body = logic.parse_curl_response(result.stdout)
    if status_code >= 400 then
      local error_detail = "open_http_" .. tostring(status_code)
      local decode_ok, decoded_body = pcall(vim.json.decode, response_body)
      if decode_ok == true and type(decoded_body) == "table" then
        if type(decoded_body.error) == "table" then
          local error_code = tostring(decoded_body.error.code)
          local error_message = tostring(decoded_body.error.message)
          error_detail = error_code .. ":" .. error_message
        end
      end
      state.debug.last_open_error = error_detail
      warn_throttled("open_route_rejected", "PreviewBridge: open route rejected - " .. error_detail .. ".")
      open_url(fallback_url, "preview app rejected open route")
      return
    end

    local decode_ok, decoded_body = pcall(vim.json.decode, response_body)
    if decode_ok ~= true then
      state.debug.last_open_error = "open_decode_failed"
      open_url(fallback_url, "preview open response invalid")
      return
    end

    local result_body = decoded_body.result
    if type(result_body) ~= "table" then
      state.debug.last_open_error = "open_missing_result"
      open_url(fallback_url, "preview open response missing result")
      return
    end

    if result_body.routed == true then
      state.debug.last_open_result = "routed"
      state.debug.last_open_url = nil
      state.debug.last_open_error = nil
      vim.notify("PreviewBridge: routed open request to active preview tab.", vim.log.levels.INFO)
      return
    end

    local routed_url = build_preview_url_from_path(result_body.urlPath)
    if routed_url == nil then
      routed_url = fallback_url
    end
    state.debug.last_open_error = nil
    open_url(routed_url, "no active preview browser session")
  end)

  if started_ok ~= true then
    state.debug.last_open_error = tostring(started_error)
    open_url(fallback_url, "failed to invoke /api/preview/open")
    return false
  end

  return true
end

local function ws_close_pipe(pipe)
  if pipe == nil then
    return
  end
  if pipe:is_closing() ~= true then
    pipe:close()
  end
end

local function ws_send_json(message)
  if state.ws.connected ~= true then
    return false
  end
  if state.ws.stdin_pipe == nil then
    return false
  end

  local encoded_message = vim.json.encode(message)
  local payload = encoded_message .. "\n"
  local write_ok, write_error = pcall(state.ws.stdin_pipe.write, state.ws.stdin_pipe, payload)
  if write_ok ~= true then
    state.debug.last_ws_error = tostring(write_error)
    warn_throttled("ws_write_failed", "PreviewBridge: WS write failed (" .. tostring(write_error) .. ").")
    return false
  end

  return true
end

local function ws_send_hello()
  return ws_send_json({
    type = "hello",
    contract = "v1",
    sessionId = state.session_id,
    client = "editor",
  })
end

local function ws_send_ping()
  return ws_send_json({ type = "ping" })
end

local function ws_send_subscribe(file_path)
  return ws_send_json({
    type = "subscribe",
    filePath = file_path,
  })
end

local function ws_send_unsubscribe(file_path)
  return ws_send_json({
    type = "unsubscribe",
    filePath = file_path,
  })
end

local function ws_send_upsert(session_id, file_path, version, content)
  return ws_send_json({
    type = "upsert",
    sessionId = session_id,
    filePath = file_path,
    version = version,
    content = content,
  })
end

local function ws_send_close(session_id, file_path)
  return ws_send_json({
    type = "close",
    sessionId = session_id,
    filePath = file_path,
  })
end

local function ws_sync_subscription()
  if ws_subscription_enabled() ~= true then
    return
  end
  if state.ws.connected ~= true then
    return
  end

  local active_file_path = state.ws.active_file_path
  local subscribed_file_path = state.ws.subscribed_file_path

  if subscribed_file_path ~= nil and subscribed_file_path ~= active_file_path then
    ws_send_unsubscribe(subscribed_file_path)
    state.ws.subscribed_file_path = nil
  end

  if active_file_path ~= nil and state.ws.subscribed_file_path ~= active_file_path then
    if ws_send_subscribe(active_file_path) == true then
      state.ws.subscribed_file_path = active_file_path
    end
  end
end

local function ws_start_ping_timer()
  if state.config.ws_ping_interval_ms < 1 then
    return
  end

  if state.ws.ping_timer ~= nil then
    state.ws.ping_timer:stop()
    ws_close_pipe(state.ws.ping_timer)
    state.ws.ping_timer = nil
  end

  state.ws.ping_timer = (vim.uv or vim.loop).new_timer()
  state.ws.ping_timer:start(state.config.ws_ping_interval_ms, state.config.ws_ping_interval_ms, vim.schedule_wrap(function()
    if state.ws.connected ~= true then
      return
    end

    local pong_deadline_ns = state.config.ws_ping_interval_ms * 2 * 1000 * 1000
    if state.ws.last_pong_ns ~= nil then
      local pong_age_ns = now_ns() - state.ws.last_pong_ns
      if pong_age_ns > pong_deadline_ns then
        state.debug.last_ws_error = "pong_timeout"
        warn_throttled("ws_pong_timeout", "PreviewBridge: WS pong timeout, reconnecting.")
        if state.ws.process ~= nil and state.ws.process:is_closing() ~= true then
          state.ws.process:kill("sigterm")
        end
        return
      end
    end

    ws_send_ping()
  end))
end

local function ws_schedule_reconnect()
  if state.enabled ~= true then
    return
  end
  if state.config.transport ~= "ws" then
    return
  end

  local reconnect_backoff_ms = state.ws.reconnect_backoff_ms
  if type(reconnect_backoff_ms) ~= "number" then
    reconnect_backoff_ms = state.config.ws_backoff_initial_ms
  end

  local delay_ms, next_backoff_ms = logic.next_backoff_ms(
    reconnect_backoff_ms,
    state.config.ws_backoff_initial_ms,
    state.config.ws_backoff_max_ms
  )
  state.ws.reconnect_backoff_ms = next_backoff_ms
  state.ws.reconnect_attempt_count = state.ws.reconnect_attempt_count + 1

  if state.ws.reconnect_timer ~= nil then
    state.ws.reconnect_timer:stop()
    ws_close_pipe(state.ws.reconnect_timer)
    state.ws.reconnect_timer = nil
  end

  state.ws.reconnect_timer = (vim.uv or vim.loop).new_timer()
  state.ws.reconnect_timer:start(delay_ms, 0, vim.schedule_wrap(function()
    state.ws.reconnect_timer:stop()
    ws_close_pipe(state.ws.reconnect_timer)
    state.ws.reconnect_timer = nil
    if state.enabled ~= true then
      return
    end
    if state.config.transport ~= "ws" then
      return
    end
    if state.ws.connecting == true then
      return
    end
    if state.ws.connected == true then
      return
    end
    -- Defer actual connect to avoid deep callback nesting.
    preview_bridge.connect_ws()
  end))
end

local function ws_handle_server_message(decoded_message)
  if type(decoded_message) ~= "table" then
    state.debug.last_ws_error = "invalid_message_shape"
    return
  end

  local message_type = decoded_message.type
  state.debug.last_ws_message = message_type

  if message_type == "pong" then
    state.ws.last_pong_ns = now_ns()
    return
  end

  if message_type == "ack" then
    state.debug.last_ws_ack_event = decoded_message.event
    state.debug.last_ws_ack_applied = decoded_message.applied
    state.debug.last_ws_ack_version = decoded_message.version
    state.debug.last_ws_ack_removed = decoded_message.removed
    return
  end

  if message_type == "preview:error" then
    local code = tostring(decoded_message.code)
    local message = tostring(decoded_message.message)
    state.debug.last_ws_error = code .. ":" .. message
    warn_throttled("ws_preview_error", "PreviewBridge: WS error " .. code .. " - " .. message .. ".")
  end
end

local function ws_read_stdout(_, chunk)
  if chunk == nil then
    return
  end

  state.ws.stdout_buffer = state.ws.stdout_buffer .. chunk

  while true do
    local newline_index = state.ws.stdout_buffer:find("\n", 1, true)
    if newline_index == nil then
      break
    end

    local line = state.ws.stdout_buffer:sub(1, newline_index - 1)
    state.ws.stdout_buffer = state.ws.stdout_buffer:sub(newline_index + 1)

    if line ~= "" then
      local decode_ok, decoded_message = pcall(vim.json.decode, line)
      if decode_ok ~= true then
        state.debug.last_ws_error = "invalid_json"
      else
        ws_handle_server_message(decoded_message)
      end
    end
  end
end

local function ws_read_stderr(_, chunk)
  if chunk == nil then
    return
  end

  state.ws.stderr_buffer = state.ws.stderr_buffer .. chunk
  local newline_index = state.ws.stderr_buffer:find("\n", 1, true)
  if newline_index ~= nil then
    local line = state.ws.stderr_buffer:sub(1, newline_index - 1)
    state.ws.stderr_buffer = state.ws.stderr_buffer:sub(newline_index + 1)
    if line ~= "" then
      state.debug.last_ws_error = line
      warn_throttled("ws_stderr", "PreviewBridge WS: " .. line)
    end
  end
end

local function ws_disconnect(should_reconnect)
  state.ws.intentional_close = should_reconnect ~= true
  state.ws.connecting = false
  state.ws.connected = false
  set_ws_state("disconnected")

  if state.ws.process ~= nil and state.ws.process:is_closing() ~= true then
    state.ws.process:kill("sigterm")
    state.ws.process:close()
  end

  ws_close_pipe(state.ws.stdin_pipe)
  ws_close_pipe(state.ws.stdout_pipe)
  ws_close_pipe(state.ws.stderr_pipe)

  state.ws.process = nil
  state.ws.stdin_pipe = nil
  state.ws.stdout_pipe = nil
  state.ws.stderr_pipe = nil
  state.ws.subscribed_file_path = nil

  if state.ws.ping_timer ~= nil then
    state.ws.ping_timer:stop()
    ws_close_pipe(state.ws.ping_timer)
    state.ws.ping_timer = nil
  end

  if should_reconnect == true then
    ws_schedule_reconnect()
  end
end

function preview_bridge.connect_ws()
  if state.config.transport ~= "ws" then
    return false
  end
  if state.enabled ~= true then
    return false
  end
  if state.ws.connected == true or state.ws.connecting == true then
    return true
  end
  if ensure_websocat_available() ~= true then
    state.debug.last_ws_error = "websocat_missing"
    return false
  end

  local resolved_ws_url = ws_url()
  if type(resolved_ws_url) ~= "string" then
    state.debug.last_ws_error = "invalid_ws_url"
    warn_throttled("ws_url_invalid", "PreviewBridge: invalid WS URL configuration.")
    return false
  end

  state.ws.connecting = true
  set_ws_state("connecting")

  local stdin_pipe = (vim.uv or vim.loop).new_pipe(false)
  local stdout_pipe = (vim.uv or vim.loop).new_pipe(false)
  local stderr_pipe = (vim.uv or vim.loop).new_pipe(false)

  local process_handle, spawn_error = (vim.uv or vim.loop).spawn("websocat", {
    args = { "-t", resolved_ws_url },
    stdio = { stdin_pipe, stdout_pipe, stderr_pipe },
  }, vim.schedule_wrap(function(exit_code, _)
    state.debug.last_ws_error = "ws_exit:" .. tostring(exit_code)
    local should_reconnect = state.enabled == true and state.config.transport == "ws"
    if state.ws.intentional_close == true then
      should_reconnect = false
    end
    state.ws.intentional_close = false
    ws_disconnect(should_reconnect)
  end))

  if process_handle == nil then
    state.ws.connecting = false
    set_ws_state("disconnected")
    state.debug.last_ws_error = tostring(spawn_error)
    warn_throttled("ws_spawn_failed", "PreviewBridge: WS spawn failed (" .. tostring(spawn_error) .. ").")
    ws_close_pipe(stdin_pipe)
    ws_close_pipe(stdout_pipe)
    ws_close_pipe(stderr_pipe)
    ws_schedule_reconnect()
    return false
  end

  state.ws.process = process_handle
  state.ws.stdin_pipe = stdin_pipe
  state.ws.stdout_pipe = stdout_pipe
  state.ws.stderr_pipe = stderr_pipe
  state.ws.stdout_buffer = ""
  state.ws.stderr_buffer = ""
  state.ws.connected = true
  state.ws.connecting = false
  state.ws.reconnect_backoff_ms = state.config.ws_backoff_initial_ms
  state.ws.last_pong_ns = now_ns()
  set_ws_state("connected")

  stdout_pipe:read_start(vim.schedule_wrap(ws_read_stdout))
  stderr_pipe:read_start(vim.schedule_wrap(ws_read_stderr))

  ws_send_hello()
  ws_sync_subscription()
  ws_start_ping_timer()
  return true
end

local function resolve_buffer_path(buffer_number)
  local absolute_path = vim.api.nvim_buf_get_name(buffer_number)
  if absolute_path == "" then
    return nil
  end

  local workspace_roots = {}
  local nearest_git_root = find_nearest_git_root(absolute_path)

  if type(nearest_git_root) == "string" then
    table.insert(workspace_roots, nearest_git_root)
  end

  if type(state.workspace_root) == "string" then
    if nearest_git_root ~= state.workspace_root then
      table.insert(workspace_roots, state.workspace_root)
    end
  end

  local relative_path = logic.normalize_relative_path_from_roots(absolute_path, workspace_roots)
  if type(relative_path) == "string" then
    if relative_path:sub(1, 8) == "content/" then
      return relative_path
    end
  end

  return logic.normalize_content_relative_path(absolute_path)
end

local function is_eligible_buffer(buffer_number)
  local absolute_path = vim.api.nvim_buf_get_name(buffer_number)
  local relative_path = resolve_buffer_path(buffer_number)
  if relative_path == nil then
    state.debug.last_skip_reason = "path_unresolved"
    return false, nil
  end

  local is_eligible = logic.is_eligible_path(relative_path, buffer_number, state.config.file_filter)
  if is_eligible ~= true then
    state.debug.last_skip_reason = "path_ineligible:" .. relative_path
    if relative_path:sub(-3) == ".md" then
      warn_throttled(
        "path_rejected",
        "PreviewBridge: skipped ineligible path '"
          .. relative_path
          .. "' from "
          .. absolute_path
          .. ". Expected content/*.md relative to nearest Git root or /content/ path segment."
      )
    end
    return false, relative_path
  end

  state.debug.last_skip_reason = nil
  return true, relative_path
end

local function ws_set_active_file(file_path)
  if state.ws.active_file_path == file_path then
    return
  end

  state.ws.active_file_path = file_path
  ws_sync_subscription()
end

local function clear_buffer_debounce(buffer_state)
  logic.cancel_debounce(buffer_state)
end

local function get_buffer_state(buffer_number, relative_path)
  local existing_buffer_state = state.buffers[buffer_number]
  if existing_buffer_state ~= nil then
    if relative_path ~= nil then
      existing_buffer_state.relative_path = relative_path
    end
    return existing_buffer_state
  end

  local created_buffer_state = {
    relative_path = relative_path,
    version = 0,
    last_content_hash = nil,
    debounce_timer = nil,
  }
  state.buffers[buffer_number] = created_buffer_state
  return created_buffer_state
end

local function collect_buffer_content(buffer_number)
  local lines = vim.api.nvim_buf_get_lines(buffer_number, 0, -1, false)
  return table.concat(lines, "\n")
end

local function send_upsert(buffer_number)
  if state.enabled ~= true then
    state.debug.last_skip_reason = "bridge_disabled"
    return false
  end

  if vim.api.nvim_buf_is_valid(buffer_number) ~= true then
    state.debug.last_skip_reason = "buffer_invalid"
    return false
  end

  local is_eligible, relative_path = is_eligible_buffer(buffer_number)
  if is_eligible ~= true then
    if buffer_number == vim.api.nvim_get_current_buf() then
      ws_set_active_file(nil)
    end
    return false
  end

  ws_set_active_file(relative_path)

  local buffer_state = get_buffer_state(buffer_number, relative_path)
  local content = collect_buffer_content(buffer_number)
  local content_hash = vim.fn.sha256(content)

  if buffer_state.last_content_hash == content_hash then
    state.debug.last_skip_reason = "content_unchanged"
    return false
  end

  local version = (state.file_versions[relative_path] or 0) + 1
  local upsert_sent = false

  if ws_write_enabled() == true then
    upsert_sent = ws_send_upsert(state.session_id, relative_path, version, content)
    if upsert_sent ~= true and state.config.ws_write_http_fallback ~= true then
      state.debug.last_skip_reason = "ws_write_not_started"
      return false
    end
  end

  if upsert_sent ~= true then
    local payload = logic.build_upsert_payload(state.session_id, relative_path, version, content)
    upsert_sent = post_live_payload_async(payload)
    if upsert_sent ~= true then
      state.debug.last_skip_reason = "request_not_started"
      return false
    end
  end

  state.file_versions[relative_path] = version
  buffer_state.version = version
  buffer_state.last_content_hash = content_hash
  state.debug.last_upsert = {
    file_path = relative_path,
    version = version,
    bytes = #content,
  }
  state.debug.last_skip_reason = nil
  return true
end

local function remove_buffer_state(buffer_number)
  local buffer_state = state.buffers[buffer_number]
  if buffer_state == nil then
    return
  end

  clear_buffer_debounce(buffer_state)
  state.buffers[buffer_number] = nil
end

local function send_close(buffer_number)
  local relative_path = nil
  local buffer_state = state.buffers[buffer_number]

  if buffer_state ~= nil then
    relative_path = buffer_state.relative_path
  end

  if relative_path == nil then
    local is_eligible, resolved_path = is_eligible_buffer(buffer_number)
    if is_eligible ~= true then
      remove_buffer_state(buffer_number)
      return false
    end
    relative_path = resolved_path
  end

  local payload = logic.build_close_payload(state.session_id, relative_path)
  local started = false

  if ws_write_enabled() == true then
    started = ws_send_close(state.session_id, relative_path)
    if started ~= true and state.config.ws_write_http_fallback ~= true then
      state.debug.last_skip_reason = "ws_close_not_started"
    end
  end

  if started ~= true then
    started = post_live_payload_async(payload)
  end

  if started == true then
    state.debug.last_close = {
      file_path = relative_path,
    }
  end
  if state.ws.active_file_path == relative_path then
    ws_set_active_file(nil)
  end

  remove_buffer_state(buffer_number)
  return true
end

local function schedule_upsert(buffer_number)
  if state.enabled ~= true then
    return
  end

  local is_eligible, relative_path = is_eligible_buffer(buffer_number)
  if is_eligible ~= true then
    if buffer_number == vim.api.nvim_get_current_buf() then
      ws_set_active_file(nil)
    end
    return
  end

  ws_set_active_file(relative_path)

  local buffer_state = get_buffer_state(buffer_number, relative_path)
  logic.schedule_debounce(buffer_state, state.config.debounce_ms, function()
    return (vim.uv or vim.loop).new_timer()
  end, vim.schedule_wrap, function()
    send_upsert(buffer_number)
  end)
end

local function close_all_buffers()
  local buffer_numbers = {}
  for buffer_number, _ in pairs(state.buffers) do
    table.insert(buffer_numbers, buffer_number)
  end

  for _, buffer_number in ipairs(buffer_numbers) do
    send_close(buffer_number)
  end
end

local function setup_autocmds()
  if state.autocmd_group ~= nil then
    vim.api.nvim_del_augroup_by_id(state.autocmd_group)
  end

  state.autocmd_group = vim.api.nvim_create_augroup("preview_bridge", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = state.autocmd_group,
    callback = function(args)
      send_upsert(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = state.autocmd_group,
    callback = function(args)
      schedule_upsert(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = state.autocmd_group,
    callback = function(args)
      send_upsert(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = state.autocmd_group,
    callback = function(args)
      send_close(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
    group = state.autocmd_group,
    callback = function()
      close_all_buffers()
    end,
  })
end

local function tracked_buffer_count()
  local count = 0
  for _, _ in pairs(state.buffers) do
    count = count + 1
  end
  return count
end

local function status_lines()
  local lines = {
    "PreviewBridge status:",
    "enabled=" .. tostring(state.enabled),
    "transport=" .. tostring(state.config.transport),
    "session_id=" .. tostring(state.session_id),
    "workspace_root=" .. tostring(state.workspace_root),
    "ws_state=" .. tostring(state.debug.ws_state),
    "ws_url=" .. tostring(ws_url()),
    "ws_subscribe_enabled=" .. tostring(ws_subscription_enabled()),
    "ws_write_enabled=" .. tostring(ws_write_enabled()),
    "ws_write_http_fallback=" .. tostring(state.config.ws_write_http_fallback),
    "ws_active_file=" .. tostring(state.ws.active_file_path),
    "tracked_buffers=" .. tostring(tracked_buffer_count()),
  }

  for buffer_number, buffer_state in pairs(state.buffers) do
    local description = string.format(
      "- bufnr=%s file=%s version=%s",
      tostring(buffer_number),
      tostring(buffer_state.relative_path),
      tostring(buffer_state.version)
    )
    table.insert(lines, description)
  end

  return lines
end

local function debug_lines()
  local pong_age_ms = nil
  if state.ws.last_pong_ns ~= nil then
    pong_age_ms = math.floor((now_ns() - state.ws.last_pong_ns) / (1000 * 1000))
  end

  local lines = {
    "PreviewBridge debug:",
    "last_skip_reason=" .. tostring(state.debug.last_skip_reason),
    "last_transport_error=" .. tostring(state.debug.last_transport_error),
    "last_http_status=" .. tostring(state.debug.last_http_status),
    "last_ws_error=" .. tostring(state.debug.last_ws_error),
    "last_ws_ack_event=" .. tostring(state.debug.last_ws_ack_event),
    "last_ws_ack_applied=" .. tostring(state.debug.last_ws_ack_applied),
    "last_ws_ack_version=" .. tostring(state.debug.last_ws_ack_version),
    "last_ws_ack_removed=" .. tostring(state.debug.last_ws_ack_removed),
    "last_ws_message=" .. tostring(state.debug.last_ws_message),
    "last_open_result=" .. tostring(state.debug.last_open_result),
    "last_open_url=" .. tostring(state.debug.last_open_url),
    "last_open_error=" .. tostring(state.debug.last_open_error),
    "ws_reconnect_attempts=" .. tostring(state.ws.reconnect_attempt_count),
    "last_pong_age_ms=" .. tostring(pong_age_ms),
    "last_warning=" .. tostring(state.debug.last_warning),
  }

  if state.debug.last_upsert ~= nil then
    table.insert(
      lines,
      "last_upsert=file="
        .. tostring(state.debug.last_upsert.file_path)
        .. " version="
        .. tostring(state.debug.last_upsert.version)
        .. " bytes="
        .. tostring(state.debug.last_upsert.bytes)
    )
  else
    table.insert(lines, "last_upsert=nil")
  end

  if state.debug.last_close ~= nil then
    table.insert(lines, "last_close=file=" .. tostring(state.debug.last_close.file_path))
  else
    table.insert(lines, "last_close=nil")
  end

  return lines
end

local function setup_commands()
  vim.api.nvim_create_user_command("PreviewBridgeStatus", function()
    vim.notify(table.concat(status_lines(), "\n"), vim.log.levels.INFO)
  end, { desc = "Show preview bridge status" })

  vim.api.nvim_create_user_command("PreviewBridgeDebug", function()
    vim.notify(table.concat(debug_lines(), "\n"), vim.log.levels.INFO)
  end, { desc = "Show preview bridge debug state" })

  vim.api.nvim_create_user_command("PreviewBridgeReconnect", function()
    ws_disconnect(false)
    preview_bridge.connect_ws()
  end, { desc = "Reconnect preview bridge websocket" })

  vim.api.nvim_create_user_command("PreviewBridgeResubscribe", function()
    if ws_subscription_enabled() ~= true then
      vim.notify("PreviewBridge: websocket subscription is disabled.", vim.log.levels.INFO)
      return
    end

    state.ws.subscribed_file_path = nil
    ws_sync_subscription()
  end, { desc = "Resubscribe current file on websocket" })

  vim.api.nvim_create_user_command("PreviewBridgePush", function()
    local buffer_number = vim.api.nvim_get_current_buf()
    send_upsert(buffer_number)
  end, { desc = "Push current markdown buffer to live preview" })

  vim.api.nvim_create_user_command("PreviewBridgeOpen", function()
    preview_bridge.open_current_buffer()
  end, { desc = "Open current markdown file in preview browser" })

  vim.api.nvim_create_user_command("PreviewBridgeClose", function()
    local buffer_number = vim.api.nvim_get_current_buf()
    send_close(buffer_number)
  end, { desc = "Close current markdown buffer in live preview" })

  vim.api.nvim_create_user_command("PreviewBridgeEnable", function()
    state.enabled = true
    if state.config.transport == "ws" then
      preview_bridge.connect_ws()
    end
  end, { desc = "Enable live markdown preview bridge" })

  vim.api.nvim_create_user_command("PreviewBridgeDisable", function()
    state.enabled = false
    ws_disconnect(false)
    close_all_buffers()
  end, { desc = "Disable live markdown preview bridge" })
end

function preview_bridge.setup(user_config)
  local merged_config = vim.tbl_deep_extend("force", default_config, user_config or {})

  if merged_config.debounce_ms < 1 then
    merged_config.debounce_ms = 1
  end
  if merged_config.ws_ping_interval_ms < 1000 then
    merged_config.ws_ping_interval_ms = 1000
  end
  if merged_config.ws_backoff_initial_ms < 50 then
    merged_config.ws_backoff_initial_ms = 50
  end
  if merged_config.ws_backoff_max_ms < merged_config.ws_backoff_initial_ms then
    merged_config.ws_backoff_max_ms = merged_config.ws_backoff_initial_ms
  end
  if merged_config.transport ~= "ws" then
    merged_config.transport = "http"
  end
  if merged_config.open_fallback_mode ~= "system_open" and merged_config.open_fallback_mode ~= "custom_command" then
    merged_config.open_fallback_mode = "notify_copy"
  end
  if type(merged_config.browser_base_url) == "string" then
    merged_config.browser_base_url = merged_config.browser_base_url:gsub("/+$", "")
  end

  state.config = merged_config
  state.enabled = merged_config.enabled == true

  local configured_workspace_root = normalize_root_path(merged_config.workspace_root)
  if configured_workspace_root ~= nil then
    state.workspace_root = configured_workspace_root
  else
    state.workspace_root = detect_workspace_root()
  end

  if state.session_id == nil then
    state.session_id = create_session_id()
  end

  ensure_curl_available()

  if state.enabled == true and state.config.transport == "ws" then
    preview_bridge.connect_ws()
  else
    ws_disconnect(false)
  end

  setup_autocmds()

  if state.initialized ~= true then
    setup_commands()
  end

  state.initialized = true
end

function preview_bridge.push_current_buffer()
  return send_upsert(vim.api.nvim_get_current_buf())
end

function preview_bridge.open_current_buffer()
  local buffer_number = vim.api.nvim_get_current_buf()
  local is_eligible, relative_path = is_eligible_buffer(buffer_number)
  if is_eligible ~= true then
    state.debug.last_open_error = "open_path_ineligible"
    vim.notify("PreviewBridge: current buffer is not an eligible content/*.md file.", vim.log.levels.WARN)
    return false
  end

  ws_set_active_file(relative_path)
  return request_open_in_browser(relative_path)
end

function preview_bridge.close_current_buffer()
  return send_close(vim.api.nvim_get_current_buf())
end

function preview_bridge.reconnect_ws()
  ws_disconnect(false)
  return preview_bridge.connect_ws()
end

function preview_bridge.resubscribe_ws()
  state.ws.subscribed_file_path = nil
  ws_sync_subscription()
end

preview_bridge._state = state
preview_bridge._logic = logic
preview_bridge._test = {
  post_live_payload_async = post_live_payload_async,
  ws_url = ws_url,
  ws_subscription_enabled = ws_subscription_enabled,
  ws_write_enabled = ws_write_enabled,
}

return preview_bridge

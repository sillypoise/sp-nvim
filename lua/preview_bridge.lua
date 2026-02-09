local logic = require("preview_bridge.logic")

local preview_bridge = {}

local default_config = {
  enabled = true,
  server_url = "http://localhost:3000",
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
  warning_seen = {},
  warning_last_ns = 0,
  debug = {
    last_warning = nil,
    last_skip_reason = nil,
    last_transport_error = nil,
    last_http_status = nil,
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
    return false
  end

  local buffer_state = get_buffer_state(buffer_number, relative_path)
  local content = collect_buffer_content(buffer_number)
  local content_hash = vim.fn.sha256(content)

  if buffer_state.last_content_hash == content_hash then
    state.debug.last_skip_reason = "content_unchanged"
    return false
  end

  if ensure_curl_available() ~= true then
    state.debug.last_skip_reason = "curl_unavailable"
    return false
  end

  local version = (state.file_versions[relative_path] or 0) + 1
  local payload = logic.build_upsert_payload(state.session_id, relative_path, version, content)

  local started = post_live_payload_async(payload)
  if started ~= true then
    state.debug.last_skip_reason = "request_not_started"
    return false
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
  local started = post_live_payload_async(payload)
  if started == true then
    state.debug.last_close = {
      file_path = relative_path,
    }
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
    return
  end

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
    "session_id=" .. tostring(state.session_id),
    "workspace_root=" .. tostring(state.workspace_root),
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
  local lines = {
    "PreviewBridge debug:",
    "last_skip_reason=" .. tostring(state.debug.last_skip_reason),
    "last_transport_error=" .. tostring(state.debug.last_transport_error),
    "last_http_status=" .. tostring(state.debug.last_http_status),
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

  vim.api.nvim_create_user_command("PreviewBridgePush", function()
    local buffer_number = vim.api.nvim_get_current_buf()
    send_upsert(buffer_number)
  end, { desc = "Push current markdown buffer to live preview" })

  vim.api.nvim_create_user_command("PreviewBridgeClose", function()
    local buffer_number = vim.api.nvim_get_current_buf()
    send_close(buffer_number)
  end, { desc = "Close current markdown buffer in live preview" })

  vim.api.nvim_create_user_command("PreviewBridgeEnable", function()
    state.enabled = true
  end, { desc = "Enable live markdown preview bridge" })

  vim.api.nvim_create_user_command("PreviewBridgeDisable", function()
    state.enabled = false
    close_all_buffers()
  end, { desc = "Disable live markdown preview bridge" })
end

function preview_bridge.setup(user_config)
  local merged_config = vim.tbl_deep_extend("force", default_config, user_config or {})

  if merged_config.debounce_ms < 1 then
    merged_config.debounce_ms = 1
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
  setup_autocmds()

  if state.initialized ~= true then
    setup_commands()
  end

  state.initialized = true
end

function preview_bridge.push_current_buffer()
  return send_upsert(vim.api.nvim_get_current_buf())
end

function preview_bridge.close_current_buffer()
  return send_close(vim.api.nvim_get_current_buf())
end

preview_bridge._state = state
preview_bridge._logic = logic
preview_bridge._test = {
  post_live_payload_async = post_live_payload_async,
}

return preview_bridge

local logic = {}

local default_file_filter = "^content/.*%.md$"

local function normalize_separators(path)
  return path:gsub("\\", "/")
end

function logic.normalize_relative_path(absolute_path, workspace_root)
  if type(absolute_path) ~= "string" then
    return nil
  end
  if type(workspace_root) ~= "string" then
    return nil
  end

  local normalized_absolute_path = normalize_separators(absolute_path)
  local normalized_workspace_root = normalize_separators(workspace_root)

  if normalized_workspace_root:sub(-1) == "/" then
    normalized_workspace_root = normalized_workspace_root:sub(1, -2)
  end

  local root_prefix = normalized_workspace_root .. "/"
  if normalized_absolute_path:sub(1, #root_prefix) ~= root_prefix then
    return nil
  end

  return normalized_absolute_path:sub(#root_prefix + 1)
end

function logic.normalize_relative_path_from_roots(absolute_path, workspace_roots)
  if type(workspace_roots) ~= "table" then
    return nil
  end

  local best_relative_path = nil
  local best_root_length = -1

  for _, workspace_root in ipairs(workspace_roots) do
    local relative_path = logic.normalize_relative_path(absolute_path, workspace_root)
    if relative_path ~= nil then
      local root_length = #tostring(workspace_root)
      if root_length > best_root_length then
        best_relative_path = relative_path
        best_root_length = root_length
      end
    end
  end

  return best_relative_path
end

function logic.normalize_content_relative_path(absolute_path)
  if type(absolute_path) ~= "string" then
    return nil
  end

  local normalized_absolute_path = normalize_separators(absolute_path)
  local content_index = normalized_absolute_path:find("/content/", 1, true)
  if content_index == nil then
    return nil
  end

  return normalized_absolute_path:sub(content_index + 1)
end

function logic.is_valid_preview_path(relative_path)
  if type(relative_path) ~= "string" then
    return false
  end
  if relative_path == "" then
    return false
  end
  if relative_path:sub(1, 1) == "/" then
    return false
  end
  if relative_path:find("\\", 1, true) ~= nil then
    return false
  end
  if relative_path:sub(1, 8) ~= "content/" then
    return false
  end
  if relative_path:sub(-3) ~= ".md" then
    return false
  end

  for segment in relative_path:gmatch("[^/]+") do
    if segment == ".." then
      return false
    end
  end

  return true
end

function logic.matches_file_filter(relative_path, buffer_number, file_filter)
  local filter_value = file_filter
  if filter_value == nil then
    filter_value = default_file_filter
  end

  if type(filter_value) == "string" then
    return relative_path:match(filter_value) ~= nil
  end

  if type(filter_value) == "function" then
    local call_ok, filter_result = pcall(filter_value, relative_path, buffer_number)
    if call_ok ~= true then
      return false
    end
    return filter_result == true
  end

  return false
end

function logic.is_eligible_path(relative_path, buffer_number, file_filter)
  if logic.is_valid_preview_path(relative_path) ~= true then
    return false
  end

  return logic.matches_file_filter(relative_path, buffer_number, file_filter)
end

function logic.next_version(file_versions, relative_path)
  local current_version = file_versions[relative_path]
  if current_version == nil then
    current_version = 0
  end

  local next_version = current_version + 1
  file_versions[relative_path] = next_version
  return next_version
end

function logic.build_upsert_payload(session_id, relative_path, version, content)
  return {
    action = "upsert",
    sessionId = session_id,
    filePath = relative_path,
    version = version,
    content = content,
  }
end

function logic.build_close_payload(session_id, relative_path)
  return {
    action = "close",
    sessionId = session_id,
    filePath = relative_path,
  }
end

function logic.parse_curl_response(stdout)
  if type(stdout) ~= "string" then
    return 0, ""
  end

  local status_code = tonumber(stdout:match("\n(%d%d%d)%s*$"))
  if status_code == nil then
    return 0, stdout
  end

  local response_body = stdout:gsub("\n%d%d%d%s*$", "")
  return status_code, response_body
end

function logic.schedule_debounce(buffer_state, debounce_ms, timer_factory, schedule_wrap, callback)
  if buffer_state.debounce_timer == nil then
    buffer_state.debounce_timer = timer_factory()
  end

  local debounce_timer = buffer_state.debounce_timer
  debounce_timer:stop()
  debounce_timer:start(debounce_ms, 0, schedule_wrap(callback))
end

function logic.cancel_debounce(buffer_state)
  if buffer_state.debounce_timer == nil then
    return
  end

  buffer_state.debounce_timer:stop()
  buffer_state.debounce_timer:close()
  buffer_state.debounce_timer = nil
end

return logic

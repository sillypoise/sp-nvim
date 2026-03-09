return {
  {
    "preview-bridge/local",
    name = "preview-bridge",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    opts = {
      enabled = false,
      transport = "ws",
      -- sagamd profile (default)
      server_url = "http://sp-dev:3101",
      browser_base_url = "http://sp-dev:3101",
      ws_url = nil,
      ws_subscribe_enabled = false,
      ws_write_enabled = true,
      ws_write_http_fallback = true,
      open_fallback_mode = "notify_copy",
      open_custom_command = nil,
      max_payload_bytes = 1000000,
      ws_ping_interval_ms = 15000,
      ws_backoff_initial_ms = 250,
      ws_backoff_max_ms = 2000,
      debounce_ms = 100,
      -- Must align with PREVIEW_ALLOWED_PREFIX=/sagamd/notes/
      file_filter = "^sagamd/notes/.*%.md$",
      workspace_root = vim.fn.expand("~/personal"),
    },
    config = function(_, opts)
      local preview_bridge = require("preview_bridge")
      local active_profile = "sagamd"

      local profiles = {
        sagamd = vim.deepcopy(opts),
        blog = vim.tbl_deep_extend("force", vim.deepcopy(opts), {
          server_url = "http://localhost:3000",
          browser_base_url = "http://localhost:3000",
          file_filter = "^content/.*%.md$",
          workspace_root = nil,
        }),
      }

      local function apply_profile(name, notify_user)
        local profile_opts = profiles[name]
        if type(profile_opts) ~= "table" then
          vim.notify("PreviewBridge: unknown profile '" .. tostring(name) .. "'.", vim.log.levels.WARN)
          return false
        end

        local effective_opts = vim.deepcopy(profile_opts)
        if preview_bridge._state ~= nil and preview_bridge._state.initialized == true then
          effective_opts.enabled = preview_bridge._state.enabled == true
        end

        preview_bridge.setup(effective_opts)
        active_profile = name

        if notify_user == true then
          vim.notify(
            "PreviewBridge profile switched to '"
              .. active_profile
              .. "' ("
              .. tostring(effective_opts.server_url)
              .. ")",
            vim.log.levels.INFO
          )
        end

        return true
      end

      local function set_command(name, rhs, description)
        pcall(vim.api.nvim_del_user_command, name)
        vim.api.nvim_create_user_command(name, rhs, { desc = description })
      end

      apply_profile(active_profile, false)

      set_command("PreviewBridgeProfileSagamd", function()
        apply_profile("sagamd", true)
      end, "Switch PreviewBridge profile to sagamd")

      set_command("PreviewBridgeProfileBlog", function()
        apply_profile("blog", true)
      end, "Switch PreviewBridge profile to blog")

      set_command("PreviewBridgeProfileToggle", function()
        local next_profile = active_profile == "sagamd" and "blog" or "sagamd"
        apply_profile(next_profile, true)
      end, "Toggle PreviewBridge profile")

      set_command("PreviewBridgeProfileStatus", function()
        local active_opts = profiles[active_profile] or {}
        vim.notify(
          table.concat({
            "PreviewBridge profile status:",
            "active_profile=" .. tostring(active_profile),
            "server_url=" .. tostring(active_opts.server_url),
            "browser_base_url=" .. tostring(active_opts.browser_base_url),
            "file_filter=" .. tostring(active_opts.file_filter),
            "workspace_root=" .. tostring(active_opts.workspace_root),
          }, "\n"),
          vim.log.levels.INFO
        )
      end, "Show PreviewBridge profile status")
    end,
  },
}

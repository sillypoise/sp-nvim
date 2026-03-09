return {
  {
    "preview-bridge/local",
    name = "preview-bridge",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    opts = {
      enabled = false,
      transport = "ws",
      -- sagamd container
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
      -- IMPORTANT: must align with PREVIEW_ALLOWED_PREFIX=/sagamd/notes/
      file_filter = "^sagamd/notes/.*%.md$",
      workspace_root = vim.fn.expand("~/personal"),
    },
    config = function(_, opts)
      require("preview_bridge").setup(opts)
    end,
  },
}

return {
  {
    "preview-bridge/local",
    name = "preview-bridge",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    opts = {
      enabled = true,
      transport = "ws",
      server_url = "http://localhost:3000",
      ws_url = nil,
      ws_subscribe_enabled = true,
      ws_write_enabled = true,
      ws_write_http_fallback = true,
      ws_ping_interval_ms = 15000,
      ws_backoff_initial_ms = 250,
      ws_backoff_max_ms = 2000,
      debounce_ms = 100,
      file_filter = "^content/.*%.md$",
      workspace_root = nil,
    },
    config = function(_, opts)
      require("preview_bridge").setup(opts)
    end,
  },
}

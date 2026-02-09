return {
  {
    "preview-bridge/local",
    name = "preview-bridge",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    opts = {
      enabled = true,
      server_url = "http://localhost:3000",
      debounce_ms = 100,
      file_filter = "^content/.*%.md$",
      workspace_root = nil,
    },
    config = function(_, opts)
      require("preview_bridge").setup(opts)
    end,
  },
}

return {
  "mason-org/mason-lspconfig.nvim",
  opts = {
    ensure_installed = {
      "clangd",
      "gopls",
      "just",
      "oxlint",
      -- "tsgo",
      -- "vtsls",
    },
  },
}

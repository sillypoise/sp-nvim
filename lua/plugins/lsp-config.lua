return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      marksman = {},
    },
    -- -- Enable this to enable the builtin LSP code lenses on Neovim >= 0.10.0
    -- -- Be aware that you also will need to properly configure your LSP server to
    -- -- provide the code lenses.
    -- codelens = {
    --   enabled = false,
    -- },
  },
}

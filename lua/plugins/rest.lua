return {
  "rest-nvim/rest.nvim",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "j-hui/fidget.nvim",
  },
  ft = { "http", "rest" },
  rocks = {
    "mimetypes",
    "xml2lua",
    "tree-sitter-http",
  },
}

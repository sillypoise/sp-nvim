return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      oxlint = {},
      tsgo = {},
      vtsls = { enabled = false },
      tinymist = {
        keys = {
          {
            "<leader>cP",
            function()
              local buf_name = vim.api.nvim_buf_get_name(0)
              local file_name = vim.fn.fnamemodify(buf_name, ":t")
              LazyVim.lsp.execute({
                command = "tinymist.pinMain",
                arguments = { buf_name },
              })
              LazyVim.info("Tinymist: Pinned " .. file_name)
            end,
            desc = "Pin main file",
          },
        },
        single_file_support = true,
        settings = {
          formatterMode = "typstyle",
        },
      },
    },
  },
}

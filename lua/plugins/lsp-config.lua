return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      oxlint = {
        cmd = { vim.fn.stdpath("data") .. "/mason/bin/oxlint", "--lsp" },
      },
      tsgo = {
        cmd = { vim.fn.stdpath("data") .. "/mason/bin/tsgo", "--lsp", "--stdio" },
      },
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

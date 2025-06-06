return {
  "stevearc/conform.nvim",
  optional = true,
  opts = {
    formatters = {
      ["markdown-toc"] = {
        condition = function(_, ctx)
          for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
            if line:find("<!%-%- toc %-%->") then
              return true
            end
          end
        end,
      },
      ["markdownlint-cli2"] = {
        condition = function(_, ctx)
          local diag = vim.tbl_filter(function(d)
            return d.source == "markdownlint"
          end, vim.diagnostic.get(ctx.buf))
          return #diag > 0
        end,
      },
    },
    formatters_by_ft = {
      ["astro"] = { "astro" },
      ["json"] = { "biome", "jq" },
      ["javascript"] = { "biome" },
      ["javascriptreact"] = { "biome" },
      ["typescript"] = { "biome" },
      ["typescriptreact"] = { "biome" },
      ["markdown"] = { "prettierd", "markdownlint-cli2", "markdown-toc" },
      ["markdown.mdx"] = { "prettierd", "markdownlint-cli2", "markdown-toc" },
    },
  },
}

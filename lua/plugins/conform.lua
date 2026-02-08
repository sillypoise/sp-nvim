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
      ["css"] = { "oxfmt" },
      ["graphql"] = { "oxfmt" },
      ["handlebars"] = { "oxfmt" },
      ["hbs"] = { "oxfmt" },
      ["html"] = { "oxfmt" },
      ["htmlangular"] = { "oxfmt" },
      ["javascript"] = { "oxlint", "oxfmt" },
      ["javascriptreact"] = { "oxlint", "oxfmt" },
      ["json"] = { "oxfmt" },
      ["jsonc"] = { "oxfmt" },
      ["json5"] = { "oxfmt" },
      ["less"] = { "oxfmt" },
      ["markdown"] = { "oxfmt", "markdownlint-cli2", "markdown-toc" },
      ["mdx"] = { "oxfmt", "markdownlint-cli2", "markdown-toc" },
      ["markdown.mdx"] = { "oxfmt", "markdownlint-cli2", "markdown-toc" },
      ["scss"] = { "oxfmt" },
      ["toml"] = { "oxfmt" },
      ["typescript"] = { "oxlint", "oxfmt" },
      ["typescriptreact"] = { "oxlint", "oxfmt" },
      ["typst"] = { "typstyle", lsp_format = "prefer" },
      ["vue"] = { "oxfmt" },
      ["yaml"] = { "oxfmt" },
    },
  },
}

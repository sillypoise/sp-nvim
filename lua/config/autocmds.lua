-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local anki_group = vim.api.nvim_create_augroup("anki_markdown", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = anki_group,
  pattern = "markdown",
  callback = function(args)
    vim.keymap.set("x", "<leader>ac", "<leader>cwac3h", {
      buffer = args.buf,
      remap = true,
      desc = "Wrap selection as Anki cloze",
    })
  end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = anki_group,
  pattern = "*.anki.md",
  callback = function(args)
    vim.b[args.buf].autoformat = false
  end,
})

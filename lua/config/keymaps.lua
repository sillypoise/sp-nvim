-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Escape with jk
vim.keymap.set("i", "jk", "<Esc>")

-- osc52 support
local osc52 = require("osc52")

vim.keymap.set("n", "<leader>y", require("osc52").copy_operator, { expr = true })
vim.keymap.set("n", "<leader>yy", "<leader>y_", { remap = true })
vim.keymap.set("v", "<leader>y", require("osc52").copy_visual)

-- Function to get the current file's path relative to the monorepo root
local function copy_file_path()
  -- Get the working directory (assumed to be the monorepo root)
  local root_dir = vim.fn.getcwd()
  -- Get the current file's absolute path
  local file_path = vim.fn.expand("%:p")
  -- Get the relative path from the root directory
  local relative_path = vim.fn.fnamemodify(file_path, ":~:.")
  -- Copy the relative path to the clipboard using OSC52
  osc52.copy(relative_path)
  print("Copied: " .. relative_path)
end

-- Map the keybinding to copy the file path to clipboard
vim.keymap.set("n", "<leader>yf", copy_file_path, { desc = "Copy file path to clipboard using OSC52" })

return {
  "bullets-vim/bullets.vim",
  init = function()
    -- Enable bullets.vim only for these filetypes
    vim.g.bullets_enabled_file_types = {
      "markdown",
      "text",
      "gitcommit",
    }

    -- Optional: define the bullet characters per indentation level
    -- First level: • Second level: ◦ Third level: ▪
    -- vim.g.bullets_symbol_map = { "•", "◦", "▪" }

    -- Optional: enable automatic renumbering for numbered lists
    -- vim.g.bullets_auto_renumber = 1

    -- Optional: checkbox support
    -- vim.g.bullets_checkbox_markers = " x"

    -- Optional: let <CR> insert a new bullet
    -- This is default behavior, but you can customize it
    -- Leave it out if it interferes with other plugins
    vim.g.bullets_custom_mappings = {
      { "imap", "<CR>", "<Plug>(bullets-newline)" },
      { "inoremap", "<C-CR>", "<CR>" },

      { "nmap", "o", "<Plug>(bullets-newline)" },

      { "vmap", "gN", "<Plug>(bullets-renumber)" },
      { "nmap", "gN", "<Plug>(bullets-renumber)" },

      { "nmap", "<leader>x", "<Plug>(bullets-toggle-checkbox)" },

      { "imap", "<C-f>", "<Plug>(bullets-demote)" },
      { "nmap", ">>", "<Plug>(bullets-demote)" },
      { "vmap", ">", "<Plug>(bullets-demote)" },

      { "imap", "<C-d>", "<Plug>(bullets-promote)" },
      { "nmap", "<<", "<Plug>(bullets-promote)" },
      { "vmap", "<", "<Plug>(bullets-promote)" },
    }
  end,
}

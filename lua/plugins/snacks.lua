return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = true },
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
            },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
            { icon = " ", key = "<esc>", desc = "Quit", action = ":qa" },
          },

          -- https://patorjk.com/software/taag/#p=testall&f=Banner&t=sillypoise
          header = [[ 


     _____________/\/\____/\/\____/\/\________________________________________/\/\___________________________
    ___/\/\/\/\__________/\/\____/\/\____/\/\__/\/\__/\/\/\/\______/\/\/\______________/\/\/\/\____/\/\/\___ 
   _/\/\/\/\____/\/\____/\/\____/\/\____/\/\__/\/\__/\/\__/\/\__/\/\__/\/\__/\/\____/\/\/\/\____/\/\/\/\/\_  
  _______/\/\__/\/\____/\/\____/\/\______/\/\/\/\__/\/\/\/\____/\/\__/\/\__/\/\__________/\/\__/\/\_______   
 _/\/\/\/\____/\/\/\__/\/\/\__/\/\/\________/\/\__/\/\__________/\/\/\____/\/\/\__/\/\/\/\______/\/\/\/\_    
_____________________________________/\/\/\/\____/\/\___________________________________________________     



s i l l y p o i s e . i o 


          ]],
        },
      },
      dim = { enabled = true },
      explorer = {
        enabled = true,
        replace_netrw = true, -- Replace netrw with the snacks explorer
      },
      image = {
        enabled = true,
        doc = {
          -- Personally I set this to false, I don't want to render all the
          -- images in the file, only when I hover over them
          -- render the image inline in the buffer
          -- if your env doesn't support unicode placeholders, this will be disabled
          -- takes precedence over `opts.float` on supported terminals
          inline = vim.g.neovim_mode == "skitty" and true or false,
          -- only_render_image_at_cursor = vim.g.neovim_mode == "skitty" and false or true,
          -- render the image in a floating window
          -- only used if `opts.inline` is disabled
          float = true,
          -- Sets the size of the image
          -- max_width = 60,
          -- max_width = vim.g.neovim_mode == "skitty" and 20 or 60,
          -- max_height = vim.g.neovim_mode == "skitty" and 10 or 30,
          max_width = vim.g.neovim_mode == "skitty" and 5 or 60,
          max_height = vim.g.neovim_mode == "skitty" and 2.5 or 30,
          -- max_height = 30,
          -- Apparently, all the images that you preview in neovim are converted
          -- to .png and they're cached, original image remains the same, but
          -- the preview you see is a png converted version of that image
          --
          -- Where are the cached images stored?
          -- This path is found in the docs
          -- :lua print(vim.fn.stdpath("cache") .. "/snacks/image")
          -- For me returns `~/.cache/neobean/snacks/image`
          -- Go 1 dir above and check `sudo du -sh ./* | sort -hr | head -n 5`
        },
      },
      indent = { enabled = true },
      input = { enabled = true },
      ---@class snacks.picker.matcher.Config
      matcher = {
        fuzzy = true, -- use fuzzy matching
        smartcase = true, -- use smartcase
        ignorecase = true, -- use ignorecase
        sort_empty = false, -- sort results when the search string is empty
        filename_bonus = true, -- give bonus for matching file names (last part of the path)
        file_pos = true, -- support patterns like `file:line:col` and `file:line`
        -- the bonusses below, possibly require string concatenation and path normalization,
        -- so this can have a performance impact for large lists and increase memory usage
        cwd_bonus = false, -- give bonus for matching files in the cwd
        frecency = true, -- frecency bonus
        history_bonus = false, -- give more weight to chronological order
      },
      picker = {
        enabled = true,
        sources = {
          explorer = {
            layout = { layout = { position = "right" } },
            win = {
              list = {
                keys = {
                  ["<BS>"] = "explorer_up",
                  ["l"] = "confirm",
                  ["h"] = "explorer_close", -- close directory
                  ["a"] = "explorer_add",
                  ["d"] = "explorer_del",
                  ["r"] = "explorer_rename",
                  ["c"] = "explorer_copy",
                  ["m"] = "explorer_move",
                  ["o"] = "explorer_open", -- open with system application
                  ["P"] = "toggle_preview",
                  ["y"] = { "explorer_yank", mode = { "n", "x" } },
                  ["p"] = "explorer_paste",
                  ["u"] = "explorer_update",
                  ["<c-c>"] = "tcd",
                  ["<leader>/"] = "picker_grep",
                  ["<c-t>"] = "terminal",
                  ["."] = "explorer_focus",
                  ["I"] = "toggle_ignored",
                  ["H"] = "toggle_hidden",
                  ["Z"] = "explorer_close_all",
                  ["]g"] = "explorer_git_next",
                  ["[g"] = "explorer_git_prev",
                  ["]d"] = "explorer_diagnostic_next",
                  ["[d"] = "explorer_diagnostic_prev",
                  ["]w"] = "explorer_warn_next",
                  ["[w"] = "explorer_warn_prev",
                  ["]e"] = "explorer_error_next",
                  ["[e"] = "explorer_error_prev",
                },
              },
            },
          },
          keymaps = {
            layout = "vertical",
          },
        },
        win = {
          -- input window
          input = {
            keys = {
              -- to close the picker on ESC instead of going to normal mode,
              -- add the following keymap to your config
              -- ["<Esc>"] = { "close", mode = { "n", "i" } },
              ["/"] = "toggle_focus",
              ["<C-Down>"] = { "history_forward", mode = { "i", "n" } },
              ["<C-Up>"] = { "history_back", mode = { "i", "n" } },
              ["<C-c>"] = { "cancel", mode = "i" },
              ["<C-w>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
              ["<CR>"] = { "confirm", mode = { "n", "i" } },
              ["<Down>"] = { "list_down", mode = { "i", "n" } },
              ["<Esc>"] = "cancel",
              ["<S-CR>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
              ["<S-Tab>"] = { "select_and_prev", mode = { "i", "n" } },
              ["<Tab>"] = { "select_and_next", mode = { "i", "n" } },
              ["<Up>"] = { "list_up", mode = { "i", "n" } },
              ["<leader>pd"] = { "inspect", mode = { "n", "i" }, desc = "Inspect item" },
              ["<leader>puf"] = { "toggle_follow", mode = { "i", "n" }, desc = "Toggle follow mode" },
              ["<leader>puh"] = { "toggle_hidden", mode = { "i", "n" }, desc = "Toggle hidden files" },
              ["<leader>pui"] = { "toggle_ignored", mode = { "i", "n" }, desc = "Toggle ignored files" },
              ["<a-m>"] = { "toggle_maximize", mode = { "i", "n" } },
              ["<leader>pup"] = { "toggle_preview", mode = { "i", "n" }, desc = "Toggle preview panel" },
              ["<a-w>"] = { "cycle_win", mode = { "i", "n" } },
              ["<c-a>"] = { "select_all", mode = { "n", "i" } },
              ["<c-b>"] = { "preview_scroll_up", mode = { "i", "n" } },
              ["<c-d>"] = { "list_scroll_down", mode = { "i", "n" } },
              ["<c-f>"] = { "preview_scroll_down", mode = { "i", "n" } },
              ["<c-g>"] = { "toggle_live", mode = { "i", "n" } },
              ["<c-j>"] = { "list_down", mode = { "i", "n" } },
              ["<c-k>"] = { "list_up", mode = { "i", "n" } },
              ["<c-n>"] = { "list_down", mode = { "i", "n" } },
              ["<c-p>"] = { "list_up", mode = { "i", "n" } },
              ["<c-q>"] = { "qflist", mode = { "i", "n" } },
              ["<c-s>"] = { "edit_split", mode = { "i", "n" } },
              ["<c-t>"] = { "tab", mode = { "n", "i" } },
              ["<c-u>"] = { "list_scroll_up", mode = { "i", "n" } },
              ["<c-v>"] = { "edit_vsplit", mode = { "i", "n" } },
              ["<c-r>#"] = { "insert_alt", mode = "i" },
              ["<c-r>%"] = { "insert_filename", mode = "i" },
              ["<c-r><c-a>"] = { "insert_cWORD", mode = "i" },
              ["<c-r><c-f>"] = { "insert_file", mode = "i" },
              ["<c-r><c-l>"] = { "insert_line", mode = "i" },
              ["<c-r><c-p>"] = { "insert_file_full", mode = "i" },
              ["<c-r><c-w>"] = { "insert_cword", mode = "i" },
              ["<c-w>H"] = "layout_left",
              ["<c-w>J"] = "layout_bottom",
              ["<c-w>K"] = "layout_top",
              ["<c-w>L"] = "layout_right",
              ["?"] = "toggle_help_input",
              ["G"] = "list_bottom",
              ["gg"] = "list_top",
              ["j"] = "list_down",
              ["k"] = "list_up",
              ["q"] = "close",
            },
            b = {
              minipairs_disable = true,
            },
          },
          -- result list window
          list = {
            keys = {
              ["/"] = "toggle_focus",
              ["<2-LeftMouse>"] = "confirm",
              ["<CR>"] = "confirm",
              ["<Down>"] = "list_down",
              ["<Esc>"] = "cancel",
              ["<S-CR>"] = { { "pick_win", "jump" } },
              ["<S-Tab>"] = { "select_and_prev", mode = { "n", "x" } },
              ["<Tab>"] = { "select_and_next", mode = { "n", "x" } },
              ["<Up>"] = "list_up",
              ["<a-d>"] = "inspect",
              ["<a-f>"] = "toggle_follow",
              ["<a-h>"] = "toggle_hidden",
              ["<a-i>"] = "toggle_ignored",
              ["<a-m>"] = "toggle_maximize",
              ["<a-p>"] = "toggle_preview",
              ["<a-w>"] = "cycle_win",
              ["<c-a>"] = "select_all",
              ["<c-b>"] = "preview_scroll_up",
              ["<c-d>"] = "list_scroll_down",
              ["<c-f>"] = "preview_scroll_down",
              ["<c-j>"] = "list_down",
              ["<c-k>"] = "list_up",
              ["<c-n>"] = "list_down",
              ["<c-p>"] = "list_up",
              ["<c-q>"] = "qflist",
              ["<c-s>"] = "edit_split",
              ["<c-t>"] = "tab",
              ["<c-u>"] = "list_scroll_up",
              ["<c-v>"] = "edit_vsplit",
              ["<c-w>H"] = "layout_left",
              ["<c-w>J"] = "layout_bottom",
              ["<c-w>K"] = "layout_top",
              ["<c-w>L"] = "layout_right",
              ["?"] = "toggle_help_list",
              ["G"] = "list_bottom",
              ["gg"] = "list_top",
              ["i"] = "focus_input",
              ["j"] = "list_down",
              ["k"] = "list_up",
              ["q"] = "close",
              ["zb"] = "list_scroll_bottom",
              ["zt"] = "list_scroll_top",
              ["zz"] = "list_scroll_center",
            },
            wo = {
              conceallevel = 2,
              concealcursor = "nvc",
            },
          },
        },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        scope = { enabled = true },
        scroll = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
      },
    },
  },
}

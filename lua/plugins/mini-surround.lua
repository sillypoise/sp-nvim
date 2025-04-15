return {
  "echasnovski/mini.surround",
  version = false,
  keys = function(_, keys)
    -- Populate the keys based on the user's options
    local opts = LazyVim.opts("mini.surround")
    local mappings = {
      { opts.mappings.add, desc = "Add Surrounding", mode = { "n", "v" } },
      { opts.mappings.delete, desc = "Delete Surrounding" },
      { opts.mappings.find, desc = "Find Right Surrounding" },
      { opts.mappings.find_left, desc = "Find Left Surrounding" },
      { opts.mappings.highlight, desc = "Highlight Surrounding" },
      { opts.mappings.replace, desc = "Replace Surrounding" },
      { opts.mappings.update_n_lines, desc = "Update `MiniSurround.config.n_lines`" },
    }
    mappings = vim.tbl_filter(function(m)
      return m[1] and #m[1] > 0
    end, mappings)
    return vim.list_extend(mappings, keys)
  end,
  opts = {
    custom_surroundings = {
      -- Override `[` to have no space padding
      ["["] = {
        input = { "%b[]", "^.%s*", ".%s*$" },
        output = function()
          return { left = "[", right = "]" }
        end,
      },
      -- Override `(` to have no padding
      ["("] = {
        input = { "%b()", "^.%s*", ".%s*$" },
        output = function()
          return { left = "(", right = ")" }
        end,
      },
      -- New bold surrounding
      ["b"] = {
        input = { "%*%*.-%*%*", "^%*%*", "%*%*$" },
        output = function()
          return { left = "**", right = "**" }
        end,
      },
    },
    mappings = {
      add = "<leader>cwa", -- Add surrounding in Normal and Visual modes
      delete = "<leader>cwd", -- Delete surrounding
      find = "<leader>cwf", -- Find surrounding (to the right)
      find_left = "<leader>cwF", -- Find surrounding (to the left)
      highlight = "<leader>cwh", -- Highlight surrounding
      replace = "<leader>cwr", -- Replace surrounding
      update_n_lines = "<leader>cwn", -- Update `n_lines`
    },
  },
}

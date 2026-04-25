local function current_working_directory()
  return vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
end

local function root_directory()
  if type(LazyVim) == "table" then
    if type(LazyVim.root) == "function" then
      return LazyVim.root({ normalize = true }) or current_working_directory()
    end
  end

  return current_working_directory()
end

local function visual_selection_or_current_word()
  local mode = vim.fn.mode()
  local is_visual_mode = false
  if mode == "v" then
    is_visual_mode = true
  elseif mode == "V" then
    is_visual_mode = true
  elseif mode == string.char(22) then
    is_visual_mode = true
  end

  if is_visual_mode then
    local start_position = vim.fn.getpos("'<")
    local end_position = vim.fn.getpos("'>")
    local start_row = start_position[2] - 1
    local start_column = start_position[3] - 1
    local end_row = end_position[2] - 1
    local end_column = end_position[3]
    local lines = vim.api.nvim_buf_get_text(0, start_row, start_column, end_row, end_column, {})
    local selection = table.concat(lines, "\n")
    selection = vim.trim(selection)

    if selection ~= "" then
      return selection
    end
  end

  return vim.fn.expand("<cword>")
end

local function fff_find_files_root()
  require("fff").find_files_in_dir(root_directory())
end

local function fff_find_files_cwd()
  require("fff").find_files_in_dir(current_working_directory())
end

local function fff_find_config_files()
  require("fff").find_files_in_dir(vim.fn.stdpath("config"))
end

local function fff_live_grep_root(query)
  require("fff").live_grep({ cwd = root_directory(), query = query })
end

local function fff_live_grep_cwd(query)
  require("fff").live_grep({ cwd = current_working_directory(), query = query })
end

local function search_current_buffer_lines()
  Snacks.picker.lines({ layout = "bottom" })
end

local function fff_live_grep_word_root()
  fff_live_grep_root(visual_selection_or_current_word())
end

local function fff_live_grep_word_cwd()
  fff_live_grep_cwd(visual_selection_or_current_word())
end

return {
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    lazy = false,
    opts = {
      lazy_sync = true,
      max_results = 100,
      layout = {
        prompt_position = "top",
      },
      preview = {
        enabled = true,
        line_numbers = false,
        wrap_lines = false,
      },
      keymaps = {
        close = "<Esc>",
        select = "<CR>",
        select_split = "<C-s>",
        select_vsplit = "<C-v>",
        select_tab = "<C-t>",
        move_up = { "<Up>", "<C-p>" },
        move_down = { "<Down>", "<C-n>" },
        preview_scroll_up = "<C-u>",
        preview_scroll_down = "<C-d>",
        toggle_select = "<Tab>",
        send_to_quickfix = "<C-q>",
      },
      grep = {
        smart_case = true,
        modes = { "plain", "regex", "fuzzy" },
      },
      frecency = {
        enabled = true,
      },
      history = {
        enabled = true,
      },
      debug = {
        enabled = false,
        show_scores = false,
      },
      logging = {
        enabled = true,
        log_level = "info",
      },
    },
    keys = {
      { "<leader>/", fff_live_grep_root, desc = "Grep (Root Dir)" },
      { "<leader><space>", fff_find_files_root, desc = "Find Files (Root Dir)" },
      { "<leader>fc", fff_find_config_files, desc = "Find Config File" },
      { "<leader>ff", fff_find_files_root, desc = "Find Files (Root Dir)" },
      { "<leader>fF", fff_find_files_cwd, desc = "Find Files (cwd)" },
      { "<leader>sb", search_current_buffer_lines, desc = "Buffer Lines" },
      { "<leader>sg", fff_live_grep_root, desc = "Grep (Root Dir)" },
      { "<leader>sG", fff_live_grep_cwd, desc = "Grep (cwd)" },
      { "<leader>sw", fff_live_grep_word_root, desc = "Visual selection or word (Root Dir)", mode = { "n", "x" } },
      { "<leader>sW", fff_live_grep_word_cwd, desc = "Visual selection or word (cwd)", mode = { "n", "x" } },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>fB", function() Snacks.picker.buffers({ hidden = true, nofile = true }) end, desc = "Buffers (all)" },
      { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
      { "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Recent (cwd)" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
      { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (hunks)" },
      { "<leader>gD", function() Snacks.picker.git_diff({ base = "origin", group = true }) end, desc = "Git Diff (origin)" },
      { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
      { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
      { "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "GitHub Issues (open)" },
      { "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub Issues (all)" },
      { "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "GitHub Pull Requests (open)" },
      { "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub Pull Requests (all)" },
      { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
      { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
      { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
      { "<leader>s/", function() Snacks.picker.search_history() end, desc = "Search History" },
      { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
      { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
      { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
      { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
      { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
      { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
      { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
      { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
      { "<leader>su", function() Snacks.picker.undo() end, desc = "Undotree" },
      { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition", has = "definition" },
            { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
            { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
            { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
            {
              "<leader>ss",
              function() Snacks.picker.lsp_symbols({ filter = LazyVim.config.kind_filter }) end,
              desc = "LSP Symbols",
              has = "documentSymbol",
            },
            {
              "<leader>sS",
              function() Snacks.picker.lsp_workspace_symbols({ filter = LazyVim.config.kind_filter }) end,
              desc = "LSP Workspace Symbols",
              has = "workspace/symbols",
            },
            { "gai", function() Snacks.picker.lsp_incoming_calls() end, desc = "C[a]lls Incoming", has = "callHierarchy/incomingCalls" },
            { "gao", function() Snacks.picker.lsp_outgoing_calls() end, desc = "C[a]lls Outgoing", has = "callHierarchy/outgoingCalls" },
          },
        },
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    optional = true,
    keys = {
      { "<leader>st", function() Snacks.picker.todo_comments() end, desc = "Todo" },
      { "<leader>sT", function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, desc = "Todo/Fix/Fixme" },
    },
  },
}

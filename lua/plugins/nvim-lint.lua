local golangci_lint_cmd = vim.fn.stdpath("data") .. "/mason/bin/golangci-lint"

local function golangci_lint_args()
  local version_info = vim.fn.system({ golangci_lint_cmd, "version" })

  -- Keep v1 compatibility in case Mason registry ever backtracks/pins.
  if version_info:find("version v1", 1, true) or version_info:find("version 1", 1, true) then
    return {
      "run",
      "--out-format",
      "json",
      "--issues-exit-code=0",
      "--show-stats=false",
      "--print-issued-lines=false",
      "--print-linter-name=false",
      function()
        return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
      end,
    }
  end

  -- v2 JSON output flags; avoids parser errors from plain help text.
  return {
    "run",
    "--output.json.path=stdout",
    "--output.text.path=",
    "--output.tab.path=",
    "--output.html.path=",
    "--output.checkstyle.path=",
    "--output.code-climate.path=",
    "--output.junit-xml.path=",
    "--output.teamcity.path=",
    "--output.sarif.path=",
    "--issues-exit-code=0",
    "--show-stats=false",
    "--path-mode=abs",
    function()
      return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
    end,
  }
end

return {
  "mfussenegger/nvim-lint",
  optional = true,
  opts = {
    linters_by_ft = {
      go = { "golangcilint" },
    },
    linters = {
      golangcilint = {
        -- Use Mason path directly to avoid PATH race conditions on startup.
        cmd = golangci_lint_cmd,
        append_fname = false,
        args = golangci_lint_args(),
        condition = function()
          return vim.fn.executable(golangci_lint_cmd) == 1
        end,
      },
    },
  },
}

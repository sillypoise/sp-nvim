local uname = vim.uv.os_uname()
if uname.sysname == "Darwin" then
  return {
    "ghostty",
    dir = "/Applications/Ghostty.app/Contents/Resources/vim/vimfiles/",
    lazy = false,
  }
else
  return {}
end

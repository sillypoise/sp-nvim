if vim.fn.has("mac") == 1 then
  return {
    "ghostty",
    dir = "/Applications/Ghostty.app/Contents/Resources/vim/vimfiles/",
    lazy = false,
  }
else
  return {}
end

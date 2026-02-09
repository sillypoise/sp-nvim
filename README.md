# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Preview Bridge

This config includes a local Neovim bridge that streams unsaved Markdown buffer content to a preview
server.

- Loader spec: `lua/plugins/preview-bridge.lua`
- Runtime module: `lua/preview_bridge.lua`
- Logic helpers: `lua/preview_bridge/logic.lua`

### Commands

- `:PreviewBridgeStatus` shows enabled state, session id, workspace root, and tracked buffers.
- `:PreviewBridgeDebug` shows last skip reason, transport status, warning, and last payload details.
- `:PreviewBridgePush` forces an immediate upsert for the current buffer.
- `:PreviewBridgeClose` forces a close action for the current buffer.
- `:PreviewBridgeEnable` enables the bridge.
- `:PreviewBridgeDisable` disables the bridge and closes tracked live buffers.

### Troubleshooting

- If the browser updates only on save and live endpoint returns `item: null`, run
  `:PreviewBridgeStatus` and `:PreviewBridgeDebug`.
- If `tracked_buffers=0`, verify the file resolves to `content/*.md` after normalization.
- If `last_transport_error` is set, verify `curl` is available and the preview app is running on
  `server_url`.
- For monorepos or unusual workspace layouts, set `workspace_root` in
  `lua/plugins/preview-bridge.lua`.

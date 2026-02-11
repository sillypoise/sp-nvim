# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Preview Bridge

This config includes a local Neovim bridge that streams unsaved Markdown buffer content to a preview
server.

Contract source of truth in this repo: `preview_bridge_contract_v1.md`.

- Loader spec: `lua/plugins/preview-bridge.lua`
- Runtime module: `lua/preview_bridge.lua`
- Logic helpers: `lua/preview_bridge/logic.lua`

### Commands

- `:PreviewBridgeStatus` shows enabled state, session id, workspace root, and tracked buffers.
- `:PreviewBridgeDebug` shows last skip reason, transport status, warning, and last payload details.
- `:PreviewBridgeReconnect` forces websocket reconnect (WS transport mode).
- `:PreviewBridgeResubscribe` forces websocket resubscribe (when enabled).
- `:PreviewBridgeOpen` routes current markdown file to existing preview tab, or provides fallback URL.
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

### WebSocket transport (v1)

- Set `transport = "ws"` to enable websocket connection awareness.
- WS write path is primary for `upsert` and `close` in WS mode.
- HTTP fallback remains available for resilience when WS writes fail.
- `websocat` must be installed and available on `PATH` for WS mode.
- Browser owns preview subscriptions by default; plugin WS subscription signaling is optional.
- Plugin WS subscription signaling is disabled by default in WS mode.
- Set `ws_subscribe_enabled = true` to enable plugin subscribe/unsubscribe signaling.
- Set `ws_write_enabled = false` to force HTTP writes even in WS transport mode.
- Set `ws_write_http_fallback = false` to disable HTTP fallback for failed WS writes.
- `:PreviewBridgeOpen` uses `POST /api/preview/open` and defaults to remote-safe `notify_copy` fallback.

### Contract mapping

- `transport` maps to contract transport mode (`http` canonical writes, `ws` websocket lifecycle).
- `server_url` maps to HTTP endpoints under `/api/preview/live`, `/api/preview/state`, and `/api/preview/live`.
- `ws_url` maps to websocket endpoint (derived from `server_url` to `/preview-bridge` when unset).
- `ws_subscribe_enabled` maps to optional plugin-side `subscribe` and `unsubscribe` signaling.
- `ws_write_enabled` maps to websocket `upsert` and `close` writes in WS mode.
- `ws_write_http_fallback` maps to optional HTTP fallback when WS write dispatch fails.
- `browser_base_url` maps to browser-visible URL base for open fallback links.
- `open_fallback_mode` maps to fallback strategy (`notify_copy`, `system_open`, `custom_command`).
- `open_custom_command` maps to shell command used when `open_fallback_mode = "custom_command"` and
  should include `%URL%` placeholder.
- `debounce_ms` maps to typing update cadence for `TextChanged` and `TextChangedI` upserts.
- `file_filter` and path normalization map to canonical `content/**/*.md` identity invariants.
- `workspace_root` maps to workspace-relative path resolution before `filePath` emission.

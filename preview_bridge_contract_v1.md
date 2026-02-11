# Preview Bridge Contract v1

This document defines the integration contract between the Neovim bridge plugin and the preview app in `preview-app/`.

## Scope

- Local authoring workflow only (`localhost` trust model).
- Unsaved Markdown buffer updates from Neovim must appear in browser preview.
- Contract version is `v1` and must remain backward-compatible unless version is bumped.

## Canonical File Identity

- Client sends `filePath` as POSIX-style, workspace-relative path.
- Allowed files are strict `content/**/*.md`.
- Invalid examples: leading `/`, path traversal (`..`), non-markdown, non-content paths.
- Monorepo/nested path normalization is allowed client-side as long as server receives `content/...`.

## Session and Version Semantics

- `sessionId` is process-lifetime (`nvim-<uuid>`), not persisted across restarts.
- `version` is monotonic per `(sessionId, filePath)`.
- Client increments version only when an upsert is actually sent.
- Server rejects stale versions by returning `applied: false` and keeping current state.

## Event Model (Neovim)

- Initial snapshot upsert on `BufEnter`.
- Debounced upsert on `TextChanged` and `TextChangedI` (target debounce ~100ms).
- Immediate upsert on `BufWritePost` (client may skip if content hash unchanged).
- Close action on `BufUnload`, `BufWipeout`, and `VimLeavePre` (best-effort, non-blocking).

## Transport and Reliability

- v1 transport supports HTTP and WebSocket.
- Bridge failures are non-fatal in editor; plugin retries naturally on subsequent edits.
- No guaranteed queue/backoff persistence in v1.
- WebSocket channel is available for browser realtime updates and future plugin transport migration.
- Current rollout supports full websocket write actions (`upsert`, `close`) while HTTP remains compatible.

### Recommended Plugin Profile (Current)

- `transport = "ws"`
- `ws_write_enabled = true`
- `ws_write_http_fallback = true`
- `ws_subscribe_enabled = false` (browser preview client remains subscription owner)
- Open command should call `POST /api/preview/open` and use fallback URL when `routed: false`.

## API Contract

### Upsert Live Buffer

- `POST /api/preview/live`
- Body:

```json
{
  "action": "upsert",
  "sessionId": "nvim-...",
  "filePath": "content/markdown.md",
  "version": 12,
  "content": "# Draft"
}
```

- Success response (`200`):

```json
{
  "ok": true,
  "result": {
    "applied": true,
    "state": {
      "sessionId": "nvim-...",
      "filePath": "content/markdown.md",
      "version": 12,
      "content": "# Draft",
      "updatedAt": "2026-02-09T00:00:00.000Z"
    }
  }
}
```

### Close Live Buffer

- `POST /api/preview/live`
- Body:

```json
{
  "action": "close",
  "sessionId": "nvim-...",
  "filePath": "content/markdown.md"
}
```

- Success response (`200`):

```json
{
  "ok": true,
  "result": {
    "removed": true
  }
}
```

- `removed` is boolean:
  - `true` when a matching `(sessionId, filePath)` live entry existed and was removed.
  - `false` when no matching live entry existed (idempotent close behavior).

### Debug Endpoints

- `GET /api/preview/live`
- `GET /api/preview/live?file=content/markdown.md`
- `GET /api/preview/state?file=content/markdown.md`
- `DELETE /api/preview/live` (clears all live buffers, returns `204`)

### Open/Navigate Preview

- `POST /api/preview/open`
- Body:

```json
{
  "filePath": "content/markdown.md"
}
```

- Success response when existing browser preview client is connected (`200`):

```json
{
  "ok": true,
  "result": {
    "routed": true
  }
}
```

- Success response when no browser preview client is connected (`200`):

```json
{
  "ok": true,
  "result": {
    "routed": false,
    "urlPath": "/preview?file=content%2Fmarkdown.md"
  }
}
```

### WebSocket Endpoint

- `ws://localhost:3000/preview-bridge` (or `wss` on HTTPS)
- Client -> server messages:
  - `{ "type": "hello" }`
  - `{ "type": "hello", "client": "browser" }`
  - `{ "type": "subscribe", "filePath": "content/markdown.md" }`
  - `{ "type": "unsubscribe", "filePath": "content/markdown.md" }`
  - `{ "type": "ping" }`
  - `{ "type": "upsert", "sessionId": "nvim-...", "filePath": "content/markdown.md", "version": 12, "content": "# Draft" }`
  - `{ "type": "close", "sessionId": "nvim-...", "filePath": "content/markdown.md" }`
- Server -> client messages:
  - `{ "type": "ack", "event": "hello|subscribe|unsubscribe|upsert|close", ... }`
  - `{ "type": "preview:state", ... }`
  - `{ "type": "preview:navigate", "filePath": "content/markdown.md", "urlPath": "/preview?file=content%2Fmarkdown.md" }`
  - `{ "type": "preview:error", "code": "...", "message": "..." }`
  - `{ "type": "pong" }`

WebSocket notes:

- Extra fields in client payloads are ignored in current implementation.
- Subscription operations are idempotent for normal repeated calls.
- Browser currently owns preview subscriptions in this app; plugin subscriptions are optional.
- `upsert` broadcasts `preview:state` only when `applied: true`.
- `close` always emits an ack and then attempts a `preview:state` publish for subscribers.
- `preview:navigate` is emitted to websocket peers identified as browser clients.

### Shared Envelope and Error Codes

- Success shape: `{ ok: true, ... }`
- Error shape: `{ ok: false, error: { code, message } }`
- Contract header is required on API responses:
  - `x-preview-bridge-contract: v1`
- Current error codes:
  - `INVALID_PAYLOAD`
  - `INVALID_PATH`
  - `PAYLOAD_TOO_LARGE`
  - `NOT_FOUND`
  - `INTERNAL_ERROR`

### Current WebSocket `preview:error` codes

- `INVALID_PAYLOAD`
- `INVALID_PATH`
- `PAYLOAD_TOO_LARGE`
- `INVALID_STATE`
- `SUBSCRIPTION_LIMIT`
- `STATE_RESOLVE_FAILED`
- `UNSUPPORTED_CONTRACT`

## Server-Side Limits and Lifecycle

- Max HTTP live payload size (`POST /api/preview/live`): `1_000_000` bytes.
- Max websocket message size (`/preview-bridge`): `1_000_000` bytes.
- Live entries are TTL-pruned:
  - `LIVE_BUFFER_TTL_MS = 15 * 60 * 1000`
- Preview state source priority is fixed:
  1. `live`
  2. `disk`

## Observability

- Server logs these events:
  - `preview_live` (`upsert`, `close`, `clear`)
  - `preview_state` (`resolve`, `error`)
- Include key fields for triage:
  - `sessionId`, `filePath`, `version`, `applied`, `source`, `code`

## Compatibility Policy

- This contract is the source of truth for v1 behavior.
- Any breaking field/behavior change requires a version bump (e.g. `v2`).
- Additive changes are allowed if existing fields and semantics remain stable.

## v1.1 (Planned)

The following are planned non-breaking clarifications for plugin websocket transport rollout:

- `hello` may include contract and session metadata (already accepted in server parser):
  - `{ "type": "hello", "contract": "v1.1", "sessionId": "nvim-..." }`
- `ack` includes websocket contract version in current implementation:
  - `{ "type": "ack", "event": "hello", "contract": "v1" }`
- Recommended reconnect bounds for plugin WS mode:
  - backoff start `250ms`, cap `2000ms`, jitter enabled.
- Heartbeat remains optional in v1.1:
  - recommended ping interval `15s`, dead connection after 2 missed pongs.
- Suggested standard websocket error codes:
  - `INVALID_MESSAGE`
  - `UNSUPPORTED_CONTRACT`
  - `RATE_LIMITED`
  - `INTERNAL_ERROR`

## Verification Checklist

- Start preview app on strict port:

```bash
cd preview-app
bun run dev
```

- Upsert live content:

```bash
curl -X POST "http://localhost:3000/api/preview/live" \
  -H "content-type: application/json" \
  -d '{"action":"upsert","sessionId":"manual-1","filePath":"content/markdown.md","version":1,"content":"# Live"}'
```

- Verify effective state prefers live:

```bash
curl "http://localhost:3000/api/preview/state?file=content/markdown.md"
```

- Verify contract header exists on API responses:

```bash
curl -i "http://localhost:3000/api/preview/state?file=content/markdown.md" | grep x-preview-bridge-contract
```

- Verify payload guard:

```bash
python - <<'PY'
import requests
payload = {
  "action": "upsert",
  "sessionId": "manual-1",
  "filePath": "content/markdown.md",
  "version": 2,
  "content": "x" * 1100000,
}
r = requests.post("http://localhost:3000/api/preview/live", json=payload)
print(r.status_code, r.text)
PY
```

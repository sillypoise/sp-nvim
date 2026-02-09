local logic = require("preview_bridge.logic")
local preview_bridge = require("preview_bridge")

describe("preview bridge path normalization", function()
  -- This test verifies absolute paths are converted to repo-relative POSIX paths.
  it("normalizes repo-relative markdown paths", function()
    local relative_path = logic.normalize_relative_path(
      "/workspace/repo/content/til/notes.md",
      "/workspace/repo"
    )
    assert.equals("content/til/notes.md", relative_path)
  end)

  -- This test verifies out-of-workspace paths are rejected.
  it("rejects paths outside workspace", function()
    local relative_path = logic.normalize_relative_path("/tmp/notes.md", "/workspace/repo")
    assert.is_nil(relative_path)
  end)

  -- This test verifies the nearest matching root is selected in nested repositories.
  it("prefers the deepest matching root", function()
    local relative_path = logic.normalize_relative_path_from_roots(
      "/workspace/sp-blog/preview-app/content/notes.md",
      { "/workspace/sp-blog", "/workspace/sp-blog/preview-app" }
    )
    assert.equals("content/notes.md", relative_path)
  end)

  -- This test verifies nil is returned when no root matches the absolute path.
  it("returns nil when no root matches", function()
    local relative_path = logic.normalize_relative_path_from_roots(
      "/workspace/other/content/notes.md",
      { "/workspace/sp-blog", "/workspace/sp-blog/preview-app" }
    )
    assert.is_nil(relative_path)
  end)

  -- This test verifies content-relative fallback for nested app directories.
  it("normalizes from content directory when root-relative path is prefixed", function()
    local relative_path = logic.normalize_content_relative_path(
      "/workspace/sp-blog/preview-app/content/notes.md"
    )
    assert.equals("content/notes.md", relative_path)
  end)

  -- This test verifies non-content files do not produce content-relative paths.
  it("returns nil when content directory is missing", function()
    local relative_path = logic.normalize_content_relative_path(
      "/workspace/sp-blog/preview-app/docs/notes.md"
    )
    assert.is_nil(relative_path)
  end)
end)

describe("preview bridge eligibility", function()
  -- This test verifies strict path rules for content markdown files.
  it("accepts valid content markdown paths", function()
    assert.is_true(logic.is_eligible_path("content/til/notes.md", 1, "^content/.*%.md$"))
  end)

  -- This test verifies invalid root paths are rejected.
  it("rejects non-content markdown paths", function()
    assert.is_false(logic.is_eligible_path("notes.md", 1, "^content/.*%.md$"))
  end)

  -- This test verifies traversal segments are rejected.
  it("rejects traversal paths", function()
    assert.is_false(logic.is_eligible_path("content/../notes.md", 1, "^content/.*%.md$"))
  end)

  -- This test verifies functional file filters can narrow eligible paths.
  it("supports function-based file filters", function()
    local file_filter = function(path)
      return path == "content/allowed.md"
    end
    assert.is_true(logic.is_eligible_path("content/allowed.md", 1, file_filter))
    assert.is_false(logic.is_eligible_path("content/denied.md", 1, file_filter))
  end)
end)

describe("preview bridge versioning", function()
  -- This test verifies versions increment monotonically per file path.
  it("increments versions in order", function()
    local file_versions = {}
    assert.equals(1, logic.next_version(file_versions, "content/a.md"))
    assert.equals(2, logic.next_version(file_versions, "content/a.md"))
    assert.equals(1, logic.next_version(file_versions, "content/b.md"))
  end)
end)

describe("preview bridge debounce", function()
  -- This test verifies multiple rapid schedules collapse into one callback execution.
  it("coalesces rapid updates", function()
    local buffer_state = {}
    local callback_count = 0

    local fake_timer = {
      pending_callback = nil,
    }

    fake_timer.stop = function()
      return nil
    end
    fake_timer.close = function()
      return nil
    end
    fake_timer.start = function(_, _, _, callback)
      fake_timer.pending_callback = callback
    end

    local timer_factory = function()
      return fake_timer
    end

    local schedule_wrap = function(callback)
      return callback
    end

    local callback = function()
      callback_count = callback_count + 1
    end

    logic.schedule_debounce(buffer_state, 100, timer_factory, schedule_wrap, callback)
    logic.schedule_debounce(buffer_state, 100, timer_factory, schedule_wrap, callback)
    logic.schedule_debounce(buffer_state, 100, timer_factory, schedule_wrap, callback)

    assert.is_not_nil(fake_timer.pending_callback)
    fake_timer.pending_callback()
    assert.equals(1, callback_count)
  end)
end)

describe("preview bridge payload shape", function()
  -- This test verifies the upsert payload matches the API contract.
  it("builds an upsert payload", function()
    local payload = logic.build_upsert_payload("nvim-123", "content/notes.md", 7, "# Draft")
    assert.same({
      action = "upsert",
      sessionId = "nvim-123",
      filePath = "content/notes.md",
      version = 7,
      content = "# Draft",
    }, payload)
  end)

  -- This test verifies the close payload matches the API contract.
  it("builds a close payload", function()
    local payload = logic.build_close_payload("nvim-123", "content/notes.md")
    assert.same({
      action = "close",
      sessionId = "nvim-123",
      filePath = "content/notes.md",
    }, payload)
  end)
end)

describe("preview bridge failure handling", function()
  -- This test verifies transport startup failures are contained and non-fatal.
  it("handles unavailable server transport without crashing", function()
    local old_system = vim.system
    local old_config = preview_bridge._state.config
    local old_curl = preview_bridge._state.curl_available

    preview_bridge._state.config = {
      server_url = "http://localhost:3000",
      debounce_ms = 100,
      enabled = true,
      file_filter = "^content/.*%.md$",
    }
    preview_bridge._state.curl_available = true

    vim.system = function()
      error("simulated transport startup failure")
    end

    local call_ok, result = pcall(preview_bridge._test.post_live_payload_async, {
      action = "close",
      sessionId = "nvim-test",
      filePath = "content/notes.md",
    })

    vim.system = old_system
    preview_bridge._state.config = old_config
    preview_bridge._state.curl_available = old_curl

    assert.is_true(call_ok)
    assert.is_false(result)
  end)
end)

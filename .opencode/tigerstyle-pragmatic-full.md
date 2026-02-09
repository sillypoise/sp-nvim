# TigerStyle Rulebook — Pragmatic / Full

## Preamble

### Purpose

This document is a comprehensive, language-agnostic coding rulebook derived from TigerBeetle's
TigerStyle. It is intended to be dropped into any codebase as part of an `AGENTS.md` file, a
system prompt, or a code review checklist. Every rule is actionable. This is the pragmatic variant:
rules are strong recommendations that acknowledge tradeoffs and existing codebases.

### Design Goal Priority

All rules serve three design goals, in this order:

1. **Safety** — correctness, bounded behavior, crash on corruption.
2. **Performance** — mechanical sympathy, batching, resource awareness.
3. **Developer Experience** — clarity, naming, readability, maintainability.

When goals conflict, higher-priority goals win.

### Keyword Definitions

- **SHOULD** — Strong recommendation. Follow unless there is a documented, justifiable reason not to.
- **PREFER** — Default choice. Use this approach unless an alternative is clearly better for the
  specific situation.
- **CONSIDER** — Worth evaluating. Apply when the benefit outweighs the cost in context.
- **AVOID** — Strong discouragement. Do not use unless there is a documented, justifiable reason.

### Exception Clause

Any rule in this document may be overridden in a specific instance if:

1. The exception is documented in a code comment or commit message.
2. The comment explains **why** the rule does not apply.
3. The exception is reviewed and approved by at least one other contributor.

Undocumented exceptions are violations.

### How to Use This Document

- Reference rules by ID (e.g., SAF-01, DX-05) in code reviews and commit messages.
- All 69 rules are organized into 7 categories.
- Each rule has: a recommendation, a rationale, and a pseudocode example or template.
- Rules are language-agnostic. Adapt examples to your language and tooling.

---

## Safety & Correctness (SAF)

### SAF-01 — Use simple, explicit control flow. Avoid recursion.

All control flow SHOULD be simple, explicit, and statically analyzable. Recursion SHOULD be avoided.

Rationale: Predictable, bounded execution is the foundation of safety. Recursion makes it difficult
to prove termination and risks stack overflow.

```text
# Prefer: explicit loop with fixed bound
for i in 0..max_iterations:
    process(item[i])

# Avoid: recursive call
def process(items):
    if items.empty(): return
    process(items.rest())
```

### SAF-02 — Put a limit on everything.

All loops, queues, retries, buffers, and any form of repeated or accumulated work SHOULD have a
fixed upper bound. Where a loop cannot terminate (e.g., an event loop), this SHOULD be asserted.

Rationale: Unbounded work causes infinite loops, tail-latency spikes, and resource exhaustion.
The fail-fast principle demands that violations are detected sooner rather than later.

```text
# Prefer: bounded loop
for i in 0..MAX_RETRIES:
    if try_connect(): break
assert(i < MAX_RETRIES, "connection retries exhausted")

# Prefer: assert non-terminating loop
while true:  # event loop
    assert(is_running, "event loop must be explicitly stopped")
    process_events()
```

### SAF-03 — Use explicitly-sized types.

Integer types SHOULD be explicitly sized (e.g., u32, i64). AVOID architecture-dependent types
(e.g., usize, size_t, long) unless required by a foreign interface.

Rationale: Implicit sizing creates architecture-specific behavior and makes overflow analysis
impossible without knowing the target.

```text
# Prefer
count: u32 = 0
offset: u64 = 0

# Avoid
count: usize = 0   # architecture-dependent
```

### SAF-04 — Assert all preconditions, postconditions, and invariants.

Every function SHOULD assert its preconditions (valid arguments), postconditions (valid return
values), and any invariants that must hold during execution. A function SHOULD NOT operate blindly
on unchecked data.

Rationale: Assertions detect programmer errors. Unlike operating errors which must be handled,
assertion failures are unexpected. The only correct response to corrupt code is to crash. Assertions
downgrade catastrophic correctness bugs into liveness bugs.

```text
def transfer(from_account, to_account, amount):
    assert(from_account != to_account)
    assert(amount > 0)
    assert(from_account.balance >= amount)

    from_account.balance -= amount
    to_account.balance += amount

    assert(from_account.balance >= 0)
    assert(to_account.balance > 0)
```

### SAF-05 — Maintain assertion density of at least 2 per function.

The assertion density of the codebase SHOULD average a minimum of two assertions per function.

Rationale: High assertion density is a force multiplier for discovering bugs through testing and
fuzzing. Low assertion density leaves large regions of state space unchecked.

```text
def process_batch(items, max_size):
    assert(len(items) <= max_size)       # precondition
    result = do_work(items)
    assert(len(result) == len(items))    # postcondition
    return result
```

### SAF-06 — Pair assertions across different code paths.

For every property to enforce, CONSIDER adding at least two assertions on different code paths that
verify the property. For example, assert validity before writing and after reading.

Rationale: Bugs hide at the boundary between valid and invalid data. A single assertion covers one
side; paired assertions cover the transition.

```text
# Assert before write
assert(record.checksum == compute_checksum(record.data))
write_to_disk(record)

# Assert after read
record = read_from_disk()
assert(record.checksum == compute_checksum(record.data))
```

### SAF-07 — Split compound assertions.

Compound assertions SHOULD be split into individual assertions. PREFER `assert(a); assert(b);` over
`assert(a and b)`.

Rationale: Split assertions are simpler to read and provide precise failure information. A compound
assertion that fails gives no indication of which condition was violated.

```text
# Prefer
assert(index >= 0)
assert(index < length)

# Avoid
assert(index >= 0 and index < length)  # compound
```

### SAF-08 — Use single-line implication assertions.

When a property B must hold whenever condition A is true, PREFER expressing this as a single-line
implication: `if (a) assert(b)`.

Rationale: Preserves logical intent without introducing complex boolean expressions or unnecessary
nesting.

```text
if (is_committed) assert(has_quorum)
if (is_leader) assert(term == current_term)
```

### SAF-09 — Assert compile-time constants and type sizes.

Relationships between compile-time constants, type sizes, and configuration values SHOULD be
asserted at compile time (or at program startup if the language lacks compile-time assertions).

Rationale: Compile-time assertions verify design integrity before the program executes. They catch
configuration drift and subtle invariant violations that runtime testing may miss.

```text
static_assert(BLOCK_SIZE % PAGE_SIZE == 0)
static_assert(sizeof(Header) == 64)
static_assert(MAX_BATCH_SIZE <= BUFFER_CAPACITY)
```

### SAF-10 — Assert both positive and negative space.

Assertions SHOULD cover both the positive space (what is expected) AND the negative space (what is
not expected). Where data moves across the valid/invalid boundary, both sides SHOULD be asserted.

Rationale: Most interesting bugs occur at the boundary between valid and invalid states. Asserting
only the happy path leaves the error path unchecked.

```text
if index < length:
    # Positive space: index is valid.
    assert(buffer[index] != SENTINEL)
else:
    # Negative space: index is out of bounds.
    assert(index == length, "index must not skip values")
```

### SAF-11 — Test valid data, invalid data, and boundary transitions exhaustively.

Tests SHOULD exercise valid inputs, invalid inputs, and the transitions between valid and invalid
states. Tests SHOULD NOT only cover the happy path.

Rationale: An analysis of production failures found that 92% of catastrophic failures resulted from
incorrect handling of non-fatal errors. Testing only valid data misses the majority of real-world
failure modes.

```text
# Test valid
test_transfer(amount=100, balance=200)  # succeeds

# Test invalid
test_transfer(amount=0, balance=200)    # rejected: zero amount
test_transfer(amount=300, balance=200)  # rejected: insufficient

# Test boundary
test_transfer(amount=200, balance=200)  # edge: exact balance
test_transfer(amount=201, balance=200)  # edge: one over
```

### SAF-12 — Prefer static allocation after initialization. Avoid runtime reallocation.

All memory SHOULD be statically allocated at initialization. AVOID dynamically allocating or freeing
and reallocating memory after initialization.

Rationale: Dynamic allocation introduces unpredictable latency, fragmentation, and use-after-free
risk. Static allocation forces upfront design of all memory usage patterns, which produces simpler,
more performant, and more maintainable systems.

```text
# Prefer: allocate once at startup
buffer = allocate(MAX_BUFFER_SIZE)   # startup
# ... use buffer for lifetime of program ...

# Avoid: allocate at runtime
def process(data):
    temp = allocate(len(data))       # runtime allocation
    free(temp)                       # runtime deallocation
```

### SAF-13 — Declare variables at the smallest possible scope.

Variables SHOULD be declared at the smallest possible scope and the number of variables in any given
scope SHOULD be minimized.

Rationale: Fewer variables in scope reduces the probability that a variable is misused or confused
with another. Tight scoping limits the blast radius of errors.

```text
# Prefer: declare at point of use
for item in batch:
    checksum = compute_checksum(item)
    assert(checksum == item.expected_checksum)

# Avoid: declare far from use
checksum = 0
# ... 30 lines of unrelated code ...
for item in batch:
    checksum = compute_checksum(item)
```

### SAF-14 — Keep functions short (~70 lines hard limit).

Functions SHOULD NOT exceed approximately 70 lines.

Rationale: There is a sharp cognitive discontinuity between a function that fits on screen and one
that requires scrolling. The limit forces clean decomposition.

```text
# If a function approaches 70 lines, split it:
# - Keep control flow (if/switch) in the parent function.
# - Move non-branching logic into helper functions.
# - Keep leaf functions pure (no state mutation).
```

### SAF-15 — Centralize control flow in parent functions.

When splitting a large function, all branching logic (if/switch/match) SHOULD remain in the parent
function. Helper functions SHOULD NOT contain control flow that determines program behavior.

Rationale: Centralizing control flow means there is exactly one place to understand all branches.
Scattered branching across helpers makes case analysis exponentially harder.

```text
# Prefer: parent owns all branching
def process(request):
    if request.type == READ:
        data = read_helper(request.key)
        return respond(data)
    elif request.type == WRITE:
        write_helper(request.key, request.value)
        return acknowledge()

# Avoid: helper decides behavior
def read_helper(key, request):
    if request.needs_auth:       # control flow in helper
        authenticate(request)
```

### SAF-16 — Centralize state mutation. Keep leaf functions pure.

Parent functions SHOULD own state mutation. Helper functions SHOULD compute and return values
without mutating shared state.

Rationale: Pure helper functions are easier to test, reason about, and compose. When only one
function mutates state, bugs are localized to one site.

```text
# Prefer: helper computes, parent mutates
def update_balance(account, amount):
    new_balance = compute_new_balance(account.balance, amount)  # pure
    assert(new_balance >= 0)
    account.balance = new_balance  # mutation in parent

# Avoid: helper mutates directly
def compute_new_balance(account, amount):
    account.balance -= amount  # mutation in leaf
```

### SAF-17 — Enable all compiler warnings at the strictest setting.

All compiler and linter warnings SHOULD be enabled at the strictest available setting. Warnings
SHOULD be resolved, not suppressed.

Rationale: Warnings frequently indicate latent correctness issues. Suppressing them normalizes
ignoring the tool that is best positioned to catch mechanical errors.

```text
# Compiler/linter flags (adapt to your language):
# C/C++:   -Wall -Wextra -Werror -pedantic
# Rust:    #![deny(warnings)]
# Go:      go vet + staticcheck
# TS/JS:   strict: true + no-any + no-unused
```

### SAF-18 — Do not react directly to external events. Batch and process at your own pace.

Programs SHOULD NOT perform work directly in response to external events. Instead, events SHOULD be
queued and processed in controlled batches at the program's own pace.

Rationale: Reacting directly to external events surrenders control flow to the environment, making
it impossible to bound work per time period. Batching restores control, improves throughput, and
enables assertion safety between batches.

```text
# Prefer: queue and batch
event_queue.push(incoming_event)
# ... in main loop tick ...
batch = event_queue.drain(MAX_BATCH_SIZE)
process_batch(batch)

# Avoid: react inline
on_message(msg):
    process(msg)    # direct reaction, unbounded
```

### SAF-19 — Split compound conditions into nested branches.

Compound boolean conditions SHOULD be split into nested if/else branches. Complex `else if` chains
SHOULD be rewritten as `else { if { } }` trees.

Rationale: Compound conditions obscure case coverage. Nested branches make every case explicit and
verifiable.

```text
# Prefer: nested branches
if is_valid:
    if is_authorized:
        execute()
    else:
        reject("unauthorized")
else:
    reject("invalid")

# Avoid: compound condition
if is_valid and is_authorized:
    execute()
```

### SAF-20 — State invariants positively. Avoid negations.

Conditions SHOULD be stated in positive form. Comparisons SHOULD follow the natural grain of the
domain (e.g., `index < length` rather than `index >= length` with inverted logic).

Rationale: Negations are error-prone and harder to verify. Positive conditions align with how
programmers naturally reason about loop bounds and index validity.

```text
# Prefer: positive form
if index < length:
    # invariant holds
else:
    # invariant violated

# Avoid: negated form
if index >= length:
    # it's not true that the invariant holds
```

### SAF-21 — Handle all errors explicitly.

Every error SHOULD be handled explicitly. No error SHOULD be silently ignored, swallowed, or
discarded.

Rationale: 92% of catastrophic production failures result from incorrect handling of non-fatal
errors. Silent error swallowing is the single largest class of preventable production failures.

```text
# Prefer: explicit handling
result = call()
if result.error:
    log(result.error)
    return result.error

# Avoid: swallowed error
call()                           # error ignored
```

### SAF-22 — Always state the "why" in comments and commit messages.

Every non-obvious decision SHOULD be accompanied by a comment or commit message explaining why.

Rationale: The "what" is in the code. The "why" is the only thing that enables safe future changes.
Without rationale, maintainers cannot evaluate whether the original decision still applies.

```text
# Prefer
# Why: batch to amortize syscall overhead; one-at-a-time caused 3x latency.
process_batch(items)

# Avoid
process_batch(items)             # no explanation of design choice
```

### SAF-23 — Pass explicit options to library calls. Avoid relying on defaults.

All options and configuration values SHOULD be passed explicitly at the call site. AVOID relying on
default values.

Rationale: Defaults can change across library versions, causing latent, potentially catastrophic bugs
that are invisible at the call site.

```text
# Prefer: explicit options
http.request(url, {
    timeout_ms: 5000,
    retries: 3,
    method: "GET"
})

# Avoid: rely on defaults
http.request(url)
```

---

## Performance & Design (PERF)

### PERF-01 — Design for performance from the start.

Performance SHOULD be considered during the design phase, not deferred to profiling. The largest
performance wins (1000x) come from architectural decisions that cannot be retrofitted.

Rationale: It is harder and less effective to fix a system after implementation. Mechanical sympathy
during design is like a carpenter working with the grain.

```text
# During design, answer:
# - What is the bottleneck resource? (network / disk / memory / CPU)
# - What is the expected throughput?
# - What is the latency budget per operation?
# - Can work be batched?
```

### PERF-02 — Perform back-of-the-envelope resource sketches.

Before implementation, back-of-the-envelope calculations SHOULD be performed for the four core
resources (network, disk, memory, CPU) across their two characteristics (bandwidth, latency).

Rationale: Sketches are cheap. They guide design into the right 90% of the solution space. Skipping
them is the root of all performance evil.

```text
# Example sketch:
# - 10,000 requests/sec
# - Each request: 1 KB payload
# - Network bandwidth: 10 KB/sec * 10,000 = 100 MB/sec (fits in 1 Gbps)
# - Disk writes: 10,000 * 200 bytes = 2 MB/sec (fits in SSD bandwidth)
# - Memory: 10,000 * 4 KB working set = 40 MB (fits in L3 cache? No. Plan accordingly.)
```

### PERF-03 — Optimize the slowest resource first, weighted by frequency.

Optimization effort SHOULD target the slowest resource first (network > disk > memory > CPU), after
adjusting for frequency of access.

Rationale: Bottleneck-focused optimization yields the largest gains. Optimizing the wrong resource
wastes effort.

```text
# Priority order (adjust by frequency):
# 1. Network (ms latency, limited bandwidth)
# 2. Disk (us-ms latency, sequential vs random)
# 3. Memory (ns-us latency, cache hierarchy)
# 4. CPU (ns latency, branch prediction)
```

### PERF-04 — Separate control plane from data plane.

The control plane (scheduling, coordination, metadata) SHOULD be clearly separated from the data
plane (bulk data processing).

Rationale: Mixing control and data operations prevents effective batching and forces a choice between
safety and throughput. Separation eliminates this tradeoff.

```text
# Control plane: validate, schedule, assert
batch = control_plane.prepare(requests)
assert(batch.valid())

# Data plane: execute in bulk
data_plane.execute(batch)
```

### PERF-05 — Amortize costs via batching.

Network, disk, memory, and CPU costs SHOULD be amortized by batching accesses. AVOID per-item
processing when batching is feasible.

Rationale: Per-item overhead (syscalls, context switches, cache misses) dominates at high
throughput. Batching reduces overhead by orders of magnitude.

```text
# Prefer: batch
items = collect(MAX_BATCH_SIZE)
write_all(items)                 # one syscall

# Avoid: per-item
for item in items:
    write(item)                  # syscall per item
```

### PERF-06 — Keep CPU work predictable. Avoid erratic control flow.

Hot paths SHOULD have predictable, linear control flow. AVOID branching, pointer chasing, and random
access patterns in performance-critical code.

Rationale: Modern CPUs are sprinters. Predictable work enables prefetching, branch prediction, and
cache line utilization. Erratic control flow forces pipeline stalls.

```text
# Prefer: linear access
for i in 0..count:
    process(buffer[i])           # sequential, predictable

# Avoid: pointer chasing
node = head
while node:
    process(node)
    node = node.next             # random memory access
```

### PERF-07 — Be explicit. Do not depend on compiler optimizations.

Performance-critical code SHOULD be written explicitly. AVOID relying on the compiler to inline,
unroll, vectorize, or otherwise optimize the code.

Rationale: Compiler optimizations are heuristic and fragile. Explicit code is portable across
compilers and versions, and is easier for humans to verify.

```text
# Prefer: explicit unrolling if needed
process(items[0])
process(items[1])
process(items[2])
process(items[3])

# Less predictable:
for i in 0..4:
    process(items[i])            # may or may not be unrolled
```

### PERF-08 — Use primitive arguments in hot loops. Avoid implicit self/this.

Hot loop functions SHOULD take primitive arguments directly. AVOID passing `self`/`this` or large
struct references that require the compiler to prove field caching.

Rationale: Primitive arguments enable the compiler to keep values in registers without alias
analysis. A human reader can also spot redundant computations more easily.

```text
# Prefer: primitive arguments
def hot_loop(data_ptr, length, stride):
    for i in 0..length:
        process(data_ptr[i * stride])

# Avoid: self reference
def hot_loop(self):
    for i in 0..self.length:
        process(self.data[i * self.stride])
```

---

## Developer Experience & Naming (DX)

### DX-01 — Choose precise nouns and verbs.

Names SHOULD capture what a thing is or does with precision. Take time to find the name that
provides a crisp, intuitive mental model.

Rationale: Great names are the essence of great code. They reduce documentation burden and make the
code self-describing. A wrong name actively misleads.

```text
# Prefer
pipeline, transfer, checkpoint, replica

# Avoid
data, info, manager, handler, process  # too vague
```

### DX-02 — Use snake_case for files, functions, and variables.

All file names, function names, and variable names SHOULD use snake_case.

Rationale: Underscores are the closest thing programmers have to spaces. They separate words clearly
and encourage descriptive multi-word names.

**Note:** If your language has a strong idiomatic convention (e.g., camelCase in JavaScript/TypeScript,
PascalCase for types in Go), follow the language convention but apply the spirit of this rule:
prefer clear word separation and descriptive names.

```text
# Prefer
process_batch, user_account, latency_ms_max

# Adapt to language convention where applicable
processBatch  # acceptable in JS/TS if that is the project convention
```

### DX-03 — Do not abbreviate names (except trivial loop counters).

Variable and function names SHOULD NOT be abbreviated unless the variable is a primitive integer used
as a loop counter. Script flags SHOULD use long form (--force, not -f).

Rationale: Abbreviations are ambiguous. The cost of typing extra characters is negligible; the cost
of misunderstanding is not.

```text
# Prefer
connection, request, response, configuration

# Avoid
conn, req, res, cfg
```

### DX-04 — Capitalize acronyms consistently.

Acronyms in names SHOULD use their standard capitalization (e.g., VSR, HTTP, SQL), not title case.

Rationale: Standard capitalization is unambiguous. Title-casing acronyms obscures that they are
acronyms.

```text
# Prefer
VSRState, HTTPClient, SQLQuery

# Avoid
VsrState, HttpClient, SqlQuery
```

### DX-05 — Append units and qualifiers at the end, sorted by significance.

Units and qualifiers SHOULD be appended to variable names, sorted from most significant to least.

Rationale: This causes related variables to align visually and group semantically.

```text
# Prefer
latency_ms_max
latency_ms_min
latency_ms_p99

# Avoid
max_latency_ms
min_latency
```

### DX-06 — Use meaningful names that indicate lifecycle and ownership.

Resource names SHOULD convey their lifecycle, ownership, or allocation strategy.

Rationale: Knowing whether a resource needs explicit cleanup is critical for correctness.

```text
# Prefer
arena: Allocator      # bulk free, no individual dealloc
pool: ConnectionPool  # return to pool, don't close

# Acceptable but less informative
allocator: Allocator
connection: Connection
```

### DX-07 — Align related names by character length when feasible.

When choosing names for related variables, CONSIDER names with the same character count so that
related expressions align visually.

Rationale: Symmetrical code is easier to scan and verify.

```text
# Prefer: "source" and "target" (both 6 characters)
source_offset = 0
target_offset = 0

# Less ideal: "src" (3) and "dest" (4) misalign
src_offset = 0
dest_offset = 0
```

### DX-08 — Prefix helper/callback names with the caller's name.

When a function calls a helper or callback, the helper's name SHOULD be prefixed with the calling
function's name.

Rationale: The prefix makes the call hierarchy visible in the name itself.

```text
# Prefer
read_sector()
read_sector_callback()
read_sector_validate()

# Avoid
sector_callback()
on_read_done()
```

### DX-09 — Callbacks go last in parameter lists.

Callback parameters SHOULD be the last parameters in a function signature.

Rationale: Callbacks are invoked last. Parameter order should mirror control flow.

```text
# Prefer
def read_sector(disk, sector_id, callback):

# Avoid
def read_sector(callback, disk, sector_id):
```

### DX-10 — Order declarations by importance. Put main/entry first.

Within a file, the most important declarations (entry points, main functions, public API) SHOULD
appear first.

Rationale: Files are read top-down on first encounter. The reader should encounter the most
important context first.

```text
# File structure:
# 1. Entry point / main / public API
# 2. Core logic functions
# 3. Helper functions
# 4. Utilities and constants
```

### DX-11 — Struct layout: fields, then types, then methods.

Struct/class definitions SHOULD be ordered: data fields first, then nested type definitions, then
methods.

Rationale: Predictable layout lets the reader find what they need by position.

```text
struct Replica:
    # Fields first
    term: u64
    status: Status
    log: Log

    # Types second
    type Status = enum { follower, candidate, leader }

    # Methods last
    def init(config): ...
    def step(message): ...
```

### DX-12 — Do not overload names that conflict with domain terminology.

Names SHOULD NOT be reused across different concepts in the same system.

Rationale: Overloaded terminology causes confusion in documentation, code review, and incident
response.

```text
# Prefer: distinct names for distinct concepts
pending_transfer
consensus_prepare

# Avoid: overloaded name
two_phase_commit    # means different things in payments vs. consensus
```

### DX-13 — Prefer nouns over adjectives/participles for externally-referenced names.

Names that appear in documentation, logs, or external communication SHOULD be nouns or noun phrases.

Rationale: Noun names compose cleanly into derived identifiers and work in prose without rephrasing.

```text
# Prefer
replica.pipeline         # "The pipeline is full" — works in docs
config.pipeline_max

# Avoid
replica.preparing        # "The preparing is..." — awkward in docs
```

### DX-14 — Use named option structs when arguments can be confused.

When a function takes two or more arguments of the same type, or arguments whose meaning is not
obvious at the call site, a named options struct SHOULD be used.

Rationale: Positional arguments of the same type are silently swappable.

```text
# Prefer: named options
transfer(TransferOptions {
    from: account_a,
    to: account_b,
    amount: 100,
})

# Avoid: positional same-type args
transfer(account_a, account_b, 100)
```

### DX-15 — Name nullable parameters so null's meaning is clear at the call site.

If a parameter accepts null/none/nil, the parameter name SHOULD make the meaning of null obvious.

Rationale: `foo(null)` is meaningless without context.

```text
# Prefer
connect(host, timeout_ms: null)    # clear: no timeout

# Avoid
connect(host, null)
```

### DX-16 — Thread singletons positionally: general to specific.

Constructor parameters that are singletons SHOULD be passed positionally, ordered from most general
to most specific.

Rationale: Consistent constructor signatures reduce cognitive load.

```text
# Prefer: general -> specific
Server.init(allocator, logger, config)

# Avoid: random order
Server.init(config, allocator, logger)
```

### DX-17 — Write descriptive commit messages.

Commit messages SHOULD be descriptive, informative, and explain the purpose of the change. A pull
request description is not a substitute for a commit message.

Rationale: Commit history is permanent documentation. Every `git blame` reader deserves context.

```text
# Prefer
"Enforce bounded retry queue to prevent tail-latency spikes

Previously, the retry queue grew unboundedly under sustained load,
causing p99 latency to spike to 500ms. This change adds a fixed
upper bound of 1024 entries and rejects new retries when full."

# Avoid
"fix bug"
"update code"
"wip"
```

### DX-18 — Explain "why" in code comments.

Comments SHOULD explain why the code was written this way, not what the code does.

Rationale: Without rationale, future maintainers cannot evaluate whether the decision still applies.

```text
# Prefer
# Why: fsync after every batch because we promised durability to the client.
fsync(fd)

# Avoid
# Sync the file descriptor.
fsync(fd)
```

### DX-19 — Explain "how" for tests and complex logic.

Tests and complex algorithms SHOULD include a description at the top explaining the goal and
methodology.

Rationale: Tests are documentation of expected behavior. A reader should be able to understand what
is being tested without reading every assertion.

```text
# Test: verify that the transfer engine rejects overdrafts.
# Methodology: create an account with a known balance, attempt transfers
# of exactly the balance (should succeed), balance + 1 (should fail),
# and zero (should fail).
def test_overdraft_rejection():
    ...
```

### DX-20 — Comments are well-formed sentences.

Comments SHOULD be complete sentences: space after the delimiter, capital letter, full stop.
End-of-line comments may be phrases without punctuation.

Rationale: Well-written prose is easier to read and signals careful thinking.

```text
# Prefer
# This avoids double-counting when a transfer is posted twice.

# Prefer (end-of-line)
balance -= amount  # idempotent

# Avoid
#this avoids double counting
```

---

## Cache Invalidation & State Hygiene (CIS)

### CIS-01 — Do not duplicate variables or alias state.

Every piece of state SHOULD have exactly one source of truth. AVOID duplicating or aliasing
variables unless there is a documented performance reason.

Rationale: Duplicated state will eventually desynchronize.

```text
# Prefer: single source of truth
total = compute_total(items)

# Avoid: duplicated state
cached_total = total
```

### CIS-02 — Pass large arguments (>16 bytes) by const reference.

Function arguments larger than 16 bytes SHOULD be passed by const pointer/reference, not by value.

Rationale: Passing large structs by value creates implicit copies that waste stack space and can
mask bugs.

```text
# Prefer
def process(config: *const Config):

# Avoid
def process(config: Config):     # copied on call (if >16 bytes)
```

### CIS-03 — Prefer in-place initialization via out pointers.

Large structs SHOULD be initialized in-place by passing a target/out pointer, rather than returning
a value that is then copied/moved.

Rationale: In-place initialization avoids intermediate copies, ensures pointer stability, and
eliminates undesirable stack growth.

```text
# Prefer: in-place via out pointer
def init(target: *LargeStruct):
    target.field_a = ...
    target.field_b = ...

# Less ideal: return and copy
def init() -> LargeStruct:
    return LargeStruct { ... }
```

### CIS-04 — If any field requires in-place init, the whole struct does.

In-place initialization is viral. If any field of a struct requires in-place initialization, the
entire containing struct SHOULD also be initialized in-place.

Rationale: Mixing initialization strategies breaks pointer stability guarantees.

```text
# If SubStruct requires in-place init:
def Container.init(target: *Container):
    target.sub.init()            # in-place
    target.value = 0             # rest of container also in-place
```

### CIS-05 — Declare variables close to use. Shrink scope.

Variables SHOULD be computed or checked as close as possible to where they are used. AVOID
introducing variables before they are needed.

Rationale: Minimizing the check-to-use gap reduces POCPOU/TOCTOU style bugs.

```text
# Prefer: compute at point of use
offset = compute_offset(index)
buffer[offset] = value

# Avoid: compute far from use
offset = compute_offset(index)
# ... 20 lines of unrelated code ...
buffer[offset] = value
```

### CIS-06 — Prefer simpler return types to reduce call-site dimensionality.

Function return types SHOULD be as simple as possible. PREFER `void` over `bool`, `bool` over
integer, integer over optional, optional over result/error.

Rationale: Each additional dimension creates branches at every call site.

```text
# Preference order:
# void > bool > u64 > ?u64 > Result<u64, Error>

# Prefer: return void, assert internally
def validate(data):
    assert(data.valid())

# Less ideal: return result, force caller to branch
def validate(data) -> Result:
    if not data.valid():
        return Error("invalid")
```

### CIS-07 — Functions should run to completion without suspending.

Functions that contain precondition assertions SHOULD run to completion without yielding or
suspending between the assertion and the code that depends on it.

Rationale: Suspension can invalidate preconditions, making assertions misleading.

```text
# Prefer: assert and use without suspension
assert(connection.is_alive())
connection.send(data)

# Avoid: suspend between assert and use
assert(connection.is_alive())
await some_other_work()
connection.send(data)
```

### CIS-08 — Guard against buffer underflow (buffer bleeds).

All buffers SHOULD be fully utilized or the unused portion SHOULD be explicitly zeroed.

Rationale: Buffer underflow can leak sensitive information and violate deterministic guarantees.

```text
# Prefer: zero unused space
buffer = allocate(BUFFER_SIZE)
write(data, buffer)
zero(buffer[len(data)..BUFFER_SIZE])

# Avoid: send buffer with stale padding
buffer = allocate(BUFFER_SIZE)
write(data, buffer)
send(buffer)
```

### CIS-09 — Group allocation with deallocation using blank lines.

Resource allocation and its corresponding deallocation SHOULD be visually grouped using blank lines.

Rationale: Visual grouping makes resource leaks easy to spot during code review.

```text
# Prefer: visual grouping
<blank line>
fd = open(path)
defer close(fd)
<blank line>

# Avoid: interleaved with unrelated code
fd = open(path)
config = load_config()
defer close(fd)
```

---

## Off-by-One & Arithmetic (OBO)

### OBO-01 — Treat index, count, and size as distinct types.

Indexes, counts, and sizes SHOULD be treated as conceptually distinct. Conversions SHOULD be
explicit:
- index → count: add 1.
- count → size: multiply by unit size.

Rationale: Casual interchange of index, count, and size is the primary source of off-by-one errors.

```text
# Prefer: explicit conversion
last_index = 9
count = last_index + 1           # 10 items
size_bytes = count * ITEM_SIZE

# Avoid: implicit interchange
buffer = allocate(last_index)    # is this count or index?
```

### OBO-02 — Use explicit division semantics.

All integer division SHOULD use an explicitly-named operation: exact (asserts no remainder), floor,
or ceiling.

Rationale: Default `/` rounding behavior varies by language and surprises programmers.

```text
# Prefer: explicit semantics
pages = div_ceil(total_bytes, PAGE_SIZE)
aligned = div_floor(offset, ALIGNMENT)
slots = div_exact(buffer_size, SLOT_SIZE)

# Avoid: implicit division
pages = total_bytes / PAGE_SIZE
```

---

## Formatting & Code Style (FMT)

### FMT-01 — Run the language formatter.

All code SHOULD be formatted by the project's standard formatter.

Rationale: Automated formatting eliminates style debates in code review.

```text
# Examples per language:
# Zig: zig fmt  |  Go: gofmt  |  Rust: rustfmt
# Python: black / ruff format  |  TS/JS: prettier / biome
```

### FMT-02 — Use 4-space indentation (or the project's declared standard).

Indentation SHOULD be 4 spaces unless the project explicitly declares a different standard.

Rationale: 4 spaces is more visually distinct than 2 spaces at a distance.

```text
# Prefer: 4 spaces
if condition:
    if nested:
        do_work()
```

### FMT-03 — Hard limit all lines to 100 columns.

No line SHOULD exceed 100 columns.

Rationale: 100 columns allows two files side-by-side on a standard monitor.

```text
# If a line exceeds 100 columns, break it:
# - Add a trailing comma to trigger formatter wrapping.
# - Break at logical boundaries.
```

### FMT-04 — Always use braces on if statements (unless single-line).

If statements SHOULD have braces unless the entire statement fits on a single line.

Rationale: Braceless multi-line if statements are the root cause of "goto fail" style bugs.

```text
# Prefer: single-line, no braces needed
if (done) return

# Prefer: multi-line, braces required
if (done) {
    cleanup()
    return
}

# Avoid: multi-line without braces
if (done)
    cleanup()
    return              # not guarded by the if
```

---

## Dependencies & Tooling (DEP)

### DEP-01 — Minimize dependencies.

The number of external dependencies SHOULD be minimized. Every dependency SHOULD be justified.

Rationale: Dependencies introduce supply chain risk, safety risk, performance risk, and
installation complexity.

```text
# Before adding a dependency, answer:
# 1. Can the standard library do this?
# 2. Can we write this in <100 lines?
# 3. Is the dependency actively maintained?
# 4. What is the transitive dependency count?
# 5. What is the security track record?
```

### DEP-02 — Prefer existing tools over adding new ones.

New tools SHOULD NOT be introduced when an existing tool can accomplish the task.

Rationale: A small, standardized toolbox is simpler to operate than specialized instruments each
with a dedicated manual.

```text
# Before adding a new tool, answer:
# 1. Can an existing tool do this?
# 2. Is the marginal benefit worth the maintenance cost?
# 3. Will every team member need to learn this tool?
```

### DEP-03 — Prefer typed, portable tooling for scripts.

Scripts and automation SHOULD prefer typed, portable languages over shell scripts.

Rationale: Shell scripts are not portable, not type-safe, and fail silently.

```text
# Prefer: typed script
scripts/deploy.ts
scripts/migrate.py

# Avoid: complex shell script (>20 lines or containing logic)
scripts/deploy.sh
```

---

## Appendix: Rule Index

| ID | Rule (short form) |
|----|-------------------|
| SAF-01 | Simple explicit control flow; no recursion |
| SAF-02 | Bound everything |
| SAF-03 | Explicitly-sized types |
| SAF-04 | Assert pre/post/invariants |
| SAF-05 | Assertion density ≥ 2/function |
| SAF-06 | Pair assertions across paths |
| SAF-07 | Split compound assertions |
| SAF-08 | Single-line implication asserts |
| SAF-09 | Assert compile-time constants |
| SAF-10 | Assert positive and negative space |
| SAF-11 | Test valid, invalid, and boundary |
| SAF-12 | Static allocation only |
| SAF-13 | Smallest possible variable scope |
| SAF-14 | ~70-line function limit |
| SAF-15 | Centralize control flow in parent |
| SAF-16 | Centralize state mutation; pure leaves |
| SAF-17 | All warnings as errors |
| SAF-18 | Batch external events |
| SAF-19 | Split compound conditions |
| SAF-20 | Positive invariants; no negations |
| SAF-21 | Handle all errors explicitly |
| SAF-22 | Always state the why |
| SAF-23 | Explicit options; no defaults |
| PERF-01 | Design for performance from start |
| PERF-02 | Back-of-envelope resource sketches |
| PERF-03 | Optimize slowest resource first |
| PERF-04 | Separate control and data planes |
| PERF-05 | Amortize via batching |
| PERF-06 | Predictable CPU work |
| PERF-07 | Explicit; no compiler reliance |
| PERF-08 | Primitive args in hot loops |
| DX-01 | Precise nouns and verbs |
| DX-02 | snake_case for files/functions/variables |
| DX-03 | No abbreviations |
| DX-04 | Consistent acronym capitalization |
| DX-05 | Units/qualifiers appended last |
| DX-06 | Meaningful lifecycle names |
| DX-07 | Align related names by length |
| DX-08 | Prefix helpers with caller name |
| DX-09 | Callbacks last in params |
| DX-10 | Important declarations first |
| DX-11 | Struct: fields → types → methods |
| DX-12 | No overloaded domain terms |
| DX-13 | Noun names for external reference |
| DX-14 | Named options for confusable args |
| DX-15 | Name nullable params clearly |
| DX-16 | Singletons: general → specific |
| DX-17 | Descriptive commit messages |
| DX-18 | Explain "why" in comments |
| DX-19 | Explain "how" in tests |
| DX-20 | Comments are sentences |
| CIS-01 | No state duplication or aliasing |
| CIS-02 | Large args by const reference |
| CIS-03 | In-place init via out pointers |
| CIS-04 | In-place init is viral |
| CIS-05 | Declare close to use |
| CIS-06 | Simpler return types |
| CIS-07 | No suspension with active assertions |
| CIS-08 | Guard against buffer bleeds |
| CIS-09 | Group alloc/dealloc visually |
| OBO-01 | Index ≠ count ≠ size |
| OBO-02 | Explicit division semantics |
| FMT-01 | Run the formatter |
| FMT-02 | 4-space indent |
| FMT-03 | 100-column hard limit |
| FMT-04 | Braces on if (unless single-line) |
| DEP-01 | Minimize dependencies |
| DEP-02 | Prefer existing tools |
| DEP-03 | Typed portable scripts |

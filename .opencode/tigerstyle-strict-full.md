# TigerStyle Rulebook — Strict / Full

## Preamble

### Purpose

This document is a comprehensive, language-agnostic coding rulebook derived from TigerBeetle's
TigerStyle. It is intended to be dropped into any codebase as part of an `AGENTS.md` file, a
system prompt, or a code review checklist. Every rule is actionable and enforceable.

### Design Goal Priority

All rules serve three design goals, in this order:

1. **Safety** — correctness, bounded behavior, crash on corruption.
2. **Performance** — mechanical sympathy, batching, resource awareness.
3. **Developer Experience** — clarity, naming, readability, maintainability.

When goals conflict, higher-priority goals win.

### Keyword Definitions (RFC 2119)

- **MUST / SHALL** — Absolute requirement. Violations are defects.
- **MUST NOT / SHALL NOT** — Absolute prohibition. Violations are defects.
- **REQUIRED** — Equivalent to MUST.

Non-compliance with any MUST/SHALL rule is a blocking review finding unless the rule is explicitly
marked as not applicable to the project in a project-level override document.

### How to Use This Document

- Reference rules by ID (e.g., SAF-01, DX-05) in code reviews and commit messages.
- All 69 rules are organized into 7 categories.
- Each rule has: an imperative statement, a rationale, and a pseudocode example or template.
- Rules are language-agnostic. Adapt examples to your language and tooling.

---

## Safety & Correctness (SAF)

### SAF-01 — Use simple, explicit control flow. Do not use recursion.

All control flow MUST be simple, explicit, and statically analyzable. Recursion MUST NOT be used.
This ensures all executions that should be bounded are bounded.

Rationale: Predictable, bounded execution is the foundation of safety. Recursion makes it difficult
to prove termination and risks stack overflow.

```text
# Do: explicit loop with fixed bound
for i in 0..max_iterations:
    process(item[i])

# Do not: recursive call
def process(items):
    if items.empty(): return
    process(items.rest())  # VIOLATION
```

### SAF-02 — Put a limit on everything.

All loops, queues, retries, buffers, and any form of repeated or accumulated work MUST have a fixed
upper bound. Where a loop cannot terminate (e.g., an event loop), this MUST be asserted.

Rationale: Unbounded work causes infinite loops, tail-latency spikes, and resource exhaustion.
The fail-fast principle demands that violations are detected sooner rather than later.

```text
# Do: bounded loop
for i in 0..MAX_RETRIES:
    if try_connect(): break
assert(i < MAX_RETRIES, "connection retries exhausted")

# Do: assert non-terminating loop
while true:  # event loop
    assert(is_running, "event loop must be explicitly stopped")
    process_events()
```

### SAF-03 — Use explicitly-sized types.

All integer types MUST be explicitly sized (e.g., u32, i64). Architecture-dependent types (e.g.,
usize, size_t, long) MUST NOT be used unless required by a foreign interface.

Rationale: Implicit sizing creates architecture-specific behavior and makes overflow analysis
impossible without knowing the target.

```text
# Do
count: u32 = 0
offset: u64 = 0

# Do not
count: usize = 0   # VIOLATION: architecture-dependent
```

### SAF-04 — Assert all preconditions, postconditions, and invariants.

Every function MUST assert its preconditions (valid arguments), postconditions (valid return values),
and any invariants that must hold during execution. A function MUST NOT operate blindly on unchecked
data.

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

The assertion density of the codebase MUST average a minimum of two assertions per function.

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

For every property to enforce, there MUST be at least two assertions on different code paths that
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

Compound assertions MUST be split into individual assertions. Prefer `assert(a); assert(b);` over
`assert(a and b)`.

Rationale: Split assertions are simpler to read and provide precise failure information. A compound
assertion that fails gives no indication of which condition was violated.

```text
# Do
assert(index >= 0)
assert(index < length)

# Do not
assert(index >= 0 and index < length)  # VIOLATION: compound
```

### SAF-08 — Use single-line implication assertions.

When a property B must hold whenever condition A is true, this MUST be expressed as a single-line
implication: `if (a) assert(b)`.

Rationale: Preserves logical intent without introducing complex boolean expressions or unnecessary
nesting.

```text
if (is_committed) assert(has_quorum)
if (is_leader) assert(term == current_term)
```

### SAF-09 — Assert compile-time constants and type sizes.

Relationships between compile-time constants, type sizes, and configuration values MUST be asserted
at compile time (or at program startup if the language lacks compile-time assertions).

Rationale: Compile-time assertions verify design integrity before the program executes. They catch
configuration drift and subtle invariant violations that runtime testing may miss.

```text
static_assert(BLOCK_SIZE % PAGE_SIZE == 0)
static_assert(sizeof(Header) == 64)
static_assert(MAX_BATCH_SIZE <= BUFFER_CAPACITY)
```

### SAF-10 — Assert both positive and negative space.

Assertions MUST cover both the positive space (what is expected) AND the negative space (what is not
expected). Where data moves across the valid/invalid boundary, both sides MUST be asserted.

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

Tests MUST exercise valid inputs, invalid inputs, and the transitions between valid and invalid
states. Tests MUST NOT only cover the happy path.

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

### SAF-12 — Allocate memory statically at startup. No runtime reallocation.

All memory MUST be statically allocated at initialization. No memory SHALL be dynamically allocated
or freed and reallocated after initialization.

Rationale: Dynamic allocation introduces unpredictable latency, fragmentation, and use-after-free
risk. Static allocation forces upfront design of all memory usage patterns, which produces simpler,
more performant, and more maintainable systems.

```text
# Do: allocate once at startup
buffer = allocate(MAX_BUFFER_SIZE)   # startup
# ... use buffer for lifetime of program ...

# Do not: allocate at runtime
def process(data):
    temp = allocate(len(data))       # VIOLATION: runtime allocation
    free(temp)                       # VIOLATION: runtime deallocation
```

### SAF-13 — Declare variables at the smallest possible scope.

Variables MUST be declared at the smallest possible scope and the number of variables in any given
scope MUST be minimized.

Rationale: Fewer variables in scope reduces the probability that a variable is misused or confused
with another. Tight scoping limits the blast radius of errors.

```text
# Do: declare at point of use
for item in batch:
    checksum = compute_checksum(item)
    assert(checksum == item.expected_checksum)

# Do not: declare far from use
checksum = 0                          # VIOLATION: premature declaration
# ... 30 lines of unrelated code ...
for item in batch:
    checksum = compute_checksum(item)
```

### SAF-14 — Hard limit function length to 70 lines.

No function SHALL exceed 70 lines. This is a hard limit, not a guideline.

Rationale: There is a sharp cognitive discontinuity between a function that fits on screen and one
that requires scrolling. The 70-line limit forces clean decomposition. Art is born of constraints —
there are many ways to split a long function, but only a few will feel right.

```text
# If a function approaches 70 lines, split it:
# - Keep control flow (if/switch) in the parent function.
# - Move non-branching logic into helper functions.
# - Keep leaf functions pure (no state mutation).
```

### SAF-15 — Centralize control flow in parent functions.

When splitting a large function, all branching logic (if/switch/match) MUST remain in the parent
function. Helper functions MUST NOT contain control flow that determines program behavior.

Rationale: Centralizing control flow means there is exactly one place to understand all branches.
Scattered branching across helpers makes case analysis exponentially harder.

```text
# Do: parent owns all branching
def process(request):
    if request.type == READ:
        data = read_helper(request.key)
        return respond(data)
    elif request.type == WRITE:
        write_helper(request.key, request.value)
        return acknowledge()

# Do not: helper decides behavior
def read_helper(key, request):
    if request.needs_auth:       # VIOLATION: control flow in helper
        authenticate(request)
```

### SAF-16 — Centralize state mutation. Keep leaf functions pure.

Parent functions MUST own state mutation. Helper functions MUST compute and return values without
mutating shared state. Keep leaf functions pure.

Rationale: Pure helper functions are easier to test, reason about, and compose. When only one
function mutates state, bugs are localized to one site.

```text
# Do: helper computes, parent mutates
def update_balance(account, amount):
    new_balance = compute_new_balance(account.balance, amount)  # pure
    assert(new_balance >= 0)
    account.balance = new_balance  # mutation in parent

# Do not: helper mutates directly
def compute_new_balance(account, amount):
    account.balance -= amount  # VIOLATION: mutation in leaf
```

### SAF-17 — Treat all compiler warnings as errors at the strictest setting.

All compiler and linter warnings MUST be enabled at the strictest available setting. All warnings
MUST be resolved, not suppressed.

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

Programs MUST NOT perform work directly in response to external events (network, user input,
signals). Instead, events MUST be queued and processed in controlled batches at the program's own
pace.

Rationale: Reacting directly to external events surrenders control flow to the environment, making
it impossible to bound work per time period. Batching restores control, improves throughput, and
enables assertion safety between batches.

```text
# Do: queue and batch
event_queue.push(incoming_event)
# ... in main loop tick ...
batch = event_queue.drain(MAX_BATCH_SIZE)
process_batch(batch)

# Do not: react inline
on_message(msg):
    process(msg)    # VIOLATION: direct reaction, unbounded
```

### SAF-19 — Split compound conditions into nested branches.

Compound boolean conditions (evaluating multiple booleans in one expression) MUST be split into
nested if/else branches. Complex `else if` chains MUST be rewritten as `else { if { } }` trees.

Rationale: Compound conditions obscure case coverage. Nested branches make every case explicit and
verifiable. They also force the author to consider whether both the positive and negative branches
are handled.

```text
# Do: nested branches
if is_valid:
    if is_authorized:
        execute()
    else:
        reject("unauthorized")
else:
    reject("invalid")

# Do not: compound condition
if is_valid and is_authorized:   # VIOLATION: compound
    execute()
```

### SAF-20 — State invariants positively. Avoid negations.

Conditions MUST be stated in positive form. Comparisons MUST follow the natural grain of the domain
(e.g., `index < length` rather than `index >= length` with inverted logic).

Rationale: Negations are error-prone and harder to verify. Positive conditions align with how
programmers naturally reason about loop bounds and index validity.

```text
# Do: positive form
if index < length:
    # invariant holds
else:
    # invariant violated

# Do not: negated form
if index >= length:              # VIOLATION: negation
    # it's not true that the invariant holds
```

### SAF-21 — Handle all errors explicitly.

Every error MUST be handled explicitly. No error SHALL be silently ignored, swallowed, or discarded.

Rationale: 92% of catastrophic production failures result from incorrect handling of non-fatal
errors. Silent error swallowing is the single largest class of preventable production failures.

```text
# Do: explicit handling
result = call()
if result.error:
    log(result.error)
    return result.error

# Do not: swallowed error
call()                           # VIOLATION: error ignored
```

### SAF-22 — Always state the "why" in comments and commit messages.

Every non-obvious decision MUST be accompanied by a comment or commit message explaining why. Code
without rationale is incomplete.

Rationale: The "what" is in the code. The "why" is the only thing that enables safe future changes.
Without rationale, maintainers cannot evaluate whether the original decision still applies.

```text
# Do
# Why: batch to amortize syscall overhead; one-at-a-time caused 3x latency.
process_batch(items)

# Do not
process_batch(items)             # no explanation of design choice
```

### SAF-23 — Pass explicit options to library calls. Do not rely on defaults.

All options and configuration values MUST be passed explicitly at the call site. Default values
MUST NOT be relied upon.

Rationale: Defaults can change across library versions, causing latent, potentially catastrophic bugs
that are invisible at the call site.

```text
# Do: explicit options
http.request(url, {
    timeout_ms: 5000,
    retries: 3,
    method: "GET"
})

# Do not: rely on defaults
http.request(url)                # VIOLATION: implicit defaults
```

---

## Performance & Design (PERF)

### PERF-01 — Design for performance from the start.

Performance MUST be considered during the design phase, not deferred to profiling. The largest
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

Before implementation, back-of-the-envelope calculations MUST be performed for the four core
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

Optimization effort MUST target the slowest resource first (network > disk > memory > CPU), after
adjusting for frequency of access. A frequent cache miss can cost more than a rare disk sync.

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

The control plane (scheduling, coordination, metadata) MUST be clearly separated from the data plane
(bulk data processing). This separation enables batching on the data plane without sacrificing
assertion safety on the control plane.

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

Network, disk, memory, and CPU costs MUST be amortized by batching accesses. Per-item processing
MUST be avoided when batching is feasible.

Rationale: Per-item overhead (syscalls, context switches, cache misses) dominates at high
throughput. Batching reduces overhead by orders of magnitude.

```text
# Do: batch
items = collect(MAX_BATCH_SIZE)
write_all(items)                 # one syscall

# Do not: per-item
for item in items:
    write(item)                  # VIOLATION: syscall per item
```

### PERF-06 — Keep CPU work predictable. Avoid erratic control flow.

Hot paths MUST have predictable, linear control flow. Avoid branching, pointer chasing, and random
access patterns in performance-critical code.

Rationale: Modern CPUs are sprinters. Predictable work enables prefetching, branch prediction, and
cache line utilization. Erratic control flow forces pipeline stalls.

```text
# Do: linear access
for i in 0..count:
    process(buffer[i])           # sequential, predictable

# Do not: pointer chasing
node = head
while node:
    process(node)
    node = node.next             # random memory access
```

### PERF-07 — Be explicit. Do not depend on compiler optimizations.

Performance-critical code MUST be written explicitly. Do not rely on the compiler to inline, unroll,
vectorize, or otherwise optimize the code.

Rationale: Compiler optimizations are heuristic and fragile. Explicit code is portable across
compilers and versions, and is easier for humans to verify.

```text
# Do: explicit unrolling if needed
process(items[0])
process(items[1])
process(items[2])
process(items[3])

# Do not: hope the compiler unrolls
for i in 0..4:
    process(items[i])            # may or may not be unrolled
```

### PERF-08 — Use primitive arguments in hot loops. Avoid implicit self/this.

Hot loop functions MUST take primitive arguments directly. They MUST NOT take `self`/`this` or large
struct references that require the compiler to prove field caching.

Rationale: Primitive arguments enable the compiler to keep values in registers without alias
analysis. A human reader can also spot redundant computations more easily.

```text
# Do: primitive arguments
def hot_loop(data_ptr, length, stride):
    for i in 0..length:
        process(data_ptr[i * stride])

# Do not: self reference
def hot_loop(self):
    for i in 0..self.length:     # VIOLATION: compiler must prove self.length stable
        process(self.data[i * self.stride])
```

---

## Developer Experience & Naming (DX)

### DX-01 — Choose precise nouns and verbs.

Names MUST capture what a thing is or does with precision. Take time to find the name that provides
a crisp, intuitive mental model. Names MUST show understanding of the domain.

Rationale: Great names are the essence of great code. They reduce documentation burden and make the
code self-describing. A wrong name actively misleads.

```text
# Do
pipeline, transfer, checkpoint, replica

# Do not
data, info, manager, handler, process  # too vague
```

### DX-02 — Use snake_case for files, functions, and variables.

All file names, function names, and variable names MUST use snake_case.

Rationale: Underscores are the closest thing programmers have to spaces. They separate words clearly
and encourage descriptive multi-word names. Consistency eliminates style debates.

```text
# Do
process_batch, user_account, latency_ms_max

# Do not
processBatch, UserAccount, latencyMsMax  # camelCase/PascalCase for these
```

**Note:** If your language has a strong idiomatic convention (e.g., camelCase in JavaScript/TypeScript,
PascalCase for types in Go), follow the language convention but apply the spirit of this rule:
prefer clear word separation and descriptive names.

### DX-03 — Do not abbreviate names (except trivial loop counters).

Variable and function names MUST NOT be abbreviated unless the variable is a primitive integer used
as a loop counter, sort index, or matrix coordinate. Script flags MUST use long form (--force, not
-f).

Rationale: Abbreviations are ambiguous. `ctx` could mean context, contract, or counter. The cost of
typing a few extra characters is negligible; the cost of misunderstanding is not.

```text
# Do
connection, request, response, configuration

# Do not
conn, req, res, cfg              # VIOLATION: abbreviated
```

### DX-04 — Capitalize acronyms consistently.

Acronyms in names MUST use their standard capitalization (e.g., VSR, HTTP, SQL), not title case.

Rationale: Standard capitalization is unambiguous. Title-casing acronyms (Vsr, Http) obscures that
they are acronyms and can cause confusion with regular words.

```text
# Do
VSRState, HTTPClient, SQLQuery

# Do not
VsrState, HttpClient, SqlQuery   # VIOLATION: title-cased acronyms
```

### DX-05 — Append units and qualifiers at the end, sorted by significance.

Units and qualifiers MUST be appended to variable names, sorted from most significant to least
significant (descending). The variable MUST start with the most meaningful word.

Rationale: This convention causes related variables to align visually and group semantically. It
also makes alphabetical sorting useful.

```text
# Do
latency_ms_max
latency_ms_min
latency_ms_p99
transfer_count_pending
transfer_count_posted

# Do not
max_latency_ms                   # VIOLATION: qualifier first
min_latency                      # VIOLATION: no unit
```

### DX-06 — Use meaningful names that indicate lifecycle and ownership.

Resource names MUST convey their lifecycle, ownership, or allocation strategy. A name like
`allocator` is acceptable; a name like `arena` or `pool` is better because it informs the reader
about cleanup expectations.

Rationale: Knowing whether a resource needs explicit cleanup is critical for correctness. The name
should make this obvious.

```text
# Do
arena: Allocator      # reader knows: bulk free, no individual dealloc
pool: ConnectionPool  # reader knows: return to pool, don't close

# Acceptable but less informative
allocator: Allocator
connection: Connection
```

### DX-07 — Align related names by character length when feasible.

When choosing names for related variables, PREFER names with the same character count so that
related expressions align visually in the source.

Rationale: Symmetrical code is easier to scan and verify. Alignment makes differences (and bugs)
stand out.

```text
# Do: "source" and "target" are both 6 characters
source_offset = 0
target_offset = 0
copy(source[source_offset..], target[target_offset..])

# Do not: "src" (3) and "dest" (4) misalign
src_offset = 0
dest_offset = 0
```

### DX-08 — Prefix helper/callback names with the caller's name.

When a function calls a helper or callback, the helper's name MUST be prefixed with the calling
function's name.

Rationale: The prefix makes the call hierarchy visible in the name itself, without requiring the
reader to trace call sites.

```text
# Do
read_sector()
read_sector_callback()
read_sector_validate()

# Do not
sector_callback()                # VIOLATION: no caller prefix
on_read_done()                   # VIOLATION: inconsistent scheme
```

### DX-09 — Callbacks go last in parameter lists.

Callback parameters MUST be the last parameters in a function signature.

Rationale: Callbacks are invoked last. Parameter order should mirror control flow for consistency
and readability.

```text
# Do
def read_sector(disk, sector_id, callback):

# Do not
def read_sector(callback, disk, sector_id):  # VIOLATION: callback first
```

### DX-10 — Order declarations by importance. Put main/entry first.

Within a file, the most important declarations (entry points, main functions, public API) MUST
appear first. Internal helpers and utilities follow.

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

Struct/class definitions MUST be ordered: data fields first, then nested type definitions, then
methods.

Rationale: Predictable layout lets the reader find what they need by position. Data is the most
important thing about a struct; it comes first.

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

Names MUST NOT be reused across different concepts in the same system. If a term has a specific
meaning in one context (e.g., protocol), it MUST NOT be reused with a different meaning elsewhere.

Rationale: Overloaded terminology causes confusion in documentation, code review, and incident
response. It forces the reader to determine meaning from context, which is error-prone.

```text
# Do: distinct names for distinct concepts
pending_transfer    # domain: payment lifecycle
consensus_prepare   # domain: distributed protocol

# Do not: overloaded name
two_phase_commit    # VIOLATION: means different things in payments vs. consensus
```

### DX-13 — Prefer nouns over adjectives/participles for externally-referenced names.

Names that appear in documentation, logs, or external communication MUST be nouns (or noun phrases)
that can be used directly as section headers or conversation topics.

Rationale: Noun names compose cleanly into derived identifiers and work in prose without
rephrasing. A noun like `pipeline` can be a section header; a participle like `preparing` cannot.

```text
# Do
replica.pipeline         # "The pipeline is full" — works in docs
config.pipeline_max      # clean derived identifier

# Do not
replica.preparing        # "The preparing is..." — awkward in docs
```

### DX-14 — Use named option structs when arguments can be confused.

When a function takes two or more arguments of the same type, or arguments whose meaning is not
obvious at the call site, a named options struct MUST be used.

Rationale: Positional arguments of the same type are silently swappable. Named fields make the call
site self-documenting and prevent transposition bugs.

```text
# Do: named options
transfer(TransferOptions {
    from: account_a,
    to: account_b,
    amount: 100,
})

# Do not: positional same-type args
transfer(account_a, account_b, 100)  # which is from, which is to?
```

### DX-15 — Name nullable parameters so null's meaning is clear at the call site.

If a parameter accepts null/none/nil, the parameter name MUST make the meaning of null obvious when
read at the call site.

Rationale: `foo(null)` is meaningless without context. `foo(timeout_ms: null)` communicates "no
timeout."

```text
# Do
connect(host, timeout_ms: null)    # clear: no timeout

# Do not
connect(host, null)                # VIOLATION: null meaning unclear
```

### DX-16 — Thread singletons positionally: general to specific.

Constructor parameters that are singletons (allocator, logger, tracer) MUST be passed positionally,
ordered from most general to most specific. They have unique types and cannot be confused.

Rationale: Consistent constructor signatures reduce cognitive load. General-to-specific ordering
mirrors dependency scope.

```text
# Do: general -> specific
Server.init(allocator, logger, config)

# Do not: random order
Server.init(config, allocator, logger)  # VIOLATION: inconsistent ordering
```

### DX-17 — Write descriptive commit messages.

Commit messages MUST be descriptive, informative, and explain the purpose of the change. A pull
request description is not a substitute for a commit message because PR descriptions are not stored
in the git repository and are invisible in `git blame`.

Rationale: Commit history is permanent documentation. Every `git blame` reader deserves context.

```text
# Do
"Enforce bounded retry queue to prevent tail-latency spikes

Previously, the retry queue grew unboundedly under sustained load,
causing p99 latency to spike to 500ms. This change adds a fixed
upper bound of 1024 entries and rejects new retries when full."

# Do not
"fix bug"
"update code"
"wip"
```

### DX-18 — Explain "why" in code comments.

Comments MUST explain why the code was written this way, not what the code does. The "what" is in
the code; the "why" is the only thing that enables safe future changes.

Rationale: Without rationale, future maintainers cannot evaluate whether the decision still applies.
They must either preserve code they don't understand or risk breaking it.

```text
# Do
# Why: fsync after every batch because we promised durability to the client.
# A crash between batches may lose at most one batch, which is acceptable
# per our SLA, but losing acknowledged writes is not.
fsync(fd)

# Do not
# Sync the file descriptor.     # VIOLATION: restates the code
fsync(fd)
```

### DX-19 — Explain "how" for tests and complex logic.

Tests and complex algorithms MUST include a description at the top explaining the goal and
methodology.

Rationale: Tests are documentation of expected behavior. A reader should be able to understand what
is being tested and why, without reading every assertion. This also helps readers skip irrelevant
tests quickly.

```text
# Test: verify that the transfer engine rejects overdrafts.
# Methodology: create an account with a known balance, attempt transfers
# of exactly the balance (should succeed), balance + 1 (should fail),
# and zero (should fail). Verify account balance is unchanged after
# rejected transfers.
def test_overdraft_rejection():
    ...
```

### DX-20 — Comments are well-formed sentences.

Comments MUST be complete sentences: space after the delimiter, capital letter, full stop (or colon
if followed by related content). End-of-line comments may be phrases without punctuation.

Rationale: Well-written prose is easier to read and signals that the author has thought carefully.
Sloppy comments suggest sloppy thinking.

```text
# Do
# This avoids double-counting when a transfer is posted twice.

# Do (end-of-line)
balance -= amount  # idempotent

# Do not
#this avoids double counting  # VIOLATION: no space, no caps, no period
```

---

## Cache Invalidation & State Hygiene (CIS)

### CIS-01 — Do not duplicate variables or alias state.

Every piece of state MUST have exactly one source of truth. Variables MUST NOT be duplicated or
aliased unless there is a compelling performance reason, in which case the alias MUST be documented
and its synchronization asserted.

Rationale: Duplicated state will eventually desynchronize. The farther apart the copies, the harder
the bug.

```text
# Do: single source of truth
total = compute_total(items)

# Do not: duplicated state
cached_total = total             # VIOLATION: will desync if items change
```

### CIS-02 — Pass large arguments (>16 bytes) by const reference.

Function arguments larger than 16 bytes MUST be passed by const pointer/reference, not by value.

Rationale: Passing large structs by value creates implicit copies that waste stack space and can
mask bugs where the caller modifies state expecting the callee to see the change.

```text
# Do
def process(config: *const Config):

# Do not
def process(config: Config):     # VIOLATION: copied on call (if >16 bytes)
```

### CIS-03 — Prefer in-place initialization via out pointers.

Large structs MUST be initialized in-place by passing a target/out pointer, rather than returning a
value that is then copied/moved.

Rationale: In-place initialization avoids intermediate copies, ensures pointer stability, and
eliminates undesirable stack growth. It enables immovable types.

```text
# Do: in-place via out pointer
def init(target: *LargeStruct):
    target.field_a = ...
    target.field_b = ...

# Do not: return and copy
def init() -> LargeStruct:
    return LargeStruct { ... }   # VIOLATION: intermediate copy
```

### CIS-04 — If any field requires in-place init, the whole struct does.

In-place initialization is viral. If any field of a struct requires in-place initialization, the
entire containing struct MUST also be initialized in-place.

Rationale: Mixing in-place and return-value initialization for different fields of the same struct
breaks pointer stability guarantees.

```text
# If SubStruct requires in-place init:
def Container.init(target: *Container):
    target.sub.init()            # in-place
    target.value = 0             # rest of container also in-place
```

### CIS-05 — Declare variables close to use. Shrink scope.

Variables MUST be computed or checked as close as possible to where they are used. Do not introduce
variables before they are needed. Do not leave them in scope after they are consumed.

Rationale: Minimizing the gap between check and use (POCPOU) reduces the probability of
time-of-check-to-time-of-use errors. Most bugs come from semantic gaps in time or space.

```text
# Do: compute at point of use
offset = compute_offset(index)
buffer[offset] = value

# Do not: compute far from use
offset = compute_offset(index)
# ... 20 lines of unrelated code ...    # VIOLATION: gap
buffer[offset] = value
```

### CIS-06 — Prefer simpler return types to reduce call-site dimensionality.

Function return types MUST be as simple as possible. Prefer `void` over `bool`, `bool` over integer,
integer over optional, optional over result/error.

Rationale: Each additional dimension in the return type creates branches at every call site. This
dimensionality is viral, propagating through the call chain.

```text
# Preference order (simplest to most complex):
# void > bool > u64 > ?u64 > Result<u64, Error>

# Do: return void, assert internally
def validate(data):
    assert(data.valid())         # crash if invalid

# Avoid if possible: return result, force caller to branch
def validate(data) -> Result:
    if not data.valid():
        return Error("invalid")  # caller must handle
```

### CIS-07 — Functions must run to completion without suspending.

Functions that contain precondition assertions MUST run to completion without yielding, suspending,
or awaiting between the assertion and the code that depends on it.

Rationale: If a function suspends after asserting a precondition, the precondition may no longer
hold when execution resumes. The assertion becomes misleading documentation.

```text
# Do: assert and use without suspension
assert(connection.is_alive())
connection.send(data)

# Do not: suspend between assert and use
assert(connection.is_alive())
await some_other_work()          # VIOLATION: connection may have died
connection.send(data)
```

### CIS-08 — Guard against buffer underflow (buffer bleeds).

All buffers MUST be fully utilized or the unused portion MUST be explicitly zeroed. Buffers MUST NOT
be sent or persisted with uninitialized or stale padding bytes.

Rationale: Buffer underflow (the opposite of overflow) can leak sensitive information and violate
deterministic guarantees. This is the class of bug that caused Heartbleed.

```text
# Do: zero unused space
buffer = allocate(BUFFER_SIZE)
write(data, buffer)
zero(buffer[len(data)..BUFFER_SIZE])   # zero the rest

# Do not: send buffer with stale padding
buffer = allocate(BUFFER_SIZE)
write(data, buffer)
send(buffer)                           # VIOLATION: padding may contain secrets
```

### CIS-09 — Group allocation with deallocation using blank lines.

Resource allocation and its corresponding deallocation (defer/finally/cleanup) MUST be visually
grouped using blank lines: a blank line before the allocation and after the corresponding
defer/cleanup.

Rationale: Visual grouping makes resource leaks easy to spot during code review. If allocation and
deallocation are not adjacent, the eye cannot verify correctness at a glance.

```text
# Do: visual grouping
<blank line>
fd = open(path)
defer close(fd)
<blank line>

# Do not: interleaved with unrelated code
fd = open(path)
config = load_config()           # VIOLATION: unrelated code between alloc and defer
defer close(fd)
```

---

## Off-by-One & Arithmetic (OBO)

### OBO-01 — Treat index, count, and size as distinct types.

Indexes, counts, and sizes MUST be treated as conceptually distinct types even when they share the
same underlying integer type. Conversions between them MUST be explicit:
- index → count: add 1 (indexes are 0-based, counts are 1-based).
- count → size: multiply by unit size.

Rationale: The casual interchange of index, count, and size is the primary source of off-by-one
errors. Explicit conversion makes the intent clear and the math verifiable.

```text
# Do: explicit conversion
last_index = 9
count = last_index + 1           # 10 items (index -> count)
size_bytes = count * ITEM_SIZE   # count -> size

# Do not: implicit interchange
buffer = allocate(last_index)    # VIOLATION: is this count or index?
```

### OBO-02 — Use explicit division semantics.

All integer division MUST use an explicitly-named operation that communicates the rounding behavior:
exact division (asserts no remainder), floor division, or ceiling division.

Rationale: The default `/` operator's rounding behavior varies by language and surprises
programmers. Explicit division shows the reader that rounding has been considered.

```text
# Do: explicit semantics
pages = div_ceil(total_bytes, PAGE_SIZE)     # round up
aligned = div_floor(offset, ALIGNMENT)       # round down
slots = div_exact(buffer_size, SLOT_SIZE)    # assert no remainder

# Do not: implicit division
pages = total_bytes / PAGE_SIZE              # VIOLATION: truncation toward zero? floor?
```

---

## Formatting & Code Style (FMT)

### FMT-01 — Run the language formatter.

All code MUST be formatted by the project's standard formatter. No manual formatting overrides are
permitted in code that the formatter handles.

Rationale: Automated formatting eliminates style debates in code review and ensures consistency
across the codebase.

```text
# Examples per language:
# Zig:    zig fmt
# Go:     gofmt
# Rust:   rustfmt
# Python: black / ruff format
# TS/JS:  prettier / biome
```

### FMT-02 — Use 4-space indentation (or the project's declared standard).

Indentation MUST be 4 spaces unless the project explicitly declares a different standard. Tabs
MUST NOT be used unless the language mandates them (e.g., Go).

Rationale: 4 spaces is more visually distinct than 2 spaces at a distance, making nesting depth
immediately apparent.

```text
# Do: 4 spaces
if condition:
    if nested:
        do_work()

# Do not: 2 spaces (unless project standard)
if condition:
  if nested:
    do_work()
```

### FMT-03 — Hard limit all lines to 100 columns.

No line SHALL exceed 100 columns. No exceptions. Nothing should be hidden by a horizontal scrollbar.

Rationale: 100 columns allows two files side-by-side on a standard monitor. The limit is physical:
it ensures code is always fully visible during review and diffing.

```text
# If a line exceeds 100 columns, break it:
# - Add a trailing comma to trigger formatter wrapping.
# - Break at logical boundaries (after operators, before arguments).
```

### FMT-04 — Always use braces on if statements (unless single-line).

If statements MUST have braces unless the entire statement (condition + body) fits on a single line.

Rationale: Braceless multi-line if statements are the root cause of Apple's "goto fail" vulnerability
and similar bugs. Braces provide defense in depth.

```text
# Do: single-line, no braces needed
if (done) return

# Do: multi-line, braces required
if (done) {
    cleanup()
    return
}

# Do not: multi-line without braces
if (done)
    cleanup()
    return              # VIOLATION: not guarded by the if
```

---

## Dependencies & Tooling (DEP)

### DEP-01 — Minimize dependencies.

The number of external dependencies MUST be minimized. Every dependency MUST be justified by a
clear, documented need that cannot be reasonably met by the standard library or existing code.

Rationale: Dependencies introduce supply chain risk, safety risk, performance risk, and
installation complexity. For infrastructure code, these costs are amplified throughout the stack.

```text
# Before adding a dependency, answer:
# 1. Can the standard library do this?
# 2. Can we write this in <100 lines?
# 3. Is the dependency actively maintained?
# 4. What is the transitive dependency count?
# 5. What is the security track record?
```

### DEP-02 — Prefer existing tools over adding new ones.

New tools MUST NOT be introduced when an existing tool in the project's toolchain can accomplish
the task. The cost of a new tool includes learning, maintenance, CI configuration, and
cross-platform support.

Rationale: A small, standardized toolbox is simpler to operate than an array of specialized
instruments each with a dedicated manual.

```text
# Before adding a new tool, answer:
# 1. Can an existing tool do this (perhaps with a flag or plugin)?
# 2. Is the marginal benefit worth the maintenance cost?
# 3. Will every team member need to learn this tool?
```

### DEP-03 — Prefer typed, portable tooling for scripts.

Scripts and automation MUST prefer typed, portable languages over shell scripts. Shell scripts are
acceptable only for trivial glue (< 20 lines) with no logic.

Rationale: Shell scripts are not portable (Bash/Zsh/POSIX differences), not type-safe, and fail
silently in ways that are difficult to debug. Typed scripts are cross-platform and catch errors at
compile time.

```text
# Do: typed script
scripts/deploy.ts     # or .go, .rs, .py with type hints
scripts/migrate.py

# Do not: complex shell script
scripts/deploy.sh     # VIOLATION if >20 lines or contains logic
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
| SAF-14 | 70-line function limit |
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

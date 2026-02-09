# TigerStyle Rulebook — Pragmatic / Compact

## Preamble

This is the compact variant of the TigerStyle Pragmatic rulebook. Each rule is a recommendation
with a one-line rationale. For full rationale and examples, see `tigerstyle-pragmatic-full.md`.

**Design goal priority:** Safety > Performance > Developer Experience.

**Keywords:** SHOULD, PREFER, CONSIDER, AVOID — strong recommendations that acknowledge tradeoffs.

**Exception clause:** Any rule may be overridden if the exception is documented in a code comment
or commit message explaining why, and reviewed by at least one other contributor.

Rule IDs are stable across all TigerStyle variants for cross-referencing.

---

## Safety & Correctness (SAF)

**SAF-01** — All control flow SHOULD be simple and explicit. AVOID recursion.
Rationale: Ensures bounded, analyzable execution.

**SAF-02** — All loops, queues, retries, and buffers SHOULD have a fixed upper bound.
Rationale: Prevents infinite loops, tail-latency spikes, and resource exhaustion.

**SAF-03** — Integer types SHOULD be explicitly sized (u32, i64). AVOID architecture-dependent types.
Rationale: Eliminates architecture-specific behavior and overflow ambiguity.

**SAF-04** — Every function SHOULD assert its preconditions, postconditions, and invariants.
Rationale: Assertions catch programmer errors early; crashing is correct on corruption.

**SAF-05** — Assertion density SHOULD average at least 2 per function.
Rationale: High density is a force multiplier for correctness and fuzzing yield.

**SAF-06** — CONSIDER pairing assertions on at least two different code paths per enforced property.
Rationale: Bugs hide at the boundary between valid and invalid data.

**SAF-07** — PREFER split assertions: `assert(a); assert(b);` over `assert(a and b)`.
Rationale: Split assertions isolate failure causes and improve readability.

**SAF-08** — PREFER single-line implication asserts: `if (a) assert(b)`.
Rationale: Preserves logical intent without complex boolean expressions.

**SAF-09** — Compile-time constants and type sizes SHOULD be asserted at compile time (or startup).
Rationale: Catches design integrity violations before runtime.

**SAF-10** — Assertions SHOULD cover both positive space (expected) and negative space (not expected).
Rationale: Boundary-crossing bugs are the most common class of correctness errors.

**SAF-11** — Tests SHOULD exercise valid inputs, invalid inputs, and boundary transitions.
Rationale: 92% of catastrophic failures stem from incorrect handling of non-fatal errors.

**SAF-12** — PREFER static allocation at initialization. AVOID runtime reallocation.
Rationale: Avoids unpredictable latency, fragmentation, and use-after-free.

**SAF-13** — Variables SHOULD be declared at the smallest possible scope; minimize variables in scope.
Rationale: Reduces misuse probability and limits blast radius of errors.

**SAF-14** — Functions SHOULD NOT exceed approximately 70 lines.
Rationale: Forces clean decomposition; eliminates scrolling discontinuity.

**SAF-15** — Branching logic (if/switch/match) SHOULD remain in parent functions, not helpers.
Rationale: Centralizes case analysis in one place.

**SAF-16** — State mutation SHOULD be centralized in parent functions. Leaf functions SHOULD be pure.
Rationale: Localizes bugs to one mutation site; enables testable helpers.

**SAF-17** — All compiler/linter warnings SHOULD be enabled at strictest settings and resolved.
Rationale: Warnings hide latent correctness issues.

**SAF-18** — External events SHOULD be queued and batch-processed, not handled inline.
Rationale: Keeps control flow bounded and internal.

**SAF-19** — Compound boolean conditions SHOULD be split into nested if/else branches.
Rationale: Makes case coverage explicit and verifiable.

**SAF-20** — PREFER stating invariants positively. AVOID negated conditions.
Rationale: Positive form aligns with natural reasoning about bounds and validity.

**SAF-21** — Every error SHOULD be handled explicitly. AVOID silently ignoring errors.
Rationale: Error-handling bugs are the dominant cause of catastrophic production failures.

**SAF-22** — Every non-obvious decision SHOULD have a comment or commit message explaining why.
Rationale: Rationale enables safe future changes; code without "why" is incomplete.

**SAF-23** — All options SHOULD be passed explicitly to library calls. AVOID relying on defaults.
Rationale: Defaults can change across versions, introducing latent bugs.

---

## Performance & Design (PERF)

**PERF-01** — Performance SHOULD be considered during design, not deferred to profiling.
Rationale: Architecture-level wins (1000x) cannot be retrofitted.

**PERF-02** — Back-of-the-envelope calculations SHOULD be performed for network, disk, memory, and CPU.
Rationale: Rough math guides design into the right 90% of solution space.

**PERF-03** — Optimization SHOULD target the slowest resource first, weighted by access frequency.
Rationale: Bottleneck-focused optimization yields the largest gains.

**PERF-04** — Control plane (scheduling, metadata) SHOULD be separated from data plane (bulk processing).
Rationale: Enables batching without sacrificing assertion safety.

**PERF-05** — Network, disk, memory, and CPU costs SHOULD be amortized via batching.
Rationale: Per-item overhead dominates at high throughput.

**PERF-06** — Hot paths SHOULD have predictable, linear control flow.
Rationale: Predictability enables prefetching, branch prediction, and cache utilization.

**PERF-07** — Performance-critical code SHOULD be explicit. AVOID depending on compiler optimizations.
Rationale: Compiler heuristics are fragile and non-portable.

**PERF-08** — Hot loop functions SHOULD take primitive arguments. AVOID passing `self`/`this`.
Rationale: Enables register allocation without alias analysis.

---

## Developer Experience & Naming (DX)

**DX-01** — Names SHOULD capture what a thing is or does with precision.
Rationale: Great names are the essence of great code.

**DX-02** — File, function, and variable names SHOULD use snake_case (adapt to language idiom where required).
Rationale: Underscores separate words clearly and encourage descriptive names.

**DX-03** — Names SHOULD NOT be abbreviated (except trivial loop counters i, j, k).
Rationale: Abbreviations are ambiguous; full names are unambiguous.

**DX-04** — Acronyms SHOULD use standard capitalization (VSR, HTTP, SQL), not title case.
Rationale: Standard form is unambiguous.

**DX-05** — Units and qualifiers SHOULD be appended to names, sorted by descending significance.
Rationale: Groups related variables visually and semantically.

**DX-06** — Resource names SHOULD convey lifecycle and ownership (e.g., arena, pool).
Rationale: Cleanup expectations should be obvious from the name.

**DX-07** — CONSIDER aligning related variable names by character length.
Rationale: Symmetry improves visual parsing and correctness checking.

**DX-08** — Helper/callback names SHOULD be prefixed with the calling function's name.
Rationale: Makes call hierarchy visible in the name.

**DX-09** — Callbacks SHOULD be the last parameter in function signatures.
Rationale: Mirrors control flow (callbacks are invoked last).

**DX-10** — Important declarations (entry points, public API) SHOULD appear first in a file.
Rationale: Files are read top-down; important context comes first.

**DX-11** — Struct/class layout SHOULD follow: fields → types → methods.
Rationale: Predictable layout enables navigation by position.

**DX-12** — AVOID overloading names with multiple domain-specific meanings.
Rationale: Overloaded terms cause confusion across contexts.

**DX-13** — Externally-referenced names SHOULD be nouns that work as prose and section headers.
Rationale: Noun names compose cleanly in documentation and conversation.

**DX-14** — Functions with confusable arguments (same type, swappable) SHOULD use named option structs.
Rationale: Prevents silent transposition bugs at the call site.

**DX-15** — Nullable parameters SHOULD be named so null's meaning is clear at the call site.
Rationale: `foo(null)` is meaningless; `foo(timeout_ms: null)` is not.

**DX-16** — Singleton constructor params SHOULD be ordered from most general to most specific.
Rationale: Consistent ordering reduces cognitive load.

**DX-17** — Commit messages SHOULD be descriptive and explain the purpose of the change.
Rationale: Commit history is permanent documentation visible in `git blame`.

**DX-18** — Comments SHOULD explain "why," not "what."
Rationale: "Why" enables safe future changes; "what" restates the code.

**DX-19** — Tests and complex logic SHOULD include a description of goal and methodology.
Rationale: Tests are documentation; readers need context to understand or skip them.

**DX-20** — Comments SHOULD be well-formed sentences (space, capital, full stop).
Rationale: Sloppy comments signal sloppy thinking.

---

## Cache Invalidation & State Hygiene (CIS)

**CIS-01** — Every piece of state SHOULD have exactly one source of truth. AVOID duplication or aliasing.
Rationale: Duplicated state will desynchronize.

**CIS-02** — Function arguments larger than 16 bytes SHOULD be passed by const reference.
Rationale: Avoids implicit copies and stack waste.

**CIS-03** — Large structs SHOULD be initialized in-place via out pointers, not returned by value.
Rationale: Avoids copies and ensures pointer stability.

**CIS-04** — If any field requires in-place init, the entire struct SHOULD be initialized in-place.
Rationale: In-place init is viral; mixing strategies breaks pointer stability.

**CIS-05** — Variables SHOULD be declared and computed as close as possible to their point of use.
Rationale: Minimizes check-to-use gaps (POCPOU/TOCTOU risk).

**CIS-06** — PREFER simpler return types: void > bool > int > optional > result.
Rationale: Each dimension in the return type creates viral call-site branching.

**CIS-07** — Functions with precondition assertions SHOULD run to completion without suspending.
Rationale: Suspension can invalidate preconditions, making assertions misleading.

**CIS-08** — Unused buffer space SHOULD be explicitly zeroed before use or transmission.
Rationale: Buffer underflow leaks sensitive data (Heartbleed class).

**CIS-09** — Allocation and deallocation SHOULD be visually grouped with surrounding blank lines.
Rationale: Makes resource leaks easy to spot during code review.

---

## Off-by-One & Arithmetic (OBO)

**OBO-01** — Index, count, and size SHOULD be treated as distinct types with explicit conversions.
Rationale: Casual interchange is the primary source of off-by-one errors.

**OBO-02** — All integer division SHOULD use explicit semantics: exact, floor, or ceiling.
Rationale: Default `/` rounding varies by language; explicit shows intent.

---

## Formatting & Code Style (FMT)

**FMT-01** — All code SHOULD be formatted by the project's standard formatter.
Rationale: Eliminates style debates and ensures consistency.

**FMT-02** — Indentation SHOULD be 4 spaces (or the project's declared standard).
Rationale: 4 spaces is visually distinct at a distance.

**FMT-03** — Lines SHOULD NOT exceed 100 columns.
Rationale: Ensures side-by-side review with no horizontal scroll.

**FMT-04** — If statements SHOULD have braces unless the entire statement fits on a single line.
Rationale: Prevents "goto fail" class bugs.

---

## Dependencies & Tooling (DEP)

**DEP-01** — External dependencies SHOULD be minimized and justified.
Rationale: Supply chain risk, safety risk, performance risk, installation complexity.

**DEP-02** — New tools SHOULD NOT be introduced when an existing tool suffices.
Rationale: Tool sprawl increases complexity and maintenance burden.

**DEP-03** — Scripts SHOULD prefer typed, portable languages over shell scripts.
Rationale: Shell scripts are not portable, not type-safe, and fail silently.

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

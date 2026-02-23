# Repo-Local AGENTS Overlay

<!-- BEGIN MANAGED OVERLAY -->
Do not edit this managed block directly. Use `opencode-sync-repo --write` to update it from the
shared template.

Overlay-Template-Version: 0.1.1
Overlay-Template-Hash: 646ce926fbe1275e002ef90674b2bbb53b801cae33409ba975c1700dcdbdd519
Guide-Bundle-Version: 0.3.1
Guide-Bundle-Source-Ref: v0.3.1

This file is a repo-local overlay for project-specific instructions.
It supplements the shared guide bundle and should only contain context that is specific to this
repository.

Do not include secrets, credentials, or tokens.

## Guide Layering Contract

This overlay extends and complements (does not replace) the shared guide policy loaded from
`files/AGENTS.md`.

The shared policy is the primary behavioral instruction source. This overlay adds repository-specific
constraints, context, workflows, and optional active-guide additions.

Agents MUST apply both layers together:

1. Follow shared policy as baseline behavior.
2. Apply repo-specific constraints from this overlay in addition to shared policy.

When guidance appears to conflict, preserve shared mandatory requirements and treat overlay guidance
as project-specific augmentation that narrows or clarifies behavior for this repository.

## Mandatory Guide Compliance Loop

For non-trivial tasks, the agent MUST:

1. Identify which active guides apply before implementation.
2. Apply active guide rules during implementation and self-review.
3. In the final response, include a rule-application trace with concrete references:
   - Rule ID (or section heading if no stable ID),
   - where applied (`path:line`),
   - one short note on how it shaped the change.
4. Explicitly verify negative/error/boundary paths, not only happy paths.
5. If a rule is intentionally not applied, state why and mark it as a project-level exception.
6. If active guides do not cover the task domain, suggest 1-2 minimal guide additions from
   `VARIANTS.md`.

When guidance conflicts, follow canonical precedence from the guide system.

## Response Prefix Contract

For implementation tasks, start the final response with:

`Guide check: active guides applied.`
<!-- END MANAGED OVERLAY -->

## Optional Active-Guide Additions

Add project-specific guides here when needed (for example, language or framework guides from
`VARIANTS.md`). Keep defaults high-signal and only add guides required by this repo.

Example:

- `go/tigerstyle-go-strict-full.md`
- `nextjs/nextjs-strict-full.md`

<!-- BEGIN LOCAL GUIDE ADDITIONS -->
<!-- END LOCAL GUIDE ADDITIONS -->

## Repo-Specific Context

Use concise, factual notes for architecture, workflows, constraints, and release expectations.

When durable repo facts are learned during work, update this section to keep it current.
Only include stable information that helps future tasks.

<!-- BEGIN REPO CONTEXT -->
<!-- END REPO CONTEXT -->

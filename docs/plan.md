# Plan

_Updated by the Tech Lead chat before each task._

## Status

**Active task:** Phase 2 / Task 10 — **Decrypt-failure UX + mismatch composer lock**.

Task 9 landed the crypto core but left the failure mode invisible: when phrases mismatch, the peer currently sees a base64 blob (`<<...>>`) on a normal chat bubble, with no signal that anything is wrong, and nothing stops them from continuing to type. Task 10 closes that gap.

The locked Phase 2 constraint (sessions.md, "Phrase model — exact match, no retry") is binding here:

> Phrase match is **100% exact, case-sensitive**. On mismatch: **no retry**. User must leave the room and reconnect from scratch. Mismatch is **visible to both sides**.

Task 10 makes that visibility real on both sides and physically prevents retry.

## Context

### What Task 9 left in place

In [lib/network/chat_client.dart](../lib/network/chat_client.dart):
- `ChatMessage.decryptFailed` exists but is rendered identically to a successful message (just with `<<base64>>` as the text).
- There is no client-level "mismatch detected" state — just per-message failure flags.
- The composer is enabled as long as `_peerLeft` is false; failed decrypts do not lock it.

In [lib/screens/chat_screen.dart](../lib/screens/chat_screen.dart):
- Stale copy: the password-mode SystemMessage still ends `"(encryption arrives in task 9)"` and the open-mode banner still says `"[plaintext — encryption arrives in task 9]"`. Both ship today's behaviour incorrectly.
- The footer micro-text still hardcodes `"PLAINTEXT"` regardless of mode.

In [lib/components/message_bubble.dart](../lib/components/message_bubble.dart):
- No `decryptFailed` styling variant.

### Mismatch detection — the rule

A *single* failed decrypt is enough to declare the room mismatched. Reasons:
- Same key on both sides decrypts every message; if one fails authentically (auth-tag mismatch), the keys do not agree.
- The phrase is the only key input. If it didn't match for one message, it won't match for any.
- Bit-flip / tamper failures from a malicious server are out of scope — server is opaque relay; we treat any auth failure as phrase mismatch.

So: the **first** ciphertext decrypt failure (after `_key` is set) flips a one-way `_mismatchDetected` flag. The flag is cleared only by `close()`.

### What "no retry" means in the UI

When `mismatchDetected == true`:
- Composer text field is **disabled** (same disabled style as `_peerLeft`).
- SEND button is dimmed and inert (same as `_peerLeft`).
- Hint text becomes `"phrase mismatch — leave the room"`.
- A `SystemMessage(tone: warning)` appears at the top of the message list with the explicit instruction to leave and reconnect.
- The back arrow / tap-anywhere-to-exit behaviour mirrors `_peerLeft`: tap exits to Home and runs `chatClient.close()`.

Both sides flip into this state independently because both will encounter a failed decrypt of the other's first message. No server signalling needed.

### What we're NOT doing in Task 10

- No automatic "leave room" — the user has to tap. (Visible state > silent recovery.)
- No "try again" affordance. The constraint is locked: leave and reconnect from scratch.
- No change to wire format or server.
- No persistence. No memory-wipe audit (that's a separate Phase 2 task).
- No styling work on successful bubbles or non-failure system messages.

## Read First

- [CLAUDE.md](../CLAUDE.md)
- [docs/result.md](result.md) — Task 9 closeout
- [docs/sessions.md](sessions.md) — especially "Phase 2 — Confirmed Constraints (locked 2026-05-05)"
- [docs/changelog.md](changelog.md)
- [lib/network/chat_client.dart](../lib/network/chat_client.dart) — `_decryptAndEmit`, `_drainPending`, `close`
- [lib/screens/chat_screen.dart](../lib/screens/chat_screen.dart) — composer, hint, system message, footer micro-text
- [lib/components/message_bubble.dart](../lib/components/message_bubble.dart) — extend with failed style
- [lib/components/system_message.dart](../lib/components/system_message.dart) — `SystemMessageTone` already supports warning
- [lib/tokens/tokens.dart](../lib/tokens/tokens.dart) — palette slots for muted/error tone (no new tokens unless strictly needed)
- [test/network/chat_client_test.dart](../test/network/chat_client_test.dart) — extend with mismatch tests

## Current Task

### Part A — Branching

1. Switch to `main`. Merge `task/e2e-encryption` into `main` (no fast-forward).
2. Delete the local `task/e2e-encryption` branch.
3. Branch off `main` as `task/decrypt-failure-ux`.

### Part B — `ChatClient`: `mismatchDetected` state

In [lib/network/chat_client.dart](../lib/network/chat_client.dart):

1. Add private field `bool _mismatchDetected = false;` and public getter `bool get mismatchDetected => _mismatchDetected;`.
2. In `_decryptAndEmit` and in `_drainPending`, when `decryptMessage` returns `null`:
   - Set `_mismatchDetected = true` (idempotent).
   - Still append the `ChatMessage(decryptFailed: true, …)` so the message list reflects what was received.
   - **Stop including the raw base64 in `text`.** The bubble no longer shows the ciphertext. Set `text` to an empty string (or a fixed placeholder — `'unreadable'` is fine; the UI will style it). Rationale: leaking ciphertext into the UI is noise and looks like a bug. The styled bubble in Part D communicates the failure.
3. After draining pending in `sendMessage` (the `_key == null` branch), call `notifyListeners()` once after the drain completes — currently the drain mutates `_messages` but doesn't notify until the local message is appended. With mismatch detection, listeners need to react as soon as the flag flips, even if the local message hasn't been added yet. (Look at the existing flow carefully — `notifyListeners` is called after the local append; ensure listeners observe `_mismatchDetected = true` *before or together with* that notify, not after a paint frame later.)
4. In `close()`, reset `_mismatchDetected = false`.

Do NOT add any logging around mismatch detection. Do NOT include phrase/key/ciphertext in any debug output.

### Part C — `MessageBubble`: failed style

In [lib/components/message_bubble.dart](../lib/components/message_bubble.dart):

1. Add a new constructor param `bool decryptFailed = false`.
2. When `decryptFailed == true`:
   - Render the bubble with a muted background (use `palette.surface` or the existing `bubbleReceived` color desaturated — pick the palette slot that already conveys "inactive"; do not introduce new tokens).
   - Border color: `palette.textMuted` (or whatever the existing "muted border" slot is).
   - Text content: render the literal label `unreadable` in italic, color `palette.textMuted`. Ignore the `text` prop's contents — the bubble's purpose is to occupy the slot in the message list, not to show the failed payload.
   - `senderLabel` still renders normally (peer/host/nickname).
3. All other bubble layout (alignment, max-width, radii, padding) is unchanged. Same component file — do not create a new bubble component.

### Part D — `ChatScreen`: warning + composer lock + copy cleanup

In [lib/screens/chat_screen.dart](../lib/screens/chat_screen.dart):

1. Read `mismatchDetected` from `chatClient` and treat it analogously to `_peerLeft` for composer state. Effective rule: composer is interactive **only when** `!_peerLeft && !chatClient.mismatchDetected`.
2. Add a top-of-list `SystemMessage(tone: warning)` when `mismatchDetected == true`:
   ```
   // phrase mismatch
   the phrase you typed does not match the other participant's. messages cannot be decrypted. leave the room and reconnect to try again.
   ```
   Insert it **above** the existing password-mode SystemMessage (or replace it — see step 4).
3. Change the composer hint text precedence to:
   - `_peerLeft` → `'room closed'`
   - `mismatchDetected` → `'phrase mismatch — leave the room'`
   - `passwordMode && !hasKey` → `'type the phrase…'`
   - else → `'message'`
4. Clean up stale copy from Task 9:
   - Replace `'(encryption arrives in task 9)'` in the phrase-mode SystemMessage with `'messages will be unreadable without an exact case-sensitive match.'` (i.e., drop the parenthetical entirely; the sentence already exists earlier in the body).
   - Replace open-mode SystemMessage `'[plaintext — encryption arrives in task 9]'` with `'[open mode — messages are sent in plaintext]'`.
   - Replace the hardcoded `'PLAINTEXT'` micro-text in both the top-bar (line ~146) and the footer (line ~290) with a mode-aware label: `passwordMode ? 'ENCRYPTED' : 'PLAINTEXT'`. Two occurrences, same logic.
5. When `mismatchDetected`, the footer micro-text on the right (`'TAP TO TYPE'` / `'TAP ANYWHERE TO EXIT'`) becomes `'TAP ANYWHERE TO EXIT'`, mirroring `_peerLeft`. Tap-to-exit gesture also activates: `onTap: (_peerLeft || mismatchDetected) ? _goHome : null`.

### Part E — `ChatMessage` text rule

Update the `ChatMessage` instances created in `_decryptAndEmit` and `_drainPending` for the failure branch (per Part B step 2): drop `'<<$ciphertext>>'`, use empty string. The bubble will not render this anyway.

### Part F — Tests

In [test/network/chat_client_test.dart](../test/network/chat_client_test.dart), add cases under a new group `mismatchDetected`:

- Mismatch on incoming: peer A uses phrase `xerxes`, peer B uses `Xerxes`. After B's first received decrypt fails → `chatClient.mismatchDetected == true`. The corresponding `ChatMessage` has `decryptFailed: true` and `text == ''`.
- Idempotent: a second failed decrypt does not change `mismatchDetected` (still true); listeners are not double-notified for the same flag flip (assert listener call count tightly).
- Buffer + mismatch: peer sends 2 ciphertexts before B types the phrase; B types a wrong phrase; both buffered messages emit with `decryptFailed: true`, `mismatchDetected` flips true exactly once during the drain.
- Round-trip success leaves `mismatchDetected == false` (regression guard).
- `close()` resets `mismatchDetected` to false.

In [test/widget/](../test/widget/) (or wherever existing widget tests live — check the directory; if there's no widget test for ChatScreen yet, place it under `test/screens/chat_screen_test.dart`):

- When `chatClient.mismatchDetected == true`, the composer's `TextField.enabled` is false and the SEND `GestureDetector.onTap` is null/inert.
- The mismatch SystemMessage with the exact warning copy is present.
- Hint text is `'phrase mismatch — leave the room'`.
- Tapping the body area (with mismatch active) calls `Navigator.pop`-equivalent (`popUntil` to first route). If wiring a real Navigator into the test is too heavy, assert the `_goHome` path indirectly via `chatClient.close()` having been called after a tap — pick whichever is cleaner with the existing test scaffolding.

In [test/network/chat_client_test.dart](../test/network/chat_client_test.dart), update the existing mismatched-phrase test from Task 9 if it asserted `text` starting with `<<` and ending with `>>` — that contract has changed (now `text == ''`). Also assert `mismatchDetected == true` there.

Do not add server-side tests — server unchanged.

### Part G — `flutter analyze`, `flutter test`, `npm test`

All clean. New flutter test count grows from 59. Server tests stay at 39.

### Part H — Commit

One commit:

`feat: decrypt-failure ux — mismatch warning + composer lock`

### Part I — Output (in your response and at the top of `result.md`)

- Confirm `flutter analyze` clean.
- `flutter test` count vs. Task 9's 59.
- `npm test` count (expect unchanged: 39).
- `git diff --name-only main..HEAD` — expect changes in: `chat_client.dart`, `chat_screen.dart`, `message_bubble.dart`, `chat_client_test.dart`, plus a new ChatScreen widget test file.
- A note on whether you found and fixed the stale "encryption arrives in task 9" / hardcoded `PLAINTEXT` copy (Part D step 4 + 5).

### Part J — Update docs/result.md, docs/sessions.md, docs/changelog.md

Per CLAUDE.md §4–§6.

## Specs

- Branch: `task/decrypt-failure-ux` (off `main`, after merging Task 9).
- One commit at the end.
- No new dependencies.
- No protocol or server changes.
- No new components — extend existing `MessageBubble` and reuse `SystemMessage`.
- No new tokens — use existing palette slots.

## Do NOT

- Do not log mismatch state, phrase, key, or ciphertext anywhere.
- Do not show ciphertext in the UI in any form (drop the `<<...>>` rendering).
- Do not add a "try again" or "re-enter phrase" affordance — locked constraint.
- Do not auto-close the connection on mismatch — user must tap to exit.
- Do not extend the wire protocol with a mismatch signal.
- Do not change open-mode behaviour at all (other than the copy fix in Part D step 4).
- Do not push the branch.

## Commit Message

`feat: decrypt-failure ux — mismatch warning + composer lock`

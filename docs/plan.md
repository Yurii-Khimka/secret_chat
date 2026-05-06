# Plan

_Updated by the Tech Lead chat before each task._

## Status

**Active task:** Phase 3 / Task 17 — **Activation gate v1: ed25519-signed access codes**.

V1 of the invite-only access model. A single signed activation code, owner-minted offline, locally verified on first launch. No server, no chains, no expiry. The full long-term direction (delegated trust chains) is intentionally deferred — see project memory `project_invite_only_direction.md` and `project_activation_v1.md`.

## Context

### Threat model & non-goals

The activation gate defends against **someone who got the binary outside the private store listing** (sideload of an IPA, leaked APK). It does **not** defend against:

- A user who got a legitimate code from someone else (sharing is out of scope to prevent — the long-term trust-chain direction tackles this).
- An attacker who forks the repo, swaps the embedded public key, and rebuilds. They can do that. We accept it — they have to ship a forked binary that the user must install.
- Process-memory attacks. Out of scope (same threat model as Task 11).

The gate **does** prevent: an unmodified, store-shipped binary from being usable without an owner-issued code.

### Crypto

- Algorithm: **ed25519** (the existing `cryptography` package supports it via `Ed25519()`). No new dependency.
- **Private key** lives in `tools/keys/activation.private.key` — gitignored. Owner generates it locally with `tools/keygen.dart` and never commits it. Even a collaborator who builds the app cannot mint codes without this file.
- **Public key** lives as a `const List<int>` in [lib/security/activation_pubkey.dart](../lib/security/activation_pubkey.dart). Committed. The repo ships with a **placeholder** (32 zero bytes) — production builds require the owner to replace it. `verifyActivationCode` returns false unconditionally on the placeholder, so any unmodified-but-unconfigured build is locked.

### Activation code format

`<base64url(payload)>.<base64url(signature)>` — two segments separated by a single `.`. Approximately 110–130 ASCII characters total.

- Payload: JSON object `{"id":"<uuidv4>","iat":<unix-seconds>}`. Bytes are the UTF-8 encoding of the JSON string as emitted by the minter — verifier must NOT re-parse and re-serialize. Verifier decodes the base64url payload to bytes and feeds those bytes to ed25519 as the signed message.
- Signature: 64 raw ed25519 signature bytes, base64url-encoded.
- The `iat` field is debug-only (helps the owner remember when a code was minted). It is not enforced at verify time. No expiry in v1.

### Persistence

`shared_preferences` key `activation.code` stores the **full code string**, not a boolean. On launch, the controller re-verifies it. If verification fails (corrupted, tampered, or public key was rotated by an app update), the persisted entry is cleared and the activation screen is shown again.

Reason: a boolean alone could be flipped by anyone with shared_prefs access; storing the code and re-verifying it makes the persisted state unforgeable without the private key.

### What v1 does NOT include

- No "deactivate" / clear-code option in Settings.
- No code grouping / dashes in display — paste-only, raw base64url.
- No expiry, no revocation list, no denylist.
- No invite-issuing from inside the app.
- No multiple-codes / multiple-keys support.
- No remote validation, no health check, no telemetry.
- No "your code expires in N days" UX.
- No code distribution mechanism beyond the owner running `tools/mint_code.dart` and DMing the result.

## Read First

- [CLAUDE.md](../CLAUDE.md)
- [docs/result.md](result.md) — Task 16 closeout
- [docs/sessions.md](sessions.md) — Phase 3 roadmap
- [docs/changelog.md](changelog.md)
- [pubspec.yaml](../pubspec.yaml) — confirm `cryptography` is present (Task 9 added it)
- [lib/main.dart](../lib/main.dart) — controller composition pattern
- [lib/theme/theme_controller.dart](../lib/theme/theme_controller.dart) — pattern to mirror for `ActivationController` (load, persist, ChangeNotifier)
- [lib/network/crypto.dart](../lib/network/crypto.dart) — existing `cryptography` usage style
- [.gitignore](../.gitignore) — new entries needed

## Current Task

### Part A — Branching

1. Switch to `main`. Merge `task/ui-polish-pass-1` into `main` (no fast-forward).
2. Delete the local `task/ui-polish-pass-1` branch.
3. Branch off `main` as `task/activation-gate-v1`.

### Part B — `.gitignore`

Add to [.gitignore](../.gitignore):

```
# Activation signing keys — never commit.
tools/keys/
*.private.key
```

If `tools/keys/` already exists from a stray local run, that's fine — the gitignore prevents future accidents.

### Part C — Owner-side CLI tools

Create `tools/keygen.dart`:

```
Usage: dart run tools/keygen.dart

Generates a fresh ed25519 keypair. Writes the private key (raw 32 bytes,
hex-encoded with a trailing newline) to tools/keys/activation.private.key.
Refuses to overwrite an existing file. Prints the public key as a Dart
array literal ready to paste into lib/security/activation_pubkey.dart.
```

Create `tools/mint_code.dart`:

```
Usage: dart run tools/mint_code.dart [--id=<custom-id>]

Reads tools/keys/activation.private.key. Generates a payload {id, iat}
(id auto-generated UUIDv4 if not provided), signs it, prints the
activation code as <base64url(payload)>.<base64url(signature)> on stdout.
Nothing else on stdout — script output is paste-ready.
```

Implementation notes:

- Both tools are pure Dart, run with `dart run`, and import `package:cryptography/cryptography.dart`. They are **never** imported by the app — Flutter analysis will not pick them up. To prevent accidental imports, place them under `tools/` (not `lib/`) and add a `// ignore_for_file: avoid_print` comment at the top.
- Use `Ed25519()` from `cryptography`. `newKeyPair()` for keygen; `sign(bytes, keyPair: ...)` for mint.
- Private key extraction: `await keyPair.extractPrivateKeyBytes()` returns the 32-byte seed (cryptography package convention). Hex-encode for storage.
- For `mint_code.dart`, generate UUIDv4 inline using `Random.secure()` — avoid pulling in a `uuid` package dependency for ten lines of code.
- Refuse-to-overwrite: `keygen.dart` exits with status 1 and a printed warning if the private key file exists. The owner can manually delete it if they really want a new keypair.

These tools have **no tests**. They are scripts the owner runs locally; correctness is verified end-to-end by the activation tests in Part F using a runtime-generated keypair.

### Part D — Embedded public key + verifier

Create [lib/security/activation_pubkey.dart](../lib/security/activation_pubkey.dart):

```dart
/// Public key for verifying activation codes.
///
/// Replace the 32-byte placeholder below with your production public key
/// before shipping a release build. Run `dart run tools/keygen.dart` to
/// generate a fresh keypair; paste the printed array into [activationPublicKey].
///
/// The placeholder (all zeros) causes [verifyActivationCode] to reject every
/// code, intentionally locking the app until configured.
const List<int> activationPublicKey = <int>[
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
];
```

Create [lib/security/activation.dart](../lib/security/activation.dart):

```dart
/// Verifies an activation code against the embedded public key.
/// Returns false on any error (malformed, wrong-length signature, bad signature,
/// placeholder pubkey). Does not throw.
Future<bool> verifyActivationCode(String code) async { ... }
```

Implementation notes:

- The `code` argument is trimmed and whitespace-stripped before parsing (paste hygiene).
- Reject if pubkey is all zeros (the placeholder). This is a fast-path: if the binary hasn't been configured, every code fails.
- Split on the first `.` only (be lenient if base64url somehow contained a `.` — it can't, but defensive parsing is cheap).
- Decode base64url with `base64Url` from `dart:convert`. Tolerate missing padding (`base64Url.normalize`).
- Signature must be exactly 64 bytes; reject otherwise.
- Use `Ed25519().verify(payloadBytes, signature: Signature(sigBytes, publicKey: SimplePublicKey(pubkeyBytes, type: KeyPairType.ed25519)))`.
- Wrap the entire body in `try/catch` returning false on any thrown exception.
- Add a `@visibleForTesting` mechanism to override the embedded public key in tests:
  ```dart
  List<int>? _testPublicKeyOverride;
  @visibleForTesting
  void setActivationPublicKeyForTesting(List<int>? bytes) {
    _testPublicKeyOverride = bytes;
  }
  // Internal: List<int> _activeKey() => _testPublicKeyOverride ?? activationPublicKey;
  ```
  Tests reset to `null` in `tearDown`.

Do NOT log the code, the payload, or the signature anywhere. No `debugPrint` calls.

### Part E — `ActivationController`

Create [lib/security/activation_controller.dart](../lib/security/activation_controller.dart):

```dart
class ActivationController extends ChangeNotifier {
  static const _prefsKey = 'activation.code';
  bool _activated = false;
  String? _error;

  bool get activated => _activated;
  String? get error => _error;

  /// Loads any persisted code and re-verifies it. Called once at app startup
  /// before runApp(). If the persisted code fails to verify (corrupted,
  /// tampered, or pubkey rotated), it is cleared.
  Future<void> load() async { ... }

  /// Verifies [code]; on success persists it and flips activated to true.
  /// On failure sets [error] = '[ERROR] code not valid' and returns false.
  Future<bool> activate(String code) async { ... }
}
```

Implementation notes:

- Mirror `ThemeController.load()` shape (already exists; check that file for the exact `SharedPreferences` pattern).
- `activate()` trims input and runs the same `verifyActivationCode`. On success: clear `_error`, set `_activated = true`, persist the cleaned code, `notifyListeners()`. On failure: set `_error`, leave `_activated` alone, `notifyListeners()`.
- `error` is cleared automatically when the user starts editing again — but that's screen-level UX, not controller logic. Don't clear it inside the controller on `activate()` until success.
- Do not include the code in any error string. The single error is `'[ERROR] code not valid'`.
- No analytics, no telemetry, no logging.

### Part F — `ActivationScreen`

Create [lib/screens/activation_screen.dart](../lib/screens/activation_screen.dart). Terminal aesthetic, matching the rest of the app.

Layout (top to bottom):

1. TermHeader-style top bar: PulseDot + `ACCESS CODE` on the left, no right-side text.
2. Hero block (mirrors HomeScreen's hero):
   - Section label `// ACTIVATION` in caption muted.
   - One-line heading `Invite required` in heading-primary, with a blinking `Caret` after it (reuse the Caret component from Task 16).
   - Body micro-text: `paste the access code you were sent. it's tied to this app, not to your identity.` (Trust framing per the locked direction memory.)
3. A multi-line `TextField` that accepts paste. Monospace, 4–6 lines tall, soft-wrap. Hint text: `paste activation code…`.
4. Below: an "ACTIVATE" button (full-width, primary). Disabled when input is empty.
5. Error text below the button when `controller.error != null`, in `palette.warning`. The error clears as soon as the user edits the field.
6. Footer micro-text: `NOTHING IS SAVED · NOTHING IS LOGGED` (matches HomeScreen's footer).

Behavior:

- On ACTIVATE: trim & whitespace-strip the input, call `controller.activate(...)`. If true, the screen does nothing — `main.dart`'s AnimatedBuilder will swap to HomeScreen. If false, error renders below.
- The TextField listener clears `controller._error` when input changes (call a public `clearError()` method on the controller — add one in Part E, single-line).
- No "back" button. There's nothing to go back to until activated.
- No "deactivate" affordance anywhere.

Reuse existing components: `AppScaffold`, `AppButton`, `Caret`, `PulseDot`, `AppTypography`. No new components.

### Part G — Wire `main.dart`

In [lib/main.dart](../lib/main.dart):

1. Add `final activationController = ActivationController();` next to the existing `themeController` and `chatClient`.
2. In `main()`: `await activationController.load();` after the theme load.
3. Pass `activationController` to `SecretChatApp`.
4. In `SecretChatApp.build`, the `AnimatedBuilder` listens to **both** controllers (use `Listenable.merge([themeController, activationController])`). Then:
   ```dart
   home: activationController.activated
       ? HomeScreen(theme: theme, controller: themeController, chatClient: widget.chatClient)
       : ActivationScreen(theme: theme, controller: activationController),
   ```
5. Lifecycle handler is unchanged — `detached` still calls `chatClient.close()`. Activation state is decoupled from chat lifecycle.

### Part H — Tests

#### Pure-verification tests
[test/security/activation_test.dart](../test/security/activation_test.dart):

- Round-trip: generate a fresh keypair at runtime, sign a payload, build the code string, override the test pubkey, assert `verifyActivationCode` returns true.
- Wrong key: sign with key A, verify with key B → false.
- Tampered payload: sign correctly, then flip a bit in the payload base64 → false.
- Tampered signature: same with signature → false.
- Malformed code (no `.`, multiple `.`, empty, whitespace-only) → false.
- Wrong signature length → false.
- Placeholder pubkey (all zeros) → false even with an otherwise-valid signature (because verification cannot succeed against a zero key).
- Whitespace tolerance: code with leading/trailing whitespace and embedded newlines verifies correctly after the controller's clean step. (Test `activate` rather than `verifyActivationCode` for this one.)

#### Controller tests
[test/security/activation_controller_test.dart](../test/security/activation_controller_test.dart):

- `load()` with empty prefs → `activated == false`.
- `load()` with valid persisted code → `activated == true`.
- `load()` with tampered persisted code → `activated == false` AND prefs cleared.
- `activate()` with valid code → returns true, `activated == true`, code persisted.
- `activate()` with invalid code → returns false, `activated == false`, `error == '[ERROR] code not valid'`, prefs unchanged.
- `clearError()` resets `error` to null without touching `activated`.

Use `SharedPreferences.setMockInitialValues({})` to drive prefs state.

#### Screen tests
[test/screens/activation_screen_test.dart](../test/screens/activation_screen_test.dart):

- ACTIVATE button is disabled with empty input.
- After typing → button enabled. After tapping with valid code (with override pubkey set) → controller.activated flips true.
- With invalid code → error text renders.
- Editing the field after an error clears the error text.

#### Existing tests
- `flutter test` count grows from 102. Confirm. No existing tests should break — `main.dart` changes don't affect the chat-flow tests because they construct screens directly with a `ChatClient`.

### Part I — Documentation

Update [docs/readme.md](readme.md):

Add a new section `## Activation (v1)` near the top, ~10 lines:

- The app requires an owner-issued activation code on first launch.
- Codes are signed with an ed25519 private key kept offline by the project owner.
- Public key is embedded in the binary. Bypass requires forking and rebuilding.
- For collaborators who build the app: `dart run tools/keygen.dart` (once) → paste the printed public key into `lib/security/activation_pubkey.dart` → `dart run tools/mint_code.dart` per code → DM codes to invitees.
- The placeholder pubkey shipped in the repo locks the app — production builds must replace it.

Do NOT include the activation flow in `readme.md`'s public-facing security table — that table is for end-users and the activation step is invisible to them after first launch.

Do NOT update `chat.md` or `claude.md` — those govern the dev workflow, unchanged.

### Part J — `flutter analyze`, `flutter test`, `npm test`

All clean. Flutter test count grows from 102. Server tests stay at 43 (no server changes).

### Part K — Commit

One commit:

`feat: activation gate v1 — ed25519-signed access codes`

Stage:
- `.gitignore`
- `tools/keygen.dart`, `tools/mint_code.dart`
- `lib/security/activation_pubkey.dart`, `lib/security/activation.dart`, `lib/security/activation_controller.dart`
- `lib/screens/activation_screen.dart`
- `lib/main.dart`
- `test/security/*.dart`, `test/screens/activation_screen_test.dart`
- `docs/readme.md`
- `docs/result.md`, `docs/sessions.md`, `docs/changelog.md`

Do **not** stage:
- Anything under `tools/keys/` (gitignored, shouldn't appear, but double-check).

### Part L — Output (in your response and at the top of `result.md`)

- Confirm `flutter analyze` clean.
- `flutter test` count vs. Task 16's 102.
- `npm test` count (expect unchanged: 43).
- `git diff --name-only main..HEAD` — expect new `tools/`, new `lib/security/`, new `lib/screens/activation_screen.dart`, modified `lib/main.dart`, `.gitignore`, plus tests + docs.
- Confirm `tools/keys/` is **not** in the diff. If it is, you accidentally staged a key — abort, remove, redo.
- Confirm the placeholder pubkey is all zeros and `verifyActivationCode` returns false against it (one of the tests asserts this — confirm it passed).
- A note on the Caret component reuse on ActivationScreen — the heading "Invite required" should have a blinking caret after it.

### Part M — Update docs/result.md, docs/sessions.md, docs/changelog.md

Per CLAUDE.md §4–§6.

In sessions.md, add a new line under Phase 3:
- [x] Activation gate v1 — ed25519-signed access codes (`task/activation-gate-v1`)

This is a Phase 3 addition that wasn't in the original roadmap; that's fine — the roadmap is a living document.

## Specs

- Branch: `task/activation-gate-v1` (off `main`, after merging Task 16).
- One commit at the end.
- No new dependencies (`cryptography` already in pubspec).
- No protocol changes (server is untouched).
- New components: zero. Reuses Caret, AppButton, AppScaffold, PulseDot.
- New screen: `ActivationScreen`.
- Two new top-level directories: `lib/security/`, `tools/`.

## Do NOT

- Do not commit any private key, hex-encoded or otherwise.
- Do not log activation codes, payloads, signatures, or public keys (the public key is in source, but don't echo it in `debugPrint`).
- Do not add a "deactivate" / "reset activation" option in Settings.
- Do not add expiry handling or denylist logic in v1.
- Do not add a "request a code" or "contact owner" link — that's a feature for a later task if at all.
- Do not import `tools/` from `lib/` (it would defeat the purpose; tools must be owner-side only).
- Do not introduce a `uuid` package dependency for one UUIDv4 — generate inline with `Random.secure()`.
- Do not change the `cryptography` dependency version.
- Do not push the branch.

## Commit Message

`feat: activation gate v1 — ed25519-signed access codes`

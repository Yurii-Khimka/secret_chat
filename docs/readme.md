# [App Name TBD]

A secure, anonymous mobile chat app for iOS and Android. Built with Flutter. The app has one goal — let two people chat privately, with no trace left behind.

## Core Rules

- No user accounts
- No nicknames
- No chat history
- No IP address logging
- No data stored on the server
- Even the developers cannot read messages

## How It Works

1. User A opens the app and creates a room code — e.g. `WOLF-7342`
2. User A shares the code with User B outside the app — via SMS, WhatsApp, anywhere
3. Both users optionally enter the same password before connecting
4. The password is case sensitive
5. The password never leaves the device — it is converted into an encryption key locally using Argon2
6. Messages are encrypted with AES-256 on the device before sending
7. The server passes the encrypted message — it cannot read it
8. When the app is closed — everything is deleted

## Security

| Data             | Server sees it? |
|------------------|-----------------|
| Name/identity    | No              |
| IP address       | No              |
| Password         | No              |
| Message content  | No              |
| Chat history     | No              |
| Room code        | Yes — to connect users only |
| Encrypted msg    | Yes — unreadable without key |

## Tech Stack

| Part               | Technology       |
|--------------------|------------------|
| Mobile app         | Flutter          |
| Server             | Node.js          |
| Real-time          | WebSockets + TLS |
| Password hashing   | Argon2           |
| Message encryption | AES-256          |
| Session identity   | Random UUID      |

## UI Design Direction

- Terminal-inspired aesthetic
- Dark background — near black
- Green accent colour
- Monospace font — JetBrains Mono or Courier New
- Fully minimalistic — no icons, no illustrations, no gradients
- Follows iOS and Android guidelines — safe areas, 44px touch targets

## Three Main Screens

1. **Home** — two buttons: "Create Room" and "Join Room"
2. **Join Room** — room code input, optional password field, "Connect" button
3. **Chat** — message list, text input at bottom, no usernames, messages aligned left/right by sender and receiver

## Development Phases

### Phase 1 — Foundation
Flutter app skeleton, Node.js server, WebSocket connection, basic room creation and joining

### Phase 2 — Security
Argon2 password hashing, AES-256 encryption, no server logs, session cleanup on exit

### Phase 3 — Polish
Clean terminal UI, connection error handling, smooth session management

## Workflow

| Role       | Tool            | Responsibility                              |
|------------|-----------------|---------------------------------------------|
| Owner      | —               | Makes decisions, reviews results             |
| Tech Lead  | Claude.ai chat  | Plans tasks, writes prompts                  |
| Developer  | Claude Code     | Executes tasks, commits, updates docs        |

## Project Files

| File          | Purpose                              |
|---------------|--------------------------------------|
| claude.md     | Instructions for Claude Code         |
| chat.md       | Instructions for the Tech Lead chat  |
| readme.md     | Project overview                     |
| plan.md       | Current task — updated before each task |
| result.md     | Result of the last completed task    |
| changelog.md  | Full history of completed tasks      |
| sessions.md   | Session state log                    |

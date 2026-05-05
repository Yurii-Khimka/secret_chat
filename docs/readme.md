# [App Name TBD]

A secure, anonymous mobile chat app built with Flutter.

## What It Does

- No user accounts or nicknames
- No chat history — messages exist only during the session
- No data stored on the server
- End-to-end encrypted — even developers cannot read messages

## How It Works

1. User A creates a room code — e.g. `WOLF-7342`
2. User A shares the code with User B outside the app
3. Both users optionally enter the same password (case sensitive)
4. The password never leaves the device — converted to an encryption key locally
5. Messages are encrypted on device before sending
6. Everything is deleted when the app is closed

## Tech Stack

| Part             | Technology     |
|------------------|----------------|
| Mobile app       | Flutter        |
| Server           | Node.js        |
| Real-time        | WebSockets     |
| Encryption       | Argon2+AES-256 |
| Session          | Random UUID    |

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

## Project Structure

| File          | Purpose                              |
|---------------|--------------------------------------|
| claude.md     | Instructions for Claude Code         |
| chat.md       | Instructions for the Tech Lead chat  |
| plan.md       | Current task prompt                  |
| result.md     | Result of the last completed task    |
| changelog.md  | History of all completed tasks       |
| sessions.md   | Current session state                |

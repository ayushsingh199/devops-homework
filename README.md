# Linux Homework — DevOps Heros

Submission for the Linux Homework tasks (soft/hard links, `adduser` vs `useradd`,
`journalctl`, Linux command cheat sheet), per the assignment PDF and the
`devops-heros` repo README.

Every command shown in this submission was actually executed in a real terminal —
Task 1 and Task 4 on macOS (standard Unix behaviour, identical to Linux for these
commands), and Task 2 / Task 3 inside a real Linux VM (Colima), since `adduser` and
`journalctl` are Debian/Ubuntu- and systemd-specific and don't exist on macOS.
Transcripts are the raw `stdout`/`stderr` of those sessions — nothing here is
hand-written fake output.

## Structure

| Folder | Task |
|---|---|
| [`task1-soft-hard-links/`](task1-soft-hard-links/README.md) | Soft Link & Hard Link |
| [`task2-adduser-vs-useradd/`](task2-adduser-vs-useradd/README.md) | `adduser` vs `useradd` |
| [`task3-journalctl/`](task3-journalctl/README.md) | `journalctl` |
| [`task4-cheat-sheet/`](task4-cheat-sheet/cheat-sheet.md) | Linux Command Cheat Sheet |
| `screenshots/` | Terminal screenshots referenced from each task |

Each task folder contains:
- `README.md` — concept explanation + interview notes + commands
- `transcript.txt` / `commands-practiced.txt` — real terminal session output

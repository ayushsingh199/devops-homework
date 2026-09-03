# Task 3 — `journalctl`

## What it is

`journalctl` is the query tool for the **systemd journal** (`journald`) — the
centralized, binary-format logging system used by all modern systemd-based Linux
distros (Ubuntu, Debian, RHEL/CentOS 7+, Fedora, ...). It replaces (or augments)
classic plain-text logs under `/var/log/` (like `syslog`/`messages`) with a single,
indexed, structured log store that captures kernel messages, systemd unit
(service) logs, and application stdout/stderr for services managed by systemd.

Compared to grepping through flat text files, `journalctl` lets you filter by time
range, by unit/service, by priority (error, warning, ...), by boot, and it stores
structured metadata (PID, unit name, timestamp) with each entry.

## Key commands

```bash
journalctl                       # show the entire journal, oldest first
journalctl -e                    # jump to the end (most recent entries)
journalctl -f                    # "follow" mode — like tail -f, live stream

journalctl -u ssh                # logs for a specific systemd unit/service
journalctl -u nginx --since today

journalctl -b                    # logs only from the current boot
journalctl -b -1                 # logs from the previous boot

journalctl --since "1 hour ago"  # time-window filtering
journalctl --since "2026-09-01" --until "2026-09-02"

journalctl -p err                # only priority >= error
journalctl -p warning..err       # priority range

journalctl -k                    # kernel messages only (like dmesg)
journalctl --disk-usage          # how much disk the journal is using
journalctl --vacuum-time=2weeks  # trim old logs
```

## Practice: checking logs for a specific service

Real commands run (see [`transcript.txt`](transcript.txt)):

```bash
journalctl -u ssh --no-pager | tail -20      # last 20 log lines for the ssh service
journalctl -u cron --since "10 min ago"      # recent cron activity
journalctl -p err -b --no-pager              # any errors since last boot
```

## Note on environment

`journalctl`/`journald` requires **systemd running as PID 1** — it does not exist on
macOS, and it does not work in a *plain* Docker container either (those don't run an
init system by default). For this task the commands above were run inside a real
systemd-enabled Linux VM (via Colima) so the log output is genuine, not fabricated.

**Interview note:** if asked "what's the difference between `journalctl` and
`/var/log/syslog`?" — `journalctl` reads systemd's structured binary journal
(`/var/run/log/journal` or `/var/log/journal` if persistent storage is enabled), while
`/var/log/syslog` is the older flat-text log written by the classic syslog daemon.
On modern distros syslog is often just a *forwarder* fed by journald.

Screenshot: [`../screenshots/task3-journalctl.png`](../screenshots/task3-journalctl.png)

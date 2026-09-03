# Networking Fundamentals

## Task 1 — Practice the commands/repo shared in `devops-heros`

The `devops-heros` repo's `session4-networking/resources.md` links to
[`Nency-Ravaliya/Network-Troubleshooting`](https://github.com/Nency-Ravaliya/Network-Troubleshooting),
a guide for diagnosing connectivity to `google.com` using 10 commands. Each one was
actually run against `google.com` from this machine — full output in
[`task1-commands-transcript.txt`](task1-commands-transcript.txt).

| Command | What it does | What the real output showed |
|---|---|---|
| `ping -c 4 google.com` | Sends ICMP echo requests to check reachability + latency | 0% packet loss, ~15–42 ms round-trip |
| `traceroute` | Shows every router hop (TTL expiry trick) between here and the destination, to localize slow/dead hops | 12 hops through the local gateway → ISP (Tata) → Chennai POP → Google's network (`1e100.net`) |
| `netstat -an \| grep ESTABLISHED` | Lists active TCP connections and their state | Real established HTTPS (443) connections from this machine to GitHub, Fastly, Cloudflare, etc. |
| `telnet google.com 443` | Opens a raw TCP connection to a specific port — proves the port is open/reachable, independent of the application protocol | `Connected to google.com` then the remote closed the connection (expected — we sent no TLS handshake) |
| `tcpdump` | Captures and inspects raw packets on the wire | **Not run** — `tcpdump` needs root (`sudo`), and this environment can't supply an interactive sudo password non-interactively. See note below. |
| `nslookup google.com` | Queries DNS and shows the resolver used + resolved IP | Resolved via the local router (`192.168.1.1`) to `142.250.77.142` |
| `dig google.com` | Lower-level, more detailed DNS query tool (shows query time, TTL, authoritative servers) | Same IP, 12s TTL, 30ms query time |
| `curl -I https://google.com` | Sends an HTTP HEAD request, shows just the response headers/status | `HTTP/2 301` redirect to `www.google.com`, server `gws` |
| `arp -an` | Shows the local ARP table — IP → MAC address mappings on the LAN | 1,373 entries (a large shared/corporate network) — first 15 shown |
| `systemctl` | Manages/queries systemd services (Linux-only — doesn't exist on macOS) | Run inside a real Linux VM — see below |

**Why `tcpdump` was skipped:** it requires raw socket access, gated behind
`sudo`. This session cannot type a password into an interactive prompt (by design —
credential entry is off-limits for an automated agent). Running it would have either
hung waiting for input or needed the password typed in chat, which isn't safe to do.
`sudo -n tcpdump ...` was tried first and confirmed this: `sudo: a password is
required`.

**`systemctl`:** see [`task1-systemctl-transcript.txt`](task1-systemctl-transcript.txt)
for a real run against a Linux (systemd) VM, since `systemctl` has no macOS
equivalent.

## Task 2 — Markdown file with commands, output, and explanations

This file *is* Task 2: real command output above with an explanation of what each
command showed.

Screenshots:
[`../screenshots/03-networking.png`](../screenshots/03-networking.png),
[`../screenshots/03-networking-systemctl.png`](../screenshots/03-networking-systemctl.png)

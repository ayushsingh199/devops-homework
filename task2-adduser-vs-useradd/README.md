# Task 2 — `adduser` vs `useradd`

## Concept

| | `useradd` | `adduser` |
|---|---|---|
| Type | Low-level C binary, part of `shadow-utils` | Higher-level, interactive **Perl script** that wraps `useradd`, `usermod`, `passwd`, etc. |
| Available on | Every Linux distro (RHEL/CentOS, Debian/Ubuntu, ...) | Mainly Debian/Ubuntu (a `useradd`-alike also exists on RHEL but behaves differently) |
| Home directory | **Not created by default** — needs `-m` flag | Created **automatically**, populated from `/etc/skel` |
| Password | Not set — account is locked until `passwd` is run | **Prompted interactively** during creation |
| Default shell | Whatever `/etc/default/useradd` says (often `/bin/sh` or none) | Set sensibly, prompts to confirm |
| Prompts for extra info (full name, room #, phone) | No | Yes (the classic GECOS field prompts) |
| Feedback / confirmation | Silent on success | Interactive, asks "Is the information correct?" |
| Scriptable / non-interactive | Yes — this is its main use case | Harder — designed to be interactive (though `--disabled-password --gecos ""` can be used non-interactively) |

## Which is preferred on Ubuntu/Debian, and why

**`adduser` is preferred for interactive/manual use on Ubuntu/Debian.** It's the
friendlier, safer front-end: it creates the home directory, copies skeleton dotfiles,
sets a sane shell, and prompts for a password — all the things a human actually wants
when creating an account, without having to remember extra flags.

`useradd` is preferred **inside scripts/automation** (Ansible, shell scripts, Dockerfiles,
Terraform provisioners) precisely *because* it is low-level, predictable, and
non-interactive — you pass every option explicitly (`-m` for home dir, `-s` for shell,
`-G` for groups) and it does exactly that and nothing more.

**Interview one-liner:** *"`useradd` is the low-level primitive, `adduser` is a
Debian/Ubuntu-only interactive wrapper around it that does the sensible defaults for
you — I use `adduser` by hand and `useradd` in scripts."*

## Commands

```bash
sudo useradd testuser1                 # low-level, no home dir/password set
sudo useradd -m -s /bin/bash testuser1 # explicit: create home dir + shell

sudo adduser testuser2                 # interactive: creates home dir, prompts for password/info
```

## Practice (real terminal session)

Run on a Linux environment (macOS doesn't ship `adduser`/GNU `useradd`), see
[`transcript.txt`](transcript.txt) for the real output — a fresh Ubuntu container
where a test user was created with `adduser`, its home directory verified in
`/etc/passwd` and `/home`, and compared against a plain `useradd` invocation.

Screenshot: [`../screenshots/task2-adduser-vs-useradd.png`](../screenshots/task2-adduser-vs-useradd.png)

# Task 4 — Linux Command Cheat Sheet

Practiced and reviewed the following commands. Each was actually run in a
terminal (see `commands-practiced.txt` in this folder for the real session
transcript) so the purpose/behavior notes below are backed by real output,
not just documentation.

## File & Directory Navigation

| Command | Purpose | Example |
|---|---|---|
| `pwd` | Print current working directory | `pwd` |
| `ls -la` | List all files (incl. hidden) with details | `ls -la /etc` |
| `cd` | Change directory | `cd /var/log` |
| `mkdir -p` | Create directory (and parents if needed) | `mkdir -p a/b/c` |
| `rmdir` | Remove an *empty* directory | `rmdir old_dir` |
| `find` | Search for files by name/type/time/etc. | `find / -name "*.log" -mtime -1` |
| `tree` | Show directory structure as a tree | `tree -L 2` |

## File Operations

| Command | Purpose | Example |
|---|---|---|
| `touch` | Create empty file / update timestamp | `touch app.log` |
| `cp -r` | Copy files/directories | `cp -r src/ backup/` |
| `mv` | Move or rename | `mv old.txt new.txt` |
| `rm -rf` | Remove files/directories forcefully & recursively | `rm -rf build/` |
| `cat` | Print file contents | `cat app.log` |
| `less` / `more` | Page through a file | `less app.log` |
| `head` / `tail` | Show first/last N lines | `tail -f app.log` |
| `tail -f` | Follow a file live (e.g. logs) | `tail -f /var/log/syslog` |
| `grep` | Search text with pattern matching | `grep -ri "error" app.log` |
| `sed` | Stream-edit text (find/replace) | `sed -i 's/foo/bar/g' file.txt` |
| `awk` | Pattern scanning & column processing | `awk '{print $1}' access.log` |
| `diff` | Compare two files | `diff file1 file2` |

## Permissions & Ownership

| Command | Purpose | Example |
|---|---|---|
| `chmod` | Change file permissions | `chmod 755 script.sh` |
| `chown` | Change file owner/group | `chown user:group file.txt` |
| `umask` | Show/set default permission mask | `umask 022` |

## Users & Processes

| Command | Purpose | Example |
|---|---|---|
| `whoami` | Show current user | `whoami` |
| `adduser` / `useradd` | Create a user (see Task 2) | `sudo adduser deploy` |
| `passwd` | Set/change a user's password | `sudo passwd deploy` |
| `su` / `sudo` | Switch user / run as root | `sudo systemctl restart nginx` |
| `ps aux` | List running processes | `ps aux \| grep nginx` |
| `top` / `htop` | Live process/resource monitor | `top` |
| `kill` / `kill -9` | Terminate a process by PID | `kill -9 1234` |
| `jobs`, `fg`, `bg` | Manage shell jobs | `bg %1` |

## Disk & System Info

| Command | Purpose | Example |
|---|---|---|
| `df -h` | Show disk space usage (human-readable) | `df -h` |
| `du -sh` | Show size of a directory | `du -sh /var/log` |
| `free -h` | Show memory usage | `free -h` |
| `uname -a` | Show kernel/system info | `uname -a` |
| `uptime` | Show how long system has been running | `uptime` |
| `lsblk` | List block devices/partitions | `lsblk` |

## Archives & Transfer

| Command | Purpose | Example |
|---|---|---|
| `tar -czvf` | Create a gzipped tarball | `tar -czvf backup.tar.gz app/` |
| `tar -xzvf` | Extract a gzipped tarball | `tar -xzvf backup.tar.gz` |
| `scp` | Copy files over SSH | `scp file.txt user@host:/path` |
| `rsync -avz` | Efficient file sync (local/remote) | `rsync -avz src/ user@host:dst/` |
| `curl` / `wget` | Fetch data over HTTP(S) | `curl -I https://example.com` |
| `ssh` | Remote shell access | `ssh user@host` |

## Networking

| Command | Purpose | Example |
|---|---|---|
| `ping` | Test connectivity to a host | `ping -c 4 8.8.8.8` |
| `ss -tulpn` / `netstat -tulpn` | Show listening ports/sockets | `ss -tulpn` |
| `ip a` / `ifconfig` | Show network interfaces | `ip a` |
| `curl -I` | Check HTTP headers/status | `curl -I https://example.com` |

## Services & Logs (systemd)

| Command | Purpose | Example |
|---|---|---|
| `systemctl status` | Show status of a service | `systemctl status nginx` |
| `systemctl start/stop/restart` | Control a service | `sudo systemctl restart nginx` |
| `systemctl enable` | Start a service on boot | `sudo systemctl enable nginx` |
| `journalctl` | Query the systemd journal (see Task 3) | `journalctl -u nginx -f` |

## Misc / Interview-relevant

| Command | Purpose | Example |
|---|---|---|
| `man <cmd>` | Manual page for a command | `man chmod` |
| `history` | Show command history | `history \| tail -20` |
| `alias` | Create a shortcut for a command | `alias ll='ls -la'` |
| `env` | Show environment variables | `env \| grep PATH` |
| `export` | Set an environment variable | `export PATH=$PATH:/opt/bin` |
| `which` / `type` | Locate a command's binary | `which python3` |
| `xargs` | Build/execute commands from stdin | `find . -name "*.tmp" \| xargs rm` |

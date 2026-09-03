# Shell Scripting — System Information Script

## Task

Write a shell script that prints system info (date, hostname, username, disk
usage, running processes), uses variables, takes interactive input via
`read -p`, creates a directory (`mkdir`) and a file (`touch`), and saves the
running-process list to that file using `>` output redirection.

## Script

See [`system_info.sh`](system_info.sh).

Commands used: `mkdir`, `touch`, `echo`, `df`, `ps`, `read -p`, shell
variables, `>` output redirection.

## Real run (real output)

```bash
chmod +x system_info.sh
./system_info.sh
```

Full transcript: [`run-output.txt`](run-output.txt). Summary:

- Prompted for a directory name (`proc-report`) → created with `mkdir`.
- Prompted for a file name (`running-processes`) → created with `touch`,
  then populated via `ps aux > proc-report/running-processes.txt`.
- The saved file contains the **full, untruncated** `ps aux` output (538
  lines on this machine) — the on-screen "top 10" preview truncates the
  `COMMAND` column only for display; the redirected file does not.

Screenshot: [`../screenshots/02-shell-scripting.png`](../screenshots/02-shell-scripting.png)

# Task 1 — Soft Link vs Hard Link

## Concept

| | Hard Link | Soft (Symbolic) Link |
|---|---|---|
| What it stores | A second directory entry pointing at the **same inode** as the original file | A tiny special file that stores the **path string** of the target |
| Inode number | **Same** as the original | **Different** — it has its own inode |
| Crosses filesystems/partitions? | No — must be on the same filesystem | Yes — can point anywhere, even across filesystems or to a directory |
| Can link to a directory? | No (not allowed on most systems, to avoid loops) | Yes |
| If the original is deleted | Data **survives** — it's only freed when the link count drops to 0 | **Breaks** — becomes a "dangling" link, since the path it points to no longer resolves |
| `ls -l` size field | Actual file size | Length of the path string it stores |
| `ls -l` first char | `-` (regular file) | `l` (link), with `-> target` shown |
| Command to create | `ln target linkname` | `ln -s target linkname` |

**Why it matters / interview framing:** a hard link is really just another *name* for
the exact same data on disk (same inode, same link count) — deleting one name doesn't
delete the data until every hard link to that inode is gone. A symlink is a separate,
tiny file that just contains a path, similar to a Windows shortcut — deleting or moving
the original breaks it.

## Commands

```bash
ln  target  linkname     # hard link
ln -s target  linkname   # soft/symbolic link
ls -li                   # show inode numbers to compare
stat -f "%N inode:%i links:%l" file   # (macOS) inspect inode + link count
```

## Practice (real terminal session)

See [`transcript.txt`](transcript.txt) for the full, real output. Summary of what was
demonstrated:

1. Created `original.txt`.
2. Created a hard link (`hardlink.txt`) and a soft link (`softlink.txt`) to it.
3. `ls -li` showed `original.txt` and `hardlink.txt` sharing the **same inode number**
   and a link count of `2`; `softlink.txt` had its **own inode**, link count `1`.
4. Edited the file through the hard link — the change was visible through the original
   name too, because they are literally the same data on disk.
5. Deleted `original.txt`.
   - `hardlink.txt` **still worked** and still had the full content.
   - `softlink.txt` was now **broken** (`No such file or directory`) since it only ever
     stored the path `original.txt`, which no longer exists.

Screenshot: [`../screenshots/task1-soft-hard-links.png`](../screenshots/task1-soft-hard-links.png)

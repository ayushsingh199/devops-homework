# Session 16: CI/CD & GitHub Actions

A real pipeline, run on GitHub's actual infrastructure three times — passing, intentionally
broken, and fixed — not simulated locally. Workflow:
[`../.github/workflows/session16-ci.yml`](../.github/workflows/session16-ci.yml) (note:
GitHub only picks up workflows from the **repo root** `.github/workflows/`, not a
subfolder's — the file lives there, scoped to this topic via `paths:` and
`working-directory:`).

## CI vs CD

- **CI (Continuous Integration)**: every push is automatically built and tested — catches
  breakage the moment it's introduced, not days later. That's the `test` job here.
- **CD (Continuous Delivery/Deployment)**: the verified build is automatically packaged
  and made ready to ship (Delivery) or actually shipped (Deployment). The `build` job's
  artifact upload is the "ready to ship" half of that — this pipeline stops short of an
  actual deploy target, which is exactly what Session 17 (DevSecOps) and the final project
  build on top of.

## The pipeline: 3 jobs, one dependency

```
         push / PR / workflow_dispatch
                     │
                     ▼
              ┌─────────────┐
              │    test     │  checkout → setup python → install deps → pytest
              └──────┬──────┘
                 needs: test
           ┌─────────┴─────────┐
           ▼                   ▼
    ┌─────────────┐    ┌──────────────────┐
    │    build    │    │  security-check  │
    │ build.sh -> │    │  scan for .env,  │
    │  artifact   │    │  *.pem, *.key    │
    └─────────────┘    └──────────────────┘
```

- **Jobs**: `test`, `build`, `security-check` — each runs in its own fresh VM.
- **Steps**: the individual actions inside a job (checkout, setup, run, upload).
- **Runners**: every job runs on GitHub-hosted `ubuntu-latest` — no self-hosted
  infrastructure needed.
- **Artifacts**: the `build` job uploads `build/` (the built `calculator.py` +
  `build-info.txt`) as `calculator-build` — downloadable from the run's page for 90 days.
- **Secrets**: not exercised here (no external deploy target yet — nothing needs a
  credential), but the mechanism is `${{ secrets.NAME }}`, set in the repo's
  Settings → Secrets, injected as an env var at run time and automatically masked in logs.

## Run 1: passing — [`task2-ci-run-passing.txt`](task2-ci-run-passing.txt)

[Run #37633312666](https://github.com/ayushsingh199/devops-homework/actions/runs/37633312666)
— every step in all 3 jobs succeeded, full step-by-step breakdown captured via the GitHub
Actions REST API.

## Run 2: intentionally broken — [`task3-ci-run-failing.txt`](task3-ci-run-failing.txt)

Changed `add(a, b)` to `return a + b + 1`, pushed.

[Run #37633587986](https://github.com/ayushsingh199/devops-homework/actions/runs/37633587986)
— `Test Application: failure`, and **`Build Application` and `Security Check` both show
`skipped`** — they never even started. This is `needs: test` doing its job: a broken build
never reaches the artifact stage, so nothing broken could ever get "built and ready to
ship."

## Run 3: fixed — [`task4-ci-run-fixed.txt`](task4-ci-run-fixed.txt)

Reverted `add()`, pushed.

[Run #37633668007](https://github.com/ayushsingh199/devops-homework/actions/runs/37633668007)
— all 3 jobs back to `success`.

## Local run (before any of this ever touched GitHub)

[`task1-local-run.txt`](task1-local-run.txt) — `pytest -v` (5 passed) and `./build.sh`
run directly on this Mac first, to confirm the app works before trusting CI with it.

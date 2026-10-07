# Session 17: Complete CI/CD & DevSecOps

A full secure pipeline, run for real on GitHub's infrastructure:

```
Code → Build → Unit Test → SAST → SCA → Secret Scan → Docker Build →
Container Image Scan → Security Gate → Push Image → Deploy to Kubernetes
```

Workflow: [`../.github/workflows/session17-devsecops.yml`](../.github/workflows/session17-devsecops.yml).
The app: a small Flask "DevSecOps Dashboard" with a health check, a status API, and a
calculator API — [`app/app.py`](app/app.py), tested by
[`tests/test_app.py`](tests/test_app.py) (8 tests).

## CI vs CD, and where security fits

- **CI**: `test`, `sast`, `sca`, `secret-scan` all run in parallel on every push — nothing
  proceeds until every one of them passes.
- **The security gate**: `docker-build` has `needs: [test, sast, sca, secret-scan]` — a
  vulnerability, a leaked secret, or a failing test all block the image from ever being
  built, let alone shipped.
- **CD**: `push` (to a real registry) and `deploy` (to a real, if ephemeral, Kubernetes
  cluster) are the delivery/deployment half — this is the piece Session 16's pipeline
  stopped short of.

## The 8 jobs, what each one actually does, and what it found

| Job | Tool | What it checks | Real result |
|---|---|---|---|
| Unit Tests | pytest + coverage | App logic is correct | 8/8 passed, 86% coverage |
| SAST | **CodeQL** (GitHub's own) | Scans the *source code itself* for security bug patterns (injection, unsafe deserialization, etc.) — without running it | passed |
| SCA | **pip-audit** | Checks every dependency in `requirements.txt` against known-CVE databases — would catch a vulnerable Flask version, for instance | passed |
| Secret Scanning | **gitleaks** | Scans the git history itself for accidentally committed credentials (API keys, tokens, private keys) | passed |
| Docker Build | `docker build` | Confirms the image actually builds | passed |
| Image Scan | **Trivy** | Scans the *built image's OS packages and installed libraries* for known CVEs — a different layer than SCA, which only looks at Python deps | ran, `exit-code: 0` (informational — doesn't fail the build on findings, matching the reference curriculum's intent of a visible report rather than a hard block at this stage) |
| Push | `docker push` | Publishes the scanned, verified image | pushed to GHCR |
| Deploy | `kubectl apply` | Rolls the new image out and proves it actually serves traffic | deployed to an ephemeral Kind cluster, verified with a live `curl` |

**SAST vs SCA vs image scanning — the distinction that matters**: SAST looks at code
*you wrote*. SCA looks at *libraries you depend on*. Image scanning looks at *everything
in the final container* — including OS packages from the base image that neither of the
other two ever touches. All three are needed; none of them substitutes for the others.

## A real failure, diagnosed and fixed mid-pipeline

First run: `Image Scan - Trivy` failed in 3 seconds — not a vulnerability finding, a setup
error:
```
Unable to resolve action `aquasecurity/trivy-action@0.28.0`, unable to find version `0.28.0`
```
The action's actual git tags are `v`-prefixed (`v0.28.0`, `v0.36.0`, ...), not bare
semver — a real, easy-to-make pinning mistake. Diagnosed by opening the failed run's
annotation in a browser (the GitHub Actions log-download API requires repo admin rights
even for public repos, so the UI was the faster path), fixed by repointing to
`@v0.36.0`, pushed again.

**Also real**: that fix commit alone didn't trigger a new run — the workflow's
`paths: 16-devsecops-pipeline/**` filter only reacts to changes inside this folder, and
the fix only touched the workflow file itself. This README is what re-triggered the next
run. A genuine, slightly counterintuitive consequence of path-filtered triggers worth
knowing about.

## Why GHCR instead of Docker Hub

The reference curriculum's workflow pushes to the instructor's own Docker Hub account
using a `DOCKERHUB_TOKEN` secret I don't have and can't create without an external
account. Swapped to **GitHub Container Registry** (`ghcr.io`), authenticated with the
`GITHUB_TOKEN` every Actions run already has — zero extra secrets, zero extra accounts,
same mechanics (`docker/login-action` → build → tag → push).

## Why deploy to a throwaway Kind cluster inside the runner

`helm/kind-action` spins up a real (if temporary) Kubernetes cluster *inside the GitHub
Actions runner itself* in about 30 seconds. No cloud credentials, no persistent
infrastructure to pay for or clean up — the cluster is destroyed automatically when the
job ends. The `deploy` job applies the real Deployment + Service, waits for
`kubectl rollout status`, then proves the app is actually serving traffic with a live
`curl` against both `/` and `/api/status` — not just "the YAML applied without error."

Local verification before any of this touched GitHub:
[`task1-local-run.txt`](task1-local-run.txt) (pytest),
[`task2-local-docker-run.txt`](task2-local-docker-run.txt) (`docker build` + `docker run`
+ live curl against `/health`, `/api/status`, `/api/calculate`).
Full pipeline run evidence: [`task3-ci-pipeline-run.txt`](task3-ci-pipeline-run.txt).

Screenshot: [`../screenshots/16-devsecops.png`](../screenshots/16-devsecops.png)

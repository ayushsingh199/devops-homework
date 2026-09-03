# Dockerfiles & Images — Multi-Stage Build Homework

## Task 1 — Run the Multi-Stage Dockerfile

The task says to clone the repo containing the multi-stage Dockerfile. The
`devops-heros` repo's `session6-7-docker/multi-stage-dockerfile/` folder is that
reference — its exact `Dockerfile`, `package.json`, and `server.js` were pulled
(via GitHub's raw file host) and rebuilt here in
[`multi-stage-build/`](multi-stage-build/), then actually built and run.

The Dockerfile has two stages:
1. **`builder`** — installs *all* deps (including dev) and copies the source.
2. **`production`** — starts fresh from `node:24-alpine`, copies only
   `package*.json` and `server.js` from the builder stage, and runs
   `npm install --omit=dev`. The builder stage (and its dev dependencies) is
   discarded from the final image.

Real run, see [`multi-stage-build/run-output.txt`](multi-stage-build/run-output.txt):

```bash
docker build -t multistage-hello .
docker run -d --name multistage-hello -p 8080:3000 multistage-hello
curl -s http://localhost:8080
# → <h1>Hello World from Docker Multi-Stage Build!</h1>
docker ps --filter name=multistage-hello
# → confirms it's running, host port 8080 → container port 3000
```

## Task 2 — Documentation

- **Name:** Ayush Singh
- **Enrollment number:** *(not provided — fill in before submitting)*
- **Application running successfully:** confirmed via the real `curl` output above —
  `<h1>Hello World from Docker Multi-Stage Build!</h1>` — screenshot:
  [`../screenshots/06-multistage.png`](../screenshots/06-multistage.png)
- **`docker ps` on port 8080:** included in the same transcript/screenshot above.

## Task 3 — Deploy 3 Different Application Types

Reused three of the images already built in
[`05-docker-fundamental`](../05-docker-fundamental/) (Node.js, Python, Java) and ran
all three **simultaneously** as separate containers:

```bash
docker run -d --name deploy-nodejs -p 8091:3000 nodejs-hello
docker run -d --name deploy-python -p 8092:5000 python-hello
docker run -d --name deploy-java   -p 8093:8000 java-hello
```

Real transcript: [`task3-deploy-3-apps.txt`](task3-deploy-3-apps.txt) — all three
verified with real `curl` responses and `docker ps` showing all three running at
once. Screenshot: [`../screenshots/06-task3-deploy.png`](../screenshots/06-task3-deploy.png)

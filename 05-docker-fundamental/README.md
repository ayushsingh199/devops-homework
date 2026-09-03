# Docker Fundamental — Hello World Applications

Six Hello World apps, each in its own folder with its own `Dockerfile`, each
actually built and run with real Docker (via Colima), each verified with a real
`curl` against the running container.

| Folder | Stack | Base image(s) | Port |
|---|---|---|---|
| [`nodejs-app/`](nodejs-app/) | Plain Node.js `http` server | `node:20-alpine` | 3000 |
| [`python-app/`](python-app/) | Python `http.server` (stdlib only) | `python:3.12-alpine` | 5000 |
| [`java-app/`](java-app/) | Java `com.sun.net.httpserver` | `eclipse-temurin:21-jdk-alpine` | 8000 |
| [`Apache-app/`](Apache-app/) | Static HTML on Apache httpd | `httpd:alpine` | 80 |
| [`React-app/`](React-app/) | React (Vite) — multi-stage build, served by Nginx | `node:20-alpine` (build) → `nginx:alpine` (serve) | 80 |
| [`nginx-app/`](nginx-app/) | Static HTML on Nginx | `nginx:alpine` | 80 |

Each folder's `run-output.txt` is the real transcript of:
`docker build` → `docker run -d -p <host>:<container>` → `curl` (proves "Hello
World" is really served) → `docker ps` (proves the container is up).

Screenshots: [`../screenshots/05-docker-*.png`](../screenshots/)

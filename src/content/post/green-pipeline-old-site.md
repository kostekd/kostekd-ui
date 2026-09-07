---
title: "Green pipeline, old site"
publishDate: 2026-09-07
description: "Actions said the deploy worked. kostekd.com didn't move. Notes on this blog's CI/CD, a private GHCR image, and a 403 the job swallowed."
tags: [cicd, docker, github]
---

I merged two PRs, GitHub Actions went green both times, and [kostekd.com](https://kostekd.com) still served the previous build. Did it twice on purpose. Same result.

The build wasn't the lie. The deploy was.

## How this thing ships

The site lives in [kostekd/kostekd-ui](https://github.com/kostekd/kostekd-ui). Astro on Node 22, pnpm, a Dockerfile that builds the app and then runs `node ./dist/server/entry.mjs` on port 4321. Not a static dump on Pages. A container.

That container runs on a Hostinger VPS, on a docker network called `vps_net`. The reverse proxy finds it through the usual labels, `VIRTUAL_HOST=kostekd.com` and `VIRTUAL_PORT=4321`. The image itself sits in GitHub's container registry: `ghcr.io/kostekd/kostekd-ui`.

Two workflows, on purpose.

A pull request against `main` hits `.github/workflows/ci.yml`. Lint, `pnpm build`, and a Docker build that **does not push**. That's the "don't merge a broken image" check.

Push to `main` hits `.github/workflows/deploy.yml`:

1. The Actions runner logs into GHCR with `GITHUB_TOKEN` (`packages: write`).
2. It builds and pushes two tags: `:latest` and `:<commit sha>`.
3. It SSHes into the VPS (`appleboy/ssh-action`) with `VPS_HOST` / `VPS_USER` / `VPS_SSH_KEY`, pulls the image, and replaces the `kostekd-ui` container.

1 and 2 were fine. 3 is the part that quietly did nothing.

## Why the package went private

It used to be public. That's the easy mode: `docker pull ghcr.io/kostekd/kostekd-ui:latest` works from any machine, no login. Also the reason I flipped it.

A public image is not "the source is on GitHub so whatever." It's the built app. Anyone who knows the name (it isn't a secret, it's the repo name) can pull the exact thing running in production. Run it locally. Peel the layers. Look for leftovers from the build. Reverse engineer it, then go try the same holes against the live site.

I don't want a free, anonymous copy of the running site sitting in a public registry. So the package is private. The git repo can stay public. Pulling the image should require being me.

## What broke

The VPS never logged into GHCR. While the package was public, anonymous `docker pull` just worked. After it went private, GHCR answered:

```text
Error response from daemon: unknown: failed to resolve reference
"ghcr.io/kostekd/kostekd-ui:latest": unexpected status from HEAD request: 403 Forbidden
```

That's the correct response. Anonymous pull of a private package should fail.

The job still passed.

`appleboy/ssh-action` does not stop the remote script on the first failed command unless the script starts with `set -e`. The pull got a 403. The script kept going anyway: `docker stop`, `docker rm`, `docker run ...:latest`. On the VPS, `:latest` was still the old image sitting in the local cache. Then the action printed "Successfully executed commands to all hosts."

I went and looked at the last two Deploy runs after PRs #9 and #10. Both green. Both 403s. Both recycled the previous container. An older run from 25 Jul still shows `Status: Downloaded newer image` — that was before the visibility change.

So: image got built, image got pushed, production restarted what it already had, the check stayed green. The error is in the log if you open it. Nothing turned red.

## What I changed

The VPS has to log in as me before it pulls.

The SSH step now gets three env vars into the remote session: GitHub username, a token (`github.token` for the length of the job, or a `GHCR_TOKEN` PAT if I ever need a longer-lived one), and the image name pinned to that commit SHA. Then: `docker login ghcr.io`, pull that tag, run it, confirm `docker ps` actually shows it, log out.

Also `set -euo pipefail`. Next time GHCR says 403, the workflow fails instead of restarting whatever was already on disk.

That's the whole lesson. Pushing from Actions was always authenticated. Pulling on the VPS was a leftover from when the registry was public. Private package means both ends of the pipe need credentials, and a failed pull has to fail the job — otherwise you get this, a green pipeline and an old site.

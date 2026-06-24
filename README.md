# hermes-sandbox

Custom Docker image for the [Hermes Agent](https://hermes-agent.nousresearch.com)
terminal (Docker) backend. Extends the default
`nikolaik/python-nodejs:python3.11-nodejs20` base with extra CLIs the agent can
use inside its sandbox.

## Tools included

- [`gh`](https://cli.github.com/) — GitHub CLI
- [`glab`](https://gitlab.com/gitlab-org/cli) — GitLab CLI 

## Adding a tool

Append a new `# --- <tool> ---` `RUN` block to the `Dockerfile` (one block per
tool keeps Docker layer caching effective), commit, and push — the
`build-and-push` workflow rebuilds and publishes a new image.

## CI / publishing

`.github/workflows/build-and-push.yml` builds on every change to the `Dockerfile`,
on manual dispatch, and weekly (to absorb base-image / CLI security updates). It
publishes to **`ghcr.io/<owner>/hermes-sandbox`** using the built-in
`GITHUB_TOKEN` (no PAT required).

Tags: `latest`, `sha-<short>`, and `<YYYYMMDD>` for scheduled builds.

## Using it in Hermes (on the host running the gateway)

```bash
docker pull ghcr.io/<owner>/hermes-sandbox:latest
```

Then in `~/.hermes/config.yaml`:

```yaml
terminal:
  docker_image: ghcr.io/<owner>/hermes-sandbox:latest
  docker_forward_env: ["GITHUB_TOKEN", "GITLAB_TOKEN"]  # secrets stay in ~/.hermes/.env
```

Restart the gateway: `systemctl --user restart hermes-gateway`.

> If the GHCR package is **private**, the host must authenticate first:
> `echo $CR_PAT | docker login ghcr.io -u <owner> --password-stdin`
> (PAT with `read:packages`). Making the package **public** avoids this.

## First-time setup (publish to GHCR)

`gh` is not installed on the nimbus host, so create the repo in the browser, then
push from nimbus.

1. Create an **empty** repo `hermes-sandbox` at <https://github.com/new> — no
   README/license (this local repo already has commits).
2. Push from nimbus (requires nimbus to have GitHub auth: an SSH key registered
   with GitHub, or an HTTPS PAT):
   ```bash
   cd ~/Projects/hermes-sandbox
   git remote add origin git@github.com:<your-user>/hermes-sandbox.git
   git push -u origin main
   ```
   The push touches `Dockerfile` + the workflow, so it triggers the build
   immediately (also available via the Actions "Run workflow" button, and weekly).
   Publishing uses the built-in `GITHUB_TOKEN` — no PAT or repo secrets to set up.
3. Make the GHCR package pullable by nimbus. After the first build the package
   appears under your GitHub *Packages*. Either set its visibility to **Public**
   (no auth needed to pull), or keep it private and run once on nimbus:
   ```bash
   echo "$CR_PAT" | docker login ghcr.io -u <your-user> --password-stdin   # PAT w/ read:packages
   ```

## Notes / gotchas

- CI builds **linux/amd64** (matches nimbus, which is x86_64). The Dockerfile is
  arch-aware, so multi-arch later is just adding `linux/arm64` + a
  `docker/setup-qemu-action` step to the workflow.
- **Modular loop**: adding a tool = append a `# --- <tool> ---` block to the
  `Dockerfile`, commit, push → CI rebuilds and republishes `:latest`.
- After updating the image, on nimbus: `docker pull ghcr.io/<owner>/hermes-sandbox:latest`
  then `systemctl --user restart hermes-gateway` so new sandbox containers use it.
- Keep tool credentials out of the image: use `terminal.docker_forward_env`
  (`GITHUB_TOKEN`, `GITLAB_TOKEN`) so secrets stay in `~/.hermes/.env`. Scope the
  tokens — sandboxed tool code can use them.
- Sanity check after a build:
  `docker run --rm ghcr.io/<owner>/hermes-sandbox:latest bash -lc 'gh --version && glab --version'`

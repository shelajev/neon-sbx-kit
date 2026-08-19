# Neon Docker Sandboxes Kit

A Docker Sandboxes mixin kit for [Neon](https://neon.tech). It installs the current Neon CLI, authenticates API calls without exposing the real API key to the sandbox, and teaches the agent how to provision projects and branches, retrieve connection strings, wire them into applications, and inspect Neon resources.

## What you get

- `neon` on `PATH` (the current CLI; `neonctl` is now a compatibility command)
- Neon's official `neon` and `neon-postgres` agent skills
- proxy-managed `NEON_API_KEY` authentication to the Neon Management API
- project and branch provisioning
- connection strings and project linking through `neon link` / `neon env pull`
- project, branch, operation, and database inspection

## Quick start

### 1. Create a Neon API key

Create an API key in the [Neon Console](https://console.neon.tech/app/settings/api-keys). Prefer a project-scoped key for agent use, limiting the key to the project the sandbox should manage.

If you already use the Neon CLI on the host, you can also mint a scoped key there:

```bash
neon profile create sbx --mint --project-id <project-id>
```

### 2. Store it as a Docker Sandboxes secret

```bash
sbx secret set -g neon
```

Paste the key when prompted. The key stays in the host credential store. On first use, approve `console.neon.tech` as the domain where the `neon` credential may be injected.

### 3. Run a sandbox with the kit

During local development:

```bash
sbx run claude --kit . .
```

After this repository is published, use an immutable commit SHA:

```bash
sbx run claude \
  --kit "git+https://github.com/shelajev/neon-sbx-kit.git#ref=<40-character-commit-sha>" \
  .
```

Inside the sandbox, verify access:

```bash
neon me --output json
neon projects list --output json
```

The skills are installed globally under `~/.agents/skills`, so compatible
agents can discover them without modifying the mounted project. The `neon`
skill provides the platform overview; `neon-postgres` contains the primary
development guidance for connections, drivers, ORMs, branching, and database
best practices.

## Common workflows

Provision a project and retrieve its connection string:

```bash
neon projects create --name my-app --output json
neon connection-string --project-id <project-id>
```

Link an application to a branch and populate its local env file:

```bash
neon link --project-id <project-id> --branch main
neon env pull
```

`neon link` records local context in `.neon` and ensures it is ignored. `env pull` updates Neon-managed values such as `DATABASE_URL` and `DATABASE_URL_UNPOOLED` in an existing `.env`, or in `.env.local` when no `.env` exists. Confirm those files are ignored before committing.

Create an isolated development branch:

```bash
neon branches create --project-id <project-id> --name feature-x --output json
neon connection-string feature-x --project-id <project-id>
```

Inspect resources and recent activity:

```bash
neon branches list --project-id <project-id> --output json
neon operations list --project-id <project-id> --output json
neon status --project-id <project-id>
neon inspect db --project-id <project-id>
```

For usage and transfer metrics beyond the CLI's resource views, query Neon's Management API or Consumption API. Availability and granularity depend on the Neon plan.

## Security model

The kit declares a required `neon` credential. Docker Sandboxes puts the literal sentinel `proxy-managed` in `NEON_API_KEY`; when the CLI sends `Authorization: Bearer proxy-managed` to `console.neon.tech`, the host proxy substitutes the real key. The key itself never enters the sandbox.

Connection strings are different: Neon returns them as normal API response data, and they contain database credentials. Treat generated `.env` files as secrets and never commit them.

The kit permits `console.neon.tech`, the npm registry used during installation, GitHub for Neon's official skills repository, and Neon service/database hosts (including PostgreSQL on port 5432). It does not grant access to unrelated providers. Direct database connections whose hostnames contain region and cloud labels require an `sbx` release with v2 multi-label (`**`) network matching; management API operations and retrieving/writing connection strings do not depend on that support.

## CLI version

The default CLI version is pinned in `spec.yaml` for reproducible installs. The kit exposes the `neon-version` kit argument for installers that support v2 argument overrides; pinning the version in published revisions is recommended.

## Local helper

```bash
./run.sh neon-current
```

Additional arguments are passed to `sbx run`.

## Validate

```bash
sbx kit validate .
sbx kit inspect .
sbx kit pack . -o /tmp/neon-sbx-kit.zip
sbx kit validate /tmp/neon-sbx-kit.zip
bash tests/smoke.sh
```

## Publish to Docker Hub

The GitHub Actions publishing workflow expects these repository secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN` — a Docker Hub access token with read/write permission

Push a semantic-version tag to validate and publish the kit:

```bash
git tag v0.1.0
git push origin v0.1.0
```

This publishes:

```text
docker.io/<DOCKERHUB_USERNAME>/neon-sbx-kit:0.1.0
```

The workflow can also be started manually from the Actions tab with a version
input. `sbx kit push` uses Docker's credential store, populated in CI by
`docker/login-action`.

## Requirements

The base sandbox must provide npm and Node.js 20.19 or newer. Current Docker Sandboxes coding-agent images satisfy this requirement.

## License

Apache 2.0. See [LICENSE](LICENSE).

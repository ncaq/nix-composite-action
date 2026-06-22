# nix-composite-action

GitHub Composite Action for Nix setup with cache integration.

Install Nix by [install-nix-action](https://github.com/cachix/install-nix-action)
and cache configure:

- [cachix](https://github.com/cachix/cachix)
  by [cachix-action](https://github.com/cachix/cachix-action)
- [niks3](https://github.com/Mic92/niks3)
  by [niks3-action](https://github.com/Mic92/niks3-action)

## Usage

```yaml
name: check

on:
  push:
    branches: [master, main]
  pull_request:
  merge_group:

permissions: {}

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  nix-flake-check:
    name: nix-flake-check
    runs-on: ubuntu-24.04
    permissions:
      contents: read # read-only access to repository contents
      id-token: write # required for OIDC authentication with niks3
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v6
        with:
          persist-credentials: false
      - uses: ncaq/nix-composite-action@v2
        with:
          cachix-auth-token: "${{ secrets.CACHIX_AUTH_TOKEN }}"
      - run: nix flake check
```

## Inputs

| Name                | Description                                 | Required | Default                         |
| ------------------- | ------------------------------------------- | -------- | ------------------------------- |
| `free-disk-space`   | Free disk space on GitHub-hosted Linux only | No       | `true`                          |
| `extra-nix-config`  | Append nix.conf settings                    | No       | `""`                            |
| `use-daemon`        | Use post-build-hook                         | No       | `true`                          |
| `cachix-name`       | Cachix cache name                           | No       | `ncaq`                          |
| `cachix-auth-token` | Cachix authentication token                 | No       | `""`                            |
| `niks3-endpoint`    | niks3 server endpoint URL                   | No       | `https://niks3-public.ncaq.net` |

## Behavior

### Free disk space

On GitHub-hosted Ubuntu runners,
[jlumbroso/free-disk-space](https://github.com/jlumbroso/free-disk-space)
removes pre-installed software
before Nix installs to enlarge the root partition where `/nix/store` lives.

Only the fast removals of large directories (Android SDK, .NET, Haskell) are enabled by default.

- `docker-images`
- `large-packages`
- `swap-storage`
- `tool-cache`

are kept disabled.

Set `free-disk-space: false` to skip this step.

The step is a no-op on self-hosted or non-Linux runners.

### Nix installation

Uses [cachix/install-nix-action](https://github.com/cachix/install-nix-action) to install Nix.
On GitHub-hosted runners, `accept-flake-config = true` is automatically
set so that `flake.nix` cache configurations are respected.

### Daemon mode

Both cache pushes default to nix-daemon `post-build-hook` mode for efficiency.
On self-hosted runners where the daemon cannot reach the hook path
(e.g. containerized runners whose `${RUNNER_TEMP}` is not visible to the host daemon),
set `use-daemon: false` to fall back to store scan mode.
`use-daemon` currently controls Cachix only;
niks3 falls back to store scan automatically when `trusted-users` excludes the runner,
and explicit control will be wired up once `Mic92/niks3-action` exposes the option.

### Cachix

Configured via [cachix/cachix-action](https://github.com/cachix/cachix-action).
Requires both `cachix-name` and `cachix-auth-token` to be set.
Cache push is automatically skipped for pull requests from forks.

### niks3

Configured via [Mic92/niks3-action](https://github.com/Mic92/niks3-action)
with OIDC authentication.
Cache push is automatically skipped for pull requests from forks.

## License

Apache-2.0

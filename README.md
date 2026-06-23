# nix-composite-action

GitHub Composite Action for Nix setup with cache integration.

Install Nix by [install-nix-action](https://github.com/cachix/install-nix-action)
and push store paths to [niks3](https://github.com/Mic92/niks3)
via [niks3-action](https://github.com/Mic92/niks3-action).

Read-only substituters such as Cachix are not configured by this action.
List them in `flake.nix` under `nixConfig.extra-substituters` and
`nixConfig.extra-trusted-public-keys`, and they will be picked up by the
Nix daemon thanks to `accept-flake-config = true` on GitHub-hosted runners.
Writes are concentrated on niks3 because pushing the same store paths to
multiple caches wastes bandwidth and risks the Nix daemon racing on the
same artifacts.

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
      - uses: ncaq/nix-composite-action@v3
      - run: nix flake check
```

## Inputs

| Name               | Description                                 | Required | Default                         |
| ------------------ | ------------------------------------------- | -------- | ------------------------------- |
| `free-disk-space`  | Free disk space on GitHub-hosted Linux only | No       | `true`                          |
| `extra-nix-config` | Append nix.conf settings                    | No       | `""`                            |
| `niks3-endpoint`   | niks3 server endpoint URL                   | No       | `https://niks3-public.ncaq.net` |

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
Read-only substituters such as Cachix should be declared in `flake.nix`
under `nixConfig.extra-substituters` instead of being configured by this action,
which avoids the cachix-action daemon racing with niks3 over post-build-hook pushes.

### niks3

Configured via [Mic92/niks3-action](https://github.com/Mic92/niks3-action)
with OIDC authentication.
This is the only writable cache.
On self-hosted runners where the daemon cannot reach the hook path,
niks3 falls back to store scan automatically
when `trusted-users` excludes the runner.
Cache push is automatically skipped for pull requests from forks.

## License

Apache-2.0

# nix-composite-action

GitHub Composite Action for Nix setup with cache integration.

Install Nix by [install-nix-action](https://github.com/cachix/install-nix-action)
and cache configure:

- [cachix](https://github.com/cachix/cachix) by [cachix-action](https://github.com/cachix/cachix-action)
- [niks3](https://github.com/Mic92/niks3) by [niks3-action](https://github.com/aleadag/niks3-action)

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
      - uses: ncaq/nix-composite-action@v1
        with:
          cachix-auth-token: "${{ secrets.CACHIX_AUTH_TOKEN }}"
      - run: nix flake check
```

## Inputs

| Name                | Description                            | Required | Default                         |
| ------------------- | -------------------------------------- | -------- | ------------------------------- |
| `extra-nix-config`  | Additional nix.conf settings to append | No       | `""`                            |
| `cachix-name`       | Cachix cache name                      | No       | `ncaq`                          |
| `cachix-auth-token` | Cachix authentication token            | No       | `""`                            |
| `niks3-endpoint`    | niks3 server endpoint URL              | No       | `https://niks3-public.ncaq.net` |

## Behavior

### Nix installation

Uses [cachix/install-nix-action](https://github.com/cachix/install-nix-action) to install Nix.
On GitHub-hosted runners, `accept-flake-config = true` is automatically
set so that `flake.nix` cache configurations are respected.

### Cachix

Configured via [cachix/cachix-action](https://github.com/cachix/cachix-action).
Requires both `cachix-name` and `cachix-auth-token` to be set.
Cache push is automatically skipped for pull requests from forks.

### niks3

Configured via [aleadag/niks3-action](https://github.com/aleadag/niks3-action) with OIDC authentication.
Skipped entirely for fork pull requests to avoid build failures due to missing credentials.

## License

Apache-2.0

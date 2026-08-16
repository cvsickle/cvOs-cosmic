# Dev Container

Provides every CLI tool referenced by the Agent Skills in `.agents/skills/`, the
`Justfile` recipes, and the `AGENTS.md` pre-commit checklist.

Open with **Dev Containers: Reopen in Container**. Tools install via
`.devcontainer/post-create.sh` (versions pinned at the top of that script).

## Tool inventory

| Tool                        | Used for                                                     | Source            |
| --------------------------- | ------------------------------------------------------------ | ----------------- |
| `bash`, coreutils, `sed`    | build scripts (`build/*.sh`), Justfile recipes               | apt               |
| `just`                      | `just build`, `just lint`, `just check`, `just --list`       | GitHub release    |
| `podman` / `buildah`        | image builds, `bootc-image-builder`, VM recipes              | apt + docker-in-docker |
| `skopeo`                    | `skopeo list-tags`, `skopeo copy` (nvidia akmods)            | apt               |
| `jq`                        | Justfile tag inspection, `podman inspect` parsing            | apt               |
| `shellcheck`                | `just lint`, pre-commit checklist                            | apt               |
| `shfmt`                     | `just format` / `just fix`                                   | GitHub release    |
| `hadolint`                  | `Containerfile` linting (matches `pr-validation.yml`)        | GitHub release    |
| `actionlint`                | `.github/workflows/*.yml` linting                            | GitHub release    |
| `renovate-config-validator` | `.github/renovate.json` validation                           | npm (`renovate`)  |
| `markdownlint`              | README / docs linting                                        | npm               |
| `prettier`                  | JSON/YAML/Markdown formatting                                | npm               |
| `python3` + `pyyaml`        | YAML validation step in the pre-commit checklist             | feature + pip     |
| `git`                       | `just clean`, commit workflow                                | feature           |
| `gh`                        | PR checklist step 0 (`gh pr list`)                           | feature           |
| `cosign`                    | keyless signature verification of published images           | GitHub release    |
| `curl`, `wget`, `rsync`     | build scripts, pinned-tool install pattern                   | apt               |
| `iproute2` (`ss`)           | Justfile free-port scan in `_run-vm`                         | apt               |
| `xdg-utils` (`xdg-open`)    | Justfile `_run-vm` opens the VM web console                  | apt               |

### Not installed (intentionally)

- `dnf5`, `rpm`, `systemctl`, `bootc`, `nvidia-ctk`, `brew` — these run **inside
  the image** during `podman build`, not on the host. Test them with `just build`.
- `systemd-vmspawn` — requires a systemd host; use `just run-vm-qcow2` instead of
  `just spawn-vm` from inside the container.

## Common commands

```bash
just --list                     # verify Justfile syntax
just lint                       # shellcheck all shell scripts
just check                      # formatting check (shfmt + just fmt)
hadolint Containerfile
actionlint .github/workflows/*.yml
renovate-config-validator .github/renovate.json
markdownlint README.md
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build-image.yml'))"
```

## Notes

- The container runs privileged with docker-in-docker so rootful `podman build`
  and `bootc-image-builder` work. Nested KVM (`just run-vm-qcow2`) requires
  `/dev/kvm` on the host.
- Bump a tool version by editing the pinned constants in `post-create.sh` and
  rebuilding the container.

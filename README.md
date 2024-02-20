# Jellyfin TV Guide
Download TV guide metadata for Jellyfin using a cron job.

> [!TIP]
> **tl;dr**
> ```bash
> export ZAP2IT_PASSWORD='hunter2'
> sudo ./dl-guide.sh -u 'someone@example.com' -o '.' -c "$USER"
> ```

### Index
1. [Installation](#installation)
    1. [bpkg](#bpkg)
    1. [Manual](#manual)
1. [Development](#development)
    1. [Lint](#lint)
    1. [CI](#ci)
1. [See Also](#see-also)

## Installation
This tool runs a docker container, so you will need the [docker engine](https://docs.docker.com/engine/install) installed on your system to use it.

### bpkg
This is the recommended installation method. Install [bpkg](https://github.com/bpkg/bpkg) if you have not already. Then, install using `bpkg`.
```bash
sudo bpkg install kj4ezj/jellyfin-tv-guide
```
This does a global install so `dl-guide` should now be in your system `PATH`.

### Manual
If you can't or won't use `bpkg`, you can install manually. Clone this repo locally with `git` using your preferred method. You can invoke the script directly from your copy of the repo, or perform the same global install that `bpkg` does using `make` from the root of this repo.
```bash
sudo make install
```
Do the reverse to uninstall. From the root of this repo in your terminal:
```bash
sudo make uninstall
```

## Development
Contributors need these tools installed.
- [act](https://github.com/nektos/act)
    - docker
- [bpkg](https://github.com/bpkg/bpkg)
    - git
    - make
- [git](https://git-scm.com)

Please [sign your commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits).

### Lint
This project uses [bashate](https://github.com/openstack/bashate) _and_ [shellcheck](https://github.com/koalaman/shellcheck) for linting.
```bash
bpkg run lint
```
This invokes `lint.sh` which contains the specific configuration for each permutation of linter and target file.

### CI
This repo uses GitHub Actions workflows for CI.
1. **jellyfin-tv-guide CI** - initialize and lint the `jellyfin-tv-guide` project.
    - [Pipeline](https://github.com/kj4ezj/jellyfin-tv-guide/actions/workflows/ci.yml)
    - [Documentation](./.github/workflows/README.md)

The CI must pass before a pull request will be peer-reviewed.

You can run the GitHub Actions workflow(s) locally using [act](https://github.com/nektos/act).
```bash
bpkg run act
```
Please make sure any pipeline changes do not break `act` compatibility.

## See Also
- Jellyfin
    - Documentation
        - [Adding Guide Data](https://jellyfin.org/docs/general/server/live-tv/setup-guide/#adding-guide-data)
    - [GitHub](https://github.com/jellyfin)
    - [Website](https://jellyfin.org)
- [zap2it](https://tvlistings.zap2it.com)
- zap2xml
    - [Docker Hub](https://hub.docker.com/r/kj4ezj/zap2xml)
    - [GitHub](https://github.com/kj4ezj/zap2xml)

***
> **_Legal Notice_**  
> This repo contains assets created in collaboration with a large language model, machine learning algorithm, or weak artificial intelligence (AI). This notice is required in some countries.

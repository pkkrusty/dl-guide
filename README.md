# Jellyfin TV Guide
Download TV guide metadata for Jellyfin using a cron job.

### Index
1. [Development](#development)
    1. [Lint](#lint)
1. [See Also](#see-also)

## Development
Contributors need these tools installed.
- [bpkg](https://github.com/bpkg/bpkg)
    - git
    - make
- [git](https://git-scm.com)

### Lint
This project uses [bashate](https://github.com/openstack/bashate) _and_ [shellcheck](https://github.com/koalaman/shellcheck) for linting.
```bash
bpkg run lint
```
This invokes `lint.sh` which contains the specific configuration for each permutation of linter and target file.

## See Also
- Jellyfin
    - Documentation
        - [Adding Guide Data](https://jellyfin.org/docs/general/server/live-tv/setup-guide/#adding-guide-data)
    - [GitHub](https://github.com/jellyfin)
    - [Website](https://jellyfin.org)
- [zap2it](https://tvlistings.zap2it.com)

***
> **_Legal Notice_**
> This repo contains assets created in collaboration with a large language model, machine learning algorithm, or weak artificial intelligence (AI). This notice is required in some countries.

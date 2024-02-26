# Download TV Guide
Download TV guide metadata for [Jellyfin](https://jellyfin.org), or any other media software that accepts the [XMLTV format](https://wiki.xmltv.org/index.php/XMLTVFormat).

> [!TIP]
> **tl;dr**
> ```bash
> export ZAP2IT_PASSWORD='hunter2'
> ./dl-guide.sh -u 'someone@example.com' -o '.'
> ```

### Index
1. [Installation](#installation)
    1. [bpkg](#bpkg)
    1. [Manual](#manual)
1. [Usage](#usage)
    1. [Password](#password)
    1. [Jellyfin](#jellyfin)
    1. [cron](#cron)
1. [Development](#development)
    1. [Lint](#lint)
    1. [CI](#ci)
1. [See Also](#see-also)

## Installation
This tool runs the [zap2xml](https://github.com/kj4ezj/zap2xml) docker container, so you will need the [docker engine](https://docs.docker.com/engine/install) installed on your system to use it.

> [!NOTE]
> > If you are on macOS or BSD, you will need to [default to GNU tools](https://apple.stackexchange.com/a/69332) in your environment. You can check this by running `grep --version`, which will tell you whether it is BSD or GNU `grep`.

### bpkg
This is the recommended installation method. Install [bpkg](https://github.com/bpkg/bpkg) if you have not already.

Install the [echo-eval](https://github.com/kj4ezj/echo-eval) dependency.
```bash
sudo bpkg install -g kj4ezj/ee
```
Then, install this tool using `bpkg`.
```bash
sudo bpkg install kj4ezj/dl-guide
```
This does a global install so `dl-guide` should now be in your system `PATH`.

You can also have `bpkg` install a specific version.
```bash
sudo bpkg install kj4ezj/dl-guide@v0.1.0
```

### Manual
Install [bpkg](https://github.com/bpkg/bpkg) if you have not already. Clone this repo locally with `git` using your preferred method. Install project dependencies.
```bash
bpkg install
```
You can invoke the script directly from your copy of the repo.

## Usage
You need a [zap2it](https://tvlistings.zap2it.com) account setup with your rough location and provider to use this script. What you see while logged into the online TV guide is what this script will download.

You can provide inputs to `dl-guide` as arguments...
```
$ dl-guide [OPTIONS]

[OPTIONS] - command-line arguments to change behavior
    -c, --chown, --owner, --change-owner <USER>
        Change the ownership of the output file to the specified user. If not
        specified, the ownership will not be changed.
            Requires script be run with "sudo -E" or root privileges.

    -h, --help, -?
        Print this help message and exit.

    -l, --license
        Print software license and exit.

    -o, --output, --output-dir, --output-file, --path <PATH>
        Specify the output directory or file. If a directory is given, the
        default file name (tv-guide.xml) will be used. If no output file,
        folder, or path is given, then the default Jellyfin metadata directory
        will be used if it exists.

    -u, --username, --zap2it-username <USERNAME>
        Specify the zap2it username.

    -v, --version
        Print the script version with debug info and exit.
```
...or using environment variables.

Variable | Type | Description
--- | --- | ---
`CHOWN_USER` | String | The user to change the ownership of the output file to. Equivalent to '--chown'.
`OUTPUT` | String | The output directory or file. Equivalent to `--output`.
`ZAP2IT_PASSWORD` | String | The password for your zap2it account (**required**).
`ZAP2IT_USERNAME` | String | The username for your zap2it account. Equivalent to `--username`.

Arguments take precedence over environment variables.

### Password
Your zap2it password cannot be provided as a command-line argument because it would be visible to other programs on your computer via the process list and shell history. The best option is to save it to a file somewhere...
```bash
export ZAP2IT_PASSWORD='hunter2'
```
...then source the file.
```bash
source ~/.secrets
```
If you don't care about it being in your shell history, you can export it as a variable.
```bash
export ZAP2IT_PASSWORD='hunter2'
```
At least this keeps it out of your process list while the script is running.

If you are using Kubernetes, you can make this variable available like you would any other secret.

### Jellyfin
Jellyfin doesn't care where you put the `tv-guide.xml` file, but I chose to put it in my Jellyfin metadata directory.

> [!TIP]
> You can find your Jellyfin metadata directory in your Jellyfin web portal > hamburger menu (three horizontal lines) > Administration > Dashboard, scroll down and you will see it under `Paths`. Mine was `/var/lib/jellyfin/metadata`.

Jellyfin also may run under its own user account (usually `jellyfin`), depending how you installed it, in which case you will need to pass that username to `dl-guide` so it can make sure the permissions are correct for Jellyfin to read the output file.
```bash
sudo -E dl-guide -u 'someone@example.com' -o /var/lib/jellyfin/metadata -c jellyfin
```
After that, follow [their instructions](https://jellyfin.org/docs/general/server/live-tv/setup-guide/#adding-guide-data) to point Jellyfin to the `tv-guide.xml` file in `/var/lib/jellyfin/metadata`.

Jellyfin reads the `tv-guide.xml` file using a scheduled task that (at least for me) is already in there by default. You can check in the Administration Dashboard > Advanced > Scheduled Tasks > Live TV > Refresh Guide using the Jellyfin web portal.

### cron
Finally, run this script at regular intervals using a [cron job](https://en.wikipedia.org/wiki/Cron).

> [!TIP]
> > Note the following command sets `dl-guide` to run as `root`. If you don't want to run `dl-guide` as `root` then you can omit `sudo`, but you won't be able to use the `-c` flag and your user account must have permission to run `docker` without `sudo`.

Open your crontab to create the schedule.
```bash
sudo crontab -e
```
You will see some instructions explaining the general idea, and you can use [crontab.guru](https://crontab.guru) for help with the syntax. You probably want to run it somewhere between 1-4 times per day because sometimes `zap2it` throttles itself and refuses to respond. Please give a random minute offset to prevent everyone from querying the server all at once.

For example, this will run twice per day - once at 00:47, and once at 12:47.
```cron
ZAP2IT_PASSWORD='hunter2'
47 */12 * * * /usr/local/bin/dl-guide -u 'someone@example.com' -c jellyfin -o /var/lib/jellyfin/metadata
```
This example captures the logs so you can see it worked, this time running once per day at 14:15 local time.
```cron
ZAP2IT_PASSWORD='hunter2'
15 14 * * * /usr/local/bin/dl-guide -u 'someone@example.com' -c jellyfin -o /var/lib/jellyfin/metadata > /var/lib/jellyfin/metadata/dl-guide.log 2>&1
```
One more example running at 2:23, 3:23, and 4:23 AM local time.
```cron
ZAP2IT_PASSWORD='hunter2'
23 2-4/1 * * * /usr/local/bin/dl-guide -u 'someone@example.com' -c jellyfin -o /var/lib/jellyfin/metadata > /var/lib/jellyfin/metadata/dl-guide.log 2>&1
```
The cron syntax is the same if you choose to use a Kubernetes cron job.

## Development
Contributors need these tools installed.
- [act](https://github.com/nektos/act)
    - docker
- [bpkg](https://github.com/bpkg/bpkg)
    - git
    - make
- [git](https://git-scm.com)

Pull requests are welcomed to add support for other media software. Please [sign your commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits).

### Lint
This project uses [bashate](https://github.com/openstack/bashate) _and_ [shellcheck](https://github.com/koalaman/shellcheck) for linting.
```bash
bpkg run lint
```
This invokes `lint.sh` which contains the specific configuration for each permutation of linter and target file.

### CI
This repo uses GitHub Actions workflows for CI.
1. **dl-guide CI** - initialize and lint the `dl-guide` project.
    - [Pipeline](https://github.com/kj4ezj/dl-guide/actions/workflows/ci.yml)
    - [Documentation](./.github/workflows/README.md)

The CI must pass before a pull request will be peer-reviewed.

You can run the GitHub Actions workflow(s) locally using [act](https://github.com/nektos/act).
```bash
bpkg run act
```
Please make sure any pipeline changes do not break `act` compatibility.

## See Also
- [crontab.guru](https://crontab.guru)
- [echo-eval](https://github.com/kj4ezj/echo-eval)
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

# acme-orchestrate

ACME certificate orchestration and deployment for FreeBSD.

`acme-orchestrate` manages Let's Encrypt certificates using `acme.sh`, DNS-01 validation and authenticated DNS updates via `nsupdate`. It reconciles certificate definitions against existing certificate state, constructs validated deployment snapshots and distributes certificates to configured local or remote destinations.

The project is written in FreeBSD-compatible shell and distributed as a FreeBSD package.

**Current release:** v1.0.1 (FreeBSD 15)  
**License:** BSD 2-Clause  
**Releases:** https://github.com/misterhelbig/acme-orchestrate/releases

## Components

| Program | Run as | Purpose |
|---|---|---|
| `acme-orchestrate` | `acme` | Reconcile certificates, perform issuance and renewal, and prepare replica snapshots |
| `acme-orchestrate-runner` | `acme` | Scheduled preflight, reconciliation, locking and logging |
| `acme-orchestrate-push` | `root` | Deploy prepared snapshots using `rsync` |

The DNS plugin, `dns_nsupdate.sh`, supplies authenticated RFC 2136 dynamic DNS updates to `acme.sh`.

Certificate reconciliation and certificate deployment are deliberately separate operations.

## Key concepts

### Certificate bundles

Each definition in `domains.conf` describes a certificate bundle consisting of an apex domain and/or a set of Subject Alternative Names (SANs).

A bundle may contain an apex and wildcard certificate, or an explicit selection of subdomains.

### Replica sets

A replica set is the collection of certificates deployed to one destination.

Each certificate definition references one or more replica aliases. The orchestrator prepares a validated snapshot for each replica. The push command subsequently synchronises that snapshot to its configured destination.

Because deployment uses `rsync --delete`, every destination must be a dedicated directory managed exclusively by this software.

### DNS-01 challenge delegation

The system uses a dedicated authoritative DNS zone for ACME DNS-01 challenges.

Each managed domain delegates its `_acme-challenge` records through public DNS CNAMEs into this zone. The DNS plugin creates and removes temporary TXT records using authenticated `nsupdate` operations.

Two independent settings must agree:

- `ACME_CHALLENGE_ZONE` — configured in `/usr/local/etc/acme/orchestrate.conf`; used by the orchestrator to construct and validate challenge aliases.
- `NSUPDATE_ZONE` — configured in the DNS plugin's acme.sh account settings; identifies the authoritative DNS zone receiving dynamic updates.

For the current architecture, these must identify the same zone.

The DNS server must authorise updates using an appropriate TSIG key. The key and credentials are not included in the package.

## Installation

Download a FreeBSD 15 package from the [GitHub releases](https://github.com/misterhelbig/acme-orchestrate/releases).

For example:

```sh
fetch https://github.com/misterhelbig/acme-orchestrate/releases/download/v1.0.1/acme-orchestrate-1.0.1.pkg
pkg install ./acme-orchestrate-1.0.1.pkg
```

The package installs the scripts, sample configuration files, documentation and newsyslog configuration.

Runtime dependencies are:

- `acme.sh`
- `bind-tools` (`nsupdate` and `dig`)
- `rsync`

The FreeBSD `acme.sh` package normally creates the dedicated `acme` user and group.

Installation does **not** automatically configure certificate definitions, DNS credentials, cron jobs, remote SSH access or production certificate state.

See the packaged installation guide:

```
/usr/local/share/doc/acme-orchestrate/README.install
```

## Configuration

Primary configuration files:

| File | Purpose |
|---|---|
| `/usr/local/etc/acme/domains.conf` | Certificate bundles and replica destinations |
| `/usr/local/etc/acme/orchestrate.conf` | Authoritative DNS challenge zone |
| `/usr/local/etc/newsyslog.conf.d/acme-orchestrate.conf` | Log rotation |

`domains.conf` must be created from `domains.conf.sample`.

The other two active configuration files are installed from their `.sample` files using FreeBSD package `@sample` handling.

The DNS plugin is installed at:

```
/usr/local/share/acme-orchestrate/dns_nsupdate.sh
```

It must also be made accessible in each applicable `acme.sh` DNS API directory.

The installation guide explains the initial `NSUPDATE_*` environment variables, their persistence in `account.conf`, production and staging environments, TSIG requirements and the first certificate issuance.

## Scheduled operation

The intended deployment uses two independent cron jobs.

**The `acme` user's crontab:**

```cron
12 3 * * 1,4 /usr/local/sbin/acme-orchestrate-runner
```

**Root's crontab:**

```cron
12 4 * * 1,4 /usr/local/sbin/acme-orchestrate-push >> /var/log/acme-orchestrate-push.log 2>&1
```

These examples run on Mondays and Thursdays at 03:12 and 04:12, respectively, using the system's local timezone.

The runner performs a dry-run preflight before live reconciliation. Deployment is performed separately by the push command.

Cron entries are **not** installed or enabled automatically.

## Manual operation

Run certificate reconciliation as the `acme` user:

```sh
/usr/local/sbin/acme-orchestrate --dry-run
/usr/local/sbin/acme-orchestrate
```

Run deployment as root:

```sh
/usr/local/sbin/acme-orchestrate-push --dry-run
/usr/local/sbin/acme-orchestrate-push
```

Always review the dry-run output before live operations, especially when changing certificate definitions, replica assignments or DNS delegations.

## Building the FreeBSD package

The repository includes the FreeBSD port definition and its source payload.

On a FreeBSD system with the Ports Collection installed:

```sh
make clean
make package
```

The built package is normally available under:

```
work/pkg/
```

Inspect the package before installation:

```sh
pkg info -F work/pkg/acme-orchestrate-<version>.pkg
pkg info -lF work/pkg/acme-orchestrate-<version>.pkg
```

The port does not install production certificate data, private keys, DNS credentials or account state.

## Security and operational notes

- Certificate and TSIG private keys must be protected independently of the package.
- Use dedicated replica destinations: deployment can delete files that are not part of the prepared snapshot.
- Do not configure multiple hosts to perform independent production issuance without coordinating their state and schedules.
- Review proposed certificate removals and replica changes before live reconciliation.
- Certificate deployment does not automatically reload consuming services.
- Preserve operational account state and credentials separately when migrating servers.

Source code and package releases are maintained at:

https://github.com/misterhelbig/acme-orchestrate


# Building

`build.sh` does the whole thing: installs its dependencies, clones Chromium at
the targeted version, applies all four patch layers, builds, and signs. This
file is about where to run it and what goes wrong.

## What it needs

| | |
| --- | --- |
| CPU | x86-64. Chromium ships prebuilt toolchains for `linux-x64` only, so an ARM host is not a starting point even though the *output* is ARM |
| Disk | ~150GB free, and it should be an SSD. The tree is millions of small files and the build hammers them; on spinning disks the I/O costs more than the CPU does |
| RAM | 16GB works, 32GB is comfortable. The link steps are the hungry part |
| Time | Roughly 5 hours for a full build on 6 fast cores. Incremental rebuilds after a Java change are more like 30 minutes |
| OS | Current Ubuntu, or anything close enough that `install-build-deps.sh` runs |

One architecture at a time halves the work, which is worth it for a local
build that only has to run on one device:

```shell
ARCHS=arm64 ./build.sh
```

## Signing

`build.sh` expects `LOCAL_TEST_JKS` and `STORE_TEST_JKS` in the environment,
base64-encoded, holding `local.properties` (`keyAlias`, `keyPassword`,
`storePassword`) and the keystore itself.

Keep that keystore. Android refuses to install a build signed with a different
key over one already installed, so losing it means every user uninstalling and
reinstalling, losing their data.

## Under WSL2, on Windows

Works, with two rules:

- **Build inside the Linux filesystem** (`/root`, `/home/...`), never under
  `/mnt/c` or `/mnt/d`. The 9p filesystem that bridges to Windows is slow
  enough on small files to turn hours into days.
- **Give the VM room** in `%UserProfile%\.wslconfig`, since it defaults to half
  of host RAM:

  ```ini
  [wsl2]
  memory=26GB
  processors=12
  swap=32GB
  ```

Run the build under systemd rather than as a plain background process:

```shell
systemd-run --unit=browser-build /root/build_unit.sh
```

A process started from `wsl.exe` is killed when the client that launched it
exits, which will happen halfway through a five-hour build. A transient
systemd unit survives it. Keep one WSL client attached — a `tail -F` of the log
will do — or WSL may idle the VM out from under the build.

## On a NAS or a second machine

Anything x86-64 that can run Docker works, and a NAS is a good fit for the
full rebuild after a Chromium bump: it happens every few weeks, takes hours,
and nobody is waiting on it. Keep quick iteration on a desktop, where a Java
change turns around in half an hour.

Do not build in a NAS operating system's own userland — Synology DSM and its
kin are not Debian and `install-build-deps.sh` will not run there. Use a
container:

```shell
docker run -d --name browser-build -v /volume1/build:/work ubuntu:24.04 sleep infinity
```

Point the volume at SSD or NVMe storage if there is any, for the reason in the
table above, and confirm the container has the full ~150GB.

To have CI drive it, register the machine as a self-hosted runner and run
**Build** against it. `build.yml` triggers only on schedule and manual
dispatch, never on `pull_request`, which is what keeps a fork's pull request
from running code on a machine that holds your files. Runners can be labelled,
so a desktop and a NAS can both be registered and chosen per run.

Expect a low-TDP mobile part (a 15–25W `U`-series chip, typical in a NAS) to
land within a small factor of a desktop chip with the same core count: more
cores, much lower sustained clocks. Watch for thermal throttling — hours at
100% on all cores is a duty cycle NAS chassis are not designed around.

## Things that go wrong

**`bzip2: No such file or directory` during `gclient runhooks`.** The hooks run
before `install-build-deps.sh`, so on a fresh minimal image the AFDO profile
hook has no `bzip2`, dies, and takes every hook after it — including toolchain
downloads — with it. The build then fails much later, confusingly. Install
`bzip2` before the first sync, or re-run `gclient runhooks` afterwards.

**`python3_bin_reldir.txt not found`.** depot_tools never finished
bootstrapping, usually as fallout from the above. `gn` and `autoninja` will not
run until it does:

```shell
depot_tools/ensure_bootstrap
```

**A patch fails.** That is the design — see [UPDATING.md](UPDATING.md). Run
`tools/verify_patches.sh` before starting a build rather than finding out hours
in; CI does this on every push.

**`arc.sh` fails on a second run over one checkout.** It is not idempotent by
design: it verifies an anchor before editing, and the first run consumed the
anchors. Build from a fresh checkout, or apply only the patches the tree has
not seen.

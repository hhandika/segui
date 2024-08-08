---
sidebar_position: 8
title: Update SEGUL
---

Updating SEGUL is necessary to take advantage of new features or bug fixes.

## SEGUL GUI

The operating system usually updates the app automatically. However, you can check it manually by going to the app management settings of your operating system.

## SEGUL CLI

To update the CLI, you must first check where the SEGUL binary is. The Conda/Mamba and Cargo installation should be straightforward to update. If you are unsure how the app was installed, you can use the `which` command on macOS and Linux to check the binary location. Windows users using PowerShell 7+ can use the same command.

```Bash
which segul
```

On Windows, another option is using the `Get-Command` command:

```Bash
Get-Command segul
```

If the path contains `~/.cargo/bin` or `~/cargo/bin`, your SEGUL binary is installed using Cargo. You can update it by running the following command:

```Bash
cargo install segul
```

If the path contains `/usr/local/bin`, `/usr/bin`, `/bin,` or `~/programs`, your SEGUL binary is installed using a pre-compiled binary. You must download the latest binary from the [release page](https://github.com/hhandika/segul/releases/latest/). After downloading the binary, replace the old binary with the new one. For more details, follow the binary [installation guidelines](/docs/installation/install_binary).

If the path contains `miniforge` or `conda`, your SEGUL binary is installed using Conda. You can update it by running the following command:

```Bash
conda update segul
```

or with mamba if you have it installed:

```Bash
mamba update segul
```

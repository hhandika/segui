---
sidebar_position: 8
title: Update SEGUL
---

## SEGUL GUI

The app is usually updated automatically. However, you can check for updates manually by going through the store where you installed the app.

## SEGUL CLI

Check where the SEGUL binary is located. On macOS and Linux, you can check the binary location by using `which` command. Windows users using PowerShell7+ can use the same command.

```Bash
which segul
```

On Windows Command Prompt, you can use `Get-Command` or `where` command.

```Bash
Get-Command segul
```

If the path contains `~/.cargo/bin` or `~/cargo/bin`, your SEGUL binary is installed using Cargo. You can update it by running the following command:

```Bash
cargo install segul
```

If the path contains `/usr/local/bin`, `/usr/bin`, or `/bin`, your SEGUL binary is installed using pre-compiled binaries. You will need to download the latest binary from the [release page](https://github.com/hhandika/segul/releases/latest/). After downloading the binary, replace the old binary with the new one.

If the path contains `miniforge` or `conda`, your SEGUL binary is installed using Conda. You can update it by running the following command:

```Bash
conda update segul
```

or with mamba:

```Bash
mamba update segul
```

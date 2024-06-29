---
sidebar_position: 3
---

# CLI Pre-compiled Binary

The pre-compiled binary is available in the [release page](https://github.com/hhandika/segul/releases/latest). To install it, the typical workflow is as follow:

1. Download the compressed executable file (.zip or .tar.gz) in [the release page](https://github.com/hhandika/segul/releases/) to your computer, either using a browser or using a command line app.
2. Extract the file.
3. Optionally, make the binary executable (Linux and MacOS only).
4. Put it in a folder registered in your environment variable. It can be run from the folder where you extract the app too, but this option is less convenient when dealing with datasets in different folders or storage partitions.

See specific details below:

- [Linux/WSL](#linuxwsl)
- [macOS](#macos)
- [Windows](#windows)

## Linux/WSL

SEGUL is highly optimized to be as fast and efficient as possible. For this reason, we provide two versions of the app for Linux:

- **Fully static executable** using [musl libc](https://musl.libc.org/). This version is suitable for running the app on old Linux distributions or some HPC systems. The file is named `segul-Linux-musl-x86_64.tar.gz` ([download](https://github.com/hhandika/segul/releases/latest/download/segul-Linux-musl-x86_64.tar.gz)).
- **Dynamically linked executable** using [glibc](https://www.gnu.org/software/libc/). This version is suitable for running the app on modern Linux distributions. The file is named `segul-Linux-x86_64.tar.gz` ([download](https://github.com/hhandika/segul/releases/latest/download/segul-Linux-x86_64.tar.gz)).

:::info
Since version 0.21.3, the CLI binary is also available for ARM64 architecture on Linux. The file is named `segul-Linux-arm64.tar.gz` ([download](https://github.com/hhandika/segul/releases/latest/download/segul-Linux-arm64.tar.gz)).
:::

:::tip
When installing SEGUL in the [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/install-win10), consider that if your files are large and are stored in the Windows partition, WSL 1 will be 2-3 times faster than WSL 2. If you prefer to use WSL 2, which is the default option, it is advisable to store your data in the Linux partition. Learn more about the differences from [Microsoft WSL Guidelines](https://docs.microsoft.com/en-us/windows/wsl/compare-versions).
:::

If you are not sure which version of SEGUL to use on Linux, check the GLIBC version:

```python
ldd --version
```

Output example:

```python
# ldd (Ubuntu GLIBC 2.35-0ubuntu3.1) 2.35
# Copyright (C) 2022 Free Software Foundation, Inc.
# This is free software; see the source for copying conditions.  There is NO
# warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# Written by Roland McGrath and Ulrich Drepper.
```

If your version is **glibc 2.17** or higher, you can use the version labeled `Linux`. If your version is older, you should use the version labeled `Linux-musl`.

:::info
We recommend using the dynamically linked executable version if your OS has the supported GLIBC version. It is more optimized by the compiler, which in theory will be faster than the static binary version. See Rust platform [tier list](https://forge.rust-lang.org/platform-support.html) for more information.
:::

### Installing Linux binary

#### Download the compressed Linux executable

Use your terminal app to download the file from the release page. You can use `wget` or `curl` to download the file. The example below is for the **dynamically linked executable** version. Replace the file name with the version you want to download.

```Bash
wget https://github.com/hhandika/segul/releases/latest/download/segul-Linux-x86_64.tar.gz
```

Or using curl:

```Bash
curl -LJO https://github.com/hhandika/segul/releases/latest/download/segul-Linux-x86_64.tar.gz
```

#### Decompress Linux executable

```Bash
tar xfvz segul-Linux-x86_64.tar.gz
```

#### Make the binary executable for Linux (optional)

It may not be necessary. However, if your terminal app does not recognize the binary, you can try this step.

```Bash
chmod +x segul
```

If you would like the binary executable for all users:

```Bash
chmod a+x segul
```

#### Put it in a folder registered in your Linux PATH variable

If you already has a PATH registered in your environment variable, put the executable in the folder. If you don't have one yet, you can create a new folder in your home directory and put the executable in it. Then, add the path to the folder to your PATH variable. To do this, on your terminal, type:

```Bash
which $SHELL
```

If it shows `bash`, add the following line to your `.bashrc` file or `.bash_profile`, whichever is available in your system. If it shows `zsh`, add the line to your `.zshrc` file.

```Bash
export PATH=$PATH:/path/to/segul/folder
```

For example, if you put the SEGUL executable in the `~/bin` folder, add the following line to your `.bashrc` file:

```Bash
export PATH=$PATH:~/bin
```

Then, run the following command to apply the changes. Change the file name if you use `.zshrc` or `.bash_profile`.

```Bash
source ~/.bashrc
```

:::tip
To check which bash profile file is available in your home directory, you can use the following command:

Make sure you are in your home directory or `cd ~`. Then, run:

```Bash
ls -a .
```

It will show all files in your home directory, including hidden files. Look for `.bashrc`, `.bash_profile`, or `.zshrc`. If you don't have any of these files, you can create one.

```Bash
touch .bashrc
```

Then, add the export PATH line to the file.
:::

#### Check the installation

Try call SEGUL from anywhere in your system:

```Bash
segul --version
```

It should show the SEGUL version number.

## macOS

For macOS, the executables are available for Intel Macs and Apple ARM M series processor.

- **Intel Macs**. The file is named `segul-macOS-x86_64.tar.gz` ([download](https://github.com/hhandika/segul/releases/latest/download/segul-macOS-x86_64.tar.gz)).
- **Apple ARM M series CPUs**. The file is named `segul-macOS-arm64.tar.gz` ([download](https://github.com/hhandika/segul/releases/latest/download/segul-macOS-x86_64.tar.gz)).

### Installing MacOS binary

#### Download the compressed MacOS executable

Similar to the Linux version, you can use `wget` or `curl` to download the file.

```Bash

wget https://github.com/hhandika/segul/releases/latest/download/segul-macOS-arm64.tar.gz
```

Or using curl:

```Bash
curl -LJO https://github.com/hhandika/segul/releases/latest/download/segul-macOS-arm64.tar.gz
```

#### Decompress MacOS executable

```Bash
tar xfvz segul-macOS-arm64.tar.gz
```

#### Make the binary executable for MacOS (optional)

This step may not be necessary. However, if your terminal app does not recognize the binary, you can try this step.

```Bash
chmod +x segul
```

If you would like the binary executable for all users:

```Bash
chmod a+x segul
```

#### Put it in a folder registered in your macOS PATH variable

Recent macOS versions use zsh as the default shell. If you are using zsh, you can add the path to the folder where you put the SEGUL executable to your PATH variable by adding the following line to your `.zshrc` file:

```Bash
export PATH=$PATH:/path/to/segul/folder
```

Copy SEGUL executable to the folder. Then, try call SEGUL from anywhere in your system:

```Bash
segul --version
```

It should show the SEGUL version number.

:::tip
It is best to avoid registering too many paths in your environment variable. It will slow down your terminal startup. If you already used a single executable cli app, the chance is that you may already have a folder registered in your path variable. Copy `segul` executable to the folder instead. For MacOS users, we recommend using [iTerm2](https://iterm2.com/) or [warp](https://www.warp.dev/) for easier navigation in the Terminal.
:::

## Windows

This instruction is for running SEGUL native on Windows. If you are using WSL, install the Linux version of the app by following [the Linux installation guideline](#installing-linux-binary). However, running SEGUL on native Windows is more efficient due to a better access to the hardware than the WSL. The installation procedure is similar to the MacOS or Linux. Keep in mind that, the Windows executable is compressed in a zip file. After downloading the zip file and extracting it, you will setup your environment variable pointing to the path where you will put the executable. In Windows, this is usually done using GUI.

### Installing Windows binary

#### Download segul-Windows-x86_64.zip

Download the compressed Windows executable: `segul-Windows-x86_64.zip` ([download](https://github.com/hhandika/segul/releases/latest/download/segul-Windows-x86_64.zip)).

#### Decompress Windows executable

Windows has a built-in feature for zip decompression. You can right-click the file and select `Extract All...` from the context menu. You can also use third-party apps like [7zip](https://www.7-zip.org/download.html).

After decompressing the file, you will find the `segul.exe` file. You can put it in a folder registered in your environment variable. Create a new folder if you don't have one yet. Then, put the `segul.exe` file in the folder.

#### Setup the environment variable

Click search and type `env`. Select `Edit the system environment variables`. Then, click `Environment Variables...` button. In the `System variables` section, select `Path` and click `Edit...` button. Click `New` and add the path to the folder where you put the SEGUL executable. Click `OK` to close the dialog boxes.

- Open a new terminal and try to call SEGUL from anywhere in your system:

```Bash
segul --version
```

:::tip
We recommend using a combination of [Windows Terminal](https://learn.microsoft.com/en-us/windows/terminal/install) and [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3) for easy navigation in the terminal. Windows terminal comes pre-installed on Windows 11. It is available on Microsoft Store for Windows 10 users.
:::

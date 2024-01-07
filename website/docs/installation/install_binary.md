---
sidebar_position: 3
---

# CLI Pre-compiled Binary

The pre-compiled binary is available in [the release page](https://github.com/hhandika/segul/releases/). To install it, the typical workflow is as follow:

1. Download the compressed executable file (.zip or .tar.gz) in [the release page](https://github.com/hhandika/segul/releases/) to your computer, either using a browser or using a command line app.
2. Extract the file.
3. Make the binary executable (Linux and MacOS only).
4. Put it in a folder registered in your environment variable. It can be run from the folder where you extract the app too, but this option is less convenient when dealing with datasets in different folders or storage partitions.

See specific details below:

## Linux/WSL/MacOS

We provide two versions of the app for Linux. The zip file labeled with `musl` is a fully static library. If you are running the app in HPC, you should use this version. The other version (labeled `Linux` only) is compiled using [Ubuntu 20.04 LTS (Kernel version 5.8)](https://github.com/actions/virtual-environments/blob/main/images/linux/Ubuntu2004-README.md). You should use this version if you are using a more up to date Linux distribution. This version also works on WSL. In simple words, if you encounter [GLIBC](https://www.gnu.org/software/libc/) error, try using the `musl` version. If the issue still persists, try to [install the app using cargo](https://docs.page/hhandika/segul-docs/install_cargo).

For MacOS, the executables are available for Intel Macs and Apple ARM Macs, such as Apple M1 series. The ARM version is labeled with `arm64`. If you are using an Intel Mac, you should use the version labeled with `x86_64`.

Here, we use the version 0.18.1 as an example. You should replace the link with the most up to date version available in the release page.

- Download the binary.

```Bash

wget https://github.com/hhandika/segul/releases/download/v0.18.1/segul-macOS-arm64.tar.gz
```

- Unzip the file.

```Bash
tar xfvz segul-macOS-arm64.tar.gz
```

- Make it executable. This step may not be necessary. However, if your terminal app does not recognize the binary, you can try this step.

```Bash
chmod +x segul
```

If you would like the binary executable for all users:

```Bash
chmod a+x segul
```

The next step is putting the binary in a folder registered in your PATH variable. Copy SEGUL executable to the folder. Then, try call SEGUL from anywhere in your system:

```Bash
segul --version
```

It should show the SEGUL version number.

> **Pro Tips**:
> It is best to avoid registering too many paths in your environment variable. It will slow down your terminal startup. If you already used a single executable cli app, the chance is that you may already have a folder registered in your path variable. Copy `segul` executable to the folder instead. For MacOS users, we recommend using [iTerm2](https://iterm2.com/) for easier navigation in the Terminal.

## Windows

This instruction is for running SEGUL native on Windows. If you are using WSL, you install the Linux version of the app by following the instruction above. However, running SEGUL on native Windows is more efficient due to a better access to the hardware than the WSL. The installation procedure is similar to the MacOS or Linux. After downloading the zip file for Windows and extracting it, you will setup your environment variable pointing to the path where you will put the executable. In Windows, this is usually done using GUI. Follow this amazing guideline from the stakoverflow [to setup the environment variable](https://stackoverflow.com/questions/44272416/how-to-add-a-folder-to-path-environment-variable-in-windows-10-with-screensho). After setup, copy the segul.exe file to the folder.

> **Windows Pro Tips**:
> We recommend using a combination of [Windows Terminal](https://learn.microsoft.com/en-us/windows/terminal/install) and [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3) for easy navigation in the terminal. Windows terminal comes pre-installed on Windows 11. It is available on Microsoft Store for Windows 10 users. You can also use [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to run the Linux version of SEGUL. Keep in mind that, if your data is big and it is in the Windows partition, WSL 1 will be 2-3 times faster than WSL 2. If you are using WSL 2, you should put your data in the Linux partition. Learn more about WSL [here](https://docs.microsoft.com/en-us/windows/wsl/compare-versions).

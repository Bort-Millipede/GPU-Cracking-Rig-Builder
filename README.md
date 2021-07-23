**July 2021 Note:** The original developer has determined that this project has reached its maximum usefulness, and as such there are currently no future plans to actively update or maintain this project after this date.

# GPU Cracking Rig Builder
Bash scripts to automatically setup a GPU cracking rig from a base-install of a 64-bit Debian-based Linux installation. Support is limited to 64-bit Debian-based Linux (see [Development Notes](#development-notes) for distributions tested) systems with installed NVIDIA GPUs only. There are 3 scripts (referred to as "Stages"), each accomplishing the following goals:

* Stage 1: Remove multiarch (32-bit) support from operating system (if enabled), and install all available updates. After execution, a system reboot is required.
* Stage 2: Install NVIDIA driver prerequisites, remove all currently-installed "nvidia" packages (if any), then:
	* If Nouveau driver is detected, blacklist Nouveau driver. After execution, a system reboot and another execution of Stage 2 will be required.
	* Otherwise, install latest NVIDIA drivers.
* Stage 3: Build hashcat from source with GPU support and install; Build John the Ripper from source with GPU support and install (to /usr/share/john); install [hashid](https://github.com/psypanda/hashID); create directory for wordlists (/usr/share/wordlists) if not already created.

Drivers and tools installed by Stages 2 and 3 can also be updated to new versions (as they become available) by re-executing the Stages at a later time (see [Updating Drivers and Tools](#updating-drivers-and-tools)).

# Usage
1. Ensure the proper physical installation of NVIDIA GPU(s) in the system (the Stages perform minimal verification of this).
2. Download the project master.zip, extract, navigate to the GPU-Cracking-Rig-Builder and add execute permissions to the Stage scripts.
	1. (Execute as root) ```apt install -y git```
	2. ```git clone https://github.com/Bort-Millipede/GPU-Cracking-Rig-Builder.git```
	3. ```cd GPU-Cracking-Rig-Builder```
	4. ```chmod +x *.sh```
3. Execute Stage 1 (gpucrack-stage1.sh) as root (or with sudo) and reboot.
4. Execute Stage 2 (gpucrack-stage2.sh) as root (or with sudo). If instructed at the end of execution, reboot and re-execute Stage 2 as root (or with sudo).
5. Execute Stage 3 (gpucrack-stage3.sh) as root (or with sudo).
6. (Recommended) Run test suites of both hashcat and John the Ripper (will likely take a long time to complete!):
	1. ```hashcat --benchmark```
	2. ```cd /usr/share/john; ./john --test=0 --format=opencl```
		* NOTE: This will only test John the Ripper with GPU-enabled crack formats with the first GPU. To test additional GPUs, consult the [John the Ripper GPU page](https://openwall.info/wiki/john/GPU)
7. To use hashcat, execute ```hashcat ...``` from any location. To use John the Ripper: ```cd /usr/share/john; ./john ...```. See [GPU Fan Control](#gpu-fan-control) for additional usage notes.

## Command-Line Options
The following command line options are available for the Stage scripts:
* ```--verbose``` (all Stages): Verbose script output. By default, the Stages attempt to suppress most command output (within reason) and execute as "quietly" as possible. Use this option to enable full output during script execution.
* ```--keep-tmp``` (Stages 2 and 3): Do not remove the temporary directory (and all its contents) after successful Stage completion. Stages 2 and 3 create a temporary "gpucrack-tmp" directory for storing the NVIDIA driver installer and the build directories (hashcat, rexgen, john), which is subsequently deleted after the successful completion of each Stage. Use this option to keep the "gpucrack-tmp" directory after Stage execution.
* ```--force-rexgen``` (Stage 3): Overwrite current rexgen installation with rexgen v2.0.9 ([commit 5b2f4b159ec948c1f9429eca4389ca2adc9c0b07](https://github.com/janstarke/rexgen/tree/5b2f4b159ec948c1f9429eca4389ca2adc9c0b07), the last known commit to be compatible with John the Ripper), even if the current installation is detected to be rexgen v2.0.9.

## GPU Fan Control
Hashcat and John the Ripper do not perform adequate automatic control of onboard GPU fans, which often results in the GPU(s) eventually reaching high temperature(s) and overheating. While methods are available to better control GPU fans and prevent overheating, these methods are not covered by the Stages or anything else provided by this project! The developer assumes no responsibility for any damage caused to systems or hardware by using this software without addressing inadequate automatic GPU fan control.

One possible method (used by the developer with positive results) for addressing automatic fan control is:

* [coolgpus](https://github.com/andyljones/coolgpus)

## Updating Drivers and Tools
If the existing NVIDIA driver, hashcat, and John the Ripper installations on the system were originally installed via Stages 2 and 3, these installations can be updated to the latest versions at any time by:
* Re-executing Stage 2 to update the NVIDIA drivers
* Re-executing Stage 3 to update hashcat and John the Ripper

Updating existing installations of the drivers or tools that were NOT installed by the Stages is untested, and the developer makes no promises of support for this.

# Development Notes
The bash scripts were developed and tested using the following setup:

* HP Z800 Server Workstation with dual NVIDIA Quadro K600 GPUs installed.
* VMWare ESXi 6.7 installed, "Hardware Passthrough" configured for both NVIDIA cards.
* VMs created with the following specifications/configurations:
	* 4 or more CPUs
	* 32GB or higher Memory
	* One of the following Operating Systems (without a GUI or X server installed):
		* 64-bit Ubuntu Server 20.04
		* 64-bit Ubuntu Server 18.04
		* 64-bit Debian 10.4
	* Configuration parameter ```hypervisor.cpuid.v0 = FALSE``` added to VMs in order to allow the NVIDIA cards to function properly.

Resources leveraged during development are as follows:

* [https://hashcat.net/wiki/doku.php?id=linux_server_howto](https://hashcat.net/wiki/doku.php?id=linux_server_howto)
* [https://github.com/hashcat/hashcat/blob/master/BUILD.md](https://github.com/hashcat/hashcat/blob/master/BUILD.md)
* [https://openwall.info/wiki/john/GPU](https://openwall.info/wiki/john/GPU)
* [https://openwall.info/wiki/john/tutorials/Ubuntu-build-howto](https://openwall.info/wiki/john/tutorials/Ubuntu-build-howto)
* [https://help.ubuntu.com/community/NvidiaManual](https://help.ubuntu.com/community/NvidiaManual)
* [https://github.com/magnumripper/JohnTheRipper/blob/bleeding-jumbo/doc/INSTALL-UBUNTU](https://github.com/magnumripper/JohnTheRipper/blob/bleeding-jumbo/doc/INSTALL-UBUNTU)
* [https://github.com/openwall/john/blob/bleeding-jumbo/doc/README.librexgen](https://github.com/openwall/john/blob/bleeding-jumbo/doc/README.librexgen)

## Desktop System Support
These scripts have not been thoroughly tested with systems running a graphical desktop environment! There is a distinct possibility that the NVIDIA drivers installed by Stage 2 will cause the graphical desktop to stop functioning properly unless the X server is reconfigured. The developer makes no promises of support for systems with a graphical desktop environment installed.

## Kali Linux Support
These scripts have NOT been thoroughly tested with Kali Linux! They may work fine on such systems (especially those without an installed X server), but the developer makes no promises of support for these.

# Disclaimer
The developer provides the software for free without warranty, and assumes no responsibility for any damage caused to systems or hardware by using the software. It is the responsibility of the user to abide by all local, state and federal laws while using the software.

# Copyright
(C) 2017, 2021 Jeffrey Cap (Bort-Millipede)


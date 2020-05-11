# GPU Cracking Rig Builder
Bash scripts to automatically setup a GPU cracking rig from a base-install of Ubuntu Server 64-bit. Support for 64-bit Ubuntu systems with installed NVIDIA GPUs only. There are 3 scripts (referred to as "stages"), each accomplishing the following goals:

* Stage 1: Remove multiarch (32-bit) support from operating system (if enabled), and install all available updates. After execution, a system reboot is required.
* Stage 2: Install NVIDIA driver prerequisites, remove all currently-installed nvidia packages (if any), then:
	* If Nouveau driver is detected, blacklist Nouveau driver. After execution, a system reboot and another execution of Stage 2 will be required.
	* Otherwise, install NVIDIA driver.
* Stage 3: Build hashcat from source with GPU support and install; Build John the Ripper from source with GPU support and install (to /usr/share/john); create directory for wordlists (/usr/share/wordlists) if not already created.

# Usage
1. Download the project master.zip, extract, navigate to the GPU-Cracking-Rig-Builder and add execute permissions to the stage scripts.
	1. (execute as root) ```apt install -y git```
	2. ```git clone https://github.com/Bort-Millipede/GPU-Cracking-Rig-Builder.git```
	3. ```cd GPU-Cracking-Rig-Builder```
	4. ```chmod +x *.sh```
2. Execute Stage 1 (gpucrack-stage1.sh) as root and reboot.
3. Execute Stage 2 (gpucrack-stage2.sh) as root. If instructed at the end of execution, reboot and re-execute Stage 2 as root.
4. Execute Stage 3 (gpucrack-stage3.sh) as root.
5. (Recommended) Run test suites of both hashcat and john (will likely take a long time to complete!):
	1. ```hashcat --benchmark```
	2. ```cd /usr/share/john; ./john --test=0 --format=opencl```
		* NOTE: This will only test john with GPU-enabled crack formats with the first GPU. To test additional GPUs, consult the John GPU page: [https://openwall.info/wiki/john/GPU](https://openwall.info/wiki/john/GPU)
6. To use hashcat, execute ```hashcat ...``` from any location. To use john: ```cd /usr/share/john; ./john ...```

## Command-Line Options
The following command line options are available for the stage scripts:
* ```--verbose``` (all stages): Verbose script output. By default, the stages attempt to suppress most command output (within reason) and execute as "quietly" as possible. Use this option to enable full output during script execution.
* ```--keep-tmp``` (stages 2 and 3): Do not remove the temporary directory (and all its contents) after successful script completion. Stages 2 and 3 create a temporary "gpucrack-tmp" directory for storing the NVIDIA driver installer and the build directories (hashcat, rexgen, john), which is subsequently deleted after successful script completion. Use this option to keep the "gpucrack-tmp" directory after completion.

# Development Notes
The bash scripts were developed and tested using the following setup:

* HP Z800 Server Workstation with dual NVIDIA Quadro K600 GPUs installed.
* VMWare ESXi 6.5 installed, "Hardware Passthrough" configured for both NVIDIA cards.
* VMs created with the following specifications/configurations:
	* 4 or more CPUs
	* 16GB or higher Memory
	* 64-bit Ubuntu Server 18.04 or 20.04 installed.
	* Configuration parameter ```hypervisor.cpuid.v0 = FALSE``` added to VM in order to allow the NVIDIA cards to function properly.

Resources leveraged during development are as follows:

* [https://hashcat.net/wiki/doku.php?id=linux_server_howto](https://hashcat.net/wiki/doku.php?id=linux_server_howto)
* [https://github.com/hashcat/hashcat/blob/master/BUILD.md](https://github.com/hashcat/hashcat/blob/master/BUILD.md)
* [https://openwall.info/wiki/john/GPU](https://openwall.info/wiki/john/GPU)
* [https://openwall.info/wiki/john/tutorials/Ubuntu-build-howto](https://openwall.info/wiki/john/tutorials/Ubuntu-build-howto)
* [https://help.ubuntu.com/community/NvidiaManual](https://help.ubuntu.com/community/NvidiaManual)
* [https://github.com/magnumripper/JohnTheRipper/blob/bleeding-jumbo/doc/INSTALL-UBUNTU](https://github.com/magnumripper/JohnTheRipper/blob/bleeding-jumbo/doc/INSTALL-UBUNTU)

# Disclaimer
The developer provides the software for free without warranty, and assume no responsibility for any damage caused to systems by using the software. It is the responsibility of the user to abide by all local, state and federal laws while using the software.

# Copyright
(C) 2017, 2018, 2020 Jeffrey Cap (Bort_Millipede)


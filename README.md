# GPU Cracking Rig Builder
Bash scripts to automatically setup a GPU cracking rig from a base-install of Ubuntu Server 64-bit. Support for 64-bit Ubuntu systems with installed NVIDIA GPUs only. There are 3 scripts (referred to as "stages"), each accomplishing the below goals:

* Stage 1: Remove multiarch (32-bit) support from operating system and install all available updates. After execution, a system reboot is required.
* Stage 2: Install build-essential and linux-headers packages and remove all currently-installed nvidia* packages, then:
	* If Nouveau driver is detected, blacklist Nouveau driver. After execution, a system reboot and another execution of Stage 2 will be required.
	* Otherwise, install NVIDIA driver.
* Stage 3: Build hashcat from source with GPU support and install; Build john from source with GPU support and install.

# Usage
1. Execute Stage 1 (gpucrack-stage1.sh) as root and reboot.
2. Execute Stage 2 (gpucrack-stage2.sh) as root. If instructed at the end of execution, reboot and re-execute Stage 2 as root.
3. Execute Stage 3 (gpucrack-stage3.sh) as root.
4. (Recommended) Run test suites of both hashcat at john (may take a while to complete)
	1. hashcat --benchmark
	2. cd /usr/share/john; ./john --test=0
5. To use hashcat, execute "hashcat ..." from any location. To use john, execute "./john ..." from /usr/share/john.

# Development Notes
The bash scripts were developed and tested using the following setup:

* HP Z800 Server Workstation with dual NVIDIA Quadro K600 GPUs installed.
* VMWare ESXi 6.5 installed, "Hardware Passthrough" configured for both NVIDIA cards.
* VM created with 8 CPUs, 16GB Memory, and Ubuntu Server 16.04.1 64-bit installed
	* Configuration parameter 'hypervisor.cpuid.v0 = "FALSE"' added to VM in order make NVIDIA cards work properly.

Resources leveraged during development are as follows:

* [https://hashcat.net/wiki/doku.php?id=linux_server_howto](https://hashcat.net/wiki/doku.php?id=linux_server_howto)
* [https://github.com/hashcat/hashcat/blob/master/BUILD.md](https://github.com/hashcat/hashcat/blob/master/BUILD.md)
* [http://openwall.info/wiki/john/GPU](http://openwall.info/wiki/john/GPU)
* [http://openwall.info/wiki/john/tutorials/Ubuntu-build-howto](http://openwall.info/wiki/john/tutorials/Ubuntu-build-howto)
* [https://help.ubuntu.com/community/NvidiaManual](https://help.ubuntu.com/community/NvidiaManual)

# Disclaimer
The developers provide the software for free without warranty, and assume no responsibility for any damage caused to systems by using the software. It is the responsibility of the user to abide by all local, state and federal laws while using the software.

# Copyright
(C) 2017 Jeffrey Cap (Bort_Millipede)
#! /bin/bash

# Stage 3 v0.1.3
# 5/X/2020

###start stage 3###
echo -e "GPU Password Cracking Rig Builder (NVIDIA only) v0.1.3"
echo -e "Jeffrey Cap (Bort-Millipede, https://twitter.com/Bort_Millipede)"
echo -e "\nStage 3: install hashcat and John the Ripper with GPU support, and create wordlists directory (if not already created)\n"

if [[ $EUID -ne 0 ]]
then
	echo -e "Error: This script must be executed as root! exiting..." 
	exit 1
fi

if [ "$(uname -m)" != "x86_64" ]
then
	echo -e "Error: this script is only compatible with 64-bit systems! exiting..."
	exit 1
fi

if [ ! -f "/etc/debian_version" ]
then
	echo -e "Error: this script is only compatible with Debian-based Linux systems! exiting..."
	exit 1
fi

apt-get -qq install `dpkg --get-selections | grep "install" | cut -f1 | head -n1` >/dev/null 2>&1
if [ $? -ne 0 ]
then
	echo -e "Possible error detected in the package manager! Ensure apt/dpkg are working properly and not in use by other processes, then try executing Stage 3 as root again!"
	exit 1
fi

VERBOSE=0
KEEPTMP=0
for var in "$@"
do
	if [ "$var" == "--verbose" ]
	then
		VERBOSE=1
	elif [ "$var" == "--keep-tmp" ]
	then
		KEEPTMP=1
	fi
done

TMP_DIR="gpucrack-tmp"
mkdir -p $TMP_DIR
ORIG_DIR=`pwd`
cd $TMP_DIR
TMP_DIR=`pwd`

if [ $VERBOSE -eq 1 ]
then
	apt-get install git -y
else
	apt-get install git -qq -y >/dev/null 2>&1
fi

#build/install hashcat#
echo -e "Building/installing hashcat..."
HC=-1
if [ $VERBOSE -eq 1 ]
then
	git clone https://github.com/hashcat/hashcat.git
else
	git clone -q https://github.com/hashcat/hashcat.git
fi
cd hashcat
if [ $VERBOSE -eq 1 ]
then
	git submodule update --init
	make clean
	make
	./hashcat -I
else
	git submodule -q update --init
	make -s clean
	make -s
	./hashcat -I >/dev/null 2>&1
fi
if [ $? -eq 255 ]
then
	echo -e "Error occurred in hashcat while attempting to communicate with installed GPU(s)!"
	echo -e "If this system is running inside an ESXi virtual machine, make sure that \"Hardware Passthrough\" is enabled for the GPU device(s) and that the following configuration parameter is added to this VM:"
	echo -e "\t\thypervisor.cpuid.v0 = FALSE"
else
	if [ $VERBOSE -eq 1 ]
	then
		make install
	else
		make -s install
	fi
	echo -e "hashcat built and installed system-wide successfully!\n"
	HC=0
fi
#end build/install hashcat#
cd $TMP_DIR


#build/install john#
JTR=-1
if [ $VERBOSE -eq 1 ]
then
	apt-get install -y libssl-dev yasm libgmp-dev libpcap-dev libnss3-dev libkrb5-dev pkg-config libbz2-dev zlib1g-dev opencl-headers ocl-icd-libopencl1 ocl-icd-opencl-dev nvidia-opencl-dev
else
	apt-get install -qq -y libssl-dev yasm libgmp-dev libpcap-dev libnss3-dev libkrb5-dev pkg-config libbz2-dev zlib1g-dev opencl-headers ocl-icd-libopencl1 ocl-icd-opencl-dev nvidia-opencl-dev
fi

REXGEN=1
which rexgen > /dev/null 2>&1
if [ $? -eq 0 ]
then
	VER=`rexgen -v 2>&1 | head -n1 | cut -d"-" -f 2`
	if [ "$VER" == "2.0.8" ]
	then
		REXGEN=0
	fi
fi
if [ $REXGEN -eq 1 ]
then
	echo -e "Building/installing Rexgen v2.0.8 for John the Ripper..."
	if [ $VERBOSE -eq 1 ]
	then
		apt-get install -y cmake bison flex
		git clone https://github.com/vay3t/rexgen-john.git rexgen
	else
		apt-get install -qq -y cmake bison flex
		git clone -q https://github.com/vay3t/rexgen-john.git rexgen
	fi
	cd rexgen/src/
	mkdir -p build
	cd build
	if [ $VERBOSE -eq 1 ]
	then
		cmake ..
		make
		make install
		ldconfig
	else
		cmake .. >/dev/null
		make -s >/dev/null
		make -s install >/dev/null
		ldconfig
	fi
	
	VER=`rexgen -v 2>&1 | head -n1 | cut -d"-" -f 2`
	if [ "$VER" == "2.0.8" ]
	then
		echo -e "Rexgen v2.0.8 installed!"
	else
		echo -e "Errors detected while building/installing Rexgen v2.0.8: John the Ripper will be built without Rexgen support"
		REXGEN=2
	fi
	cd $TMP_DIR
else
	echo -e "Rexgen v2.0.8 already installed, skipping!"
fi

echo -e "Building/installing John the Ripper..."
if [ $VERBOSE -eq 1 ]
then
	git clone git://github.com/magnumripper/JohnTheRipper -b bleeding-jumbo john
else
	git clone -q git://github.com/magnumripper/JohnTheRipper -b bleeding-jumbo john
fi
cd john/src
if [ $VERBOSE -eq 1 ]
then
	if [ $REXGEN -eq 2 ]
	then
		./configure
	else
		./configure --enable-rexgen
	fi
	make clean
	make -j4
else
	if [ $REXGEN -eq 2 ]
	then
		./configure --quiet
	else
		./configure --enable-rexgen --quiet
	fi
	make -s clean
	make -s -j4
fi
../run/john --list=opencl-devices 2>&1 | grep "No OpenCL-capable " >/dev/null
if [ $? -eq 0 ]
then
	echo -e "Error occurred in john while attempting to communicate with installed GPU(s)!"
	echo -e "If this system is running inside an ESXi virtual machine, make sure that \"Hardware Passthrough\" is enabled for the GPU device(s) and that the following lines are added to the .vmx file for this VM:"
	echo -e "\t\thypervisor.cpuid.v0 = FALSE"
else
	if [ $VERBOSE -eq 1 ]
	then
		make install
	else
		make -s install
	fi
	cd ../run
	mkdir -p /usr/share/john
	rm -rf /usr/share/john/*
	cp -prf * /usr/share/john/
	chmod -R a+w /usr/share/john
	echo -e "\njohn built and installed successfully to /usr/share/john!"
	JTR=0
fi
#end build/install john#

cd $ORIG_DIR

#create wordlists directory (if not already created)#
WORDLISTS=0
if [ ! -d /usr/share/wordlists ]
then
	mkdir -p /usr/share/wordlists
	chmod 777 /usr/share/wordlists
	echo -e "\nWordlists directory (/usr/share/wordlists) created!"
	WORDLISTS=1
fi
#end create wordlists directory#

if [ $HC -eq 0 ]
then
	echo -e "\nhashcat built and installed system-wide successfully!"
	echo -e "To ensure all is working, hashcat installation should be tested as follows (will likely take a long time to complete!):"
	echo -e "\thashcat --benchmark"
else
	echo -e "hashcat built successfully but was unable to communicate with GPU device(s), so was not installed. Please resolve this issue then re-execute stage 3 as root to install hashcat"
	echo -e "If this system is running inside an ESXi virtual machine, make sure that \"Hardware Passthrough\" is enabled for the GPU device(s) and that the following lines are added to the .vmx file for this VM:"
	echo -e "\t\thypervisor.cpuid.v0 = FALSE"
fi
if [ $JTR -eq 0 ]
then
	echo -e "\nJohn the Ripper built and installed to /usr/share/john successfully!"
	echo -e "To ensure all is working, the installation should be tested as follows (will likely take a long time to complete!):"
	echo -e "\tcd /usr/share/john\n\t./john --test=0 --format=opencl"
	echo -e "\t\tNOTE: This will only test GPU-enabled crack formats using the first GPU. To test additional GPUs, consult the John GPU page: https://openwall.info/wiki/john/GPU)"
else
	echo -e "John the Ripper built successfully, but was unable to communicate with GPU device(s), so was not installed. Please resolve this issue then re-execute stage 3 as root to install John the Ripper"
	echo -e "If this system is running inside an ESXi virtual machine, make sure that \"Hardware Passthrough\" is enabled for the GPU device(s) and that the following lines are added to the .vmx file for this VM:"
	echo -e "\t\thypervisor.cpuid.v0 = FALSE"
fi
if [ $HC -eq 0 ] && [ $JTR -eq 0 ]
then
	if [ $KEEPTMP -eq 0 ]
	then
		rm -rf $TMP_DIR
	else
		echo -e "\nStage 3 temporary files not removed, located at: $TMP_DIR"
	fi
	echo -en "\nStage 3 completed successfully! hashcat and john built and installed"
	if [ $WORDLISTS -eq 1 ]
	then
		echo -en ", and Wordlists directory created"
	fi
	echo -e "!"
else
	echo -e "\nStage 3 completed with errors. Please resolve the issue(s), then re-execute stage 3 as root to install hashcat and john"
fi

unset TMP_DIR
unset ORIG_DIR
unset HC
unset JTR
unset VERBOSE
unset KEEPTMP
unset REXGEN
###end stage 3###


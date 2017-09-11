#! /bin/bash

# Stage 3 v0.1.1
# 9/11/2017

###start stage 3###
echo -e "GPU Password Cracking Builder (NVIDIA only) v0.1"
echo -e "Jeffrey Cap (Bort-Millipede, https://twitter.com/Bort_Millipede)"
echo -e "\nStage 3: install hashcat and John The Ripper with GPU support\n"

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root! exiting..." 
   exit 1
fi

if [ "$(uname -m)" != "x86_64" ]
then
	echo "Error: this script is only compatible with 64-bit Debian-based Linux systems! exiting..."
	exit 1
fi

TMP_DIR="gpucrack-tmp"
mkdir -p $TMP_DIR
ORIG_DIR=`pwd`
cd $TMP_DIR
TMP_DIR=`pwd`

#build/install hashcat#
git clone https://github.com/hashcat/hashcat.git
cd hashcat
git submodule update --init
make
./hashcat -I
if [ $? -eq 255 ]
then
	echo -e "Error occurred in hashcat communicating with installed GPU(s)!"
	echo -e "If this system is running inside an ESXi virtual machine, make sure that \"Hardware Passthrough\" is enabled for the GPU device(s) and that the following lines are added to the .vmx file for this VM:"
	echo -e "\thypervisor.cpuid.v0 = \"FALSE\""
else
	make install
	echo -e "\nhashcat built and installed successfully!\n"
	HC=0
fi
#end build/install hashcat#
cd $TMP_DIR


#build/install john#
aptitude install -y libssl-dev yasm libgmp-dev libpcap-dev libnss3-dev libkrb5-dev pkg-config libbz2-dev zlib1g-dev subversion cmake bison flex

svn checkout https://github.com/teeshop/rexgen.git rexgen
cd rexgen/trunk/src/
mkdir -p build
cd build
cmake ..
make
make install
ldconfig
cd $TMP_DIR

aptitude install opencl-headers ocl-icd-libopencl1
aptitude download nvidia-opencl-dev
dpkg -i nvidia-opencl-dev*.deb

git clone git://github.com/magnumripper/JohnTheRipper -b bleeding-jumbo john
cd john/src
./configure
make -s clean
make -sj4
../run/john --list=opencl-devices 2>&1 | grep "No OpenCL-capable "
if [ $? -eq 0 ]
then
	echo -e "Error occurred in john communicating with installed GPU(s)!"
	echo -e "If this system is running inside an ESXi virtual machine, make sure that \"Hardware Passthrough\" is enabled for the GPU device(s) and that the following lines are added to the .vmx file for this VM:"
	echo -e "\thypervisor.cpuid.v0 = \"FALSE\""
else
	make -s install
	cd ../run
	mkdir -p /usr/share/john
	rm -rf /usr/share/john/*
	chmod -R +w /usr/share/john
	cp -rf * /usr/share/john/
	echo -e "\njohn built and installed successfully to /usr/share/john! To use john, navigate to /usr/share/john and execute:\n\t./john\n"
	JTR=0
fi
#end build/install john#

cd $ORIG_DIR

#create wordlists directory#
mkdir -p /usr/share/wordlists
chmod 777 /usr/share/wordlists
#end create wordlists directory#

if [ $HC -ne 0 ] && [ $JTR -ne 0 ]
then
	echo -e "\nhashcat and john built successfully, but unable to communicate with GPU device(s) so hashcat and john not installed. Please resolve this issue then re-execute stage 3 as root to install hashcat and john.\n"
else
	echo -e "\nStage 3 complete, hashcat and john installed successfully!\nTo ensure all is working, both installations should be tested as follows:"
	echo -e "\thashcat: hashcat --benchmark   #This will take a long time to complete!"
	echo -e "\tjohn: cd /usr/share/john; ./john --test=0   #This may take a long time to complete!"
	rm -rf $TMP_DIR
fi

unset TMP_DIR
unset ORIG_DIR
unset HC
unset JTR
###end stage 3###
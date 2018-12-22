 

#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2018 Yaroslav Furman (YaroST12)
#                    Adam W. Willis (0ctobot)

# Export fucking folders
kernel_dir="${PWD}"
objdir="${kernel_dir}/out"
builddir="${kernel_dir}/build"

# Export build variables
export CONFIG_FILE="neutrino_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_USER="0ctobot"
export CLANG_TRIPLE="aarch64-linux-gnu-"

# Home PC
CC="${HOME}/Android/toolchains/prebuilts/gcc/AOSP/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
CC_32="${HOME}/Android/toolchains/prebuilts/gcc/AOSP/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"
CT="${HOME}/Android/toolchains/prebuilts/clang/AOSP/clang-r346389b/bin/clang"
CT_BASE="${HOME}/Android/toolchains/prebuilts/clang/AOSP/clang-r346389b"
CT_BIN="${HOME}/Android/toolchains/prebuilts/clang/AOSP/clang-r346389b/bin"

TC="Android"
CC_VERSION=$($CT --version | grep -wo "clang version [0-9].[0-9].[0-9]")
CC_REVISION=$($CT --version | grep -wo "r[0-9]*" | head -1)
COMPILER="${TC} ${CC_VERSION}-${CC_REVISION}"

# Welcome to Hell

export LD_LIBRARY_PATH=${CT_BASE}/lib64:$LD_LIBRARY_PATH

# Colors
NC='\033[0m'
RED='\033[0;31m'
LRD='\033[1;31m'
LGR='\033[1;32m'
YEL='\033[1;33m'
check_everything()
{
	if [[ ! -d ${HOME}/Android/toolchains/ ]] || [[ ! -s ${CT} ]]; then
		completion "toolchains"
		exit
	fi
}
make_defconfig()
{
	# Needed to make sure we get dtb built and added to kernel image properly
	rm -rf ${objdir}/arch/arm64/boot/dts/
	echo -e ${LGR} "\r########### Generating Defconfig ############${NC}"
	make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE}
}
compile()
{
	export KBUILD_COMPILER_STRING="${COMPILER}"

	cd ${kernel_dir}
	echo -e ${LGR} "\r##### Compiling kernel with ${YEL}neutrino-clang-8.x${LGR} #####${NC}"
	PATH=${CT_BIN}:${PATH} make -s -j4 CC=clang CROSS_COMPILE=${CC} CROSS_COMPILE_ARM32=${CC_32} \
	O=${objdir} Image.gz-dtb
}
compile_gcc()
{
	cd ${kernel_dir}
	echo -e ${LGR} "\r######### Compiling kernel with GCC 8.2.0 #########${NC}"
	make -s -j9 CROSS_COMPILE=${CC} CROSS_COMPILE_ARM32=${CC_32} \
	O=${objdir} Image.gz-dtb
}
completion() 
{
	cd ${objdir}
	NO_IMAGE="### Build fuckedup, check warnings/errors ###"
	NO_TC="### Build fuckedup, toolchains are missing ##"
	COMPILED_IMAGE=arch/arm64/boot/Image.gz-dtb
	if [[ -f ${COMPILED_IMAGE} ]]; then
		mv -f ${COMPILED_IMAGE} ${builddir}/Image.gz-dtb
		echo -e ${LGR} "\r#############################################"
		echo -e ${LGR} "\r############## Build competed! ##############"
		echo -e ${LGR} "\r#############################################${NC}"
	else
		echo -e ${RED} "\r#############################################"
		if [ "$1" == toolchains ]; then
			echo -e ${RED} ${NO_TC}
		else
			echo -e ${RED} ${NO_IMAGE}
		fi
		echo -e ${RED} "\r#############################################${NC}"
	fi
}
check_everything
make_defconfig
if [ "$1" == gcc ]; then
compile_gcc
else
compile
fi
completion
cd ${kernel_dir}

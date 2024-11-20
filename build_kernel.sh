#!/bin/bash

#
# Rissu's kernel build script.
#

# COLORS SHEET
RED='\e[1;31m'
YELLOW='\e[1;33m'
NC='\e[0m'

pr_err() {
	echo -e "${RED}[ ERR ] $@${NC}";
	exit 1;
}
pr_warn() {
	echo -e "${YELLOW}[ WARN ] $@${NC}";
}
pr_info() {
	echo "[ INFO ] $@";
}


if [ -z $CROSS_COMPILE ]; then
	pr_err "Invalid empty variable for \$CROSS_COMPILE"
fi
if [ -z $PATH ]; then
	pr_err "Invalid empty variable for \$PATH"
fi
if [ -z $DEFCONFIG ]; then
	pr_err "Invalid empty variable for \$DEFCONFIG"
fi
if [[ "$KERNELSU" = "true" ]]; then
	curl -LSs "https://raw.githubusercontent.com/rsuntk/KernelSU/main/kernel/setup.sh" | bash -s main
else
	pr_info "KernelSU is disabled, export KERNELSU=true to enable it"
fi

export CC=clang
export LD=ld.lld
export KERNEL_OUT=$(pwd)/out

export ARCH=arm64
export ANDROID_MAJOR_VERSION=u
export PLATFORM_VERSION=14

export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

DATE=$(date +'%Y%m%d%H%M%S')
IMAGE="$KERNEL_OUT/arch/$ARCH/boot/Image"
RES="$(pwd)/result"

if [ -z $JOBS ]; then
	JOBS=$(nproc --all)
fi

# Build!
MKFLAG="-C $(pwd) --jobs $JOBS O=$KERNEL_OUT CC=clang LD=ld.lld KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y"

if [[ $COMPILE_WITH_LLVM = "true" ]]; then
	pr_info "Compiling with LLVM.."
	MKFLAG+=" LLVM=1"
	export LLVM=1
fi
if [[ $COMPILE_WITH_IAS = "true" ]]; then
	pr_info "Compiling with LLVM_IAS.."
	MKFLAG+=" LLVM_IAS=1"
	export LLVM_IAS=1
fi

__mk_defconfig() {
	make `echo $MKFLAG` `echo $DEFCONFIG`
}
__mk_kernel() {
	make `echo $MKFLAG`
}

mk_defconfig_kernel() {
	__mk_defconfig;
	__mk_kernel;
}

if [ -d $KERNEL_OUT ]; then
	pr_warn "An out/ folder detected, Do you wants dirty builds? (y/N)"
	read -p "" OPT;
	
	if [ $OPT = 'y' ] || [ $OPT = 'Y' ]; then
		__mk_kernel;
	else
		rm -rR out;
		make clean;
		make mrproper;
		mk_defconfig_kernel;
	fi
else
	mk_defconfig_kernel;
fi

if [ -e $IMAGE ]; then
	pr_info "Build done."
	cp $IMAGE AnyKernel3/
	cd AnyKernel3 && zip -r6 ../A042F-AnyKernel3_`echo $DATE`.zip *
 	if [[ $KBUILD_BUILD_HOST != "rsuntk_orgs" ]]; then
  		rm Image && cd ..
	fi
else
	pr_err "Build error."
fi

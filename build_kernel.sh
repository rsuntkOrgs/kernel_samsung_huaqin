#! /usr/bin/env bash

#
# Rissu's kernel build script.
#

On_Red='\033[41m'         # Red
On_Yellow='\033[43m'      # Yellow
BBlack='\033[1;30m'       # Black
BWhite='\033[1;37m'       # White
On_Blue='\033[44m'        # Blue
Color_Off='\033[0m'       # Text Reset

KERNELSU_REPO="https://raw.githubusercontent.com/rsuntk/KernelSU/main/kernel/setup.sh"

pr_info() {
	echo -e "${On_Blue}${BWhite}[  INFO  ]${Color_Off} $@"
}
pr_warn() {
	echo -e "${On_Yellow}${BBlack}[  WARN  ]${Color_Off} $@"
}
pr_err() {
	echo -e "${On_Red}${BWhite}[  ERROR  ]${Color_Off} $@"
}

if [ -z $CROSS_COMPILE ]; then
	pr_err "Invalid empty variable for \$CROSS_COMPILE"
elif [ -z $PATH ]; then
	pr_err "Invalid empty variable for \$PATH"
elif [ ! -z $PATH ]; then
	if ! command -v ld.lld; then
		pr_err "No clang toolchains! Do you set your \$PATH correctly?"
	fi
elif [ -z $DEFCONFIG ]; then
	pr_err "Invalid empty variable for \$DEFCONFIG"
fi

if [[ "$KERNELSU" = "true" ]]; then
	curl -LSs $KERNELSU_REPO | bash -s main
else
	pr_info "KernelSU is disabled, export KERNELSU=true to enable it"
fi

export CC=clang
export LD=ld.lld
export KERNEL_OUT=$(pwd)/out

export ARCH=arm64
export ANDROID_MAJOR_VERSION=u
export PLATFORM_VERSION=14
export TARGET_PRODUCT=a04

DATE=$(date +'%Y%m%d%H%M%S')
IMAGE="$KERNEL_OUT/arch/$ARCH/boot/Image"

if [ -z $JOBS ]; then
	JOBS=$(nproc --all)
fi

setconfig() { # fmt: setconfig enable/disable <CONFIG_NAME>
	if [ -d $(pwd)/scripts ]; then
		./scripts/config --file $KERNEL_OUT/.config --`echo $1` CONFIG_`echo $2`
	else
		pr_err "Folder scripts not found!"
	fi
}

# Make flags
MKFLAG="-C $(pwd) --jobs $JOBS O=$KERNEL_OUT CC=clang LD=ld.lld KCFLAGS=-w"

if [[ "$KERNELSU" = "true" ]]; then
	MKFLAG+= " CONFIG_KSU=y"
fi

if [[ "$LLVM" = "true" ]]; then
	MKFLAG+= " LLVM=1"
	pr_info "Compile with LLVM"

	export LLVM=1
	if [[ "$LLVM_IAS" = "true" ]]; then
		MKFLAG+= " LLVM_IAS=1"
		pr_info "Compile with LLVM Integrated Assembler"
		export LLVM_IAS=1
	fi
fi

build() {
	if [[ $@ = "defconfig" ]]; then
		make `echo $MKFLAG` `echo $DEFCONFIG`
	elif [[ $@ = "kernel" ]]; then
		make `echo $MKFLAG`
	else
		pr_err "Usage: build defconfig/kernel"
	fi
}

if [ -d $KERNEL_OUT ]; then
	pr_warn "An out/ folder detected, Do you wants dirty builds? (y/N)"
	read -p "" OPT;
	
	if [ $OPT = 'y' ] || [ $OPT = 'Y' ]; then
		build kernel;
	else
		rm -rR out;
		make clean;
		make mrproper;
		build defconfig
		if [[ "$KERNELSU" = "true" ]]; then
			setconfig enable KSU
		fi
		build kernel;
	fi
else
	build defconfig
	if [[ "$KERNELSU" = "true" ]]; then
		setconfig enable KSU
	fi
	build kernel;
fi

if [ -e $IMAGE ]; then
	pr_info "Build done."
	if [ -d $(pwd)/AnyKernel3 ]; then
		if [ ! -z $DEVICE ]; then
			DEVICE_MODEL="-`echo $DEVICE`"
		fi
		cp $IMAGE AnyKernel3/

		if [ -f $(pwd)/utsrelease.c ]; then
			gcc -CC utsrelease.c -o getutsrel
			UTSRELEASE=$(./getutsrel)
			sed -i "s/kernel\.string=.*/kernel.string=$UTSRELEASE/" "$(pwd)/AnyKernel3/anykernel.sh"
		fi
		kernelversion=$(make kernelversion)

		cd AnyKernel3 && zip -r9 ../AnyKernel3-`echo $kernelversion``echo $DEVICE_MODEL`_`echo $DATE`.zip *
	 	if [[ $IS_CI != "true" ]]; then
	  		rm Image && cd ..
		fi
	fi
else
	pr_err "Build error."
fi

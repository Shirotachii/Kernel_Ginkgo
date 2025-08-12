#!/bin/bash
# Edit by NekoTuru & AI
# Thanks for EdwinKJ

# Set up kernel directories and tools
SECONDS=0
kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
LOCAL_DIR="/workspace/ehhe"
TC_DIR="${LOCAL_DIR}/toolchain"
CLANG_DIR="${TC_DIR}/clang-rastamod"
ARCH_DIR="${TC_DIR}/aarch64-linux-android-4.9"
ARM_DIR="${TC_DIR}/arm-linux-androideabi-4.9"
export CONFIG_FILE="ginkgo_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST="Weeaboo"
export KBUILD_BUILD_USER="NekoTuru"
export PATH="$CLANG_DIR/bin:$ARCH_DIR/bin:$ARM_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$CLANG_DIR/lib:$LD_LIBRARY_PATH"
export KBUILD_BUILD_VERSION="1"

# Setup toolchains & optional KernelSU
setup() {
    if ! [ -d "${CLANG_DIR}" ]; then
        echo "Clang not found! Cloning to ${TC_DIR}..."
        if ! git clone --depth=1 -b clang-21.0 https://gitlab.com/kutemeikito/rastamod69-clang ${CLANG_DIR}; then
            echo "Cloning failed! Aborting..."
            exit 1
        fi
    fi

    if ! [ -d "${ARCH_DIR}" ]; then
        echo "gcc not found! Cloning to ${ARCH_DIR}..."
        if ! git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git ${ARCH_DIR}; then
            echo "Cloning failed! Aborting..."
            exit 1
        fi
    fi

    if ! [ -d "${ARM_DIR}" ]; then
        echo "gcc_32 not found! Cloning to ${ARM_DIR}..."
        if ! git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git ${ARM_DIR}; then
            echo "Cloning failed! Aborting..."
            exit 1
        fi
    fi

    if [[ $1 = "-k" || $1 = "--ksu" ]]; then
        echo -e "\nCleanup KernelSU first on local build\n"
        rm -rf KernelSU drivers/kernelsu

        echo -e "\nKSU Support, let's Make it On\n"
        curl -kLSs "https://raw.githubusercontent.com/OzoraID/KernelSU-Next/nongki-susfs/kernel/setup.sh" | bash -s nongki-susfs

        sed -i 's/CONFIG_KSU=n/CONFIG_KSU=y/g' arch/arm64/configs/ginkgo_defconfig
    else
        echo -e "\nKSU not Support, let's Skip\n"
    fi
}

# Clean build environment
clean_build() {
    echo ""
    echo "########### Starting build clean-up ###########"
    echo ""

    if [ -d "${objdir}" ]; then
        echo "Removing old build output from ${objdir}..."
        rm -rf ${objdir}
        if [ $? -eq 0 ]; then
            echo "Successfully removed old build output."
        else
            echo "Error: Failed to remove build output from ${objdir}."
            exit 1
        fi
    else
        echo "No previous build output found, skipping removal."
    fi

    if [ -f "${kernel_dir}/.config" ]; then
        echo "Cleaning kernel configuration files using make mrproper..."
        make mrproper -C ${kernel_dir}
        if [ $? -eq 0 ]; then
            echo "make mrproper completed successfully."
        else
            echo "Error: make mrproper failed."
            exit 1
        fi
    else
        echo "No existing .config file found, skipping make mrproper."
    fi

    echo ""
    echo "########### Build clean-up completed ###########"
    echo ""
}

# Generate defconfig
make_defconfig() {
    echo ""
    echo "########### Generating Defconfig ############"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc --all)
    echo "Defconfig generation completed."
    echo ""
}

# Compile kernel
compile() {
    cd ${kernel_dir}
    echo ""
    echo "######### Compiling kernel #########"
    echo ""
    make -j$(nproc --all) \
    O=${objdir} \
    ARCH=arm64 \
    CC=clang \
    LD=ld.lld \
    AR=llvm-ar \
    AS=llvm-as \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CROSS_COMPILE=$ARCH_DIR/bin/aarch64-linux-android- \
    CROSS_COMPILE_ARM32=$ARM_DIR/bin/arm-linux-androideabi- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    Image.gz-dtb \
    dtbo.img \
    CC="${CCACHE} clang" \
    $1
    echo ""
}

# Check if build succeeded
completion() {
    COMPILED_IMAGE=${objdir}/arch/arm64/boot/Image.gz-dtb
    COMPILED_DTBO=${objdir}/arch/arm64/boot/dtbo.img

    if [[ -f ${COMPILED_IMAGE} && -f ${COMPILED_DTBO} ]]; then
        echo ""
        echo "############################################"
        echo "####### Kernel Build Successful! ##########"
        echo "############################################"
        echo ""
    else
        echo ""
        echo "############################################"
        echo "##         Kernel Build Failed!           ##"
        echo "## Please check the build log for errors. ##"
        echo "############################################"
        echo ""
        exit 1
    fi
}

# Eksekusi urutan build
setup "$@"
clean_build
make_defconfig
compile
completion

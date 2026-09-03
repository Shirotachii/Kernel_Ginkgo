#!/bin/bash
# Edit by NekoTuru & AI
# Thanks for EdwinKJ

# Set up kernel directories and tools
SECONDS=0
kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
LOCAL_DIR="$(pwd)/.."
ZIPNAME="Will-Serfort-Ginkgo-$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M").zip"
ZIPNAME_KSU="Will-Serfort-Ginkgo-KSUNext-$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M").zip"
TC_DIR="${LOCAL_DIR}/toolchain"
CLANG_DIR="${TC_DIR}/clang"
ARCH_DIR="${TC_DIR}/aarch64-linux-android-4.9"
ARM_DIR="${TC_DIR}/arm-linux-androideabi-4.9"
export CONFIG_FILE="ginkgo_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST="SwordArtOnline"
export KBUILD_BUILD_USER="ShiroXD"
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
        curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s legacy
        
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
    
if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
git restore arch/arm64/configs/$DEFCONFIG
if [ -d "$AK3_DIR" ]; then
cp -r $AK3_DIR AnyKernel3
elif ! git clone --depth=1 -b ginkgo https://github.com/OzoraID/AnyKernel3; then
echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
exit 1
fi
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
rm -f *zip
cd AnyKernel3
git checkout master &> /dev/null
if [[ $1 = "-k" || $1 = "--ksu" ]]; then
zip -r9 "../$ZIPNAME_KSU" * -x '*.git*' README.md *placeholder
else
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
fi
cd ..
rm -rf AnyKernel3
rm -rf out/arch/arm64/boot
echo -e "Completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
else
echo -e "\nCompilation failed!"
fi
}

# Eksekusi urutan build
setup "$@"
clean_build
make_defconfig
compile
completion

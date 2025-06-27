#!/bin/bash
# Edit by NekoTuru & AI

# Set up kernel directories and tools
kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
CLANG_DIR=/home/neko/clang/bin
ARCH_DIR=/home/neko/arm64/bin
ARM_DIR=/home/neko/arm/bin
export CONFIG_FILE="ginkgo_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST="Weeaboo"
export KBUILD_BUILD_USER="NekoTuru"
export PATH="$CLANG_DIR:$ARCH_DIR:$ARM_DIR:$PATH"

# Function to clean the build environment
clean_build() {
    echo ""
    echo "########### Starting build clean-up ###########"
    echo ""

    # Remove old build output if it exists
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

    # Run make mrproper only if .config exists
    if [ -f "${kernel_dir}/.config" ]; then
        echo "Cleaning kernel configuration files using 'make mrproper'..."
        make mrproper -C ${kernel_dir}
        if [ $? -eq 0 ]; then
            echo "'make mrproper' completed successfully."
        else
            echo "Error: 'make mrproper' failed."
            exit 1
        fi
    else
        echo "No existing .config file found, skipping 'make mrproper'."
    fi

    echo ""
    echo "########### Build clean-up completed ###########"
    echo ""
}

# Function to generate defconfig
make_defconfig() {
    START=$(date +"%s")
    echo ""
    echo "########### Generating Defconfig ############"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc --all)
    echo "Defconfig generation completed."
    echo ""
}

# Function to compile kernel
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
    CROSS_COMPILE=$ARCH_DIR/aarch64-linux-android- \
    CROSS_COMPILE_ARM32=$ARM_DIR/arm-linux-androideabi- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    Image.gz-dtb \
    dtbo.img \
    CC="${CCACHE} clang" \
    $1
    echo ""
}

# Function to check compilation completion
completion() {
    COMPILED_IMAGE=${objdir}/arch/arm64/boot/Image.gz-dtb
    COMPILED_DTBO=${objdir}/arch/arm64/boot/dtbo.img

    # Check if compiled files exist
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

# Clean the build environment, generate defconfig, compile kernel, and check result
clean_build
make_defconfig
compile
completion

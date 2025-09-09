#!/bin/bash
# Edit by Neko

# Default Variant
VARIANT="Vanilla"

# Handle argumen
if [[ $1 == "--ksu" ]]; then
    VARIANT="KSUN"
elif [[ $1 == "--vanilla" ]]; then
    VARIANT="Vanilla"
fi

# Informasi Kernel
KERNEL_NAME="Kurumi Kernel"
NAME_KERNEL="Kurumi+"
BASE="Rebase×Pelt"
ANDROID="11-16"
KERNEL_DIR="$PWD"
KERNEL_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"
KERNEL_DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"
KBUILD_COMPILER_STRING=$(/workspace/ehhe/toolchain/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
AK3_DIR="$KERNEL_DIR/AK3"
PHONE="Redmi Note 8"
DEVICE="Ginkgo"
CHAT_ID="-1002377006405"
TOKEN="7634058501:AAH3Wdk16hD50nACQM8JfgJhVRdwQKMkK1o"

# Salin Image dan DTBO
copy() {
    for file in "$KERNEL_IMG" "$KERNEL_DTBO"; do
        if [ -f "$file" ]; then
            echo -e " Copy [$file] ke AnyKernel3..."
            cp "$file" "$AK3_DIR"
        else
            echo -e "\n❌ Image atau dtbo tidak ditemukan!"
            exit 1
        fi
    done
}

# Kompres jadi zip
main() {
    echo -e "\n📦 Membuat file ZIP..."
    cd "$AK3_DIR" || exit
    ZIP_NAME="${NAME_KERNEL}_${DEVICE}_${VARIANT}_$(date +'%d%m%Y_%H%M').zip"
    zip -r9 "$ZIP_NAME" ./*
    echo -e "\n✅ Sukses membuat: $ZIP_NAME"
}

# Kirim info ke Telegram
sendInfo() {
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage \
        -d chat_id=$CHAT_ID \
        -d "parse_mode=HTML" \
        -d text="$(
            for POST in "${@}"; do
                echo "${POST}"
            done
        )" &>/dev/null
}

# Kirim file ke Telegram
push() {
    if [ ! -f "$AK3_DIR/$ZIP_NAME" ]; then
        echo "❌ File ZIP tidak ditemukan: $ZIP_NAME"
        exit 1
    fi

    curl -F document=@"$AK3_DIR/$ZIP_NAME" "https://api.telegram.org/bot$TOKEN/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="It's time to brick | <b>${DEVICE}</b>"
}

# Akhiri
end() {
    echo ""
    echo "#####################"
    echo "   Lets Party Time   "
    echo "#####################"
    echo ""
}

# Kirim info duluan
sendInfo "<b>------ ${KERNEL_NAME} ------</b>" \
  "<b>Device:</b> <code>${PHONE}</code>" \
  "<b>Name:</b> <code>${NAME_KERNEL}</code>" \
  "<b>Base:</b> <code>${BASE}</code>" \
  "<b>Variant:</b> <code>${VARIANT}</code>" \
  "<b>Android:</b> <code>${ANDROID}</code>" \
  "<b>Commit:</b> <code>$(git log --pretty=format:'%h : %s' -2)</code>" \
  "<b>Compiler:</b> <code>${KBUILD_COMPILER_STRING}</code>"

# Eksekusi
copy
main
push
end

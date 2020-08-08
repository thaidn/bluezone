#!/bin/bash
# This is based on https://github.com/levyitay/AddSecurityExceptionAndroid.

set -e

readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f ~/.android/debug.keystore ]; then
  if [ ! -d ~/.android ]; then
    mkdir ~/.android
  fi
  echo "No debug keystore was found, creating new one..."
  keytool -genkey -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000
fi
readonly DEBUG_KEYSTORE=~/.android/debug.keystore

readonly TMP_DIR="$(mktemp -dt bluezone.XXXXXX)"
echo "Working dir is ${TMP_DIR}"


echo "Unpacking apks"

# Unpack apks
mkdir -p "${TMP_DIR}/base"
java -jar "${DIR}/apktool.jar" d -f -s -o "${TMP_DIR}/base" "apks/base.apk"

mkdir -p "${TMP_DIR}/lib"
java -jar "${DIR}/apktool.jar" d -f -s -o "${TMP_DIR}/lib" "apks/split_config.arm64_v8a.apk"

mkdir -p "${TMP_DIR}/vi"
java -jar "${DIR}/apktool.jar" d -f -s -o "${TMP_DIR}/vi" "apks/split_config.vi.apk"

mkdir -p "${TMP_DIR}/hdpi"
java -jar "${DIR}/apktool.jar" d -f -s -o "${TMP_DIR}/hdpi" "apks/split_config.xxhdpi.apk"

echo "Preparing the new apk"

# Merge apks
mv "${TMP_DIR}/lib/lib" "${TMP_DIR}/base/"
mv "${TMP_DIR}/vi/res/values-vi" "${TMP_DIR}/base/res/"
mv "${TMP_DIR}"/hdpi/res/values-* "${TMP_DIR}/base/res/"
mv "${TMP_DIR}"/hdpi/res/drawable* "${TMP_DIR}/base/res/"

# Overwrite Firebase settings to enable push notifications
cp "${DIR}/res/values/strings.xml" "${TMP_DIR}/base/res/values/"

# Overwrite misc static strings
cp "${DIR}/res/values/public.xml" "${TMP_DIR}/base/res/values/"

# Overwrite network security config to enable MiTM sniffing
cp "${DIR}/AndroidManifest.xml" "${TMP_DIR}/base/"
cp "${DIR}/network_security_config.xml" "${TMP_DIR}/base/res/xml/"

echo "Building the new APK"
java -jar "${DIR}/apktool.jar" empty-framework-dir --force "${TMP_DIR}/base/"
java -jar "$DIR/apktool.jar" b -o "bluezone.apk" "${TMP_DIR}/base/"
jarsigner -verbose -keystore "${DEBUG_KEYSTORE}" -storepass android -keypass android "bluezone.apk" androiddebugkey

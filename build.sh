#!/bin/bash -e
# dependencies: jdk11-openjdk imagemagick rsync

export APP_ID=org.shagu.mtgcounter
export APP_NAME=MTGCounter
export APP_ICON=res/logo.png

# prepare build directory
export BUILD_ROOT=$(pwd)
mkdir -p ${BUILD_ROOT}/tmp/android
cd ${BUILD_ROOT}/tmp/android

export ANDROID_COMPILE_SDK="30"
export ANDROID_BUILD_TOOLS="30.0.2"
export ANDROID_CMDLINE_TOOLS="8512546_latest"
export ANDROID_HOME=$PWD/android-sdk-linux
export ANDROID_SDK_ROOT="$PWD/android-sdk-linux/"
export ASSETS_DIR="${BUILD_ROOT}/tmp/android/love-android/app/src/embed/assets"
export APKSIGNER="${BUILD_ROOT}/tmp/android/android-sdk-linux/build-tools/${ANDROID_BUILD_TOOLS}/apksigner"
export PATH=$PATH:$PWD/android-sdk-linux/platform-tools/

# Fetch Android SDK
echo ":: Fetch & Setup Android SDK"
if ! [ -d ${BUILD_ROOT}/tmp/android/android-sdk-linux ]; then
  wget -q --show-progress --output-document=android-sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}.zip
  echo "  -> Fetch Android SDK"
  unzip -d android-sdk-linux android-sdk.zip > /dev/null
fi

# Enable Platforms in SDK
if ! [ -d ${BUILD_ROOT}/tmp/android/android-sdk-linux/platforms ]; then
  echo "  -> Enable Platforms in SDK"
  echo y | android-sdk-linux/cmdline-tools/bin/sdkmanager --sdk_root=android-sdk-linux "platforms;android-${ANDROID_COMPILE_SDK}" > /dev/null
fi

# Enable Platform-Tools in SDK
if ! [ -d ${BUILD_ROOT}/tmp/android/android-sdk-linux/platform-tools ]; then
  echo "  -> Enable Platform-Tools in SDK"
  echo y | android-sdk-linux/cmdline-tools/bin/sdkmanager --sdk_root=android-sdk-linux "platform-tools" > /dev/null
fi

# Enable Build-Tools in SDK
if ! [ -d ${BUILD_ROOT}/tmp/android/android-sdk-linux/build-tools ]; then
  echo "  -> Enable Build-Tools in SDK"
  echo y | android-sdk-linux/cmdline-tools/bin/sdkmanager --sdk_root=android-sdk-linux "build-tools;${ANDROID_BUILD_TOOLS}" > /dev/null
fi

# Enable Licenses in SDK
if ! [ -f ${BUILD_ROOT}/tmp/android/android-sdk-linux/licenses/google-gdk-license ]; then
  echo "  -> Enable Licenses in SDK"
  yes | android-sdk-linux/cmdline-tools/bin/sdkmanager --sdk_root=android-sdk-linux --licenses > /dev/null
fi

# Fetch the Love2D Android repositories
echo ":: Fetch Love2D Android"
if ! [ -d ${BUILD_ROOT}/tmp/android/love-android ]; then
  echo "  -> Clone"
  git clone --recurse-submodules https://github.com/love2d/love-android
  cd ${BUILD_ROOT}/tmp/android/love-android
else
  echo "  -> Update"
  cd ${BUILD_ROOT}/tmp/android/love-android
  git submodule sync --recursive
  git submodule update --init --force --recursive
fi

echo ":: Build Love2D APK"
echo "  -> Copy Assets"
rm -rf ${ASSETS_DIR}
rsync -a \
  --exclude 'tmp' \
  --exclude '.git*' \
  --exclude '*.jks' \
  --exclude '*.sh' \
  ${BUILD_ROOT}/ \
  ${ASSETS_DIR}

# add logo
echo "  -> Convert App Icon"
convert $BUILD_ROOT/${APP_ICON} -resize 42x42 app/src/main/res/drawable-mdpi/love.png
convert $BUILD_ROOT/${APP_ICON} -resize 72x72 app/src/main/res/drawable-hdpi/love.png
convert $BUILD_ROOT/${APP_ICON} -resize 96x96 app/src/main/res/drawable-xhdpi/love.png
convert $BUILD_ROOT/${APP_ICON} -resize 144x144 app/src/main/res/drawable-xxhdpi/love.png
convert $BUILD_ROOT/${APP_ICON} -resize 192x192 app/src/main/res/drawable-xxxhdpi/love.png

# rename
echo "  -> Rename Application"
sed -i "s/applicationId 'org.love2d.android'/applicationId '$APP_ID'/" app/build.gradle
sed -i "s/android:label=\"LÖVE for Android\"/android:label=\"$APP_NAME\"/" app/src/norecord/AndroidManifest.xml
sed -i "s/android:label=\"LÖVE for Android\"/android:label=\"$APP_NAME\"/" app/src/normal/AndroidManifest.xml
sed -i "s/android:label=\"LÖVE for Android\"/android:label=\"$APP_NAME\"/" app/src/main/AndroidManifest.xml

# perform build
echo "  -> Build Debug"
./gradlew assembleEmbedNoRecordDebug
./gradlew bundleEmbedNoRecordDebug

echo "  -> Build Release"
./gradlew assembleEmbedNoRecordRelease
./gradlew bundleEmbedNoRecordRelease

echo ":: Move Build Results"
rm -f ${BUILD_ROOT}/tmp/*.apk
cp -f ${BUILD_ROOT}/tmp/android/love-android/app/build/outputs/apk/embedNoRecord/debug/app-embed-noRecord-debug.apk ${BUILD_ROOT}/tmp/$APP_ID-debug.apk
cp -f ${BUILD_ROOT}/tmp/android/love-android/app/build/outputs/apk/embedNoRecord/release/app-embed-noRecord-release-unsigned.apk ${BUILD_ROOT}/tmp/$APP_ID-unsigned.apk

# sign APK if keystore is found
# keytool -genkey -v -keystore ${BUILD_ROOT}/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias shagu
if [ -f ${BUILD_ROOT}/keystore.jks ]; then
  echo ":: Sign APK"
  $APKSIGNER sign --ks ${BUILD_ROOT}/keystore.jks --out ${BUILD_ROOT}/tmp/${APP_ID}.apk ${BUILD_ROOT}/tmp/${APP_ID}-unsigned.apk
  $APKSIGNER verify ${BUILD_ROOT}/tmp/${APP_ID}.apk
fi

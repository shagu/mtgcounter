#!/bin/bash -e
# dependencies: jdk11-openjdk imagemagick

export APP_ID=org.shagu.mtgcounter
export APP_NAME=MTGCounter
export APP_ICON=res/logo.png

export BUILD_ROOT=$(pwd)

echo ":: Prepare Temporary Folders"
mkdir -p ${BUILD_ROOT}/tmp/android

echo ":: Clean & Build LOVE file"
echo "  -> Clean"
rm -rf ${BUILD_ROOT}/tmp/game*
echo "  -> Build Love2D File"
zip -9 -r ${BUILD_ROOT}/tmp/game.love . -x '*.git*' -x '*tmp/*'

echo ":: Fetch & Setup Android SDK"
cd ${BUILD_ROOT}/tmp/android
echo "  -> Set Environment"
export ANDROID_COMPILE_SDK="30"
export ANDROID_BUILD_TOOLS="30.0.2"
export ANDROID_CMDLINE_TOOLS="7583922_latest"
export ANDROID_HOME=$PWD/android-sdk-linux
export ANDROID_SDK_ROOT="$PWD/android-sdk-linux/"
#export JAVA_HOME=/usr/lib/jvm/default
export PATH=$PATH:$PWD/android-sdk-linux/platform-tools/

if ! [ -d ${BUILD_ROOT}/tmp/android/android-sdk-linux ]; then
  wget -q --show-progress --output-document=android-sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}.zip
  echo "  -> Extracting"
  unzip -d android-sdk-linux android-sdk.zip > /dev/null
fi

if ! [ -d ${BUILD_ROOT}/tmp/android/android-sdk-linux/platforms ]; then
  echo "  -> Platforms"
  echo y | android-sdk-linux/cmdline-tools/bin/sdkmanager --sdk_root=android-sdk-linux "platforms;android-${ANDROID_COMPILE_SDK}" > /dev/null
fi

if ! [ -d ${BUILD_ROOT}/tmp/android/android-sdk-linux/platform-tools ]; then
  echo "  -> Platform-Tools"
  echo y | android-sdk-linux/cmdline-tools/bin/sdkmanager --sdk_root=android-sdk-linux "platform-tools" > /dev/null
fi

if ! [ -d ${BUILD_ROOT}/tmp/android/android-sdk-linux/build-tools ]; then
  echo "  -> Build-Tools"
  echo y | android-sdk-linux/cmdline-tools/bin/sdkmanager --sdk_root=android-sdk-linux "build-tools;${ANDROID_BUILD_TOOLS}" > /dev/null
fi

if ! [ -f ${BUILD_ROOT}/tmp/android/android-sdk-linux/licenses/google-gdk-license ]; then
  echo "  -> Licenses"
  yes | android-sdk-linux/cmdline-tools/bin/sdkmanager --sdk_root=android-sdk-linux --licenses > /dev/null
fi

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
cp ${BUILD_ROOT}/tmp/game.love app/src/main/assets

# rename
sed -i "s/applicationId 'org.love2d.android'/applicationId '$APP_ID'/" app/build.gradle
sed -i "s/android:label=\"LÖVE for Android\"/android:label=\"$APP_NAME\"/" app/src/embed/AndroidManifest.xml
sed -i "s/android:label=\"LÖVE for Android\"/android:label=\"$APP_NAME\"/" app/src/main/AndroidManifest.xml

# add logo
convert $BUILD_ROOT/${APP_ICON} -resize 42x42 app/src/main/res/drawable-mdpi/love.png
convert $BUILD_ROOT/${APP_ICON} -resize 72x72 app/src/main/res/drawable-hdpi/love.png
convert $BUILD_ROOT/${APP_ICON} -resize 96x96 app/src/main/res/drawable-xhdpi/love.png
convert $BUILD_ROOT/${APP_ICON} -resize 144x144 app/src/main/res/drawable-xxhdpi/love.png
convert $BUILD_ROOT/${APP_ICON} -resize 192x192 app/src/main/res/drawable-xxxhdpi/love.png

# perform build
./gradlew assembleNormal

# release
#./gradlew assembleEmbedRelease
#./gradlew bundleEmbedRelease

echo ":: Move Build Results"
cp ${BUILD_ROOT}/tmp/android/love-android/app/build/outputs/apk/normal/debug/app-normal-debug.apk ${BUILD_ROOT}/tmp/$APP_ID-debug.apk

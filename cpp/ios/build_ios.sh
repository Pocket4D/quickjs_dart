
rm -fr build
mkdir build

cd build

cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=../ios.toolchain.cmake -DPLATFORM=OS64COMBINED
cmake --build . --config Release --target install

cd ..

DEVICE=$(xcodebuild -showsdks|grep "iphoneos"| awk '{print $4}')
ABI=$DEVICE sh cmd/ios_abi_build.sh

SIMU=$(xcodebuild -showsdks|grep "iphonesimulator"| awk '{print $6}')
ABI=$SIMU sh cmd/ios_abi_build.sh

cd build/output
cp -rf $DEVICE fat
lipo -create $DEVICE/Release/quickjs.framework/quickjs $SIMU/Release/quickjs.framework/quickjs -output fat/Release/quickjs.framework/quickjs

cd ../..

cp -rf build/output/fat/Release/quickjs.framework ../../ios
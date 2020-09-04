echo "build ios $ABI"
cd build

cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=../ios.toolchain.cmake -DPLATFORM=OS64COMBINED
cmake --build . --config Release --target install

# xcodebuild -project quickjs.xcodeproj -configuration Release -sdk $ABI -alltargets clean build
xcodebuild OTHER_CFLAGS="-fembed-bitcode" -project quickjs.xcodeproj -configuration Release -sdk $ABI -alltargets clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

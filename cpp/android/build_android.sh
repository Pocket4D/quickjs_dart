rm -rf ./build
a="armeabi-v7a arm64-v8a x86 x86_64"
for abi in $a;
do
export ABI=$abi
sh cmd/android.sh
done
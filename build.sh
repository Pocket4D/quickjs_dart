#!/bin/bash
rm -rf build &&
sh ./clean.sh &&
cd native_lib && 
# cmake -DCMAKE_SYSTEM_NAME=Android -DCMAKE_ANDROID_ARCH_ABI=armebi-v7a . &&
# make &&
# cd .. &&
# sh ./clean.sh &&
# cd native_lib &&
# cmake -DCMAKE_SYSTEM_NAME=Android -DCMAKE_ANDROID_ARCH_ABI=armebi . && 
# make && 
# cd .. && 
# sh ./clean.sh && 
# cd native_lib &&
# cmake -DCMAKE_SYSTEM_NAME=Android -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a . && 
# make &&
# cd .. && 
# sh ./clean.sh && 
# cd native_lib &&
# cmake -DCMAKE_SYSTEM_NAME=Android -DCMAKE_ANDROID_ARCH_ABI=x86 . && 
# make && 
cd .. && 
sh ./clean.sh && 
cd native_lib &&
cmake . && 
make &&
cd .. && 
sh ./clean.sh && 
cd native_lib &&
cmake -DBUILD_STATIC=yes . && 
make &&
cd .. && 
sh ./clean.sh && 
cd native_lib &&
cmake -DCMAKE_SYSTEM_NAME=Linux . && 
make 

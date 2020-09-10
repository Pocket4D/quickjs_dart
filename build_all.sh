#!/bin/bash
cd cpp && 
cd android && sh ./build_android.sh && cd ..
cd ios && sh ./build_ios.sh && cd ..
cd vm && sh ./build_vm.sh

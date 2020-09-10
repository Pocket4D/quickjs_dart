# QuickJS Dart

A dart binding for [QuickJS, a modern Javascript interpreter written in C by Fabrice Bellard](https://bellard.org/quickjs/)

We can run javascript VM embedded to DartVM, using [Dart:FFI](https://dart.dev/guides/libraries/c-interop)


## ENV requirement

1. dart lang 2.8+
2. clang
3. llvm(optional)
4. ios 9+
5. android api 21+

## Quick Start

```dart

// dart code

import 'package:quickjs_dart/quickjs_dart.dart';

void main(){

   JSEngine(); // initialize engine

   String jsString = r"""
      function testAdd(x,y){
         return x+y;
      }
      testAdd
   """
   var engine= JSEngine.instance; // singleton

   var testAdd = engine.evalScript(jsString);

   print(testAdd.isFunction()); // true
   
   var result= testAdd.callJS([engine.newInt32(12),engine.newInt32(34)]); // 2 params, 12 and 34;
   
   result.jsPrint(); // use `console.log` in javascript, 46 is the result;
}

```

## Table of Content


1. [QuickJS Dart](#quickjs-dart)
   1. [ENV requirement](#env-requirement)
   2. [Quick Start](#quick-start)
   3. [Table of Content](#table-of-content)
   4. [Build and Run (local machine only)](#build-and-run-local-machine-only)
   5. [Why not V8/jscore, and why QuickJS](#why-not-v8jscore-and-why-quickjs)
   6. [Why not PlatformChannel/MethodChannel and why Dart:FFI](#why-not-platformchannelmethodchannel-and-why-dartffi)
   7. [Docs and APIs](#docs-and-apis)

## Build and Run (local machine only)

1. build quickjs lib for ios/android/dartVM
   ```bash
   sh ~/.build_all.sh
   ```

   or build android only
   ```bash
   sh ~/.build_android.sh
   ```

   or bulid ios only
   ```bash
   sh ~/.build_ios.sh
   ```

2. run dart on dart vm
   ```dart
    dart main.dart
   ```
3. if you come up with `file system relative paths not allowed in hardened programs` with macos, run this
   ```bash
   codesign --remove-signature /usr/local/bin/dart
   ```
4. run flutter example, android or ios

   **note:** run `flutter doctor -v` to examine the flutter env is correctly

   Then you can run example app

   ```bash
   cd example && flutter run
   ```


## Why not V8/jscore, and why QuickJS
V8 is too big for small app and IOT devices.
jscore is a bit old and slow for modern app.

Quickjs follows latest [Javascript standard (ES2020) now](https://test262.report/). And it is fast enough, see [benchmark](https://bellard.org/quickjs/bench.html)


## Why not PlatformChannel/MethodChannel and why Dart:FFI
PlatformChannel/MethodChannel(s) are designed for communication, post and receive data, and use features that had been made by exisiting Android/iOS/Native modules. It's not managed by Dart/Flutter itself.

Using Dart:FFI, we get possibilities to expand the dart/flutter. We can call native function, back and forward, adding Callbacks, manage memory of functions and values.

## Docs and APIs
Do it later



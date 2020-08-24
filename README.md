# env requirement

1. dart lang 2.6+
2. clang
3. llvm(optional)

# build manual(local machine only, not optimized for linux)

1. build quickjs lib
   ```bash
   sh ~/.build.sh
   ```
2. run dart
   ```dart
    dart quickjs.dart
   ```
3. if you come up with `file system relative paths not allowed in hardened programs` with macos, run this
   ```bash
   codesign --remove-signature /usr/local/bin/dart
   ```



# env requirement

1. dart lang 2.8+
2. clang
3. llvm(optional)
4. ios 9+
5. android api 21+

# build manual(local machine only)

1. build quickjs lib for ios/android/dartVM
   ```bash
   sh ~/.build.sh
   ```
2. run dart on dart vm
   ```dart
    dart main.dart
   ```
3. if you come up with `file system relative paths not allowed in hardened programs` with macos, run this
   ```bash
   codesign --remove-signature /usr/local/bin/dart
   ```
4. run flutter example
   ```bash
   cd example && flutter run
   ```


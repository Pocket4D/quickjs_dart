import 'dart:ffi';

import '../core.dart';

typedef Dart_Sync_Handler(Pointer<JSContext> context, Pointer this_val, List<Pointer> args);

typedef Dart_Void_Handler(Pointer<JSContext> context, Pointer this_val, List<Pointer> args,
    int func_id, Pointer result_ptr);

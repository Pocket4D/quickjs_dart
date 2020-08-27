import 'dart:ffi';

import '../core.dart';

typedef Dart_Handler(Pointer<JSContext> context, Pointer this_val, List<Pointer> args, int func_id,
    Pointer result_ptr);

import 'dart:ffi';

import '../core.dart';

/// utils

/// JSValue *getGlobalObject(JSContext *ctx);
final Pointer Function(Pointer<JSContext> value) getGlobalObject = dylib
    .lookup<NativeFunction<Pointer Function(Pointer<JSContext>)>>('getGlobalObject')
    .asFunction();

// int definePropertyValue(JSContext *ctx, JSValueConst *this_obj,
//                            JSAtom *prop, JSValue *val, int flags);

final int Function(
        Pointer<JSContext> context, Pointer this_obj, Pointer prop, Pointer value, int flags)
    definePropertyValue = dylib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<JSContext>, Pointer this_obj, Pointer prop, Pointer value,
                    Int32 flags)>>('definePropertyValue')
        .asFunction();

// DART_EXTERN_C int setPropertyInternal(JSContext *ctx, JSValueConst *this_obj,
//                                       const JSAtom *prop, JSValue *val,
//                                       int flags)

final int Function(
        Pointer<JSContext> context, Pointer this_obj, Pointer prop, Pointer value, int flags)
    setPropertyInternal = dylib
        .lookup<
            NativeFunction<
                Int32 Function(Pointer<JSContext>, Pointer this_obj, Pointer prop, Pointer value,
                    Int32 flags)>>('setPropertyInternal')
        .asFunction();

// int setPropertyStr(JSContext *ctx, JSValueConst *this_obj,
//                    const char *prop, JSValue *val)

final int Function(
        Pointer<JSContext> context, Pointer this_obj, Pointer<Utf8Fix> prop, Pointer value)
    setPropertyStr = dylib
        .lookup<
            NativeFunction<
                Int32 Function(
          Pointer<JSContext>,
          Pointer this_obj,
          Pointer<Utf8Fix> prop,
          Pointer value,
        )>>('setPropertyStr')
        .asFunction();

// DART_EXTERN_C JSValue *getPropertyStr(JSContext *ctx, JSValueConst *this_obj,
//                                        const char *prop);

final Pointer Function(Pointer<JSContext> context, Pointer this_obj, Pointer<Utf8Fix> prop)
    getPropertyStr = dylib
        .lookup<
            NativeFunction<
                Pointer Function(
          Pointer<JSContext>,
          Pointer this_obj,
          Pointer<Utf8Fix> prop,
        )>>('getPropertyStr')
        .asFunction();

// DART_EXTERN_C void setProp(JSContext *ctx, JSValueConst *this_val, JSValueConst *prop_name, JSValueConst *prop_value,int flags);
final void Function(Pointer<JSContext> context, Pointer this_obj, Pointer prop_name,
        Pointer prop_value, int flags) setProp =
    dylib
        .lookup<
            NativeFunction<
                Void Function(Pointer<JSContext>, Pointer this_obj, Pointer prop_name,
                    Pointer prop_value, Int32 flags)>>('setProp')
        .asFunction();

// extractPointer
final Pointer Function(Pointer value) extractPointer = dylib
    .lookup<
        NativeFunction<
            Pointer Function(
      Pointer value,
    )>>('extractPointer')
    .asFunction();

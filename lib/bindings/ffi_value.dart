import 'dart:ffi';

import 'ffi_base.dart';
import 'util.dart';

final int Function(Pointer value) IsNan =
    dylib.lookup<NativeFunction<Int32 Function(Pointer)>>('isNan').asFunction();
// JS_BOOL isNumber(JSValueConst v);
final int Function(Pointer value) IsNumber =
    dylib.lookup<NativeFunction<Int32 Function(Pointer)>>('isNumber').asFunction();
// JS_BOOL isBigInt(JSContext *ctx, JSValueConst v);
final int Function(Pointer<JSContext> ctx, Pointer value) IsBigInt = dylib
    .lookup<NativeFunction<Int32 Function(Pointer<JSContext> ctx, Pointer)>>('isBigInt')
    .asFunction();
// JS_BOOL isBigFloat(JSValueConst v);
final int Function(Pointer value) IsBigFloat =
    dylib.lookup<NativeFunction<Int32 Function(Pointer)>>('isBigFloat').asFunction();
// JS_BOOL isBigDecimal(JSValueConst v);
final int Function(Pointer value) IsBigDecimal =
    dylib.lookup<NativeFunction<Int32 Function(Pointer)>>('isBigDecimal').asFunction();
// JS_BOOL isBool(JSValueConst v);
final int Function(Pointer value) IsBool =
    dylib.lookup<NativeFunction<Int32 Function(Pointer)>>('isBool').asFunction();
// JS_BOOL isNull(JSValueConst v);
final int Function(Pointer value) IsNull =
    dylib.lookup<NativeFunction<Int32 Function(Pointer)>>('isNull').asFunction();
// JS_BOOL isUndefined(JSValueConst v);
final int Function(Pointer value) IsUndefined =
    dylib.lookup<NativeFunction<Int32 Function(Pointer)>>('isUndefined').asFunction();
// JS_BOOL isUninitialized(JSValueConst v);
final int Function(Pointer value) IsUninitialized =
    dylib.lookup<NativeFunction<Int32 Function(Pointer)>>('isUninitialized').asFunction();
// JS_BOOL isString(JSValueConst v);
final int Function(Pointer value) IsString =
    dylib.lookup<NativeFunction<Int32 Function(Pointer)>>('isString').asFunction();
// JS_BOOL isSymbol(JSValueConst v);
final int Function(Pointer value) IsSymbol =
    dylib.lookup<NativeFunction<Int32 Function(Pointer)>>('isSymbol').asFunction();
// JS_BOOL isObject(JSValueConst v);
final int Function(Pointer value) IsObject =
    dylib.lookup<NativeFunction<Int32 Function(Pointer)>>('isObject').asFunction();
// JS_BOOL isError(JSContext *ctx, JSValueConst val);
final int Function(Pointer<JSContext> ctx, Pointer value) IsError = dylib
    .lookup<NativeFunction<Int32 Function(Pointer<JSContext>, Pointer)>>('isError')
    .asFunction();
// JS_BOOL isFunction(JSContext* ctx, JSValueConst val);
final int Function(Pointer<JSContext> ctx, Pointer value) IsFunction = dylib
    .lookup<NativeFunction<Int32 Function(Pointer<JSContext>, Pointer)>>('isFunction')
    .asFunction();
// JS_BOOL isConstructor(JSContext* ctx, JSValueConst val);
final int Function(Pointer<JSContext> ctx, Pointer value) IsConstructor = dylib
    .lookup<NativeFunction<Int32 Function(Pointer<JSContext>, Pointer)>>('isConstructor')
    .asFunction();
// int isArray(JSContext *ctx, JSValueConst val);
final int Function(Pointer<JSContext> ctx, Pointer value) IsArray = dylib
    .lookup<NativeFunction<Int32 Function(Pointer<JSContext>, Pointer)>>('isArray')
    .asFunction();
// int isExtensible(JSContext *ctx, JSValueConst obj);
final int Function(Pointer<JSContext> ctx, Pointer value) IsExtensible = dylib
    .lookup<NativeFunction<Int32 Function(Pointer<JSContext>, Pointer)>>('isExtensible')
    .asFunction();

// int getValueTag(JSValue v);
final int Function(Pointer value) GetValueTag =
    dylib.lookup<NativeFunction<Int32 Function(Pointer)>>('getValueTag').asFunction();
// void freeValue(JSContext *ctx, JSValue v);
final void Function(Pointer<JSContext> ctx, Pointer value) FreeValue = dylib
    .lookup<NativeFunction<Void Function(Pointer<JSContext>, Pointer)>>('freeValue')
    .asFunction();
// void freeValueRT(JSRuntime *rt, JSValue v);
final void Function(Pointer<JSRuntime> runtime, Pointer value) FreeValueRT = dylib
    .lookup<NativeFunction<Void Function(Pointer<JSRuntime>, Pointer)>>('freeValueRT')
    .asFunction();
// JSValue dupValue(JSContext *ctx, JSValueConst v);
final Pointer Function(Pointer<JSContext> ctx, Pointer value) DupValue = dylib
    .lookup<NativeFunction<Pointer Function(Pointer<JSContext>, Pointer)>>('dupValue')
    .asFunction();
// JSValue dupValueRT(JSRuntime *rt, JSValueConst v);
final Pointer Function(Pointer<JSRuntime> runtime, Pointer value) DupValueRT = dylib
    .lookup<NativeFunction<Pointer Function(Pointer<JSRuntime>, Pointer)>>('dupValueRT')
    .asFunction();

/// transformer
// int toBool(JSContext *ctx, JSValueConst val);
final int Function(Pointer<JSContext> ctx, Pointer value) ToBool = dylib
    .lookup<NativeFunction<Int32 Function(Pointer<JSContext>, Pointer)>>('toBool')
    .asFunction();
// int toInt32(JSContext *ctx, int32_t *pres, JSValueConst val);
final int Function(Pointer<JSContext> ctx, Pointer value) ToInt32 = dylib
    .lookup<NativeFunction<Int32 Function(Pointer<JSContext>, Pointer)>>('toInt32')
    .asFunction();
// int toUint32(JSContext *ctx, uint32_t *pres, JSValueConst val);
final int Function(Pointer<JSContext> ctx, Pointer<Uint32> pres, Pointer value) ToUint32 = dylib
    .lookup<NativeFunction<Int32 Function(Pointer<JSContext>, Pointer<Uint32>, Pointer)>>(
        'toUInt32')
    .asFunction();
// int toInt64(JSContext *ctx, JSValueConst val);
final int Function(Pointer<JSContext> ctx, Pointer value) ToInt64 = dylib
    .lookup<NativeFunction<Int64 Function(Pointer<JSContext> ctx, Pointer value)>>('toInt64')
    .asFunction();
// int toIndex(JSContext *ctx, uint64_t *plen, JSValueConst val);
final int Function(Pointer<JSContext> ctx, Pointer<Uint64> pres, Pointer value) ToIndex = dylib
    .lookup<NativeFunction<Int32 Function(Pointer<JSContext>, Pointer<Uint64>, Pointer)>>('toIndex')
    .asFunction();
// double toFloat64(JSContext *ctx, double *pres, JSValueConst val);
final double Function(Pointer<JSContext> ctx, Pointer value) ToFloat64 = dylib
    .lookup<NativeFunction<Double Function(Pointer<JSContext>, Pointer)>>('toFloat64')
    .asFunction();
// int toBigInt64(JSContext *ctx, int64_t *pres, JSValueConst val);
final int Function(Pointer<JSContext> ctx, Pointer<Int64> pres, Pointer value) ToBigInt64 = dylib
    .lookup<NativeFunction<Int32 Function(Pointer<JSContext>, Pointer<Int64>, Pointer)>>(
        'toBigInt64')
    .asFunction();
// int toInt64Ext(JSContext *ctx, int64_t *pres, JSValueConst val);
final int Function(Pointer<JSContext> ctx, Pointer<Int64> pres, Pointer value) ToInt64Ext = dylib
    .lookup<NativeFunction<Int32 Function(Pointer<JSContext>, Pointer<Int64>, Pointer)>>(
        'toInt64Ext')
    .asFunction();
// JSValue toString(JSContext *ctx, JSValueConst val);
final Pointer Function(Pointer<JSContext> ctx, Pointer value) ToString = dylib
    .lookup<NativeFunction<Pointer Function(Pointer<JSContext>, Pointer)>>('toString')
    .asFunction();
// JSValue toPropertyKey(JSContext *ctx, JSValueConst val);
final Pointer Function(Pointer<JSContext> ctx, Pointer value) ToPropertyKey = dylib
    .lookup<NativeFunction<Pointer Function(Pointer<JSContext>, Pointer)>>('toPropertyKey')
    .asFunction();
// const char *toCStringLen2(JSContext *ctx, size_t *plen, JSValueConst val1, JS_BOOL cesu8);
final Pointer<Utf8Fix> Function(
        Pointer<JSContext> ctx, Pointer<Int32> plen, Pointer value1, int cesu8) ToCStringLen2 =
    dylib
        .lookup<
            NativeFunction<
                Pointer<Utf8Fix> Function(
                    Pointer<JSContext>, Pointer<Int32>, Pointer, Int32)>>('toCStringLen2')
        .asFunction();
// const char *toCStringLen(JSContext *ctx, size_t *plen, JSValueConst val1);
final Pointer<Utf8Fix> Function(
    Pointer<JSContext> ctx,
    Pointer<Int32> plen,
    Pointer
        value1) ToCStringLen = dylib
    .lookup<NativeFunction<Pointer<Utf8Fix> Function(Pointer<JSContext>, Pointer<Int32>, Pointer)>>(
        'toCStringLen')
    .asFunction();
// const char *toCString(JSContext *ctx, JSValueConst val1);
final Pointer<Utf8Fix> Function(Pointer<JSContext> ctx, Pointer value1) ToCString = dylib
    .lookup<NativeFunction<Pointer<Utf8Fix> Function(Pointer<JSContext>, Pointer)>>('toCString')
    .asFunction();

// void freeCString(JSContext *ctx, const char *ptr);
final void Function(Pointer<JSContext> ctx, Pointer<Utf8Fix> ptr) FreeCString = dylib
    .lookup<NativeFunction<Void Function(Pointer<JSContext>, Pointer<Utf8Fix>)>>('freeCString')
    .asFunction();

// JSValue *parseJSON(JSContext *ctx, const char *buf, size_t buf_len,
//                      const char *filename);
final Pointer Function(Pointer<JSContext> ctx, Pointer<Utf8Fix> string_buff, int string_buff_length,
        Pointer<Utf8Fix> file_name) ParseJSON =
    dylib
        .lookup<
            NativeFunction<
                Pointer Function(Pointer<JSContext> ctx, Pointer<Utf8Fix> string_buff,
                    Int32 string_buff_length, Pointer<Utf8Fix> file_name)>>('parseJSON')
        .asFunction();
// JSValue *parseJSON2(JSContext *ctx, const char *buf, size_t buf_len,
//                       const char *filename, int flags);
final Pointer Function(Pointer<JSContext> ctx, Pointer<Utf8Fix> string_buff, int string_buff_length,
        Pointer<Utf8Fix> file_name, int flags) ParseJSON2 =
    dylib
        .lookup<
            NativeFunction<
                Pointer Function(
                    Pointer<JSContext> ctx,
                    Pointer<Utf8Fix> string_buff,
                    Int32 string_buff_length,
                    Pointer<Utf8Fix> file_name,
                    Int32 flages)>>('parseJSON2')
        .asFunction();
// JSValue *JSONStringify(JSContext *ctx, JSValueConst *obj,
//                          JSValueConst *replacer, JSValueConst *space0);
final Pointer Function(Pointer<JSContext> ctx, Pointer object) JSONStringify = dylib
    .lookup<
        NativeFunction<
            Pointer Function(
      Pointer<JSContext> ctx,
      Pointer object,
    )>>('JSONStringify')
    .asFunction();

final Pointer Function(Pointer<JSContext> ctx) newError =
    dylib.lookup<NativeFunction<Pointer Function(Pointer)>>('newError').asFunction();
// JSValue newBool(JSContext *ctx, JS_BOOL val);
final Pointer Function(Pointer<JSContext> ctx, int val) newBool =
    dylib.lookup<NativeFunction<Pointer Function(Pointer, Int32)>>('newBool').asFunction();

// JSValue newNull(JSContext *ctx);
final Pointer Function(Pointer<JSContext> ctx) newNull =
    dylib.lookup<NativeFunction<Pointer Function(Pointer)>>('newNull').asFunction();

// JSValue newInt32(JSContext *ctx, int32_t val);
final Pointer Function(Pointer<JSContext> ctx, int val) newInt32 = dylib
    .lookup<NativeFunction<Pointer<JSValue> Function(Pointer, Int32)>>('newInt32')
    .asFunction();
// JSValue newCatchOffset(JSContext *ctx, int32_t val);
final Pointer Function(Pointer<JSContext> ctx, int val) newCatchOffset =
    dylib.lookup<NativeFunction<Pointer Function(Pointer, Int32)>>('newCatchOffset').asFunction();
// JSValue newInt64(JSContext *ctx, int64_t val);
final Pointer Function(Pointer<JSContext> ctx, int val) newInt64 =
    dylib.lookup<NativeFunction<Pointer Function(Pointer, Int64)>>('newInt64').asFunction();
// JSValue newUint32(JSContext *ctx, uint32_t val);
final Pointer Function(Pointer<JSContext> ctx, int val) newUint32 =
    dylib.lookup<NativeFunction<Pointer Function(Pointer, Int64)>>('newUint32').asFunction();
// JSValue newBigInt64(JSContext *ctx, int64_t v);
final Pointer Function(Pointer<JSContext> ctx, int val) newBigInt64 =
    dylib.lookup<NativeFunction<Pointer Function(Pointer, Int64)>>('newBigInt64').asFunction();
// JSValue newBigUint64(JSContext *ctx, uint64_t v);
final Pointer Function(Pointer<JSContext> ctx, int val) newBigUint64 =
    dylib.lookup<NativeFunction<Pointer Function(Pointer, Int64)>>('newBigUint64').asFunction();
// JSValue newFloat64(JSContext *ctx, double d);
final Pointer Function(Pointer<JSContext> ctx, double val) newFloat64 =
    dylib.lookup<NativeFunction<Pointer Function(Pointer, Double)>>('newFloat64').asFunction();
// JSValue newStringLen(JSContext *ctx, const char *str1, size_t len1);
final Pointer Function(Pointer<JSContext> ctx, Pointer<Utf8Fix>, int val) newStringLen = dylib
    .lookup<NativeFunction<Pointer Function(Pointer, Pointer<Utf8Fix>, Uint32)>>('newStringLen')
    .asFunction();
// JSValue newString(JSContext *ctx, const char *str);
final Pointer Function(Pointer<JSContext> ctx, Pointer<Utf8Fix> str) newString = dylib
    .lookup<NativeFunction<Pointer Function(Pointer, Pointer<Utf8Fix>)>>('newString')
    .asFunction();
// JSValue newAtomString(JSContext *ctx, const char *str);
final Pointer Function(Pointer<JSContext> ctx, Pointer<Utf8Fix> str) newAtomString = dylib
    .lookup<NativeFunction<Pointer Function(Pointer, Pointer<Utf8Fix>)>>('newAtomString')
    .asFunction();
// DART_EXTERN_C JSAtom *newAtom(JSContext *ctx, const char *str)
final Pointer Function(Pointer<JSContext> ctx, Pointer<Utf8Fix> str) newAtom = dylib
    .lookup<NativeFunction<Pointer Function(Pointer, Pointer<Utf8Fix>)>>('newAtom')
    .asFunction();

final Pointer Function(Pointer<JSContext> context, int val) atomToString = dylib
    .lookup<NativeFunction<Pointer Function(Pointer<JSContext>, Uint32)>>('atomToString')
    .asFunction();

final Pointer Function(Pointer<JSContext> context, int val) atomToValue = dylib
    .lookup<NativeFunction<Pointer Function(Pointer<JSContext>, Uint32)>>('atomToValue')
    .asFunction();

// JSValue newObjectProtoClass(JSContext *ctx, JSValueConst proto, JSClassID class_id);
final Pointer Function(Pointer<JSContext> ctx, Pointer proto, int class_id) newObjectProtoClass =
    dylib
        .lookup<NativeFunction<Pointer Function(Pointer, Pointer, Uint32)>>('newObjectProtoClass')
        .asFunction();
// JSValue newObjectClass(JSContext *ctx, int class_id);
final Pointer Function(Pointer<JSContext> ctx, int class_id) newObjectClass =
    dylib.lookup<NativeFunction<Pointer Function(Pointer, Uint32)>>('newObjectClass').asFunction();

// JSValue newObjectProto(JSContext *ctx, JSValueConst proto);
final Pointer Function(Pointer<JSContext> ctx, Pointer proto) newObjectProto =
    dylib.lookup<NativeFunction<Pointer Function(Pointer, Pointer)>>('newObjectProto').asFunction();
// JSValue newObject(JSContext *ctx);
final Pointer Function(Pointer<JSContext> ctx) newObject =
    dylib.lookup<NativeFunction<Pointer Function(Pointer)>>('newObject').asFunction();
// JSValue newArray(JSContext *ctx);
final Pointer Function(Pointer<JSContext> ctx) newArray =
    dylib.lookup<NativeFunction<Pointer Function(Pointer)>>('newArray').asFunction();

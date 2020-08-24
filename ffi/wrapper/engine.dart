import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings/ffi_base.dart';
import '../bindings/ffi_util.dart';
import '../bindings/util.dart';
import '../ffi.dart';

class JSEngine {
  Pointer<JSRuntime> _rt;
  Pointer<JSContext> _ctx;
  Pointer<JSContext> get context => _ctx;
  JS_Value get global => _globalObject();

  JSEngine.start() {
    _rt = newRuntime();
    _ctx = newContext(_rt);
    init();
    setGlobalObject("global");
  }

  JSEngine.stop(JSEngine engine) {
    engine.stop();
  }

  void stop() {
    freeContext(_rt);
    freeRuntime(_rt);
  }

  void init() {
    final initializeApi =
        dylib.lookupFunction<IntPtr Function(Pointer<Void>), int Function(Pointer<Void>)>(
            "Dart_InitializeApiDL");
    if (initializeApi(NativeApi.initializeApiDLData) != 0) {
      throw "Failed to initialize Dart API";
    }
  }

  void setGlobalObject(String globalString) {
    var globalObj = _globalObject();
    globalObj.setPropertyString(globalString, globalObj);
  }

  void dispose() {
    stop();
  }

  JS_Value callFunction(JS_Value js_func_obj, JS_Value js_obj, int arg_length, JS_Value arg_value) {
    Pointer callResult = call(_ctx, js_func_obj.value, js_obj.value, arg_length, arg_value.value);
    return JS_Value(_ctx, callResult);
  }

  JS_Value dart_call_js(JS_Value this_val, Object params) {
    try {
      return this_val.call_js(params);
    } catch (e) {
      throw e;
    }
  }

  JS_Value evalScript(String js_string) {
    var ptr = eval(context, Utf8Fix.toUtf8(js_string), js_string.length);
    return JS_Value(context, ptr);
  }

  JS_Value _globalObject() {
    return JS_Value(_ctx, getGlobalObject(_ctx));
  }

  JS_Value newInt32(int val) {
    return JS_Value.newInt32(_ctx, val);
  }

  JS_Value newBool(bool val) {
    return JS_Value.newBool(_ctx, val);
  }

  JS_Value newNull() {
    return JS_Value.newNull(_ctx);
  }

  /// make a new js_nul

  JS_Value newError() {
    return JS_Value.newError(_ctx);
  }

  /// make a new js_uint32
  JS_Value newUint32(int val) {
    return JS_Value.newUint32(_ctx, val);
  }

  /// make a new js_int64
  JS_Value newInt64(int val) {
    return JS_Value.newInt64(_ctx, val);
  }

  /// make a new js_bigInt64
  JS_Value newBigInt64(int val) {
    return JS_Value.newBigInt64(_ctx, val);
  }

  /// make a new js_bigUint64
  JS_Value newBigUint64(int val) {
    return JS_Value.newBigUint64(_ctx, val);
  }

  JS_Value newFloat64(double val) {
    return JS_Value.newFloat64(_ctx, val);
  }

  JS_Value newString(String val) {
    return JS_Value.newString(_ctx, val);
  }

  JS_Value newAtomString(String val) {
    return JS_Value.newAtomString(_ctx, val);
  }

  JS_Value newObject() {
    return JS_Value.newObject(_ctx);
  }

  JS_Value newArray() {
    return JS_Value.newArray(_ctx);
  }
}

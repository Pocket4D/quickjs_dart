import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import '../bindings/ffi_base.dart';
import '../bindings/ffi_util.dart';
import '../bindings/ffi_value.dart';
import '../bindings/util.dart';
import '../bindings/ffi_constant.dart';
import '../core.dart';
import 'error.dart';
import 'util.dart';

class JS_Value extends Object {
  Pointer _ptr;
  Pointer _ctx;
  JSEngine engine;
  Pointer get context => _ctx;
  int get address => _ptr.address;
  Pointer get value => _ptr;
  int get value_tag => GetValueTag(_ptr);
  String get value_type => _getValueType();
  JS_Value get console =>
      JS_Value(_ctx, getGlobalObject(_ctx)).getProperty("console").getProperty("log");

  JS_Value(this._ctx, this._ptr, {this.engine});

  JS_Value getProperty(String propertyName) {
    var val_ptr = getPropertyStr(_ctx, _ptr, Utf8Fix.toUtf8(propertyName));
    var result = JS_Value(_ctx, val_ptr);
    if (engine != null) {
      result.engine = engine;
    }
    return result;
  }

  void setPropertyString(String propertyName, JS_Value property) {
    setPropertyStr(_ctx, _ptr, Utf8Fix.toUtf8(propertyName), property.value);
  }

  /// set property of js object, eg we have a js_obj,
  ///
  /// ```dart
  /// // say we have a js_obj existed
  /// js_obj.setPropertyValue("someProp",JS_Value.newInt32(js_obj.context,1),JS_Flags.JS_PROP_C_W_E);
  /// ```
  /// then we have the object with
  /// ```javascript
  /// {someProp:1}
  /// ```
  void setPropertyValue(String propertyName, JS_Value value, int flags) {
    setPropertyInternal(
        _ctx, _ptr, newAtom(_ctx, Utf8Fix.toUtf8(propertyName)), value.value, flags);
  }

  void setProperty(dynamic prop_name, JS_Value value, {int flags}) {
    JS_Value _prop_name;
    if (prop_name is int) {
      _prop_name = JS_Value.newInt32(_ctx, prop_name);
    } else {
      _prop_name = JS_Value.newString(_ctx, prop_name.toString());
    }
    setProp(_ctx, _ptr, _prop_name.value, value.value, flags ?? JS_Flags.JS_PROP_THROW);
  }

  String _getValueType() {
    return to_string(_ctx, atomToString(_ctx, oper_typeof(_ctx, _ptr)));
  }

  void addCallback(DartCallback_ cb, [JSEngine js_engine]) {
    if (this.engine == null && js_engine == null) {
      throw "Have to attach a JSEngine first";
    }
    var _engine = this.engine ?? js_engine;
    _engine?.createNewFunction(cb.name, cb.callback_wrapper, to_val: this);
  }

  JS_Value invokeObject(String prop_name, [List<JS_Value> params]) {
    try {
      if (!getProperty(prop_name).isFunction()) {
        throw Error();
      }
      Map<String, dynamic> _paramsExecuted = paramsExecutor(params);
      return JS_Value(
          _ctx,
          invoke(
              _ctx, // context
              _ptr, // this_val
              JS_Value.newAtom(_ctx, prop_name).value, // atom
              (_paramsExecuted["length"] as int), // argc
              (_paramsExecuted["data"] as Pointer<Pointer>) // argv
              ));
    } catch (e) {
      throw QuickJSError.typeError("not Function").throwError();
    }
  }

  JS_Value call_js([List<JS_Value> params]) {
    try {
      if (!isFunction()) {
        throw Error();
      }
      Map<String, dynamic> _paramsExecuted = paramsExecutor(params);
      return JS_Value(
          _ctx,
          dart_call_js(
              _ctx, // context
              _ptr, //  this_val
              newNull(_ctx), // null
              (_paramsExecuted["length"] as int), // argc
              (_paramsExecuted["data"] as Pointer<Pointer>) // atgv
              ));
    } catch (e) {
      throw QuickJSError.typeError("not Function").throwError();
    }
  }

  List<JS_Value> _toUint8Array_params(List<Object> params_to_encode) {
    try {
      if (!isFunction()) {
        throw Error();
      }
      List<JS_Value> argvs = List(params_to_encode.length);
      for (int i = 0; i < params_to_encode.length; ++i) {
        var params = params_to_encode[i];
        List<int> params_int_list = toArray(jsonEncode(params));

        // allocate with json string
        final Pointer<Uint8> pointer = allocate<Uint8>(count: params_int_list.length);

        // set pointer value to array value
        for (int j = 0; j < params_int_list.length; ++j) {
          pointer[j] = params_int_list[j];
        }
        var js_array_buf = newArrayBufferCopy(_ctx, pointer, params_int_list.length);
        // call js object with params
        JS_Value argv = JS_Value(_ctx, js_array_buf);
        argvs[i] = argv;
      }
      return argvs;
    } catch (e) {
      throw QuickJSError.typeError("not Function").throwError();
    }
  }

  // private newMutablePointerArray(
  //   length: number
  // ): Lifetime<{ typedArray: Int32Array; ptr: JSValuePointerPointer }> {
  //   const zeros = new Int32Array(new Array(length).fill(0))
  //   const numBytes = zeros.length * zeros.BYTES_PER_ELEMENT
  //   const ptr = this.module._malloc(numBytes) as JSValuePointerPointer
  //   const typedArray = new Int32Array(this.module.HEAPU8.buffer, ptr, length)
  //   typedArray.set(zeros)
  //   return new Lifetime({ typedArray, ptr }, undefined, value => this.module._free(value.ptr))
  // }

  JS_Value call_js_encode(List<Object> params) {
    try {
      if (!isFunction()) {
        throw Error();
      }
      List<JS_Value> argvs = _toUint8Array_params(params);

      JS_Value callResult = call_js(argvs);
      // pointer is unsafe allocate in dart heap, have to free manually.
      return callResult;
    } catch (e) {
      throw QuickJSError.typeError("not Function").throwError();
    }
  }

  /// make a new js_bool
  JS_Value.newBool(this._ctx, bool b, [this.engine]) {
    this._ptr = newBool(_ctx, b == true ? 1 : 0);
  }

  /// make a new js_null
  JS_Value.newNull(this._ctx, [this.engine]) {
    this._ptr = newNull(_ctx);
  }

  /// make a new js_error
  JS_Value.newError(this._ctx, [this.engine]) {
    this._ptr = newError(_ctx);
  }

  /// make a new js_int32
  JS_Value.newInt32(this._ctx, int val, [this.engine]) {
    this._ptr = newInt32(_ctx, val);
  }

  /// make a new js_uint32
  JS_Value.newUint32(this._ctx, int val, [this.engine]) {
    this._ptr = newUint32(_ctx, val);
  }

  /// make a new js_int64
  JS_Value.newInt64(this._ctx, int val, [this.engine]) {
    this._ptr = newInt64(_ctx, val);
  }

  /// make a new js_bigInt64
  JS_Value.newBigInt64(this._ctx, int val, [this.engine]) {
    this._ptr = newBigInt64(_ctx, val);
  }

  /// make a new js_bigUint64
  JS_Value.newBigUint64(this._ctx, int val, [this.engine]) {
    this._ptr = newBigUint64(_ctx, val);
  }

  JS_Value.newFloat64(this._ctx, double val, [this.engine]) {
    this._ptr = newFloat64(_ctx, val);
  }

  JS_Value.newString(this._ctx, String val, [this.engine]) {
    this._ptr = newString(_ctx, Utf8Fix.toUtf8(val));
  }

  JS_Value.newAtom(this._ctx, String val, [this.engine]) {
    this._ptr = newAtom(_ctx, Utf8Fix.toUtf8(val));
  }

  JS_Value.newAtomString(this._ctx, String val, [this.engine]) {
    this._ptr = newAtomString(_ctx, Utf8Fix.toUtf8(val));
  }

  JS_Value.newObject(this._ctx, [this.engine]) {
    this._ptr = newObject(_ctx);
  }

  JS_Value.newArray(this._ctx, [this.engine]) {
    this._ptr = newArray(_ctx);
  }

  static void free_value(Pointer<JSContext> ctx, Pointer val) {
    FreeValue(ctx, val);
  }

  static bool is_nan(Pointer val) {
    return IsNan(val) == 0 ? false : true;
  }

  static bool is_string(Pointer val) {
    return IsString(val) == 0 ? false : true;
  }

  static bool is_number(Pointer val) {
    return IsNumber(val) == 0 ? false : true;
  }

  static bool is_null(Pointer val) {
    return IsNull(val) == 0 ? false : true;
  }

  static bool is_bool(Pointer val) {
    return IsBool(val) == 0 ? false : true;
  }

  static bool is_object(Pointer val) {
    return IsObject(val) == 0 ? false : true;
  }

  static bool is_symbol(Pointer val) {
    return IsSymbol(val) == 0 ? false : true;
  }

  static bool is_error(Pointer<JSContext> ctx, Pointer val) {
    return IsError(ctx, val) == 0 ? false : true;
  }

  static bool is_function(Pointer<JSContext> ctx, Pointer val) {
    return IsFunction(ctx, val) == 0 ? false : true;
  }

  static bool is_constructor(Pointer<JSContext> ctx, Pointer val) {
    return IsConstructor(ctx, val) == 0 ? false : true;
  }

  static bool is_undefined(Pointer val) {
    return IsUndefined(val) == 0 ? false : true;
  }

  static bool is_uninitialized(Pointer val) {
    return IsUninitialized(val) == 0 ? false : true;
  }

  static bool is_bigInt(Pointer<JSContext> ctx, Pointer val) {
    return IsBigInt(ctx, val) == 0 ? false : true;
  }

  static bool is_bigFloat(Pointer val) {
    return IsBigFloat(val) == 0 ? false : true;
  }

  static bool is_bigDecimal(Pointer val) {
    return IsBigDecimal(val) == 0 ? false : true;
  }

  static bool is_array(Pointer<JSContext> ctx, Pointer val) {
    return IsArray(ctx, val) == 0 ? false : true;
  }

  static bool is_extensible(Pointer<JSContext> ctx, Pointer val) {
    return IsExtensible(ctx, val) == 0 ? false : true;
  }

  static bool is_promise_value(Pointer<JSContext> ctx, Pointer val) {
    return JS_Value(ctx, val).getProperty("then").isFunction();
  }

  static Pointer to_jsString(Pointer<JSContext> ctx, Pointer val) {
    try {
      if (JS_Value(ctx, val).value_type == "unknown") {
        throw Error();
      }
      return ToString(ctx, val);
    } catch (e) {
      throw QuickJSError.typeError("unknown").throwError();
    }
  }

  static String to_string(Pointer<JSContext> ctx, Pointer val) {
    try {
      return Utf8Fix.fromUtf8(ToCString(ctx, val));
    } catch (e) {
      throw e;
    }
  }

  static String to_JSONString(Pointer<JSContext> ctx, Pointer val) {
    try {
      if (JS_Value(ctx, val).value_type == "unknown") {
        throw Error();
      }
      return JS_Value.to_string(ctx, JSONStringify(ctx, val));
    } catch (e) {
      throw QuickJSError.typeError("unknown").throwError();
    }
  }

  /// determine if value is `NaN`
  bool isNan() {
    return is_nan(_ptr);
  }

  /// determine if value is `string`
  bool isString() {
    return is_string(_ptr);
  }

  /// determine if value is `number`
  bool isNumber() {
    return is_number(_ptr);
  }

  /// determine if value is `null`
  bool isNull() {
    return is_null(_ptr);
  }

  bool isObject() {
    return is_object(_ptr);
  }

  /// determine if value is `undefined`
  bool isUndefined() {
    return is_undefined(_ptr);
  }

  /// determine if value is `bool`
  bool isBool() {
    return is_bool(_ptr);
  }

  bool isError() {
    return is_error(_ctx, _ptr);
  }

  bool isConstructor() {
    return is_constructor(_ctx, _ptr);
  }

  bool isFunction() {
    return is_function(_ctx, _ptr);
  }

  /// determine if value is `bool`
  bool isSymbol() {
    return is_symbol(_ptr);
  }

  /// determine if value is `uninitialized`
  bool isUninitialized() {
    return is_uninitialized(_ptr);
  }

  /// determine if value is `bigInt`
  bool isBigInt() {
    return is_bigInt(_ctx, _ptr);
  }

  /// determine if value is `bigFloat`
  bool isBigFloat() {
    return is_bigFloat(_ptr);
  }

  /// determine if value is `bigDecimal`
  bool isBigDecimal() {
    return is_bigDecimal(_ptr);
  }

  bool isArray() {
    return is_array(_ctx, _ptr);
  }

  bool isExtensible() {
    return is_extensible(_ctx, _ptr);
  }

  bool isPromise() {
    return is_promise_value(_ctx, _ptr);
  }

  JS_Value js_then() {
    try {
      if (!isPromise()) {
        throw "Value is not Promise";
      }
      return getProperty("then").call_js();
    } catch (e) {
      throw e;
    }
  }

  Pointer toJSString() {
    try {
      return to_jsString(_ctx, _ptr);
    } catch (e) {
      throw e;
    }
  }

  String toDartString() {
    try {
      return to_string(_ctx, _ptr);
    } catch (e) {
      throw e;
    }
  }

  void free() {
    free_value(_ctx, _ptr);
  }

  Pointer copy() {
    return DupValue(_ctx, _ptr);
  }

  String toJSONString() {
    try {
      return to_JSONString(_ctx, _ptr);
    } catch (e) {
      throw e;
    }
  }

  JS_Value js_print({String prepend_message, JS_Value value}) {
    var prependString = prepend_message ?? null;
    if (prependString == null) {
      return console.call_js([value ?? this]);
    }
    return console.call_js([JS_Value.newString(_ctx, prepend_message), value ?? this]);
  }

  void dispose() {
    free();
  }
}

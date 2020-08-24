import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings/ffi_base.dart';
import '../bindings/ffi_util.dart';
import '../bindings/ffi_value.dart';
import '../bindings/util.dart';
import 'util.dart';

class JS_Value {
  Pointer _ptr;
  Pointer _ctx;

  int get address => _ptr.address;
  Pointer get value => _ptr;
  int get value_tag => GetValueTag(_ptr);
  String get value_type => _getValueType();

  JS_Value(this._ctx, this._ptr);

  JS_Value getProperty(String propertyName) {
    var val_ptr = getPropertyStr(_ctx, _ptr, Utf8Fix.toUtf8(propertyName));
    return JS_Value(_ctx, val_ptr);
  }

  void setPropertyString(String propertyName, JS_Value property) {
    setPropertyStr(_ctx, _ptr, Utf8Fix.toUtf8(propertyName), property.value);
  }

  String _getValueType() {
    return to_string(_ctx, atomToString(_ctx, oper_typeof(_ctx, _ptr)));
  }

  JS_Value call_js(Object params) {
    try {
      assert(!isFunction());
      // translate params to List<int>, should be encodable;
      List<int> params_int_list = toArray(jsonEncode(params));
      // allocate with json string
      final Pointer<Uint8> pointer = allocate<Uint8>(count: params_int_list.length);
      // set pointer value to array value
      for (int i = 0; i < params_int_list.length; ++i) {
        pointer[i] = params_int_list[i];
      }
      // call js object with params
      JS_Value argv = JS_Value(_ctx, newArrayBufferCopy(_ctx, pointer, params_int_list.length));
      JS_Value callResult = JS_Value(_ctx, call(_ctx, _ptr, newNull(_ctx), 1, argv.value));
      // pointer is unsafe allocate in dart heap, have to free manually.
      return callResult;
    } catch (e) {
      throw e;
    }
  }

  /// make a new js_bool
  JS_Value.newBool(this._ctx, bool b) {
    this._ptr = newBool(_ctx, b == true ? 1 : 0);
  }

  /// make a new js_null
  JS_Value.newNull(this._ctx) {
    this._ptr = newNull(_ctx);
  }

  /// make a new js_error
  JS_Value.newError(this._ctx) {
    this._ptr = newError(_ctx);
  }

  /// make a new js_int32
  JS_Value.newInt32(this._ctx, int val) {
    this._ptr = newInt32(_ctx, val);
  }

  /// make a new js_uint32
  JS_Value.newUint32(this._ctx, int val) {
    this._ptr = newUint32(_ctx, val);
  }

  /// make a new js_int64
  JS_Value.newInt64(this._ctx, int val) {
    this._ptr = newInt64(_ctx, val);
  }

  /// make a new js_bigInt64
  JS_Value.newBigInt64(this._ctx, int val) {
    this._ptr = newBigInt64(_ctx, val);
  }

  /// make a new js_bigUint64
  JS_Value.newBigUint64(this._ctx, int val) {
    this._ptr = newBigUint64(_ctx, val);
  }

  JS_Value.newFloat64(this._ctx, double val) {
    this._ptr = newFloat64(_ctx, val);
  }

  JS_Value.newString(this._ctx, String val) {
    this._ptr = newString(_ctx, Utf8Fix.toUtf8(val));
  }

  JS_Value.newAtomString(this._ctx, String val) {
    this._ptr = newAtomString(_ctx, Utf8Fix.toUtf8(val));
  }

  JS_Value.newObject(this._ctx) {
    this._ptr = newObject(_ctx);
  }

  JS_Value.newArray(this._ctx) {
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

  static Pointer to_jsString(Pointer<JSContext> ctx, Pointer val) {
    return ToString(ctx, val);
  }

  static String to_string(Pointer<JSContext> ctx, Pointer val) {
    return Utf8Fix.fromUtf8(ToCString(ctx, val));
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

  Pointer toJSString() {
    return to_jsString(_ctx, _ptr);
  }

  String toDartString() {
    return to_string(_ctx, _ptr);
  }

  void free() {
    return free_value(_ctx, _ptr);
  }

  Pointer copy() {
    return DupValue(_ctx, _ptr);
  }
}

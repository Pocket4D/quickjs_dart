import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import '../bindings/ffi_base.dart';
import '../bindings/ffi_util.dart';
import '../bindings/util.dart';
import '../bindings/ffi_value.dart';
import '../bindings/ffi_constant.dart';
import 'util.dart';
import 'value.dart';
import 'function.dart';

extension on num {
  bool get isInt => this % 1 == 0;
}

Map<int, Dart_C_Handler> dart_handler_map;

final String Global_Promise_Getter = "__promise__getter";

class JSEngine extends Object {
  /// runtime pointer
  Pointer<JSRuntime> _rt;

  /// context pointer
  Pointer<JSContext> _ctx;

  /// context getter
  Pointer<JSContext> get context => _ctx;

  Pointer<JSRuntime> get runtime => _rt;

  /// global object getter
  JS_Value get global => _globalObject();

  JS_Value get global_promise => global.getProperty(Global_Promise_Getter);

  int get handler_id => _next_func_handler_id;

  int _next_func_handler_id;

  static ReceivePort cRequests = ReceivePort()
    ..listen((message) {
      print(message);
    });

  JSEngine.start() {
    _rt = newRuntime();
    _ctx = newContext(_rt);
    init();
  }

  // JSEngine.fromContext(Pointer<JSContext> ctx) {
  //   _ctx = ctx;
  //   _rt = getRuntime(_ctx);
  //   // init();
  // }

  init() {
    initDartAPI();
    setGlobalObject("global");
    _setGlobalPromiseGetter();
    _registerDartFP();
  }

  JSEngine.loop(JSEngine engine) {
    if (engine.hasPendingJobs()) {
      engine.donePendingJobs();
    }
  }

  JSEngine.stop(JSEngine engine) {
    engine.stop();
  }

  void stop() {
    freeContext(_rt);
    freeRuntime(_rt);
  }

  /// Dart Api for Dynamic link, should place before function call
  /// TODO: Should we keep this?
  void initDartAPI() {
    final initializeApi =
        dylib.lookupFunction<IntPtr Function(Pointer<Void>), int Function(Pointer<Void>)>(
            "Dart_InitializeApiDL");
    if (initializeApi(NativeApi.initializeApiDLData) != 0) {
      throw "Failed to initialize Dart API";
    }
  }

  void _registerDartFP() {
    final dartCallbackPointer = Pointer.fromFunction<
        Void Function(Pointer<JSContext> ctx, Pointer this_val, Int32 argc, Pointer argv,
            Pointer func_data, Pointer result_ptr)>(callBackWrapper);
    registerDartCallbackFP(dartCallbackPointer);
  }

  void setGlobalObject(String globalString) {
    var globalObj = _globalObject();

    /// TODO :get own property first, to see if it is registered
    globalObj.setPropertyString(globalString, globalObj);
  }

  bool hasPendingJobs() {
    return isJobPending(_rt) == 1 ? true : false;
  }

  int donePendingJobs({int maxNumber = -1}) {
    try {
      var result = JS_Value(_ctx, executePendingJob(_rt, maxNumber));
      if (result.isNumber()) {
        // result.js_print();
        return ToInt32(_ctx, result.value);
      } else {
        return -1;
      }
    } catch (e) {
      throw "could not done pending jobs";
    }
  }

  void _setGlobalPromiseGetter() {
    String str = r"""
    function createPromise(){
      const result = {
            resolve:undefined,
            reject:undefined,
            promise:undefined
          };
      result.promise = new Promise((resolve, reject) => {
        result.resolve = resolve
        result.reject = reject
      });
      return result;
    };
    createPromise;
  """;
    var func_ = evalScript(str);
    global.setProperty(Global_Promise_Getter, func_, flags: JS_Flags.JS_PROP_THROW);
  }

  void dispose() {
    stop();
  }

  /**
   * create a function with name, and handler, attach it to some value;
   */
  createNewFunction(String func_name, Dart_C_Handler handler, {JS_Value to_val}) {
    if (_next_func_handler_id == null) {
      _next_func_handler_id = 0;
    }
    final int handler_id = ++_next_func_handler_id;

    if (dart_handler_map == null) {
      dart_handler_map = new Map();
    }
    dart_handler_map.putIfAbsent(handler_id, () => handler);

    installDartHook(_ctx, to_val?.value ?? global.value, Utf8Fix.toUtf8(func_name), handler_id);
  }

  static void callBackWrapper(Pointer<JSContext> ctx, Pointer this_val, int argc, Pointer argv,
      Pointer func_data, Pointer result_ptr) {
    final int handler_id = ToInt64(ctx, func_data);
    final Dart_C_Handler handler = dart_handler_map[handler_id];

    if (handler == null) {
      throw 'QuickJS VM had no callback with id ${handler_id}';
    }

    List<JS_Value> _args = argc > 1
        ? List.generate(argc, (index) => JS_Value(ctx, getJSValueConstPointer(argv, index)))
        : argc == 1 ? [JS_Value(ctx, argv)] : null;

    JS_Value _this_val = JS_Value(ctx, this_val);

    handler(context: ctx, this_val: _this_val, args: _args, result_ptr: result_ptr);

    _args.forEach((element) {
      element.free();
    });
    _this_val.free();
  }

  JS_Value callFunction(JS_Value js_func_obj, JS_Value js_obj, [List<JS_Value> arg_value]) {
    Map<String, dynamic> _paramsExecuted = paramsExecutor(arg_value);
    Pointer callResult = call(_ctx, js_func_obj.value, js_obj.value,
        (_paramsExecuted["length"] as int), (_paramsExecuted["value"]) as Pointer<Pointer>);
    return attachEngine(JS_Value(_ctx, callResult));
  }

  JS_Value dart_call_js(JS_Value this_val, List<JS_Value> params) {
    try {
      return attachEngine(this_val.call_js(params));
    } catch (e) {
      throw e;
    }
  }

  JS_Value dart_call_js_encode(JS_Value this_val, List<Object> params) {
    try {
      return attachEngine(this_val.call_js_encode(params));
    } catch (e) {
      throw e;
    }
  }

  JS_Value evalScript(String js_string) {
    var ptr = eval(context, Utf8Fix.toUtf8(js_string), js_string.length);
    return attachEngine(JS_Value(context, ptr));
  }

  void js_print(JS_Value val) {
    global.getProperty("console").getProperty("log").call_js([val]);
  }

  JS_Value _globalObject() {
    return attachEngine(JS_Value(_ctx, getGlobalObject(_ctx)));
  }

  JS_Value newInt32(int val) {
    return JS_Value.newInt32(_ctx, val, this);
  }

  JS_Value newBool(bool val) {
    return JS_Value.newBool(_ctx, val, this);
  }

  JS_Value newNull() {
    return JS_Value.newNull(_ctx, this);
  }

  /// make a new js_nul

  JS_Value newError() {
    return JS_Value.newError(_ctx, this);
  }

  /// make a new js_uint32
  JS_Value newUint32(int val) {
    return JS_Value.newUint32(_ctx, val, this);
  }

  /// make a new js_int64
  JS_Value newInt64(int val) {
    return JS_Value.newInt64(_ctx, val, this);
  }

  /// make a new js_bigInt64
  JS_Value newBigInt64(int val) {
    return JS_Value.newBigInt64(_ctx, val, this);
  }

  /// make a new js_bigUint64
  JS_Value newBigUint64(int val) {
    return JS_Value.newBigUint64(_ctx, val, this);
  }

  JS_Value newFloat64(double val) {
    return JS_Value.newFloat64(_ctx, val, this);
  }

  JS_Value newString(String val) {
    return JS_Value.newString(_ctx, val, this);
  }

  JS_Value newAtomString(String val) {
    return JS_Value.newAtomString(_ctx, val, this);
  }

  JS_Value newObject() {
    return JS_Value.newObject(_ctx, this);
  }

  JS_Value newArray() {
    return JS_Value.newArray(_ctx, this);
  }

  JS_Value newAtom(String val) {
    return JS_Value.newAtom(_ctx, val, this);
  }

  JS_Value createJSArray(List<dynamic> dart_list) {
    var js_array = JS_Value.newArray(_ctx, this);
    for (int i = 0; i < dart_list.length; ++i) {
      var value = dart_list[i];
      String _type = typeCheckHelper(value);
      switch (_type) {
        case "int":
          js_array.setProperty(i, JS_Value.newInt32(_ctx, value));
          break;
        case "String":
          js_array.setProperty(i, JS_Value.newString(_ctx, value));
          break;
        case "bool":
          js_array.setProperty(i, JS_Value.newBool(_ctx, value));
          break;
        case "List":
          // create array;
          var subList = createJSArray((value as List<dynamic>));
          js_array.setProperty(i, subList);
          break;
        case "Map":
          // loop this function
          var subMap = createJSObject((value as Map<String, dynamic>));
          js_array.setProperty(i, subMap);
          break;
        case "Dart_C_Handler":
          // TODO: should we support this?
          // createNewFunction(i, (value as Dart_C_Handler), to_val: js_array);
          throw "${value.runtimeType} is not supported";
          break;
        case "Not_Support":
          throw "${value.runtimeType} is not supported";
          break;
        default:
      }
    }
    return js_array;
  }

  JS_Value createJSObject(Map<String, dynamic> dart_map) {
    var js_obj = JS_Value.newObject(_ctx, this);

    dart_map.forEach((key, value) {
      String _type = typeCheckHelper(value);
      switch (_type) {
        case "int":
          js_obj.setProperty(key, JS_Value.newInt32(_ctx, value));
          break;
        case "String":
          js_obj.setProperty(key, JS_Value.newString(_ctx, value));
          break;
        case "bool":
          js_obj.setProperty(key, JS_Value.newBool(_ctx, value));
          break;
        case "List":
          // create array;
          var subList = createJSArray((value as List<dynamic>));
          js_obj.setProperty(key, subList);
          break;
        case "Map":
          // loop this function
          var subMap = createJSObject((value as Map<String, dynamic>));
          js_obj.setProperty(key, subMap);
          break;
        case "Dart_C_Handler":
          // loop this function
          createNewFunction(key, (value as Dart_C_Handler), to_val: js_obj);
          // throw "${value.runtimeType} is not supported";
          break;
        case "Not_Support":
          throw "${value.runtimeType} is not supported";
          break;
        default:
      }
    });

    return js_obj;
  }

  JS_Value to_js_val(dynamic value) {
    String _type = typeCheckHelper(value);
    switch (_type) {
      case "int":
        if (value > 2147483647 || value < -2147483648) {
          return attachEngine(JS_Value.newInt64(_ctx, value));
        }
        return attachEngine(JS_Value.newInt32(_ctx, value));
      case "double":
        return attachEngine(JS_Value.newFloat64(_ctx, value));
      case "String":
        return attachEngine(JS_Value.newString(_ctx, value));
      case "bool":
        return attachEngine(JS_Value.newBool(_ctx, value));
      case "List":
        return attachEngine(createJSArray((value as List<dynamic>)));
      case "Map":
        return attachEngine(createJSObject((value as Map<String, dynamic>)));
      case "Dart_C_Handler":
        // loop this function
        throw "${value.runtimeType} is not supported";
      // throw "${value.runtimeType} is not supported";
      case "Not_Support":
        throw "${value.runtimeType} is not supported";
      default:
        throw "${value.runtimeType} is not supported";
    }
  }

  dynamic from_js_val(JS_Value value) {
    var val_type = value.value_type;
    switch (val_type) {
      case 'number':
        {
          double trans = ToFloat64(_ctx, value.value);
          if (trans.isInt) {
            return ToInt32(_ctx, value.value);
          }
          return trans;
        }

      case 'string':
        return value.toDartString();
      case 'undefined':
        return null;
      case 'null':
        return null;
      case 'boolean':
        return ToBool(_ctx, value.value) == 1 ? true : false;
      case 'object':
        {
          if (value.isArray() || value.isObject()) {
            return jsonDecode(value.toJSONString());
          }
          throw 'not supported';
        }
      default:
        throw 'not supported';
    }
  }

  attachEngine(JS_Value result) {
    result.engine = this;
    return result;
  }
}

String typeCheckHelper(dynamic value) {
  if (value is int) {
    return 'int';
  }
  if (value is String) {
    return "String";
  }
  if (value is bool) {
    return "bool";
  }
  if (value is double) {
    return "double";
  }
  if (value is List) {
    return "List";
  }
  if (value is Map) {
    return "Map";
  }
  if (value is Dart_C_Handler) {
    return "Dart_C_Handler";
  }
  return "Not_Support";
}

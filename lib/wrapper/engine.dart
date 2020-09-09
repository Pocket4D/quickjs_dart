import 'dart:convert';
import 'dart:ffi';

import '../bindings/ffi_base.dart';
import '../bindings/ffi_util.dart';
import '../bindings/util.dart';
import '../bindings/ffi_value.dart' as ffiValue;
import '../bindings/ffi_constant.dart';
import 'util.dart';
import 'value.dart';
import 'function.dart';

extension on num {
  bool get isInt => this % 1 == 0;
}

Map<int, DartCHandler> dartHandlerMap;

final String globalPromiseGetter = "__promise__getter";

class JSEngine extends Object {
  static JSEngine _instance;

  /// 内部构造方法，可避免外部暴露构造函数，进行实例化
  JSEngine._internal() {
    _rt = newRuntime();
    _ctx = newContext(_rt);
    init();
  }

  factory JSEngine() => _getInstance();
  static JSEngine get instance => _getInstance();

  /// 获取单例内部方法
  static _getInstance() {
    // 只能有一个实例
    if (_instance == null) {
      _instance = JSEngine._internal();
    }
    return _instance;
  }

  /// runtime pointer
  Pointer<JSRuntime> _rt;

  /// context pointer
  Pointer<JSContext> _ctx;

  /// context getter
  Pointer<JSContext> get context => _ctx;

  Pointer<JSRuntime> get runtime => _rt;

  /// global object getter
  JSValue get global => _globalObject();

  JSValue get globalPromise => global.getProperty(globalPromiseGetter);

  int get handlerId => _nextFuncHandlerId;

  int _nextFuncHandlerId;

  /// Todo: with config
  /// ```dart
  ///  JSEngine.start({JSEngineConfig config})
  /// ```

  init() {
    // initDartAPI();
    setGlobalObject("global");
    _setGlobalPromiseGetter();
    _registerDartFP();
    setGlobalConsole();
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
  // void initDartAPI() {
  //   final initializeApi =
  //       dylib.lookupFunction<IntPtr Function(Pointer<Void>), int Function(Pointer<Void>)>(
  //           "Dart_InitializeApiDL");
  //   if (initializeApi(NativeApi.initializeApiDLData) != 0) {
  //     throw "Failed to initialize Dart API";
  //   }
  // }

  void _registerDartFP() {
    final dartCallbackPointer = Pointer.fromFunction<
        Pointer Function(Pointer<JSContext> ctx, Pointer thisVal, Int32 argc, Pointer argv,
            Pointer funcData)>(callBackWrapper);
    registerDartCallbackFP(dartCallbackPointer);
  }

  void setGlobalObject(String globalString) {
    var globalObj = _globalObject();

    /// TODO :get own property first, to see if it is registered
    globalObj.setPropertyString(globalString, globalObj);
  }

  void setGlobalConsole() {
    var globalObj = _globalObject();

    globalObj.addCallback(DartCallback(
        engine: this,
        name: "__console_write",
        handler: (args, engine, thisVal) {
          if (args.length > 1) {
            var tag = engine.fromJSVal(args[0]) as String;
            var newList = args.sublist(1).map((element) {
              return fromJSVal(element);
            }).toList();
            print("js console.$tag: ${newList.join(" ")}");
          } else {
            var newList2 = args.map((element) {
              return fromJSVal(element);
            }).toList();
            print("js console.${newList2.join(" ")}");
          }
        }));
    evalScript(r"""
      globalThis.console = {
                trace: (...args) => {
                    globalThis.__console_write("trace", ...args);
                },
                debug: (...args) => {
                    globalThis.__console_write("debug", ...args);
                },
                log: (...args) => {
                    globalThis.__console_write("log", ...args);
                },
                info: (...args) => {
                    globalThis.__console_write("info", ...args);
                },
                warn: (...args) => {
                    globalThis.__console_write("warn", ...args);
                },
                error: (...args) => {
                    globalThis.__console_write("error", ...args);
                },
            };
      """);
  }

  bool hasPendingJobs() {
    return isJobPending(_rt) == 1 ? true : false;
  }

  int donePendingJobs({int maxNumber = -1}) {
    try {
      var result = JSValue(_ctx, executePendingJob(_rt, maxNumber));
      if (result.isNumber()) {
        // result.js_print();
        return ffiValue.toInt32(_ctx, result.value);
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
    createPromise
  """;
    var func = evalScript(str);
    global.setProperty(globalPromiseGetter, func, flags: JSFlags.JS_PROP_THROW);
  }

  void dispose() {
    stop();
  }

  ///
  /// create a function with name, and handler, attach it to some value;
  ///
  createNewFunction(String funcName, DartCHandler handler, {JSValue toVal}) {
    if (_nextFuncHandlerId == null) {
      _nextFuncHandlerId = 0;
    }
    final int handlerId = ++_nextFuncHandlerId;

    if (dartHandlerMap == null) {
      dartHandlerMap = new Map();
    }
    dartHandlerMap.putIfAbsent(handlerId, () => handler);

    installDartHook(_ctx, toVal?.value ?? global.value, Utf8Fix.toUtf8(funcName), handlerId);
  }

  static Pointer callBackWrapper(
      Pointer<JSContext> ctx, Pointer thisVal, int argc, Pointer argv, Pointer funcData) {
    final int handlerId = ffiValue.toInt64(ctx, funcData);
    final DartCHandler handler = dartHandlerMap[handlerId];

    if (handler == null) {
      throw 'QuickJS VM had no callback with id $handlerId';
    }

    List<JSValue> _args = argc > 1
        ? List.generate(argc, (index) => JSValue(ctx, getJSValueConstPointer(argv, index)))
        : argc == 1 ? [JSValue(ctx, argv)] : null;

    JSValue _thisVal = JSValue(ctx, thisVal);

    return handler(context: ctx, thisVal: _thisVal, args: _args);
  }

  JSValue setProtoType(JSValue receiver, JSValue value) {
    try {
      setPrototype(_ctx, receiver.value, value.value);
      return attachEngine(receiver);
      // throw 'setProtoType faild';
    } catch (e) {
      throw 'setProtoType faild';
    }
  }

  JSValue callFunction(JSValue jsFunction, JSValue thisVal, [List<JSValue> args]) {
    Map<String, dynamic> _paramsExecuted = paramsExecutor(args);
    Pointer callResult = call(_ctx, jsFunction.value, thisVal.value,
        (_paramsExecuted["length"] as int), (_paramsExecuted["value"]) as Pointer<Pointer>);
    return attachEngine(JSValue(_ctx, callResult));
  }

  JSValue callJS(JSValue thisVal, List<JSValue> params) {
    try {
      return attachEngine(thisVal.callJS(params));
    } catch (e) {
      throw e;
    }
  }

  JSValue callJSEncode(JSValue thisVal, List<Object> params) {
    try {
      return attachEngine(thisVal.callJSEncode(params));
    } catch (e) {
      throw e;
    }
  }

  JSValue evalScript(String jsString) {
    var ptr = eval(context, Utf8Fix.toUtf8(jsString), jsString.length);
    return attachEngine(JSValue(context, ptr));
  }

  void jsPrint(JSValue val) {
    global.getProperty("console").getProperty("log").callJS([val]);
  }

  JSValue _globalObject() {
    return attachEngine(JSValue(_ctx, getGlobalObject(_ctx)));
  }

  JSValue newInt32(int val) {
    return JSValue.newInt32(_ctx, val, this);
  }

  JSValue newBool(bool val) {
    return JSValue.newBool(_ctx, val, this);
  }

  JSValue newNull() {
    return JSValue.newNull(_ctx, this);
  }

  JSValue newUndefined() {
    return JSValue.newUndefined(_ctx, this);
  }

  /// make a new js_nul

  JSValue newError() {
    return JSValue.newError(_ctx, this);
  }

  /// make a new js_uint32
  JSValue newUint32(int val) {
    return JSValue.newUint32(_ctx, val, this);
  }

  /// make a new js_int64
  JSValue newInt64(int val) {
    return JSValue.newInt64(_ctx, val, this);
  }

  /// make a new js_bigInt64
  JSValue newBigInt64(int val) {
    return JSValue.newBigInt64(_ctx, val, this);
  }

  /// make a new js_bigUint64
  JSValue newBigUint64(int val) {
    return JSValue.newBigUint64(_ctx, val, this);
  }

  JSValue newFloat64(double val) {
    return JSValue.newFloat64(_ctx, val, this);
  }

  JSValue newString(String val) {
    return JSValue.newString(_ctx, val, this);
  }

  JSValue newAtomString(String val) {
    return JSValue.newAtomString(_ctx, val, this);
  }

  JSValue newObject() {
    return JSValue.newObject(_ctx, this);
  }

  JSValue newArray() {
    return JSValue.newArray(_ctx, this);
  }

  JSValue newAtom(String val) {
    return JSValue.newAtom(_ctx, val, this);
  }

  JSValue createJSArray(List<dynamic> dartList) {
    var jsArray = JSValue.newArray(_ctx, this);
    for (int i = 0; i < dartList.length; ++i) {
      var value = dartList[i];
      String _type = typeCheckHelper(value);
      switch (_type) {
        case "int":
          jsArray.setProperty(i, JSValue.newInt32(_ctx, value));
          break;
        case "String":
          jsArray.setProperty(i, JSValue.newString(_ctx, value));
          break;
        case "bool":
          jsArray.setProperty(i, JSValue.newBool(_ctx, value));
          break;
        case "List":
          // create array;
          var subList = createJSArray((value as List<dynamic>));
          jsArray.setProperty(i, subList);
          break;
        case "Map":
          // loop this function
          var subMap = createJSObject((value as Map<String, dynamic>));
          jsArray.setProperty(i, subMap);
          break;
        case "DartCHandler":
          // TODO: should we support this?
          // createNewFunction(i, (value as DartCHandler), toVal: jsArray);
          throw "${value.runtimeType} is not supported";
          break;
        case "Not_Support":
          throw "${value.runtimeType} is not supported";
          break;
        default:
      }
    }
    return jsArray;
  }

  JSValue createJSObject(Map<String, dynamic> dartMap) {
    var jsObj = JSValue.newObject(_ctx, this);

    dartMap.forEach((key, value) {
      String _type = typeCheckHelper(value);
      switch (_type) {
        case "int":
          jsObj.setProperty(key, JSValue.newInt32(_ctx, value));
          break;
        case "String":
          jsObj.setProperty(key, JSValue.newString(_ctx, value));
          break;
        case "bool":
          jsObj.setProperty(key, JSValue.newBool(_ctx, value));
          break;
        case "List":
          // create array;
          var subList = createJSArray((value as List<dynamic>));
          jsObj.setProperty(key, subList);
          break;
        case "Map":
          // loop this function
          var subMap = createJSObject((value as Map<String, dynamic>));
          jsObj.setProperty(key, subMap);
          break;
        case "DartCHandler":
          // loop this function
          createNewFunction(key, (value as DartCHandler), toVal: jsObj);
          // throw "${value.runtimeType} is not supported";
          break;
        case "Not_Support":
          throw "${value.runtimeType} is not supported";
          break;
        default:
      }
    });

    return jsObj;
  }

  JSValue toJSVal(dynamic value) {
    String _type = typeCheckHelper(value);
    switch (_type) {
      case "int":
        if (value > 2147483647 || value < -2147483648) {
          return attachEngine(JSValue.newInt64(_ctx, value));
        }
        return attachEngine(JSValue.newInt32(_ctx, value));
      case "double":
        return attachEngine(JSValue.newFloat64(_ctx, value));
      case "String":
        return attachEngine(JSValue.newString(_ctx, value));
      case "bool":
        return attachEngine(JSValue.newBool(_ctx, value));
      case "List":
        return attachEngine(createJSArray((value as List<dynamic>)));
      case "Map":
        return attachEngine(createJSObject((value as Map<String, dynamic>)));
      case "DartCHandler":
        // loop this function
        throw "${value.runtimeType} is not supported";
      // throw "${value.runtimeType} is not supported";
      case "Not_Support":
        throw "${value.runtimeType} is not supported";
      default:
        throw "${value.runtimeType} is not supported";
    }
  }

  dynamic fromJSVal(JSValue value) {
    var valType = value.valueType;
    switch (valType) {
      case JSValueType.NUMBER:
        {
          double trans = ffiValue.toFloat64(_ctx, value.value);
          if (trans.isInt) {
            return ffiValue.toInt32(_ctx, value.value);
          }
          return trans;
        }

      case JSValueType.STRING:
        return value.toDartString();
      case JSValueType.UNDEFINED:
        return null;
      case JSValueType.NULL:
        return null;
      case JSValueType.BOOLEAN:
        return ffiValue.toBool(_ctx, value.value) == 1 ? true : false;
      case JSValueType.OBJECT:
        {
          if (value.isArray() || value.isObject()) {
            return jsonDecode(value.toJSONString());
          }
          return value;
        }
      case JSValueType.FUNCTION:
        return value;
      default:
        return value;
    }
  }

  attachEngine(JSValue result) {
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
  if (value is DartCHandler) {
    return "DartCHandler";
  }
  return "Not_Support";
}

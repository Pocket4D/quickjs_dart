import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'util.dart';

///////////////////////////////////////////////////////////////////////////////
// Typedef's
///////////////////////////////////////////////////////////////////////////////
// typedef struct JSRuntime JSRuntime;
class JSRuntime extends Struct {}

// typedef struct JSContext JSContext;
class JSContext extends Struct {}

// typedef struct JSObject JSObject;
class JSObject extends Struct {}

// typedef struct JSClass JSClass;
class JSClass extends Struct {}

// JSValue has complex defined in C apis. we use here to identify the datatype only with dart
class JSValue extends Struct {}

class JSGCObjectHeader extends Struct {}

// JSRuntime *JS_NewRuntime(void);
typedef newRuntime_func = Pointer<JSRuntime> Function();
typedef newRuntime_native = Pointer<JSRuntime> Function();

final newRuntimeName = "JS_NewRuntime";
final newRuntime_func newRuntime =
    dylib.lookup<NativeFunction<newRuntime_native>>(newRuntimeName).asFunction();

// /* info lifetime must exceed that of rt */
// void JS_SetRuntimeInfo(JSRuntime *rt, const char *info);
typedef setRuntimeInfo_func = void Function(Pointer<JSRuntime> rt, Pointer<Utf8> info);
typedef setRuntimeInfo_native = Void Function(Pointer, Pointer);

final setRuntimeInfo_name = "JS_SetRuntimeInfo";
final setRuntimeInfo_func setupRuntimeInfo =
    dylib.lookup<NativeFunction<setRuntimeInfo_native>>(setRuntimeInfo_name).asFunction();

// void JS_SetMemoryLimit(JSRuntime *rt, size_t limit);
typedef setMemoryLimit_func = void Function(Pointer<JSRuntime> rt, int limit);
typedef setMemoryLimit_native = Void Function(Pointer<JSRuntime>, IntPtr);

final setMemoryLimit_name = "JS_SetMemoryLimit";
final setMemoryLimit_func setupRuntimeLimit =
    dylib.lookup<NativeFunction<setMemoryLimit_native>>(setMemoryLimit_name).asFunction();

// void JS_SetGCThreshold(JSRuntime *rt, size_t gc_threshold);
typedef setGCThreshold_func = void Function(Pointer<JSRuntime> rt, int gc_threshold);
typedef setGCThreshold_native = Void Function(Pointer<JSRuntime>, IntPtr);

final setGCThreshold_name = "JS_SetGCThreshold";
final setGCThreshold_func setGCThreshold =
    dylib.lookup<NativeFunction<setGCThreshold_native>>(setGCThreshold_name).asFunction();

// void JS_SetMaxStackSize(JSRuntime *rt, size_t stack_size);
typedef setMaxStackSize_func = void Function(Pointer<JSRuntime> rt, int stack_size);
typedef setMaxStackSize_native = Void Function(Pointer<JSRuntime>, IntPtr);

final setMaxStackSize_name = "JS_SetMaxStackSize";
final setMaxStackSize_func setMaxStackSize =
    dylib.lookup<NativeFunction<setMaxStackSize_native>>(setMaxStackSize_name).asFunction();

// JSRuntime *JS_NewRuntime2(const JSMallocFunctions *mf, void *opaque);
typedef newRuntime2_func = void Function(Pointer<JSRuntime>, void);
typedef newRuntime2_native = Void Function(Pointer<JSRuntime>, Void);

final newRuntime2_name = "JS_NewRuntime2";
final newRuntime2_func newRuntime2 =
    dylib.lookup<NativeFunction<newRuntime2_native>>(newRuntime2_name).asFunction();

// void JS_FreeRuntime(JSRuntime *rt);
typedef freeRuntime_func = void Function(Pointer<JSRuntime> rt);
typedef freeRuntime_native = Void Function(Pointer<JSRuntime>);

final freeRuntime_name = "JS_SetMaxStackSize";
final freeRuntime_func freeRuntime =
    dylib.lookup<NativeFunction<freeRuntime_native>>(freeRuntime_name).asFunction();

// void *JS_GetRuntimeOpaque(JSRuntime *rt);
typedef getRuntimeOpaque_func = void Function(Pointer<JSRuntime> rt);
typedef getRuntimeOpaque_native = Void Function(Pointer<JSRuntime>);

final getRuntimeOpaque_name = "JS_GetRuntimeOpaque";
final getRuntimeOpaque_func getRuntimeOpaque =
    dylib.lookup<NativeFunction<getRuntimeOpaque_native>>(getRuntimeOpaque_name).asFunction();

// void JS_SetRuntimeOpaque(JSRuntime *rt, void *opaque); ????? void *
typedef setRuntimeOpaque_func = void Function(Pointer<JSRuntime> rt, void opaque);
typedef setRuntimeOpaque_native = Void Function(Pointer<JSRuntime>, Void);

final setRuntimeOpaque_name = "JS_SetRuntimeOpaque";
final setRuntimeOpaque_func setRuntimeOpaque =
    dylib.lookup<NativeFunction<setRuntimeOpaque_native>>(setRuntimeOpaque_name).asFunction();
// typedef void JS_MarkFunc(JSRuntime *rt, JSGCObjectHeader *gp);
// void JS_MarkValue(JSRuntime *rt, JSValueConst val, JS_MarkFunc *mark_func);
// void JS_RunGC(JSRuntime *rt);
typedef runGC_func = void Function(Pointer<JSRuntime> rt);
typedef runGC_native = Void Function(Pointer<JSRuntime>);

final runGC_name = "JS_RunGC";
final runGC_func runGC = dylib.lookup<NativeFunction<runGC_native>>(runGC_name).asFunction();

// JS_BOOL JS_IsLiveObject(JSRuntime *rt, JSValueConst obj);

// JSContext *JS_NewContext(JSRuntime *rt);
typedef newContext_func = Pointer<JSContext> Function(Pointer<JSRuntime> rt);
typedef newContext_native = Pointer<JSContext> Function(Pointer<JSRuntime>);

final newContext_name = "JS_NewContext";
final newContext_func newContext =
    dylib.lookup<NativeFunction<newContext_native>>(newContext_name).asFunction();

// void JS_FreeContext(JSContext *s);

typedef freeContext_func = void Function(Pointer<JSRuntime> s);
typedef freeContext_native = Void Function(Pointer<JSRuntime>);

final freeContext_name = "JS_FreeContext";
final freeContext_func freeContext =
    dylib.lookup<NativeFunction<freeContext_native>>(freeContext_name).asFunction();

// JSContext *JS_DupContext(JSContext *ctx);
typedef dupContext_func = Pointer<JSContext> Function(Pointer<JSRuntime> ctx);
typedef dupContext_native = Pointer<JSContext> Function(Pointer<JSRuntime>);

final dupContext_name = "JS_DupContext";
final dupContext_func dupContext =
    dylib.lookup<NativeFunction<dupContext_native>>(dupContext_name).asFunction();

// void *JS_GetContextOpaque(JSContext *ctx);
typedef getContextOpaque_func = Pointer<void> Function(Pointer<JSContext> ctx);
typedef getContextOpaque_native = Pointer<Void> Function(Pointer<JSContext> ctx);

final getContextOpaque_name = "JS_GetContextOpaque";
final getContextOpaque_func getContextOpaque =
    dylib.lookup<NativeFunction<getContextOpaque_native>>(getContextOpaque_name).asFunction();

// void JS_SetContextOpaque(JSContext *ctx, void *opaque);
typedef setContextOpaque_func = Pointer<void> Function(Pointer<JSContext> ctx);
typedef setContextOpaque_native = Pointer<Void> Function(Pointer<JSContext> ctx);

final setContextOpaque_name = "JS_SetContextOpaque";
final setContextOpaque_func setContextOpaque =
    dylib.lookup<NativeFunction<setContextOpaque_native>>(setContextOpaque_name).asFunction();

// JSRuntime *JS_GetRuntime(JSContext *ctx);
typedef getRuntime_func = Pointer<JSRuntime> Function(Pointer<JSContext> ctx);
typedef getRuntime_native = Pointer<JSRuntime> Function(Pointer<JSContext>);

final getRuntime_name = "JS_GetRuntime";
final getRuntime_func getRuntime =
    dylib.lookup<NativeFunction<getRuntime_native>>(getRuntime_name).asFunction();

// JSValue JS_GetClassProto(JSContext *ctx, JSClassID class_id);
typedef getClassProto_func = Pointer Function(Pointer<JSContext> ctx, int class_id);
typedef getClassProto_native = Pointer Function(Pointer<JSContext>, Uint32);

final getClassProto_name = "JS_SetClassProto";
final getClassProto_func getClassProto =
    dylib.lookup<NativeFunction<getClassProto_native>>(getClassProto_name).asFunction();

// JSContext *JS_NewContextRaw(JSRuntime *rt);
typedef newContextRaw_func = Pointer<JSContext> Function(Pointer<JSRuntime> rt);
typedef newContextRaw_native = Pointer<JSContext> Function(Pointer<JSRuntime>);

final newContextRaw_name = "JS_NewContextRaw";
final newContextRaw_func newContextRaw =
    dylib.lookup<NativeFunction<newContextRaw_native>>(newContextRaw_name).asFunction();

// void JS_AddIntrinsicBaseObjects(JSContext *ctx);
typedef addIntrinsicBaseObjects_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicBaseObjects_native = Void Function(Pointer<JSContext>);

final addIntrinsicBaseObjects_name = "JS_AddIntrinsicBaseObjects";
final addIntrinsicBaseObjects_func addIntrinsicBaseObjects = dylib
    .lookup<NativeFunction<addIntrinsicBaseObjects_native>>(addIntrinsicBaseObjects_name)
    .asFunction();

// void JS_AddIntrinsicDate(JSContext *ctx);
typedef addIntrinsicDate_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicDate_native = Void Function(Pointer<JSContext>);

final addIntrinsicDate_name = "JS_AddIntrinsicDate";
final addIntrinsicDate_func addIntrinsicDate =
    dylib.lookup<NativeFunction<addIntrinsicDate_native>>(addIntrinsicDate_name).asFunction();

// void JS_AddIntrinsicEval(JSContext *ctx);
typedef addIntrinsicEval_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicEval_native = Void Function(Pointer<JSContext>);

final addIntrinsicEval_name = "JS_AddIntrinsicEval";
final addIntrinsicEval_func addIntrinsicEval =
    dylib.lookup<NativeFunction<addIntrinsicEval_native>>(addIntrinsicEval_name).asFunction();

// void JS_AddIntrinsicStringNormalize(JSContext *ctx);
typedef addIntrinsicStringNormalize_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicStringNormalize_native = Void Function(Pointer<JSContext>);

final addIntrinsicStringNormalize_name = "JS_AddIntrinsicStringNormalize";
final addIntrinsicStringNormalize_func addIntrinsicStringNormalize = dylib
    .lookup<NativeFunction<addIntrinsicStringNormalize_native>>(addIntrinsicStringNormalize_name)
    .asFunction();

// void JS_AddIntrinsicRegExpCompiler(JSContext *ctx);
typedef addIntrinsicRegExpCompiler_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicRegExpCompiler_native = Void Function(Pointer<JSContext>);

final addIntrinsicRegExpCompiler_name = "JS_AddIntrinsicRegExpCompiler";
final addIntrinsicRegExpCompiler_func addIntrinsicRegExpCompiler = dylib
    .lookup<NativeFunction<addIntrinsicRegExpCompiler_native>>(addIntrinsicRegExpCompiler_name)
    .asFunction();

// void JS_AddIntrinsicRegExp(JSContext *ctx);
typedef addIntrinsicRegExp_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicRegExp_native = Void Function(Pointer<JSContext>);

final addIntrinsicRegExp_name = "JS_AddIntrinsicRegExpCompiler";
final addIntrinsicRegExp_func addIntrinsicRegExp =
    dylib.lookup<NativeFunction<addIntrinsicRegExp_native>>(addIntrinsicRegExp_name).asFunction();

// void JS_AddIntrinsicJSON(JSContext *ctx);
typedef addIntrinsicJSON_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicJSON_native = Void Function(Pointer<JSContext>);

final addIntrinsicJSON_name = "JS_AddIntrinsicJSON";
final addIntrinsicJSON_func addIntrinsicJSON =
    dylib.lookup<NativeFunction<addIntrinsicJSON_native>>(addIntrinsicJSON_name).asFunction();

/// void JS_AddIntrinsicProxy(JSContext *ctx);
typedef addIntrinsicProxy_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicProxy_native = Void Function(Pointer<JSContext>);

final addIntrinsicProxy_name = "JS_AddIntrinsicProxy";
final addIntrinsicProxy_func addIntrinsicProxy =
    dylib.lookup<NativeFunction<addIntrinsicProxy_native>>(addIntrinsicProxy_name).asFunction();

/// void JS_AddIntrinsicMapSet(JSContext *ctx);
typedef addIntrinsicMapSet_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicMapSet_native = Void Function(Pointer<JSContext>);

final addIntrinsicMapSet_name = "JS_AddIntrinsicMapSet";
final addIntrinsicMapSet_func addIntrinsicMapSet =
    dylib.lookup<NativeFunction<addIntrinsicMapSet_native>>(addIntrinsicMapSet_name).asFunction();

/// void JS_AddIntrinsicTypedArrays(JSContext *ctx);
typedef addIntrinsicTypedArrays_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicTypedArrays_native = Void Function(Pointer<JSContext>);

final addIntrinsicTypedArrays_name = "JS_AddIntrinsicTypedArrays";
final addIntrinsicTypedArrays_func addIntrinsicTypedArrays = dylib
    .lookup<NativeFunction<addIntrinsicTypedArrays_native>>(addIntrinsicTypedArrays_name)
    .asFunction();

/// void JS_AddIntrinsicPromise(JSContext *ctx);
typedef addIntrinsicPromise_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicPromise_native = Void Function(Pointer<JSContext>);

final addIntrinsicPromise_name = "JS_AddIntrinsicPromise";
final addIntrinsicPromise_func addIntrinsicPromise =
    dylib.lookup<NativeFunction<addIntrinsicPromise_native>>(addIntrinsicPromise_name).asFunction();

/// void JS_AddIntrinsicBigInt(JSContext *ctx);
typedef addIntrinsicBigInt_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicBigInt_native = Void Function(Pointer<JSContext>);

final addIntrinsicBigInt_name = "JS_AddIntrinsicBigInt";
final addIntrinsicBigInt_func addIntrinsicBigInt =
    dylib.lookup<NativeFunction<addIntrinsicBigInt_native>>(addIntrinsicBigInt_name).asFunction();

/// void JS_AddIntrinsicBigFloat(JSContext *ctx);
typedef addIntrinsicBigFloat_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicBigFloat_native = Void Function(Pointer<JSContext>);

final addIntrinsicBigFloat_name = "JS_AddIntrinsicBigFloat";
final addIntrinsicBigFloat_func addIntrinsicBigFloat = dylib
    .lookup<NativeFunction<addIntrinsicBigFloat_native>>(addIntrinsicBigFloat_name)
    .asFunction();

/// void JS_AddIntrinsicBigDecimal(JSContext *ctx);
typedef addIntrinsicBigDecimal_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicBigDecimal_native = Void Function(Pointer<JSContext>);

final addIntrinsicBigDecimal_name = "JS_AddIntrinsicBigDecimal";
final addIntrinsicBigDecimal_func addIntrinsicBigDecimal = dylib
    .lookup<NativeFunction<addIntrinsicBigDecimal_native>>(addIntrinsicBigDecimal_name)
    .asFunction();

// /* enable operator overloading */
/// void JS_AddIntrinsicOperators(JSContext *ctx);
typedef addIntrinsicOperators_func = void Function(Pointer<JSContext> ctx);
typedef addIntrinsicOperators_native = Void Function(Pointer<JSContext>);

final addIntrinsicOperators_name = "JS_AddIntrinsicOperators";
final addIntrinsicOperators_func addIntrinsicOperators = dylib
    .lookup<NativeFunction<addIntrinsicOperators_native>>(addIntrinsicOperators_name)
    .asFunction();

// /* enable "use math" */
/// void JS_EnableBignumExt(JSContext *ctx, JS_BOOL enable);
typedef enableBignumExt_func = void Function(Pointer<JSContext> ctx, int enable);
typedef enableBignumExt_native = Void Function(Pointer<JSContext>, Int32);

final enableBignumExt_name = "JS_EnableBignumExt";
final enableBignumExt_func enableBignumExt =
    dylib.lookup<NativeFunction<enableBignumExt_native>>(enableBignumExt_name).asFunction();

/// JSValue *eval(JSContext *ctx, const char *input, size_t input_len);
typedef eval_func = Pointer Function(Pointer<JSContext> ctx, Pointer script, int thisObject);
typedef eval_native = Pointer Function(Pointer<JSContext> ctx, Pointer script, Int32 length);

final eval_name = "eval";

/// To eval a piece of javascript string, and return JSValue Pointer
/// ```dart
/// eval(JSContext ctx, Utf8Fix.toUtf8("${jsString}"), jsString.length)
/// ```
///
final eval_func eval = dylib.lookup<NativeFunction<eval_native>>(eval_name).asFunction();

/// JSValue invoke(JSContext *ctx, JSValueConst *this_val, uint_32 atom,
///                   int argc, JSValueConst *argv);
typedef invoke_func = Pointer Function(
    Pointer<JSContext> ctx, Pointer this_val, Pointer atom, int argc, Pointer<Pointer> argv);
typedef invoke_native = Pointer Function(
    Pointer<JSContext> ctx, Pointer this_val, Pointer atom, Int32 argc, Pointer<Pointer> argv);

final invoke_name = "invoke";

/// To invoke a JS_Object, pass with atom, argc,argv;
final invoke_func invoke = dylib.lookup<NativeFunction<invoke_native>>(invoke_name).asFunction();

/// JSValue call(JSContext *ctx, JSValueConst *func_obj, JSValueConst *this_obj,
///             int argc, JSValueConst *argv)

typedef call_func = Pointer Function(
    Pointer<JSContext> ctx, Pointer func_obj, Pointer this_val, int argc, Pointer<Pointer> argv);
typedef call_native = Pointer Function(
    Pointer<JSContext> ctx, Pointer func_obj, Pointer this_val, Int32 argc, Pointer<Pointer> argv);

final call_name = "call";

/// To invoke a JS_Object, pass with atom, argc,argv;
final call_func call = dylib.lookup<NativeFunction<call_native>>(call_name).asFunction();

// DART_EXTERN_C JSValue *dart_call_js(JSContext *ctx, JSValueConst *func_obj, JSValueConst *this_obj, int argc, JSValueConst **argv_ptrs)
typedef dart_call_js_func = Pointer Function(
    Pointer<JSContext> ctx, Pointer func_obj, Pointer this_val, int argc, Pointer<Pointer> argv);
typedef dart_call_js_native = Pointer Function(
    Pointer<JSContext> ctx, Pointer func_obj, Pointer this_val, Int32 argc, Pointer<Pointer> argv);

final dart_call_js_name = "dart_call_js";

/// To invoke a JS_Object, pass with atom, argc,argv;
final dart_call_js_func dart_call_js =
    dylib.lookup<NativeFunction<dart_call_js_native>>(dart_call_js_name).asFunction();

/// JSValue *evalFunction(JSContext *ctx, JSValue *fun_obj);
typedef evalFunction_func = Pointer Function(Pointer ctx, Pointer func_obj);
typedef evalFunction_native = Pointer Function(Pointer ctx, Pointer func_obj);

final evalFunction_name = "evalFunction";
final evalFunction_func evalFunction =
    dylib.lookup<NativeFunction<evalFunction_native>>(evalFunction_name).asFunction();

/// DART_EXTERN_C void installDartHook(JSContext *ctx, JSValueConst *this_val, const char *func_name, JSValue* fun_data)
typedef installDartHook_func = void Function(
    Pointer<JSContext> ctx, Pointer this_val, Pointer<Utf8Fix> func_name, int func_id);
typedef installDartHook_native = Void Function(
    Pointer<JSContext> ctx, Pointer this_val, Pointer<Utf8Fix> func_name, Int64 func_id);
final installDartHook_name = "installDartHook";
final installDartHook_func installDartHook =
    dylib.lookup<NativeFunction<installDartHook_native>>(installDartHook_name).asFunction();

//
final registerDartCallbackFP =
    dylib.lookupFunction<Void Function(Pointer), void Function(Pointer)>("RegisterDartCallbackFP");

// final registerDartVoidCallbackFP = dylib
//     .lookupFunction<Void Function(Pointer), void Function(Pointer)>("RegisterDartVoidCallbackFP");

// // DART_EXTERN_C void store_async_value(int64_t func_id, JSValue *result_ptr)
// final store_async_value =
//     dylib.lookupFunction<Void Function(Int64, Pointer), void Function(int, Pointer)>(
//         "store_async_value");

// final registerAsyncDartCallbackFP = dylib
//     .lookupFunction<Void Function(Pointer), void Function(Pointer)>("RegisterAsyncDartCallbackFP");

// typedef installAsyncDartHook_func = void Function(
//     Pointer<JSContext> ctx, Pointer this_val, Pointer<Utf8Fix> func_name, Pointer func_id);
// typedef installAsyncDartHook_native = Void Function(
//     Pointer<JSContext> ctx, Pointer this_val, Pointer<Utf8Fix> func_name, Pointer func_id);
// final installAsyncDartHook_name = "installAsyncDartHook";
// final installAsyncDartHook_func installAsyncDartHook = dylib
//     .lookup<NativeFunction<installAsyncDartHook_native>>(installAsyncDartHook_name)
//     .asFunction();

// // // DART_EXPORT typedef std::function<void()> Work;
// class Work extends Struct {}

// // DART_EXTERN_C void ExecuteCallback(Work *work_ptr,JSValue *result)

// final ExecuteCallback = dylib.lookupFunction<Void Function(Pointer<Work>, Pointer),
//     void Function(Pointer<Work>, Pointer)>('ExecuteCallback');

// // DART_EXTERN_C void
// // setAsyncResult(JSContext *ctx, JSValueConst *queue_id, JSValueConst *func_data)

// final setAsyncResult = dylib.lookupFunction<Void Function(Pointer<JSContext>, Pointer, Pointer),
//     void Function(Pointer<JSContext>, Pointer, Pointer)>('setAsyncResult');

// DART_EXTERN_C int isJobPending(JSRuntime *rt)
final isJobPending =
    dylib.lookupFunction<Int32 Function(Pointer<JSRuntime>), int Function(Pointer<JSRuntime>)>(
        'isJobPending');

// DART_EXTERN_C JSValue *executePendingJob(JSRuntime *rt, int maxJobsToExecute)
final executePendingJob = dylib.lookupFunction<Pointer Function(Pointer<JSRuntime>, Int32),
    Pointer Function(Pointer<JSRuntime>, int)>('executePendingJob');

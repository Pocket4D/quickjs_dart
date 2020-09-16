#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <cstddef>
#include <cmath>
#include <csignal>
#include <sys/types.h>
#include <zconf.h>
#include <condition_variable> // NOLINT(build/c++11)
#include <functional>         // NOLINT(build/c++11)
#include <mutex>              // NOLINT(build/c++11)
#include <queue>              // NOLINT(build/c++11)
#include <thread>             // NOLINT(build/c++11)
#include <setjmp.h>           // NOLINT
#include <signal.h>           // NOLINT
#include <future>

// #include "quickjs/quickjs-libc.h"
#include "quickjs/quickjs.h"
#include "quickjs-ffi.h"

/* ---------------------------------------- */
/* JSValue Invoking                         */
/* ---------------------------------------- */

enum {
    __JS_ATOM_NULL = JS_ATOM_NULL,
#define DEF(name, str) JS_ATOM_##name,

#include "quickjs/quickjs-atom.h"

#undef DEF
    JS_ATOM_END,
};
#define JS_ATOM_LAST_KEYWORD JS_ATOM_super
#define JS_ATOM_LAST_STRICT_KEYWORD JS_ATOM_yield

static const char js_atom_init[] = {
#define DEF(name, str) str "\0"

#include "quickjs/quickjs-atom.h"

#undef DEF
};

extern "C"
{
void
RegisterDartCallbackFP(
        dart_handle_func callback) {
    dart_callback_ = callback;
}

// memcpy when result is static
JSValue *jsvalue_to_heap(JSValueConst value) {
    auto *result = static_cast<JSValue *>(malloc(sizeof(JSValueConst)));
    if (result) {
        memcpy(result, &value, sizeof(JSValue));
    }
    return result;
}

JSValue *jsvalue_copy(JSValue *des, JSValue *src) {
    memcpy(des, src, sizeof(JSValueConst));
    return des;
}

JSAtom *jsatom_to_heap(JSAtom value) {
    auto *result = static_cast<JSAtom *>(malloc(sizeof(JSAtom)));
    if (result) {
        memcpy(result, &value, sizeof(JSAtom));
    }
    return result;
}

JSValue *newPromiseCapability(JSContext *ctx, JSValue **resolve_funcs_out) {
    JSValue resolve_funcs[2];
    JSValue promise = JS_NewPromiseCapability(ctx, resolve_funcs);
    resolve_funcs_out[0] = jsvalue_to_heap(resolve_funcs[0]);
    resolve_funcs_out[1] = jsvalue_to_heap(resolve_funcs[1]);
    return jsvalue_to_heap(promise);
}

JSValue
InvokeDartCallback(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv, int magic, JSValue *func_data) {
    if (dart_callback_ == nullptr) {
        printf("callback from C, but no Callback set");
        abort();
    }
    JSValue *result_ptr = (*dart_callback_)(ctx, &this_val, argc, argv, func_data);
    JSValue ret = *result_ptr;
    free(result_ptr);
    return ret;
}

// todo: func_name should be JSValue and atom = valuetoAtom
void installDartHook(JSContext *ctx, JSValueConst *this_val, JSValueConst *func_name, int64_t func_id) {
    JSValue cfn = JS_NewCFunctionData(ctx, &InvokeDartCallback, 0, 0, 1, newInt64(ctx, func_id));
    JSValue dupped = JS_DupValue(ctx, cfn);
    // JSAtom atom = JS_NewAtom(ctx, func_name);
    JSAtom *atom = valueToAtom(ctx, func_name);
    definePropertyValue(ctx, this_val, atom, &dupped, JS_PROP_WRITABLE | JS_PROP_CONFIGURABLE);
}

// todo: func_name should be JSValue and atom = valuetoAtom, func_data should be JSValue(Object:{port_id:handler:id})

/**
* Interrupt handler - called regularly from QuickJS. Return !=0 to interrupt.
* TODO: because this is perf critical, really send a new func pointer for each
* call to QTS_RuntimeEnableInterruptHandler instead of using dispatch.
*/

dart_interrupt_func *bound_interrupt = nullptr;

int interrupt_handler(JSRuntime *rt, void *_unused) {
    if (bound_interrupt == nullptr) {
        printf("cannot call interrupt handler because no dart_interrupt_func set");
        abort();
    }
    return (*bound_interrupt)(rt);
}

void setInterruptCallback(dart_interrupt_func *cb) {
    bound_interrupt = cb;
}

void runtimeEnableInterruptHandler(JSRuntime *rt) {
    if (bound_interrupt == nullptr) {
        printf("cannot enable interrupt handler because no dart_interrupt_func set");
        abort();
    }

    JS_SetInterruptHandler(rt, &interrupt_handler, nullptr);
}

void runtimeDisableInterruptHandler(JSRuntime *rt) {
    JS_SetInterruptHandler(rt, nullptr, nullptr);
}

/*
runs pending jobs (Promises/async functions) until it encounters
an exception or it executed the passed maxJobsToExecute jobs.
Passing a negative value will run the loop until there are no more
pending jobs or an exception happened
Returns the executed number of jobs or the exception encountered
*/
JSValue *executePendingJob(JSRuntime *rt, int maxJobsToExecute) {
    JSContext *ctx_pointer;
    int status = 1;
    int executed = 0;
    while (executed != maxJobsToExecute && status == 1) {
        status = JS_ExecutePendingJob(rt, &ctx_pointer);
        if (status == -1) {
            return jsvalue_to_heap(JS_GetException(ctx_pointer));
        } else if (status == 1) {
            executed++;
        }
    }
    return jsvalue_to_heap(JS_NewFloat64(ctx_pointer, executed));
}

int isJobPending(JSRuntime *rt) {
    return JS_IsJobPending(rt);
}

/**
* If maybe_exception is an exception, get the error.
* Otherwise, return NULL.
*/
JSValue *resolveException(JSContext *ctx, const JSValue *maybe_exception) {
    if (JS_IsException(*maybe_exception)) {
        return jsvalue_to_heap(JS_GetException(ctx));
    }

    return nullptr;
}

void copy_prop_if_needed(JSContext *ctx, JSValueConst dest, JSValueConst src, const char *prop_name) {
    JSAtom prop_atom = JS_NewAtom(ctx, prop_name);
    JSValue dest_prop = JS_GetProperty(ctx, dest, prop_atom);
    if (JS_IsUndefined(dest_prop)) {
        JSValue src_prop = JS_GetProperty(ctx, src, prop_atom);
        if (!JS_IsUndefined(src_prop) && !JS_IsException(src_prop)) {
            JS_SetProperty(ctx, dest, prop_atom, src_prop);
        }
    } else {
        JS_FreeValue(ctx, dest_prop);
    }
    JS_FreeAtom(ctx, prop_atom);
}

JSValue *
dart_call_js(JSContext *ctx, JSValueConst *func_obj, JSValueConst *this_obj, int argc, JSValueConst **argv_ptrs) {
    // convert array of pointers to array of values

    JSValueConst argv[argc];
    int i;
    for (i = 0; i < argc; i++) {
        argv[i] = *(argv_ptrs[i]);
    }

    return jsvalue_to_heap(JS_Call(ctx, *func_obj, *this_obj, argc, argv));
}

JSValue *call(JSContext *ctx, JSValueConst *func_obj, JSValueConst *this_obj,
              int argc, JSValueConst **argv_ptrs) {
    JSValueConst argv[argc];
    int i;
    for (i = 0; i < argc; i++) {
        argv[i] = *(argv_ptrs[i]);
    }
    return jsvalue_to_heap(JS_Call(ctx, *func_obj, *this_obj, argc, argv));
}

JSValue *invoke(JSContext *ctx, JSValueConst *this_val, const JSAtom *atom,
                int argc, JSValueConst **argv_ptrs) {
    JSValueConst argv[argc];
    int i;
    for (i = 0; i < argc; i++) {
        argv[i] = *(argv_ptrs[i]);
    }
    return jsvalue_to_heap(JS_Invoke(ctx, *this_val, *atom, argc, argv));
}

JSValue *callConstructor(JSContext *ctx, JSValueConst *func_obj,
                         int argc, JSValueConst *argv) {
    return jsvalue_to_heap(JS_CallConstructor(ctx, *func_obj, argc, argv));
}

JSValue *callConstructor2(JSContext *ctx, JSValueConst *func_obj,
                          JSValueConst *new_target,
                          int argc, JSValueConst *argv) {
    return jsvalue_to_heap(JS_CallConstructor2(ctx, *func_obj, *new_target, argc, argv));
}

JS_BOOL detectModule(const char *input, size_t input_len) {
    return JS_DetectModule(input, input_len);
}

char *genRandomString(int length) {
    int flag, i;
    char *string;
    srand((unsigned) time(NULL));
    if ((string = (char *) malloc(length)) == NULL) {
        // myLog("Malloc failed!flag:14\n");
        return NULL;
    }

    for (i = 0; i < length - 1; i++) {
        flag = rand() % 3;
        switch (flag) {
            case 0:
                string[i] = 'A' + rand() % 26;
                break;
            case 1:
                string[i] = 'a' + rand() % 26;
                break;
            case 2:
                string[i] = '0' + rand() % 10;
                break;
            default:
                string[i] = 'x';
                break;
        }
    }
    string[length - 1] = '\0';
    return string;
}

/* 'input' must be zero terminated i.e. input[input_len] = '\0'. */
// JSValue *eval(JSContext *ctx, const char *input, size_t input_len,
//                 const char *filename, int eval_flags);
JSValue *eval(JSContext *ctx, char *input, size_t input_len) {
    //    int argc = 0;
    //    char *argv[1] = {nullptr};
    //    js_std_add_helpers(ctx, argc, argv);
    JSValue evalResult = JS_Eval(ctx, input, input_len, "<input>", JS_EVAL_TYPE_GLOBAL);
    // js_std_loop(ctx);
    return jsvalue_to_heap(evalResult);
}

char *reverse(const char *str, int length) {
    char *reversed_str = (char *) malloc((length + 1) * sizeof(char));
    for (int i = 0; i < length; i++) {
        reversed_str[length - i - 1] = str[i];
    }
    reversed_str[length] = '\0';
    return reversed_str;
}

JSValue *evalFunction(JSContext *ctx, JSValue *fun_obj) {
    return jsvalue_to_heap(JS_EvalFunction(ctx, *fun_obj));
}

// an unwrapper from pointer to JSValue, used in dart:ffi
JSValue unwrap(JSValue *value) {
    JSValue ret = *value;
    return ret;
}

JSValueConst *getJSValueConstPointer(JSValueConst *argv, int index) {
    return &argv[index];
}

JSValue *getGlobalObject(JSContext *ctx) {
    return jsvalue_to_heap(JS_GetGlobalObject(ctx));
}

/* ---------------------------------------- */
/* Properties                               */
/* ---------------------------------------- */

int isInstanceOf(JSContext *ctx, JSValueConst *val, JSValueConst *obj) {
    return JS_IsInstanceOf(ctx, *val, *obj);
}

int defineProperty(JSContext *ctx, JSValueConst *this_obj,
                   const JSAtom *prop, JSValueConst *val,
                   JSValueConst *getter, JSValueConst *setter, int flags) {
    return JS_DefineProperty(ctx, *this_obj, *prop, *val, *getter, *setter, flags);
}

int definePropertyValue(JSContext *ctx, JSValueConst *this_obj,
                        const JSAtom *prop, JSValue *val, int flags) {
    // int ret = JS_DefinePropertyValue(ctx, *this_obj, *prop, *val, flags);
    // JS_FreeValue(ctx, *val);
    return JS_DefinePropertyValue(ctx, *this_obj, *prop, *val, flags);
}

int definePropertyValueUint32(JSContext *ctx, JSValueConst *this_obj,
                              uint32_t idx, JSValue *val, int flags) {
    return JS_DefinePropertyValueUint32(ctx, *this_obj, idx, *val, flags);
}

int definePropertyValueStr(JSContext *ctx, JSValueConst *this_obj,
                           const char *prop, JSValue *val, int flags) {
    return JS_DefinePropertyValueStr(ctx, *this_obj, prop, *val, flags);
}

int definePropertyGetSet(JSContext *ctx, JSValueConst *this_obj,
                         const JSAtom *prop, JSValue *getter, JSValue *setter,
                         int flags) {
    return JS_DefinePropertyGetSet(ctx, *this_obj, *prop, *getter, *setter, flags);
}

void setOpaque(JSValue *obj, void *opaque) {
    JS_SetOpaque(*obj, opaque);
}

void *getOpaque(JSValueConst *obj, JSClassID class_id) {
    return JS_GetOpaque(*obj, class_id);
}

void *getOpaque2(JSContext *ctx, JSValueConst *obj, JSClassID class_id) {
    return JS_GetOpaque2(ctx, *obj, class_id);
}

JSValue *parseJSON(JSContext *ctx, const char *buf, size_t buf_len,
                   const char *filename) {
    return jsvalue_to_heap(JS_ParseJSON(ctx, buf, buf_len, filename));
}

JSValue *parseJSON2(JSContext *ctx, const char *buf, size_t buf_len,
                    const char *filename, int flags) {
    return jsvalue_to_heap(JS_ParseJSON2(ctx, buf, buf_len, filename, flags));
}

JSValue *JSONStringify(JSContext *ctx, JSValueConst *obj) {
    return jsvalue_to_heap(JS_JSONStringify(ctx, *obj, JS_UNDEFINED, JS_UNDEFINED));
}

JSValue *newArrayBuffer(JSContext *ctx, uint8_t *buf, size_t len,
                        JSFreeArrayBufferDataFunc *free_func, void *opaque,
                        JS_BOOL is_shared) {
    return jsvalue_to_heap(JS_NewArrayBuffer(ctx, buf, len, free_func, opaque, is_shared));
}

JSValue *newArrayBufferCopy(JSContext *ctx, const uint8_t *buf, size_t len) {
    return jsvalue_to_heap(JS_NewArrayBufferCopy(ctx, buf, len));
}

void detachArrayBuffer(JSContext *ctx, JSValueConst *obj) {
    JS_DetachArrayBuffer(ctx, *obj);
}

uint8_t *getArrayBuffer(JSContext *ctx, size_t *psize, JSValueConst *obj) {
    return JS_GetArrayBuffer(ctx, psize, *obj);
}

JSValue *getTypedArrayBuffer(JSContext *ctx, JSValueConst *obj,
                             size_t *pbyte_offset,
                             size_t *pbyte_length,
                             size_t *pbytes_per_element) {
    return jsvalue_to_heap(JS_GetTypedArrayBuffer(ctx, *obj, pbyte_offset, pbyte_length, pbytes_per_element));
}

/* ---------------------------------------- */
/* JSValue Creation                         */
/* ---------------------------------------- */

JSValue *newError(JSContext *ctx) {
    return jsvalue_to_heap(JS_NewError(ctx));
}

JSValue *newBool(JSContext *ctx, JS_BOOL val) {
    return jsvalue_to_heap(JS_NewBool(ctx, val));
}

JSValue *newNull(JSContext *ctx) {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_NULL, 0));
}

JSValue *newUndefined(JSContext *ctx) {
    return jsvalue_to_heap(JS_UNDEFINED);
}

JSValue *newInt32(JSContext *ctx, int32_t val) {
    return jsvalue_to_heap(JS_NewInt32(ctx, val));
}

JSValue *newCatchOffset(JSContext *ctx, int32_t val) {
    return jsvalue_to_heap(JS_NewCatchOffset(ctx, val));
}

JSValue *newInt64(JSContext *ctx, int64_t val) {
    return jsvalue_to_heap(JS_NewInt64(ctx, val));
}

JSValue *newUint32(JSContext *ctx, uint32_t val) {
    return jsvalue_to_heap(JS_NewUint32(ctx, val));
}

JSValue *newBigInt64(JSContext *ctx, int64_t v) {
    return jsvalue_to_heap(JS_NewBigInt64(ctx, v));
}

JSValue *newBigUint64(JSContext *ctx, uint64_t v) {
    return jsvalue_to_heap(JS_NewBigUint64(ctx, v));
}

JSValue *newFloat64(JSContext *ctx, double d) {
    return jsvalue_to_heap(JS_NewFloat64(ctx, d));
}

JSValue *newStringLen(JSContext *ctx, const char *str1, size_t len1) {
    return jsvalue_to_heap(JS_NewStringLen(ctx, str1, len1));
}

JSValue *newString(JSContext *ctx, const char *str) {
    return jsvalue_to_heap(JS_NewString(ctx, str));
}

JSValue *newAtomString(JSContext *ctx, const char *str) {
    return jsvalue_to_heap(JS_NewAtomString(ctx, str));
}

JSValue *newObjectProtoClass(JSContext *ctx, JSValueConst *proto, JSClassID class_id) {
    return jsvalue_to_heap(JS_NewObjectProtoClass(ctx, *proto, class_id));
}

JSValue *newObjectClass(JSContext *ctx, int class_id) {
    return jsvalue_to_heap(JS_NewObjectClass(ctx, class_id));
}

JSValue *newObjectProto(JSContext *ctx, JSValueConst *proto) {
    return jsvalue_to_heap(JS_NewObjectProto(ctx, *proto));
}

JSValue *newObject(JSContext *ctx) {
    return jsvalue_to_heap(JS_NewObject(ctx));
}

JSValue *newArray(JSContext *ctx) {
    return jsvalue_to_heap(JS_NewArray(ctx));
}

//#define JS_NULL      JS_MKVAL(JS_TAG_NULL, 0)
JSValue *js_null() {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_NULL, 0));
}

//#define JS_UNDEFINED JS_MKVAL(JS_TAG_UNDEFINED, 0)
JSValue *js_undefined() {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_UNDEFINED, 0));
}
//#define JS_FALSE     JS_MKVAL(JS_TAG_BOOL, 0)
JSValue *js_false() {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_BOOL, 0));
}
//#define JS_TRUE      JS_MKVAL(JS_TAG_BOOL, 1)
JSValue *js_true() {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_BOOL, 1));
}
//#define JS_EXCEPTION JS_MKVAL(JS_TAG_EXCEPTION, 0)
JSValue *js_exception() {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_EXCEPTION, 0));
}
//#define JS_UNINITIALIZED JS_MKVAL(JS_TAG_UNINITIALIZED, 0)
JSValue *js_uninitialized() {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_UNINITIALIZED, 0));
}

/* ---------------------------------------- */
/* JSValue Validator                        */
/* ---------------------------------------- */

JS_BOOL isNan(JSValue *v) {
    return JS_VALUE_IS_NAN(*v);
}

JS_BOOL isNumber(JSValue *v) {
    return JS_IsNumber(*v);
}

JS_BOOL isBigInt(JSContext *ctx, JSValueConst *v) {
    return JS_IsBigInt(ctx, *v);
}

JS_BOOL isBigFloat(JSValueConst *v) {
    return JS_IsBigFloat(*v);
}

JS_BOOL isBigDecimal(JSValueConst *v) {
    return JS_IsBigDecimal(*v);
}

JS_BOOL isBool(JSValueConst *v) {
    return JS_IsBool(*v);
}

JS_BOOL isNull(JSValueConst *v) {
    return JS_IsNull(*v);
}

JS_BOOL isUndefined(JSValueConst *v) {
    return JS_IsUndefined(*v);
}

JS_BOOL isException(JSValueConst *v) {
    return JS_IsException(*v);
}

JS_BOOL isUninitialized(JSValueConst *v) {
    return JS_IsUninitialized(*v);
}

JS_BOOL isString(JSValueConst *v) {
    return JS_IsString(*v);
}

JS_BOOL isSymbol(JSValueConst *v) {
    return JS_IsSymbol(*v);
}

JS_BOOL isObject(JSValueConst *v) {
    return JS_IsObject(*v);
}

JS_BOOL isError(JSContext *ctx, JSValueConst *val) {
    return JS_IsError(ctx, *val);
}

JS_BOOL isFunction(JSContext *ctx, JSValueConst *val) {
    return JS_IsFunction(ctx, *val);
}

JS_BOOL isConstructor(JSContext *ctx, JSValueConst *val) {
    return JS_IsConstructor(ctx, *val);
}

int isArray(JSContext *ctx, JSValueConst *val) {
    return JS_IsArray(ctx, *val);
}

int isExtensible(JSContext *ctx, JSValueConst *obj) {
    return JS_IsExtensible(ctx, *obj);
}

/* ---------------------------------------- */
/* JSAtom Execution                         */
/* ---------------------------------------- */

int getValueTag(JSValue v) {
    return JS_VALUE_GET_NORM_TAG(v);
}

void freeValue(JSContext *ctx, JSValue *v) {
    JS_FreeValue(ctx, *v);
}

void freeValueRT(JSRuntime *rt, JSValue *v) {
    JS_FreeValueRT(rt, *v);
}

JSValue *dupValue(JSContext *ctx, JSValueConst *v) {
    return jsvalue_to_heap(JS_DupValue(ctx, *v));
}

JSValue *dupValueRT(JSRuntime *rt, JSValueConst *v) {
    return jsvalue_to_heap(JS_DupValueRT(rt, *v));
}

int toBool(JSContext *ctx, JSValueConst *val) {
    return JS_ToBool(ctx, *val);
}

int32_t toInt32(JSContext *ctx, JSValueConst *val) {
    int32_t present = 0;
    JS_ToInt32(ctx, &present, *val);
    return present;
}

int toUint32(JSContext *ctx, uint32_t *pres, JSValueConst *val) {
    return JS_ToUint32(ctx, pres, *val);
}

int64_t toInt64(JSContext *ctx, JSValueConst *val) {
    int64_t present = 0;
    JS_ToInt64(ctx, &present, *val);
    // JS_FreeValue(ctx, *val);
    return present;
}

int toIndex(JSContext *ctx, uint64_t *plen, JSValueConst *val) {
    return JS_ToIndex(ctx, plen, *val);
}

double toFloat64(JSContext *ctx, JSValueConst *val) {
    double ret = NAN;
    JS_ToFloat64(ctx, &ret, *val);
    return ret;
}

int toBigInt64(JSContext *ctx, int64_t *pres, JSValueConst *val) {
    return JS_ToBigInt64(ctx, pres, *val);
}

int toInt64Ext(JSContext *ctx, int64_t *pres, JSValueConst *val) {
    return JS_ToInt64Ext(ctx, pres, *val);
}

JSValue *toString(JSContext *ctx, JSValueConst *val) {
    return jsvalue_to_heap(JS_ToString(ctx, *val));
}

JSValue *toPropertyKey(JSContext *ctx, JSValueConst *val) {
    return jsvalue_to_heap(JS_ToString(ctx, *val));
}

const char *toCStringLen2(JSContext *ctx, size_t *plen, JSValueConst *val1, JS_BOOL cesu8) {
    return JS_ToCStringLen2(ctx, plen, *val1, cesu8);
}

const char *toCStringLen(JSContext *ctx, size_t *plen, JSValueConst *val1) {
    return JS_ToCStringLen(ctx, plen, *val1);
}

const char *toCString(JSContext *ctx, JSValueConst *val1) {
    const char *value = JS_ToCString(ctx, *val1);
    char *ret_str;
    int valStrLen = strlen(value);
    // printf("valStrlen: %d \n", valStrLen);
    ret_str = (char *) malloc((valStrLen + 1) * sizeof(char));
    strcpy(ret_str, value);
    return ret_str;
}

char toDartString(JSContext *ctx, JSValueConst *val) {
    const char *value = JS_ToCString(ctx, *val);
    char *ret_str;
    int valStrLen = strlen(value);
    ret_str = (char *) malloc((valStrLen + 1) * sizeof(char));
    strcpy(ret_str, value);
    char ret = *ret_str;
    return ret;
}

void freeCString(JSContext *ctx, const char *ptr) {
    JS_FreeCString(ctx, ptr);
}

JS_BOOL setConstructorBit(JSContext *ctx, JSValueConst *func_obj, JS_BOOL val) {
    return JS_SetConstructorBit(ctx, *func_obj, val);
}

JSValue *getPropertyStr(JSContext *ctx, JSValueConst *this_obj,
                        const char *prop) {
    return jsvalue_to_heap(JS_GetPropertyStr(ctx, *this_obj, prop));
}

JSValue *getPropertyUint32(JSContext *ctx, JSValueConst *this_obj,
                           uint32_t idx) {
    return jsvalue_to_heap(JS_GetPropertyUint32(ctx, *this_obj, idx));
}

int setPropertyInternal(JSContext *ctx, JSValueConst *this_obj,
                        const JSAtom *prop, JSValue *val,
                        int flags) {
    return JS_SetPropertyInternal(ctx, *this_obj, *prop, *val, flags);
}

void
setProp(JSContext *ctx, JSValueConst *this_val, JSValueConst *prop_name, JSValueConst *prop_value, int flags) {
    JSAtom prop_atom = JS_ValueToAtom(ctx, *prop_name);
    JSValue extra_prop_value = JS_DupValue(ctx, *prop_value);
    JS_SetPropertyInternal(ctx, *this_val, prop_atom, extra_prop_value, flags); // consumes extra_prop_value
    JS_FreeAtom(ctx, prop_atom);
}

int setProperty(JSContext *ctx, JSValueConst *this_obj,
                const JSAtom *prop, JSValue *val) {
    return JS_SetProperty(ctx, *this_obj, *prop, *val);
}

int setPropertyUint32(JSContext *ctx, JSValueConst *this_obj,
                      uint32_t idx, JSValue *val) {
    return JS_SetPropertyUint32(ctx, *this_obj, idx, *val);
}

int setPropertyInt64(JSContext *ctx, JSValueConst *this_obj,
                     int64_t idx, JSValue *val) {
    return JS_SetPropertyInt64(ctx, *this_obj, idx, *val);
}

int setPropertyStr(JSContext *ctx, JSValueConst *this_obj,
                   const char *prop, JSValue *val) {
    return JS_SetPropertyStr(ctx, *this_obj, prop, *val);
}

int hasProperty(JSContext *ctx, JSValueConst *this_obj, const JSAtom *prop) {
    return JS_HasProperty(ctx, *this_obj, *prop);
}

int preventExtensions(JSContext *ctx, JSValueConst *obj) {
    return JS_PreventExtensions(ctx, *obj);
}

int deleteProperty(JSContext *ctx, JSValueConst *obj, const JSAtom *prop, int flags) {
    return JS_DeleteProperty(ctx, *obj, *prop, flags);
}

int setPrototype(JSContext *ctx, JSValueConst *obj, JSValueConst *proto_val) {
    return JS_SetPrototype(ctx, *obj, *proto_val);
}

JSValue *getPrototype(JSContext *ctx, JSValueConst *val) {
    return jsvalue_to_heap(JS_GetPrototype(ctx, *val));
}

int getOwnPropertyNames(JSContext *ctx, JSPropertyEnum **ptab,
                        uint32_t *plen, JSValueConst *obj, int flags) {
    return JS_GetOwnPropertyNames(ctx, ptab, plen, *obj, flags);
}

int getOwnProperty(JSContext *ctx, JSPropertyDescriptor *desc,
                   JSValueConst *obj, const JSAtom *prop) {
    return JS_GetOwnProperty(ctx, desc, *obj, *prop);
}

/* ---------------------------------------- */
/* JSAtom Creation                          */
/* ---------------------------------------- */

JSAtom *newAtom(JSContext *ctx, const char *str) {
    return jsatom_to_heap(JS_NewAtom(ctx, str));
}

JSAtom *valueToAtom(JSContext *ctx, JSValueConst *val) {
    return jsatom_to_heap(JS_ValueToAtom(ctx, *val));
}

JSValue *atomToValue(JSContext *ctx, JSAtom atom) {
    return jsvalue_to_heap(JS_AtomToValue(ctx, atom));
}

JSValue *atomToString(JSContext *ctx, uint32_t atom) {
    return jsvalue_to_heap(JS_AtomToString(ctx, atom));
}

int oper_typeof(JSContext *ctx, const JSValue *op1) {
    JSAtom atom;
    int32_t tag;

    tag = JS_VALUE_GET_NORM_TAG(*op1);
    switch (tag) {
#ifdef CONFIG_BIGNUM
        case JS_TAG_BIG_INT:
            atom = JS_ATOM_bigint;
            break;
        case JS_TAG_BIG_FLOAT:
            atom = JS_ATOM_bigfloat;
            break;
        case JS_TAG_BIG_DECIMAL:
            atom = JS_ATOM_bigdecimal;
            break;
#endif
        case JS_TAG_INT:
        case JS_TAG_FLOAT64:
            atom = JS_ATOM_number;
            break;
        case JS_TAG_UNDEFINED:
            atom = JS_ATOM_undefined;
            break;
        case JS_TAG_BOOL:
            atom = JS_ATOM_boolean;
            break;
        case JS_TAG_STRING:
            atom = JS_ATOM_string;
            break;
        case JS_TAG_OBJECT:
            if (JS_IsFunction(ctx, *op1))
                atom = JS_ATOM_function;
            else
                goto obj_type;
            break;
        case JS_TAG_NULL:
        obj_type:
            atom = JS_ATOM_object;
            break;
        case JS_TAG_SYMBOL:
            atom = JS_ATOM_symbol;
            break;
        default:
            atom = JS_ATOM_unknown;
            break;
    }
    return atom;
}

const char *dump(JSContext *ctx, JSValueConst *obj) {
    JSValue obj_json_value = JS_JSONStringify(ctx, *obj, JS_UNDEFINED, JS_UNDEFINED);
    if (!JS_IsException(obj_json_value)) {
        const char *obj_json_chars = JS_ToCString(ctx, obj_json_value);
        JS_FreeValue(ctx, obj_json_value);
        if (obj_json_chars != nullptr) {
            JSValue enumerable_props = JS_ParseJSON(ctx, obj_json_chars, strlen(obj_json_chars), "<dump>");
            JS_FreeCString(ctx, obj_json_chars);
            if (!JS_IsException(enumerable_props)) {
                // Copy common non-enumerable props for different object types.
                // Errors:
                copy_prop_if_needed(ctx, enumerable_props, *obj, "name");
                copy_prop_if_needed(ctx, enumerable_props, *obj, "message");
                copy_prop_if_needed(ctx, enumerable_props, *obj, "stack");

                // Serialize again.
                JSValue enumerable_json = JS_JSONStringify(ctx, enumerable_props, JS_UNDEFINED, JS_UNDEFINED);
                JS_FreeValue(ctx, enumerable_props);

                const char *result = toCString(ctx, &enumerable_json);
                JS_FreeValue(ctx, enumerable_json);
                return result;
            }
        }
    }

#ifdef QUICKJS_DEBUG_MODE
    // qts_log("Error dumping JSON:");
    js_std_dump_error(ctx);
#endif

    // Fallback: convert to string
    return toCString(ctx, obj);
}
}

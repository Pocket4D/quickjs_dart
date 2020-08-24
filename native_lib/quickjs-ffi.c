#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stddef.h>
#include <sys/types.h>
#include <zconf.h>

#include "quickjs/quickjs.h"
#include "quickjs-ffi.h"
#include "include/dart_api_dl.h"
#include "include/dart_version.h"
#include "include/internal/dart_api_dl_impl.h"

#define DART_API_DL_DEFINITIONS(name, R, A) \
    typedef R(*name##_Type) A;              \
    name##_Type name##_DL = NULL;

DART_API_ALL_DL_SYMBOLS(DART_API_DL_DEFINITIONS)

#undef DART_API_DL_DEFINITIONS

typedef void (*DartApiEntry_function)();

DartApiEntry_function FindFunctionPointer(const DartApiEntry *entries,
                                          const char *name) {
    while (entries->name != NULL) {
        if (strcmp(entries->name, name) == 0)
            return entries->function;
        entries++;
    }
    return NULL;
}

intptr_t Dart_InitializeApiDL(void *data) {
    DartApi *dart_api_data = (DartApi *) data;

    if (dart_api_data->major != DART_API_DL_MAJOR_VERSION) {
        // If the DartVM we're running on does not have the same version as this
        // file was compiled against, refuse to initialize. The symbols are not
        // compatible.
        return -1;
    }
    // Minor versions are allowed to be different.
    // If the DartVM has a higher minor version, it will provide more symbols
    // than we initialize here.
    // If the DartVM has a lower minor version, it will not provide all symbols.
    // In that case, we leave the missing symbols un-initialized. Those symbols
    // should not be used by the Dart and native code. The client is responsible
    // for checking the minor version number himself based on which symbols it
    // is using.
    // (If we would error out on this case, recompiling native code against a
    // newer SDK would break all uses on older SDKs, which is too strict.)

    const DartApiEntry *dart_api_function_pointers = dart_api_data->functions;

#define DART_API_DL_INIT(name, R, A) \
    name##_DL = (name##_Type)(       \
        FindFunctionPointer(dart_api_function_pointers, #name));
    DART_API_ALL_DL_SYMBOLS(DART_API_DL_INIT)
#undef DART_API_DL_INIT

    return 0;
}

/* ---------------------------------------- */
/* JSValue Invoking                         */
/* ---------------------------------------- */

enum {
    JS_ATOM_NULL,
#define DEF(name, str) JS_ATOM_##name,

#include "quickjs/quickjs-atom.h"

#undef DEF
    JS_ATOM_END,
};

#define JS_ATOM_LAST_KEYWORD JS_ATOM_super
#define JS_ATOM_LAST_STRICT_KEYWORD JS_ATOM_yield

static const char js_atom_init[] =
#define DEF(name, str) str "\0"

#include "quickjs/quickjs-atom.h"

#undef DEF
        ;


Dart_PersistentHandle dart_callback_handler;

DART_EXPORT void
RegisterDartCallbackFP(
        dart_handle_func callback) {
    dart_callback_ = callback;
}

DART_EXPORT void RegisterDartCallback(Dart_Handle h) {
    dart_callback_handler = Dart_NewPersistentHandle_DL(h);
}


typedef struct DartFunc {
    int32_t handler_id;
    struct DartFunc *next;
} DartFunc;



// memcpy when result is static
JSValue *jsvalue_to_heap(JSValueConst value) {
    JSValue *result = malloc(sizeof(JSValue));
    if (result) {
        memcpy(result, &value, sizeof(JSValue));
    }
    return result;
}

JSAtom *jsatom_to_heap(JSAtom value) {
    JSAtom *result = malloc(sizeof(JSAtom));
    if (result) {
        memcpy(result, &value, sizeof(JSAtom));
    }
    return result;
}



/// todo to do todo

DART_EXTERN_C JSValue InvokeDartCallback(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv, int magic, JSValue *func_data) {
    // printf("dart_callback_id_ %d \n",dart_callback_id_);
    if (dart_callback_ == NULL) {
        printf("callback from C, but no Callback set");
        abort();
    }
    JSValue* result_ptr = (*dart_callback_)(ctx, &this_val, argc, argv, func_data);
    if (result_ptr == NULL) {
        return JS_UNDEFINED;
    }
    JSValue result = *result_ptr;
    free(result_ptr);
    return result;
}




DART_EXTERN_C void installDartHook(JSContext *ctx, JSValueConst *this_val, const char *func_name, JSValue* fun_data) {
    JSValue cfn = JS_NewCFunctionData(ctx,InvokeDartCallback,0,0,1,fun_data);
    JSValue dupped = JS_DupValue(ctx, cfn);
    JSAtom atom = JS_NewAtom(ctx, func_name);
     definePropertyValue(ctx, this_val, &atom, &dupped, JS_PROP_WRITABLE | JS_PROP_CONFIGURABLE);
    // JS_DefinePropertyValueStr(ctx, cfn, "name", JS_NewString(ctx, func_name), JS_PROP_CONFIGURABLE);
}


DART_EXTERN_C JSValue *call(JSContext *ctx, JSValueConst *func_obj, JSValueConst *this_obj,
                            int argc, JSValueConst *argv) {
    return jsvalue_to_heap(JS_Call(ctx, *func_obj, *this_obj, argc, argv));
}

DART_EXTERN_C JSValue *invoke(JSContext *ctx, JSValueConst *this_val, JSAtom *atom,
                              int argc, JSValueConst *argv) {
    return jsvalue_to_heap(JS_Invoke(ctx, *this_val, *atom, argc, argv));
}

DART_EXTERN_C JSValue *callConstructor(JSContext *ctx, JSValueConst *func_obj,
                                       int argc, JSValueConst *argv) {
    return jsvalue_to_heap(JS_CallConstructor(ctx, *func_obj, argc, argv));
}

DART_EXTERN_C JSValue *callConstructor2(JSContext *ctx, JSValueConst *func_obj,
                                        JSValueConst *new_target,
                                        int argc, JSValueConst *argv) {
    return jsvalue_to_heap(JS_CallConstructor2(ctx, *func_obj, *new_target, argc, argv));
}

DART_EXTERN_C JS_BOOL detectModule(const char *input, size_t input_len) {
    return JS_DetectModule(input, input_len);
}

/* 'input' must be zero terminated i.e. input[input_len] = '\0'. */
// JSValue *eval(JSContext *ctx, const char *input, size_t input_len,
//                 const char *filename, int eval_flags);
DART_EXTERN_C JSValue *eval(JSContext *ctx, const char *input, size_t input_len) {
    int argc = 0;
    char *argv[1] = {NULL};
    js_std_add_helpers(ctx, argc, argv);
    JSValue value = JS_Eval(ctx, input, input_len, "quickjs.js", JS_EVAL_TYPE_GLOBAL);
    JSValue *ret;
    ret = (JSValueConst *) malloc(sizeof(JSValueConst));
    *ret = value;
    js_std_loop(ctx);
    return ret;
}

DART_EXTERN_C JSValue *evalFunction(JSContext *ctx, JSValue *fun_obj) {
    return jsvalue_to_heap(JS_EvalFunction(ctx, *fun_obj));
}

// an unwrapper from pointer to JSValue, used in dart:ffi
DART_EXTERN_C JSValue unwrap(JSValue *value) {
    JSValue ret = *value;
    return ret;
}

DART_EXTERN_C JSValue *getGlobalObject(JSContext *ctx) {
    return jsvalue_to_heap(JS_GetGlobalObject(ctx));
}

/* ---------------------------------------- */
/* Properties                               */
/* ---------------------------------------- */

DART_EXTERN_C int isInstanceOf(JSContext *ctx, JSValueConst *val, JSValueConst *obj) {
    return JS_IsInstanceOf(ctx, *val, *obj);
}

DART_EXTERN_C int defineProperty(JSContext *ctx, JSValueConst *this_obj,
                                 JSAtom *prop, JSValueConst *val,
                                 JSValueConst *getter, JSValueConst *setter, int flags) {
    return JS_DefineProperty(ctx, *this_obj, *prop, *val, *getter, *setter, flags);
}

DART_EXTERN_C int definePropertyValue(JSContext *ctx, JSValueConst *this_obj,
                                      JSAtom *prop, JSValue *val, int flags) {
    // int ret = JS_DefinePropertyValue(ctx, *this_obj, *prop, *val, flags);
    // JS_FreeValue(ctx, *val);
    return JS_DefinePropertyValue(ctx, *this_obj, *prop, *val, flags);
}

DART_EXTERN_C int definePropertyValueUint32(JSContext *ctx, JSValueConst *this_obj,
                                            uint32_t idx, JSValue *val, int flags) {
    return JS_DefinePropertyValueUint32(ctx, *this_obj, idx, *val, flags);
}

DART_EXTERN_C int definePropertyValueStr(JSContext *ctx, JSValueConst *this_obj,
                                         const char *prop, JSValue *val, int flags) {
    return JS_DefinePropertyValueStr(ctx, *this_obj, prop, *val, flags);
}

DART_EXTERN_C int definePropertyGetSet(JSContext *ctx, JSValueConst *this_obj,
                                       JSAtom *prop, JSValue *getter, JSValue *setter,
                                       int flags) {
    return JS_DefinePropertyGetSet(ctx, *this_obj, *prop, *getter, *setter, flags);
}

DART_EXTERN_C void setOpaque(JSValue *obj, void *opaque) {
    JS_SetOpaque(*obj, opaque);
}

DART_EXTERN_C void *getOpaque(JSValueConst *obj, JSClassID class_id) {
    return JS_GetOpaque(*obj, class_id);
}

DART_EXTERN_C void *getOpaque2(JSContext *ctx, JSValueConst *obj, JSClassID class_id) {
    return JS_GetOpaque2(ctx, *obj, class_id);
}

DART_EXTERN_C JSValue *parseJSON(JSContext *ctx, const char *buf, size_t buf_len,
                                 const char *filename) {
    return jsvalue_to_heap(JS_ParseJSON(ctx, buf, buf_len, filename));
}

DART_EXTERN_C JSValue *parseJSON2(JSContext *ctx, const char *buf, size_t buf_len,
                                  const char *filename, int flags) {
    return jsvalue_to_heap(JS_ParseJSON2(ctx, buf, buf_len, filename, flags));
}

DART_EXTERN_C JSValue *JSONStringify(JSContext *ctx, JSValueConst *obj) {
    return jsvalue_to_heap(JS_JSONStringify(ctx, *obj, JS_UNDEFINED, JS_UNDEFINED));
}

DART_EXTERN_C JSValue *newArrayBuffer(JSContext *ctx, uint8_t *buf, size_t len,
                                      JSFreeArrayBufferDataFunc *free_func, void *opaque,
                                      JS_BOOL is_shared) {
    return jsvalue_to_heap(JS_NewArrayBuffer(ctx, buf, len, free_func, opaque, is_shared));
}

DART_EXTERN_C JSValue *newArrayBufferCopy(JSContext *ctx, const uint8_t *buf, size_t len) {
    return jsvalue_to_heap(JS_NewArrayBufferCopy(ctx, buf, len));
}

DART_EXTERN_C void detachArrayBuffer(JSContext *ctx, JSValueConst *obj) {
    JS_DetachArrayBuffer(ctx, *obj);
}

DART_EXTERN_C uint8_t *getArrayBuffer(JSContext *ctx, size_t *psize, JSValueConst *obj) {
    return JS_GetArrayBuffer(ctx, psize, *obj);
}

DART_EXTERN_C JSValue *getTypedArrayBuffer(JSContext *ctx, JSValueConst *obj,
                                           size_t *pbyte_offset,
                                           size_t *pbyte_length,
                                           size_t *pbytes_per_element) {
    return jsvalue_to_heap(JS_GetTypedArrayBuffer(ctx, *obj, pbyte_offset, pbyte_length, pbytes_per_element));
}

/* ---------------------------------------- */
/* JSValue Creation                         */
/* ---------------------------------------- */

DART_EXTERN_C JSValue *newError(JSContext *ctx) {
    return jsvalue_to_heap(JS_NewError(ctx));
}

DART_EXTERN_C JSValue *newBool(JSContext *ctx, JS_BOOL val) {
    return jsvalue_to_heap(JS_NewBool(ctx, val));
}

DART_EXTERN_C JSValue *newNull(JSContext *ctx) {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_NULL, 0));
}

DART_EXTERN_C JSValue *newInt32(JSContext *ctx, int32_t val) {
    return jsvalue_to_heap(JS_NewInt32(ctx, val));
}

DART_EXTERN_C JSValue *newCatchOffset(JSContext *ctx, int32_t val) {
    return jsvalue_to_heap(JS_NewCatchOffset(ctx, val));
}

DART_EXTERN_C JSValue *newInt64(JSContext *ctx, int64_t val) {
    return jsvalue_to_heap(JS_NewInt64(ctx, val));
}

DART_EXTERN_C JSValue *newUint32(JSContext *ctx, uint32_t val) {
    return jsvalue_to_heap(JS_NewUint32(ctx, val));
}

DART_EXTERN_C JSValue *newBigInt64(JSContext *ctx, int64_t v) {
    return jsvalue_to_heap(JS_NewBigInt64(ctx, v));
}

DART_EXTERN_C JSValue *newBigUint64(JSContext *ctx, uint64_t v) {
    return jsvalue_to_heap(JS_NewBigUint64(ctx, v));
}

DART_EXTERN_C JSValue *newFloat64(JSContext *ctx, double d) {
    return jsvalue_to_heap(JS_NewFloat64(ctx, d));
}

DART_EXTERN_C JSValue *newStringLen(JSContext *ctx, const char *str1, size_t len1) {
    return jsvalue_to_heap(JS_NewStringLen(ctx, str1, len1));
}

DART_EXTERN_C JSValue *newString(JSContext *ctx, const char *str) {
    return jsvalue_to_heap(JS_NewString(ctx, str));
}

DART_EXTERN_C JSValue *newAtomString(JSContext *ctx, const char *str) {
    return jsvalue_to_heap(JS_NewAtomString(ctx, str));
}

DART_EXTERN_C JSValue *newObjectProtoClass(JSContext *ctx, JSValueConst *proto, JSClassID class_id) {
    return jsvalue_to_heap(JS_NewObjectProtoClass(ctx, *proto, class_id));
}

DART_EXTERN_C JSValue *newObjectClass(JSContext *ctx, int class_id) {
    return jsvalue_to_heap(JS_NewObjectClass(ctx, class_id));
}

DART_EXTERN_C JSValue *newObjectProto(JSContext *ctx, JSValueConst *proto) {
    return jsvalue_to_heap(JS_NewObjectProto(ctx, *proto));
}

DART_EXTERN_C JSValue *newObject(JSContext *ctx) {
    return jsvalue_to_heap(JS_NewObject(ctx));
}

DART_EXTERN_C JSValue *newArray(JSContext *ctx) {
    return jsvalue_to_heap(JS_NewArray(ctx));
}

//#define JS_NULL      JS_MKVAL(JS_TAG_NULL, 0)
DART_EXTERN_C JSValue *js_null() {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_NULL, 0));
}

//#define JS_UNDEFINED JS_MKVAL(JS_TAG_UNDEFINED, 0)
DART_EXTERN_C JSValue *js_undefined() {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_UNDEFINED, 0));
}
//#define JS_FALSE     JS_MKVAL(JS_TAG_BOOL, 0)
DART_EXTERN_C JSValue *js_false() {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_BOOL, 0));
}
//#define JS_TRUE      JS_MKVAL(JS_TAG_BOOL, 1)
DART_EXTERN_C JSValue *js_true() {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_BOOL, 1));
}
//#define JS_EXCEPTION JS_MKVAL(JS_TAG_EXCEPTION, 0)
DART_EXTERN_C JSValue *js_exception() {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_EXCEPTION, 0));
}
//#define JS_UNINITIALIZED JS_MKVAL(JS_TAG_UNINITIALIZED, 0)
DART_EXTERN_C JSValue *js_uninitialized() {
    return jsvalue_to_heap(JS_MKVAL(JS_TAG_UNINITIALIZED, 0));
}

/* ---------------------------------------- */
/* JSValue Validator                        */
/* ---------------------------------------- */

DART_EXTERN_C JS_BOOL isNan(JSValue *v) {
    return JS_VALUE_IS_NAN(*v);
}

DART_EXTERN_C JS_BOOL isNumber(JSValue *v) {
    return JS_IsNumber(*v);
}

DART_EXTERN_C JS_BOOL isBigInt(JSContext *ctx, JSValueConst *v) {
    return JS_IsBigInt(ctx, *v);
}

DART_EXTERN_C JS_BOOL isBigFloat(JSValueConst *v) {
    return JS_IsBigFloat(*v);
}

DART_EXTERN_C JS_BOOL isBigDecimal(JSValueConst *v) {
    return JS_IsBigDecimal(*v);
}

DART_EXTERN_C JS_BOOL isBool(JSValueConst *v) {
    return JS_IsBool(*v);
}

DART_EXTERN_C JS_BOOL isNull(JSValueConst *v) {
    return JS_IsNull(*v);
}

DART_EXTERN_C JS_BOOL isUndefined(JSValueConst *v) {
    return JS_IsUndefined(*v);
}

DART_EXTERN_C JS_BOOL isException(JSValueConst *v) {
    return JS_IsException(*v);
}

DART_EXTERN_C JS_BOOL isUninitialized(JSValueConst *v) {
    return JS_IsUninitialized(*v);
}

DART_EXTERN_C JS_BOOL isString(JSValueConst *v) {
    return JS_IsString(*v);
}

DART_EXTERN_C JS_BOOL isSymbol(JSValueConst *v) {
    return JS_IsSymbol(*v);
}

DART_EXTERN_C JS_BOOL isObject(JSValueConst *v) {
    return JS_IsObject(*v);
}

DART_EXTERN_C JS_BOOL isError(JSContext *ctx, JSValueConst *val) {
    return JS_IsError(ctx, *val);
}

DART_EXTERN_C JS_BOOL isFunction(JSContext *ctx, JSValueConst *val) {
    return JS_IsFunction(ctx, *val);
}

DART_EXTERN_C JS_BOOL isConstructor(JSContext *ctx, JSValueConst *val) {
    return JS_IsConstructor(ctx, *val);
}

DART_EXTERN_C int isArray(JSContext *ctx, JSValueConst *val) {
    return JS_IsArray(ctx, *val);
}

DART_EXTERN_C int isExtensible(JSContext *ctx, JSValueConst *obj) {
    return JS_IsExtensible(ctx, *obj);
}

/* ---------------------------------------- */
/* JSAtom Execution                         */
/* ---------------------------------------- */

DART_EXTERN_C int getValueTag(JSValue v) {
    return JS_VALUE_GET_NORM_TAG(v);
}

DART_EXTERN_C void freeValue(JSContext *ctx, JSValue *v) {
    JS_FreeValue(ctx, *v);
}

DART_EXTERN_C void freeValueRT(JSRuntime *rt, JSValue *v) {
    JS_FreeValueRT(rt, *v);
}

DART_EXTERN_C JSValue *dupValue(JSContext *ctx, JSValueConst *v) {
    return jsvalue_to_heap(JS_DupValue(ctx, *v));
}

DART_EXTERN_C JSValue *dupValueRT(JSRuntime *rt, JSValueConst *v) {
    return jsvalue_to_heap(JS_DupValueRT(rt, *v));
}

DART_EXTERN_C int toBool(JSContext *ctx, JSValueConst *val) {
    return JS_ToBool(ctx, *val);
}

DART_EXTERN_C int toInt32(JSContext *ctx, JSValueConst *val) {
    int present;
    int ret = JS_ToInt32(ctx, &present, *val);
    JS_FreeValue(ctx, *val);
    return ret;
}

DART_EXTERN_C int toUint32(JSContext *ctx, uint32_t *pres, JSValueConst *val) {
    return JS_ToUint32(ctx, pres, *val);
}

DART_EXTERN_C int toInt64(JSContext *ctx, int64_t *pres, JSValueConst *val) {
    return JS_ToInt64(ctx, pres, *val);
}

DART_EXTERN_C int toIndex(JSContext *ctx, uint64_t *plen, JSValueConst *val) {
    return JS_ToIndex(ctx, plen, *val);
}

DART_EXTERN_C int toFloat64(JSContext *ctx, double *pres, JSValueConst *val) {
    return JS_ToFloat64(ctx, pres, *val);
}

DART_EXTERN_C int toBigInt64(JSContext *ctx, int64_t *pres, JSValueConst *val) {
    return JS_ToBigInt64(ctx, pres, *val);
}

DART_EXTERN_C int toInt64Ext(JSContext *ctx, int64_t *pres, JSValueConst *val) {
    return JS_ToInt64Ext(ctx, pres, *val);
}

DART_EXTERN_C JSValue *toString(JSContext *ctx, JSValueConst *val) {
    return jsvalue_to_heap(JS_ToString(ctx, *val));
}

DART_EXTERN_C JSValue *toPropertyKey(JSContext *ctx, JSValueConst *val) {
    return jsvalue_to_heap(JS_ToString(ctx, *val));
}

DART_EXTERN_C const char *toCStringLen2(JSContext *ctx, size_t *plen, JSValueConst *val1, JS_BOOL cesu8) {
    return JS_ToCStringLen2(ctx, plen, *val1, cesu8);
}

DART_EXTERN_C const char *toCStringLen(JSContext *ctx, size_t *plen, JSValueConst *val1) {
    return JS_ToCStringLen(ctx, plen, *val1);
}

DART_EXTERN_C const char *toCString(JSContext *ctx, JSValueConst *val1) {
    const char *value = JS_ToCString(ctx, *val1);
    char *ret_str = "";
    int valStrLen = strlen(value);
    // printf("valStrlen: %d \n", valStrLen);
    ret_str = (char *) malloc((valStrLen + 1) * sizeof(char));
    strcpy(ret_str, value);
    return ret_str;
}

DART_EXTERN_C const char toDartString(JSContext *ctx, JSValueConst *val) {
    const char *value = JS_ToCString(ctx, *val);
    char *ret_str = "";
    int valStrLen = strlen(value);
    ret_str = (char *) malloc((valStrLen + 1) * sizeof(char));
    strcpy(ret_str, value);
    char ret = *ret_str;
    return ret;
}

DART_EXTERN_C void freeCString(JSContext *ctx, const char *ptr) {
    JS_FreeCString(ctx, ptr);
}

DART_EXTERN_C JS_BOOL setConstructorBit(JSContext *ctx, JSValueConst *func_obj, JS_BOOL val) {
    return JS_SetConstructorBit(ctx, *func_obj, val);
}

DART_EXTERN_C JSValue *getPropertyStr(JSContext *ctx, JSValueConst *this_obj,
                                      const char *prop) {
    return jsvalue_to_heap(JS_GetPropertyStr(ctx, *this_obj, prop));
}

DART_EXTERN_C JSValue *getPropertyUint32(JSContext *ctx, JSValueConst *this_obj,
                                         uint32_t idx) {
    return jsvalue_to_heap(JS_GetPropertyUint32(ctx, *this_obj, idx));
}

DART_EXTERN_C int setPropertyInternal(JSContext *ctx, JSValueConst *this_obj,
                                      JSAtom *prop, JSValue *val,
                                      int flags) {
    return JS_SetPropertyInternal(ctx, *this_obj, *prop, *val, flags);
}

DART_EXTERN_C int setProperty(JSContext *ctx, JSValueConst *this_obj,
                              JSAtom *prop, JSValue *val) {
    return JS_SetProperty(ctx, *this_obj, *prop, *val);
}

DART_EXTERN_C int setPropertyUint32(JSContext *ctx, JSValueConst *this_obj,
                                    uint32_t idx, JSValue *val) {
    return JS_SetPropertyUint32(ctx, *this_obj, idx, *val);
}

DART_EXTERN_C int setPropertyInt64(JSContext *ctx, JSValueConst *this_obj,
                                   int64_t idx, JSValue *val) {
    return JS_SetPropertyInt64(ctx, *this_obj, idx, *val);
}

DART_EXTERN_C int setPropertyStr(JSContext *ctx, JSValueConst *this_obj,
                                 const char *prop, JSValue *val) {
    return JS_SetPropertyStr(ctx, *this_obj, prop, *val);
}

DART_EXTERN_C int hasProperty(JSContext *ctx, JSValueConst *this_obj, JSAtom *prop) {
    return JS_HasProperty(ctx, *this_obj, *prop);
}

DART_EXTERN_C int preventExtensions(JSContext *ctx, JSValueConst *obj) {
    return JS_PreventExtensions(ctx, *obj);
}

DART_EXTERN_C int deleteProperty(JSContext *ctx, JSValueConst *obj, JSAtom *prop, int flags) {
    return JS_DeleteProperty(ctx, *obj, *prop, flags);
}

DART_EXTERN_C int setPrototype(JSContext *ctx, JSValueConst *obj, JSValueConst *proto_val) {
    return JS_SetPrototype(ctx, *obj, *proto_val);
}

DART_EXTERN_C JSValue *getPrototype(JSContext *ctx, JSValueConst *val) {
    return jsvalue_to_heap(JS_GetPrototype(ctx, *val));
}

DART_EXTERN_C int getOwnPropertyNames(JSContext *ctx, JSPropertyEnum **ptab,
                                      uint32_t *plen, JSValueConst *obj, int flags) {
    return JS_GetOwnPropertyNames(ctx, ptab, plen, *obj, flags);
}

DART_EXTERN_C int getOwnProperty(JSContext *ctx, JSPropertyDescriptor *desc,
                                 JSValueConst *obj, JSAtom *prop) {
    return JS_GetOwnProperty(ctx, desc, *obj, *prop);
}

/* ---------------------------------------- */
/* JSAtom Creation                          */
/* ---------------------------------------- */

DART_EXTERN_C JSAtom *newAtom(JSContext *ctx, const char *str) {
    return jsatom_to_heap(JS_NewAtom(ctx, str));
}

DART_EXTERN_C JSAtom *valueToAtom(JSContext *ctx, JSValueConst *val) {
    return jsatom_to_heap(JS_ValueToAtom(ctx, *val));
}

DART_EXTERN_C const char *valueToAtomString(JSContext *ctx, JSValueConst *val) {
    JSAtom value = JS_ValueToAtom(ctx, *val);
    JSValue *atomPtr;
    JSValue atomString = JS_AtomToString(ctx, value);
    atomPtr = (JSValueConst *) malloc(sizeof(JSValueConst));
    const char *ret = toCString(ctx, atomPtr);
    // JS_FreeAtom(ctx, value);
    // JS_FreeValue(ctx, atomString);
    return ret;
}

DART_EXTERN_C JSValue *atomToValue(JSContext *ctx, JSAtom *atom) {
    return jsvalue_to_heap(JS_AtomToValue(ctx, *atom));
}

DART_EXTERN_C JSValue *atomToString(JSContext *ctx, uint32_t atom) {
    return jsvalue_to_heap(JS_AtomToString(ctx, atom));
}

DART_EXTERN_C int oper_typeof(JSContext *ctx, JSValue *op1) {
    JSAtom atom;
    uint32_t tag;

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
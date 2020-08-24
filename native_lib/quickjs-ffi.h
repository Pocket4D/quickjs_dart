/*
 * A wrapper of quickjs library and used for dart:ffi
 * Will be changed when dart:ffi changes
 * DO NOT USE IN PRODUCTION
 * 
 * Copyright (c) 2020 Pocket4D
 * Author: neeboo@github.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef QUICKJS_FFI_H
#define QUICKJS_FFI_H

#include <stdio.h>
#include <stdlib.h>
#include "quickjs/quickjs.h"
#include "quickjs/quickjs-libc.h"

#ifndef RUNTIME_INCLUDE_DART_API_DL_H_
#define RUNTIME_INCLUDE_DART_API_DL_H_

#include "include/dart_api.h"
#include "include/dart_native_api.h"

typedef int64_t Dart_Port_DL;

typedef void (*Dart_NativeMessageHandler_DL)(Dart_Port_DL dest_port_id,
                                             Dart_CObject *message);

DART_EXTERN_C bool (*Dart_PostCObject_DL)(Dart_Port_DL port_id,
                                          Dart_CObject *message);

DART_EXTERN_C bool (*Dart_PostInteger_DL)(Dart_Port_DL port_id,
                                          int64_t message);

DART_EXTERN_C Dart_Port_DL (*Dart_NewNativePort_DL)(
        const char *name,
        Dart_NativeMessageHandler_DL handler,
        bool handle_concurrently);

DART_EXTERN_C bool (*Dart_CloseNativePort_DL)(Dart_Port_DL native_port_id);

DART_EXTERN_C bool (*Dart_IsError_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_IsApiError_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_IsUnhandledExceptionError_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_IsCompilationError_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_IsFatalError_DL)(Dart_Handle handle);

DART_EXTERN_C const char *(*Dart_GetError_DL)(Dart_Handle handle);

DART_EXTERN_C bool (*Dart_ErrorHasException_DL)(Dart_Handle handle);

DART_EXTERN_C Dart_Handle (*Dart_ErrorGetException_DL)(Dart_Handle handle);

DART_EXTERN_C Dart_Handle (*Dart_ErrorGetStackTrace_DL)(Dart_Handle handle);

DART_EXTERN_C Dart_Handle (*Dart_NewApiError_DL)(const char *error);

DART_EXTERN_C Dart_Handle (*Dart_NewCompilationError_DL)(const char *error);

DART_EXTERN_C Dart_Handle (*Dart_NewUnhandledExceptionError_DL)(
        Dart_Handle exception);

DART_EXTERN_C void (*Dart_PropagateError_DL)(Dart_Handle handle);

DART_EXTERN_C Dart_Handle (*Dart_ToString_DL)(Dart_Handle object);

DART_EXTERN_C bool (*Dart_IdentityEquals_DL)(Dart_Handle obj1,
                                             Dart_Handle obj2);

DART_EXTERN_C Dart_Handle (*Dart_HandleFromPersistent_DL)(
        Dart_PersistentHandle object);

DART_EXTERN_C Dart_Handle (*Dart_HandleFromWeakPersistent_DL)(
        Dart_WeakPersistentHandle object);

DART_EXTERN_C Dart_PersistentHandle (*Dart_NewPersistentHandle_DL)(
        Dart_Handle object);

DART_EXTERN_C void (*Dart_SetPersistentHandle_DL)(Dart_PersistentHandle obj1,
                                                  Dart_Handle obj2);

DART_EXTERN_C void (*Dart_DeletePersistentHandle_DL)(
        Dart_PersistentHandle object);

DART_EXTERN_C Dart_WeakPersistentHandle (*Dart_NewWeakPersistentHandle_DL)(
        Dart_Handle object,
        void *peer,
        intptr_t external_allocation_size,
        Dart_WeakPersistentHandleFinalizer callback);

DART_EXTERN_C void (*Dart_DeleteWeakPersistentHandle_DL)(
        Dart_WeakPersistentHandle object);

DART_EXTERN_C void (*Dart_UpdateExternalSize_DL)(
        Dart_WeakPersistentHandle object,
        intptr_t external_allocation_size);

DART_EXTERN_C Dart_FinalizableHandle (*Dart_NewFinalizableHandle_DL)(
        Dart_Handle object,
        void *peer,
        intptr_t external_allocation_size,
        Dart_HandleFinalizer callback);

DART_EXTERN_C void (*Dart_DeleteFinalizableHandle_DL)(
        Dart_FinalizableHandle object,
        Dart_Handle strong_ref_to_object);

DART_EXTERN_C void (*Dart_UpdateFinalizableExternalSize_DL)(
        Dart_FinalizableHandle object,
        Dart_Handle strong_ref_to_object,
        intptr_t external_allocation_size);

DART_EXTERN_C bool (*Dart_Post_DL)(Dart_Port_DL port_id, Dart_Handle object);

DART_EXTERN_C Dart_Handle (*Dart_NewSendPort_DL)(Dart_Port_DL port_id);

DART_EXTERN_C Dart_Handle (*Dart_SendPortGetId_DL)(Dart_Handle port,
                                                   Dart_Port_DL *port_id);

DART_EXTERN_C void (*Dart_EnterScope_DL)();

DART_EXTERN_C void (*Dart_ExitScope_DL)();

// dart handled callback
typedef JSValue *(*dart_handle_func)(JSContext *ctx, JSValueConst *this_val, int argc, JSValueConst *argv, JSValue *func_data);
// global one time release
dart_handle_func dart_callback_= NULL;
DART_EXTERN_C void installDartHook(JSContext *ctx, JSValueConst *this_val, const char *func_name, int64_t func_id);


typedef int dart_interrupt_func(JSRuntime *rt);
int interrupt_handler(JSRuntime *rt, void *_unused);
void setInterruptCallback(dart_interrupt_func *cb);
void runtimeEnableInterruptHandler(JSRuntime *rt);
void runtimeDisableInterruptHandler(JSRuntime *rt);


DART_EXTERN_C JSValue *executePendingJob(JSRuntime *rt, int maxJobsToExecute);
DART_EXTERN_C int isJobPending(JSRuntime *rt);

DART_EXTERN_C JSValue *resolveException(JSContext *ctx, JSValue *maybe_exception);

#endif /* RUNTIME_INCLUDE_DART_API_DL_H_ */ /* NOLINT */

#ifdef __cplusplus
extern "C"
{
#endif



/* JS Invoking */
DART_EXTERN_C JSValue *call(JSContext *ctx, JSValueConst *func_obj, JSValueConst *this_obj,
                            int argc, JSValueConst *argv);

DART_EXTERN_C JSValue *invoke(JSContext *ctx, JSValueConst *this_val, JSAtom *atom,
                              int argc, JSValueConst *argv);

DART_EXTERN_C JSValue *callConstructor(JSContext *ctx, JSValueConst *func_obj,
                                       int argc, JSValueConst *argv);

DART_EXTERN_C JSValue *callConstructor2(JSContext *ctx, JSValueConst *func_obj,
                                        JSValueConst *new_target,
                                        int argc, JSValueConst *argv);

DART_EXTERN_C JS_BOOL detectModule(const char *input, size_t input_len);

DART_EXTERN_C JSValue *eval(JSContext *ctx, const char *input, size_t input_len);

DART_EXTERN_C JSValue *evalFunction(JSContext *ctx, JSValue *fun_obj);

DART_EXTERN_C JSValue unwrap(JSValue *value);

DART_EXTERN_C JSValue *getGlobalObject(JSContext *ctx);

/* properties */
DART_EXTERN_C int isInstanceOf(JSContext *ctx, JSValueConst *val, JSValueConst *obj);

DART_EXTERN_C int defineProperty(JSContext *ctx, JSValueConst *this_obj,
                                 JSAtom *prop, JSValueConst *val,
                                 JSValueConst *getter, JSValueConst *setter, int flags);

DART_EXTERN_C int definePropertyValue(JSContext *ctx, JSValueConst *this_obj,
                                      JSAtom *prop, JSValue *val, int flags);

DART_EXTERN_C int definePropertyValueUint32(JSContext *ctx, JSValueConst *this_obj,
                                            uint32_t idx, JSValue *val, int flags);

DART_EXTERN_C int definePropertyValueStr(JSContext *ctx, JSValueConst *this_obj,
                                         const char *prop, JSValue *val, int flags);

DART_EXTERN_C int DefinePropertyGetSet(JSContext *ctx, JSValueConst *this_obj,
                                       JSAtom *prop, JSValue *getter, JSValue *setter,
                                       int flags);

DART_EXTERN_C void setOpaque(JSValue *obj, void *opaque);

DART_EXTERN_C void *getOpaque(JSValueConst *obj, JSClassID class_id);

DART_EXTERN_C void *getOpaque2(JSContext *ctx, JSValueConst *obj, JSClassID class_id);

DART_EXTERN_C JSValue *parseJSON(JSContext *ctx, const char *buf, size_t buf_len,
                                 const char *filename);

DART_EXTERN_C JSValue *parseJSON2(JSContext *ctx, const char *buf, size_t buf_len,
                                  const char *filename, int flags);

DART_EXTERN_C JSValue *JSONStringify(JSContext *ctx, JSValueConst *obj);

DART_EXTERN_C JSValue *newArrayBuffer(JSContext *ctx, uint8_t *buf, size_t len,
                                      JSFreeArrayBufferDataFunc *free_func, void *opaque,
                                      JS_BOOL is_shared);

DART_EXTERN_C JSValue *newArrayBufferCopy(JSContext *ctx, const uint8_t *buf, size_t len);

DART_EXTERN_C void detachArrayBuffer(JSContext *ctx, JSValueConst *obj);

DART_EXTERN_C uint8_t *getArrayBuffer(JSContext *ctx, size_t *psize, JSValueConst *obj);

DART_EXTERN_C JSValue *getTypedArrayBuffer(JSContext *ctx, JSValueConst *obj,
                                           size_t *pbyte_offset,
                                           size_t *pbyte_length,
                                           size_t *pbytes_per_element);

/* JSValue Throws*/
DART_EXTERN_C JSValue *throwError(JSContext *ctx, JSValue *obj);

DART_EXTERN_C JSValue *getException(JSContext *ctx);

/* JSValue Creation */
DART_EXTERN_C JSValue *newError(JSContext *ctx);

DART_EXTERN_C JSValue *newBool(JSContext *ctx, JS_BOOL val);

DART_EXTERN_C JSValue *newInt32(JSContext *ctx, int32_t val);

DART_EXTERN_C JSValue *newCatchOffset(JSContext *ctx, int32_t val);

DART_EXTERN_C JSValue *newInt64(JSContext *ctx, int64_t val);

DART_EXTERN_C JSValue *newUint32(JSContext *ctx, uint32_t val);

DART_EXTERN_C JSValue *newBigInt64(JSContext *ctx, int64_t v);

DART_EXTERN_C JSValue *newBigUint64(JSContext *ctx, uint64_t v);

DART_EXTERN_C JSValue *newFloat64(JSContext *ctx, double d);

DART_EXTERN_C JSValue *newStringLen(JSContext *ctx, const char *str1, size_t len1);

DART_EXTERN_C JSValue *newString(JSContext *ctx, const char *str);

DART_EXTERN_C JSValue *newAtomString(JSContext *ctx, const char *str);

DART_EXTERN_C JSValue *newObjectProtoClass(JSContext *ctx, JSValueConst *proto, JSClassID class_id);

DART_EXTERN_C JSValue *newObjectClass(JSContext *ctx, int class_id);

DART_EXTERN_C JSValue *newObjectProto(JSContext *ctx, JSValueConst *proto);

DART_EXTERN_C JSValue *newObject(JSContext *ctx);

DART_EXTERN_C JSValue *newArray(JSContext *ctx);

DART_EXTERN_C JSValue *newNull(JSContext *ctx);

DART_EXTERN_C JSValue *js_null();
//#define JS_UNDEFINED JS_MKVAL(JS_TAG_UNDEFINED, 0)
DART_EXTERN_C JSValue *js_undefined();
//#define JS_FALSE     JS_MKVAL(JS_TAG_BOOL, 0)
DART_EXTERN_C JSValue *js_false();
//#define JS_TRUE      JS_MKVAL(JS_TAG_BOOL, 1)
DART_EXTERN_C JSValue *js_true();
//#define JS_EXCEPTION JS_MKVAL(JS_TAG_EXCEPTION, 0)
DART_EXTERN_C JSValue *js_exception();
//#define JS_UNINITIALIZED JS_MKVAL(JS_TAG_UNINITIALIZED, 0)
DART_EXTERN_C JSValue *js_uninitialized();

/* JSValue Validator */
DART_EXTERN_C JS_BOOL isNan(JSValue *v);

DART_EXTERN_C JS_BOOL isNumber(JSValueConst *v);

DART_EXTERN_C JS_BOOL isBigInt(JSContext *ctx, JSValueConst *v);

DART_EXTERN_C JS_BOOL isBigFloat(JSValueConst *v);

DART_EXTERN_C JS_BOOL isBigDecimal(JSValueConst *v);

DART_EXTERN_C JS_BOOL isBool(JSValueConst *v);

DART_EXTERN_C JS_BOOL isNull(JSValueConst *v);

DART_EXTERN_C JS_BOOL isUndefined(JSValueConst *v);

DART_EXTERN_C JS_BOOL isUninitialized(JSValueConst *v);

DART_EXTERN_C JS_BOOL isString(JSValueConst *v);

DART_EXTERN_C JS_BOOL isSymbol(JSValueConst *v);

DART_EXTERN_C JS_BOOL isObject(JSValueConst *v);

DART_EXTERN_C JS_BOOL isError(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C JS_BOOL isFunction(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C JS_BOOL isConstructor(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C int isArray(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C int isExtensible(JSContext *ctx, JSValueConst *obj);

/* JSValue execution */
DART_EXTERN_C int getValueTag(JSValue v);

DART_EXTERN_C void freeValue(JSContext *ctx, JSValue *v);

DART_EXTERN_C void freeValueRT(JSRuntime *rt, JSValue *v);

DART_EXTERN_C JSValue *dupValue(JSContext *ctx, JSValueConst *v);

DART_EXTERN_C JSValue *dupValueRT(JSRuntime *rt, JSValueConst *v);

DART_EXTERN_C int toBool(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C int toInt32(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C int toUint32(JSContext *ctx, uint32_t *pres, JSValueConst *val);

DART_EXTERN_C int toInt64(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C int toIndex(JSContext *ctx, uint64_t *plen, JSValueConst *val);

DART_EXTERN_C double toFloat64(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C int toBigInt64(JSContext *ctx, int64_t *pres, JSValueConst *val);

DART_EXTERN_C int toInt64Ext(JSContext *ctx, int64_t *pres, JSValueConst *val);

DART_EXTERN_C JSValue *toString(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C JSValue *toPropertyKey(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C const char *toCStringLen2(JSContext *ctx, size_t *plen, JSValueConst *val1, JS_BOOL cesu8);

DART_EXTERN_C const char *toCStringLen(JSContext *ctx, size_t *plen, JSValueConst *val1);

DART_EXTERN_C const char *toCString(JSContext *ctx, JSValueConst *val1);

DART_EXTERN_C const char toDartString(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C void freeCString(JSContext *ctx, const char *ptr);

DART_EXTERN_C JS_BOOL setConstructorBit(JSContext *ctx, JSValueConst *func_obj, JS_BOOL val);

DART_EXTERN_C JSValue *getPropertyStr(JSContext *ctx, JSValueConst *this_obj,
                                      const char *prop);

DART_EXTERN_C JSValue *getPropertyUint32(JSContext *ctx, JSValueConst *this_obj,
                                         uint32_t idx);

DART_EXTERN_C int setPropertyInternal(JSContext *ctx, JSValueConst *this_obj,
                                      JSAtom *prop, JSValue *val,
                                      int flags);

DART_EXTERN_C int setProperty(JSContext *ctx, JSValueConst *this_obj,
                              JSAtom *prop, JSValue *val);

DART_EXTERN_C int setPropertyUint32(JSContext *ctx, JSValueConst *this_obj,
                                    uint32_t idx, JSValue *val);

DART_EXTERN_C int setPropertyInt64(JSContext *ctx, JSValueConst *this_obj,
                                   int64_t idx, JSValue *val);

DART_EXTERN_C int setPropertyStr(JSContext *ctx, JSValueConst *this_obj,
                                 const char *prop, JSValue *val);

DART_EXTERN_C int hasProperty(JSContext *ctx, JSValueConst *this_obj, JSAtom *prop);

DART_EXTERN_C int preventExtensions(JSContext *ctx, JSValueConst *obj);

DART_EXTERN_C int deleteProperty(JSContext *ctx, JSValueConst *obj, JSAtom *prop, int flags);

DART_EXTERN_C int setPrototype(JSContext *ctx, JSValueConst *obj, JSValueConst *proto_val);

DART_EXTERN_C JSValue *getPrototype(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C int getOwnPropertyNames(JSContext *ctx, JSPropertyEnum **ptab,
                                      uint32_t *plen, JSValueConst *obj, int flags);

DART_EXTERN_C int getOwnProperty(JSContext *ctx, JSPropertyDescriptor *desc,
                                 JSValueConst *obj, JSAtom *prop);

/*  JSAtom  */
DART_EXTERN_C JSAtom *newAtom(JSContext *ctx, const char *str);

DART_EXTERN_C JSAtom *valueToAtom(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C const char *valueToAtomString(JSContext *ctx, JSValueConst *val);

DART_EXTERN_C JSValue *atomToValue(JSContext *ctx, JSAtom atom);

DART_EXTERN_C JSValue *atomToString(JSContext *ctx, uint32_t atom);

DART_EXTERN_C int oper_typeof(JSContext *ctx, JSValue *op1);

DART_EXTERN_C const char *dump(JSContext *ctx, JSValueConst *obj);

#ifdef __cplusplus
} /* extern "C" { */
#endif

#endif /* QUICKJS_FFI_H */

/*
  Mapping functions to line 815
*/
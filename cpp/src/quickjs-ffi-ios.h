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

extern "C"
{
    JSRuntime *newRuntime();

    JSContext *newContext(JSRuntime *rt);
    // dart handled callback
    typedef JSValue *(*dart_handle_func)(JSContext *ctx, JSValueConst *this_val, int argc, JSValueConst *argv,
                                         JSValue *func_data);
    // global one time release
    dart_handle_func dart_callback_ = nullptr;

    // hook dart
    void installDartHook(JSContext *ctx, JSValueConst *this_val, JSValueConst *func_name, int64_t func_id);

    JSValueConst *getJSValueConstPointer(JSValueConst *argv, int index);

    //  void installAsyncDartHook(JSContext *ctx, JSValueConst *this_val, const char *func_name, int64_t func_id);

    typedef int dart_interrupt_func(JSRuntime *rt);
    int interrupt_handler(JSRuntime *rt, void *_unused);
    void setInterruptCallback(dart_interrupt_func *cb);
    void runtimeEnableInterruptHandler(JSRuntime *rt);
    void runtimeDisableInterruptHandler(JSRuntime *rt);

    JSValue *executePendingJob(JSRuntime *rt, int maxJobsToExecute);
    int isJobPending(JSRuntime *rt);

    JSValue *resolveException(JSContext *ctx, const JSValue *maybe_exception);

    /* JS Invoking */
    JSValue *call(JSContext *ctx, JSValueConst *func_obj, JSValueConst *this_obj,
                  int argc, JSValueConst **argv_ptrs);

    JSValue *invoke(JSContext *ctx, JSValueConst *this_val, const JSAtom *atom,
                    int argc, JSValueConst **argv_ptrs);

    JSValue *callConstructor(JSContext *ctx, JSValueConst *func_obj,
                             int argc, JSValueConst *argv);

    JSValue *callConstructor2(JSContext *ctx, JSValueConst *func_obj,
                              JSValueConst *new_target,
                              int argc, JSValueConst *argv);

    JS_BOOL detectModule(const char *input, size_t input_len);

    JSValue *eval(JSContext *ctx, const char *input, size_t input_len);

    JSValue *evalFunction(JSContext *ctx, JSValue *fun_obj);

    JSValue unwrap(JSValue *value);

    JSValue *getGlobalObject(JSContext *ctx);

    /* properties */
    int isInstanceOf(JSContext *ctx, JSValueConst *val, JSValueConst *obj);

    int defineProperty(JSContext *ctx, JSValueConst *this_obj,
                       const JSAtom *prop, JSValueConst *val,
                       JSValueConst *getter, JSValueConst *setter, int flags);

    int definePropertyValue(JSContext *ctx, JSValueConst *this_obj,
                            const JSAtom *prop, JSValue *val, int flags);

    int definePropertyValueUint32(JSContext *ctx, JSValueConst *this_obj,
                                  uint32_t idx, JSValue *val, int flags);

    int definePropertyValueStr(JSContext *ctx, JSValueConst *this_obj,
                               const char *prop, JSValue *val, int flags);

    int definePropertyGetSet(JSContext *ctx, JSValueConst *this_obj,
                             const JSAtom *prop, JSValue *getter, JSValue *setter,
                             int flags);

    void setOpaque(JSValue *obj, void *opaque);

    void *getOpaque(JSValueConst *obj, JSClassID class_id);

    void *getOpaque2(JSContext *ctx, JSValueConst *obj, JSClassID class_id);

    JSValue *parseJSON(JSContext *ctx, const char *buf, size_t buf_len,
                       const char *filename);

    JSValue *parseJSON2(JSContext *ctx, const char *buf, size_t buf_len,
                        const char *filename, int flags);

    JSValue *JSONStringify(JSContext *ctx, JSValueConst *obj);

    JSValue *newArrayBuffer(JSContext *ctx, uint8_t *buf, size_t len,
                            JSFreeArrayBufferDataFunc *free_func, void *opaque,
                            JS_BOOL is_shared);

    JSValue *newArrayBufferCopy(JSContext *ctx, const uint8_t *buf, size_t len);

    void detachArrayBuffer(JSContext *ctx, JSValueConst *obj);

    uint8_t *getArrayBuffer(JSContext *ctx, size_t *psize, JSValueConst *obj);

    JSValue *getTypedArrayBuffer(JSContext *ctx, JSValueConst *obj,
                                 size_t *pbyte_offset,
                                 size_t *pbyte_length,
                                 size_t *pbytes_per_element);

    /* JSValue Throws*/
    JSValue *throwError(JSContext *ctx, JSValue *obj);

    JSValue *getException(JSContext *ctx);

    /* JSValue Creation */
    JSValue *newError(JSContext *ctx);

    JSValue *newBool(JSContext *ctx, JS_BOOL val);

    JSValue *newInt32(JSContext *ctx, int32_t val);

    JSValue *newCatchOffset(JSContext *ctx, int32_t val);

    JSValue *newInt64(JSContext *ctx, int64_t val);

    JSValue *newUint32(JSContext *ctx, uint32_t val);

    JSValue *newBigInt64(JSContext *ctx, int64_t v);

    JSValue *newBigUint64(JSContext *ctx, uint64_t v);

    JSValue *newFloat64(JSContext *ctx, double d);

    JSValue *newStringLen(JSContext *ctx, const char *str1, size_t len1);

    JSValue *newString(JSContext *ctx, const char *str);

    JSValue *newAtomString(JSContext *ctx, const char *str);

    JSValue *newObjectProtoClass(JSContext *ctx, JSValueConst *proto, JSClassID class_id);

    JSValue *newObjectClass(JSContext *ctx, int class_id);

    JSValue *newObjectProto(JSContext *ctx, JSValueConst *proto);

    JSValue *newObject(JSContext *ctx);

    JSValue *newArray(JSContext *ctx);

    JSValue *newNull(JSContext *ctx);

    JSValue *js_null();
    //#define JS_UNDEFINED JS_MKVAL(JS_TAG_UNDEFINED, 0)
    JSValue *js_undefined();
    //#define JS_FALSE     JS_MKVAL(JS_TAG_BOOL, 0)
    JSValue *js_false();
    //#define JS_TRUE      JS_MKVAL(JS_TAG_BOOL, 1)
    JSValue *js_true();
    //#define JS_EXCEPTION JS_MKVAL(JS_TAG_EXCEPTION, 0)
    JSValue *js_exception();
    //#define JS_UNINITIALIZED JS_MKVAL(JS_TAG_UNINITIALIZED, 0)
    JSValue *js_uninitialized();

    /* JSValue Validator */
    JS_BOOL isNan(JSValue *v);

    JS_BOOL isNumber(JSValueConst *v);

    JS_BOOL isBigInt(JSContext *ctx, JSValueConst *v);

    JS_BOOL isBigFloat(JSValueConst *v);

    JS_BOOL isBigDecimal(JSValueConst *v);

    JS_BOOL isBool(JSValueConst *v);

    JS_BOOL isNull(JSValueConst *v);

    JS_BOOL isUndefined(JSValueConst *v);

    JS_BOOL isUninitialized(JSValueConst *v);

    JS_BOOL isString(JSValueConst *v);

    JS_BOOL isSymbol(JSValueConst *v);

    JS_BOOL isObject(JSValueConst *v);

    JS_BOOL isError(JSContext *ctx, JSValueConst *val);

    JS_BOOL isFunction(JSContext *ctx, JSValueConst *val);

    JS_BOOL isConstructor(JSContext *ctx, JSValueConst *val);

    int isArray(JSContext *ctx, JSValueConst *val);

    int isExtensible(JSContext *ctx, JSValueConst *obj);

    /* JSValue execution */
    int getValueTag(JSValue v);

    void freeValue(JSContext *ctx, JSValue *v);

    void freeValueRT(JSRuntime *rt, JSValue *v);

    JSValue *dupValue(JSContext *ctx, JSValueConst *v);

    JSValue *dupValueRT(JSRuntime *rt, JSValueConst *v);

    int toBool(JSContext *ctx, JSValueConst *val);

    int32_t toInt32(JSContext *ctx, JSValueConst *val);

    int toUint32(JSContext *ctx, uint32_t *pres, JSValueConst *val);

    int64_t toInt64(JSContext *ctx, JSValueConst *val);

    int toIndex(JSContext *ctx, uint64_t *plen, JSValueConst *val);

    double toFloat64(JSContext *ctx, JSValueConst *val);

    int toBigInt64(JSContext *ctx, int64_t *pres, JSValueConst *val);

    int toInt64Ext(JSContext *ctx, int64_t *pres, JSValueConst *val);

    JSValue *toString(JSContext *ctx, JSValueConst *val);

    JSValue *toPropertyKey(JSContext *ctx, JSValueConst *val);

    const char *toCStringLen2(JSContext *ctx, size_t *plen, JSValueConst *val1, JS_BOOL cesu8);

    const char *toCStringLen(JSContext *ctx, size_t *plen, JSValueConst *val1);

    const char *toCString(JSContext *ctx, JSValueConst *val1);

    char toDartString(JSContext *ctx, JSValueConst *val);

    void freeCString(JSContext *ctx, const char *ptr);

    JS_BOOL setConstructorBit(JSContext *ctx, JSValueConst *func_obj, JS_BOOL val);

    JSValue *getPropertyStr(JSContext *ctx, JSValueConst *this_obj,
                            const char *prop);

    JSValue *getPropertyUint32(JSContext *ctx, JSValueConst *this_obj,
                               uint32_t idx);

    int setPropertyInternal(JSContext *ctx, JSValueConst *this_obj,
                            const JSAtom *prop, JSValue *val,
                            int flags);

    int setProperty(JSContext *ctx, JSValueConst *this_obj,
                    const JSAtom *prop, JSValue *val);

    int setPropertyUint32(JSContext *ctx, JSValueConst *this_obj,
                          uint32_t idx, JSValue *val);

    int setPropertyInt64(JSContext *ctx, JSValueConst *this_obj,
                         int64_t idx, JSValue *val);

    int setPropertyStr(JSContext *ctx, JSValueConst *this_obj,
                       const char *prop, JSValue *val);

    void setProp(JSContext *ctx, JSValueConst *this_val, JSValueConst *prop_name, JSValueConst *prop_value, int flags);

    int hasProperty(JSContext *ctx, JSValueConst *this_obj, const JSAtom *prop);

    int preventExtensions(JSContext *ctx, JSValueConst *obj);

    int deleteProperty(JSContext *ctx, JSValueConst *obj, const JSAtom *prop, int flags);

    int setPrototype(JSContext *ctx, JSValueConst *obj, JSValueConst *proto_val);

    JSValue *getPrototype(JSContext *ctx, JSValueConst *val);

    int getOwnPropertyNames(JSContext *ctx, JSPropertyEnum **ptab,
                            uint32_t *plen, JSValueConst *obj, int flags);

    int getOwnProperty(JSContext *ctx, JSPropertyDescriptor *desc,
                       JSValueConst *obj, const JSAtom *prop);

    /*  JSAtom  */
    JSAtom *newAtom(JSContext *ctx, const char *str);

    JSAtom *valueToAtom(JSContext *ctx, JSValueConst *val);

    const char *valueToAtomString(JSContext *ctx, JSValueConst *val);

    JSValue *atomToValue(JSContext *ctx, JSAtom atom);

    JSValue *atomToString(JSContext *ctx, uint32_t atom);

    int oper_typeof(JSContext *ctx, const JSValue *op1);

    const char *dump(JSContext *ctx, JSValueConst *obj);
}
#endif /* QUICKJS_FFI_H */

/*
  Mapping functions to line 815
*/
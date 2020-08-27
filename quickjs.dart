import 'dart:ffi';
import 'package:dart_quickjs_ffi/core.dart';

final QSCode = r'''

global.testAny={
  static_val:2,
  good:(buffer1,buffer2)=>{
      let a = Array.from(new Uint8Array(buffer1));
      console.log('buffer1: ',Utf8ArrayToStr(a));
      let b = Array.from(new Uint8Array(buffer2));
      console.log('buffer2: ',Utf8ArrayToStr(b));
  },
  bad: async (val)=>{
    global.testAny.static_val= global.testAny.static_val+ val;
  },
  twoParams:(val1,val2)=>{
    console.log(val1);
    console.log(val2);
  }
}

function Utf8ArrayToStr(array) {
    var out, i, len, c;
    var char2, char3;

    out = "";
    len = array.length;
    i = 0;
    while(i < len) {
    c = array[i++];
    switch(c >> 4)
    { 
      case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
        // 0xxxxxxx
        out += String.fromCharCode(c);
        break;
      case 12: case 13:
        // 110x xxxx   10xx xxxx
        char2 = array[i++];
        out += String.fromCharCode(((c & 0x1F) << 6) | (char2 & 0x3F));
        break;
      case 14:
        // 1110 xxxx  10xx xxxx  10xx xxxx
        char2 = array[i++];
        char3 = array[i++];
        out += String.fromCharCode(((c & 0x0F) << 12) |
                       ((char2 & 0x3F) << 6) |
                       ((char3 & 0x3F) << 0));
        break;
      }
    }

    return out;
} 

// global.testAny.bad(2).then(()=>console.log(global.testAny.static_val))
// console.log(typeof global.testAny.good());
// console.log(global.testCallback_1("2"));
// console.log(global.testAdd(1));
// console.log(`js result testAdd : ${global.testAdd(1)}`);
// console.log(global.testAsyncAdd(1));
global.testAsyncAdd(1).then((val)=>console.log(`js result testAsyncAdd : ${val}`));
// console.log(global.testAsync(1))

''';

testAdd(Pointer<JSContext> context, Pointer this_val, List<Pointer> args, int handler_id) {
  return JS_Value.newString(context, "lll result").value;
}

testAsyncAdd(Pointer<JSContext> context, Pointer this_val, List<Pointer> args, int handler_id,
    Pointer result_ptr) {
  var str = "hello promise";
  var result = r"""function createPromiseResult(result){
        return Promise.resolve(result);
    }
  createPromiseResult;
  """;

  var promise = eval(context, Utf8Fix.toUtf8(result), result.length);
  var promise_value = JS_Value(context, promise);

  var promise_result = promise_value.call_js([JS_Value.newString(context, str)]);
  var this_val_2 = JS_Value(context, getGlobalObject(context)).getProperty("testAny");

  setPropertyInternal(context, this_val_2.value, newAtom(context, Utf8Fix.toUtf8("static_val")),
      JS_Value.newInt32(context, 888).value, JS_Flags.JS_PROP_C_W_E);

  print("this_val_2 is ${this_val_2.getProperty("static_val").toDartString()}");

  jsvalue_copy(result_ptr, promise_result.value);

  // return promise;
}

main() async {
  var engine = JSEngine.start();

  // engine.createNewFunction("testAdd", testAdd);
  engine.createNewFunction("testAsyncAdd", testAsyncAdd);

  engine.evalScript(QSCode);

  test_call_js(engine);

  // engine.evalScript("global.testAdd(2).then(console.log)");

  JSEngine.stop(engine);
}

test_call_js(JSEngine engine) {
  /// get global object with `testAny`;
  var testAny = engine.global.getProperty("testAny");

  /// get sub-object from `testAny`
  var good = testAny.getProperty("good");

  var twoParams = testAny.getProperty("twoParams");

  var bad = testAny.getProperty("bad");

  /// construct a params to send
  var sss = [
    {"hello": "2"},
    {"world": "3"}
  ];

  /// use `dart_call_js` to call;
  good.call_js_encode(sss);

  twoParams.call_js(
      [JS_Value.newString(engine.context, "i am good"), JS_Value.newInt32(engine.context, 2)]);

  bad.call_js([JS_Value.newInt32(engine.context, 2)]);
  bad.call_js([JS_Value.newInt32(engine.context, 2)]);
  bad.call_js([JS_Value.newInt32(engine.context, 2)]);
  bad.call_js([JS_Value.newInt32(engine.context, 2)]);

  /// evalScript directly to call a js script, here `global.testAny.bad` does not decode `Uint8Array` params
  // var scriptVal = engine.evalScript("global.testAdd(2)");

  // print(scriptVal.toDartString());

  var static_val = testAny.getProperty("static_val");

  print("static_val is : ${static_val.toDartString()}");
}

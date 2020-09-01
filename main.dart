import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:quickjs_dart/core.dart';

final QSCode = r'''
// import * as os from 'os';


global.testAny={
  static_val: 1,
  good:(buffer1,buffer2)=>{
      let a = Array.from(new Uint8Array(buffer1));
      console.log('js good buffer1: ',Utf8ArrayToStr(a));
      let b = Array.from(new Uint8Array(buffer2));
      console.log('js good buffer2: ',Utf8ArrayToStr(b));
  },
  bad:  (val) =>{
    global.testAny.static_val=  global.testAny.static_val + val;
  },
  twoParams:(val1,val2)=>{
    console.log(`js twoParams val1 :${val1}`);
    console.log(`js twoParams val2 :${val2}`);
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
// console.log(`js testAdd : ${global.testAdd(1)}`);
// global.testAdd(1).then((val)=>console.log(`js testAdd : ${val}`))
// console.log(global.testAsyncAdd(1));
// global.testFunctionAdd(1).then((val)=>console.log(`js testAsyncAdd : ${val}`));
// console.log(global.testAsync(1))
// console.log(os.setTimeout);

''';

Future<int> wait2(int number) async {
  await sleep(Duration(seconds: 0));
  return number + 1;
}

JS_Value testAdd({Pointer<JSContext> context, JS_Value this_val, List<JS_Value> args}) {
  var engine = JSEngine.fromContext(context);
  var newPromise = engine.global_promise.call_js(null);
  wait2(ToInt32(context, args[0].value)).then((value) {
    newPromise.getProperty("resolve").call_js([engine.newInt32(value)]);
  }).catchError((e) {
    newPromise.getProperty("reject").call_js([engine.newString(e.toString())]);
  });

  return newPromise.getProperty("promise");
}

testAsyncAdd(
  Pointer<JSContext> context,
  JS_Value this_val,
  List<JS_Value> args,
  int queue_id,
) {
  var str = "hello promise";
  var result = r"""function createPromiseResult(result){
        return Promise.resolve(result);
    }
  createPromiseResult;
  """;

  print("fuck :$queue_id");

  var promise = eval(context, Utf8Fix.toUtf8(result), result.length);
  var promise_value = JS_Value(context, promise);

  var promise_result = promise_value.call_js([JS_Value.newString(context, str)]);
  var this_val_2 = JS_Value(context, getGlobalObject(context)).getProperty("testAny");
  this_val_2.setPropertyValue(
      "static_val", JS_Value.newInt32(context, 888), JS_Flags.JS_PROP_C_W_E);
  var strrrr = this_val_2.getProperty("static_val").toDartString();

  // wait();

  var queue_list =
      JS_Value(context, getGlobalObject(context)).getProperty("__global_async_callback");
  var dartFunc = queue_list.setProperty(queue_id, JS_Value.newInt32(context, 12));

  // wait(() => dartFunc);
  // return promise_result.value;
  // return promise;
}

Object testFunctionAdd(List<String> args) async {
  final int input_1 = int.parse(args[0], radix: 10);
  int ret = 0;
  await wait(() {
    ret = input_1 + 1;
  });
  return ret;
}

wait(obj) {
  return Future.delayed(Duration(seconds: 3), () {
    obj();
  });
}

main() async {
  final engine = JSEngine.start();

  // add 2 new function
  // engine.createNewFunction("testAdd", testAdd);

  // engine.createNewAsyncFunction("testFunctionAdd", testFunctionAdd);
  var testAdd_cb = Dart_JS_Callback(
      engine: engine,
      name: "testAdd",
      handler: (args, context, this_val) async {
        await sleep(Duration(seconds: 2));
        return 1.2;
      });

  engine.createNewFunction(testAdd_cb.name, testAdd_cb.callback_wrapper);

  // eval the js_code
  engine.evalScript(QSCode);
  engine.evalScript(r"""global.testAdd().then(val=>console.log(`js testAdd : ${val}`));""");
  engine.evalScript(r"""global.testAdd().then(val=>console.log(`js testAdd : ${val}`));""");
  // JSEngine.loop(engine);
  // a test script
  await test_call_js(engine);
  JSEngine.loop(engine);
  JSEngine.stop(engine);
}

test_call_js(JSEngine engine) async {
  /// get global object with `testAny`;
  var testAny = engine.global.getProperty("testAny");

  // var cb_array = engine.global.getProperty("__global_async_callback");

  // cb_array.invokeObject("push", [engine.newInt32(16)]);
  // cb_array.getProperty("length").js_print();
  // cb_array.getProperty("0").js_print();

  /// get sub-object from `testAny`
  var good = testAny.getProperty("good");

  /// construct a params to send
  var sss = [
    {"hello": "2"},
    {"world": "3"}
  ];

  /// use `dart_call_js` to call, with encoded Uint8Array
  good.call_js_encode(sss);

  /// get sub-object from `testAny`
  var twoParams = testAny.getProperty("twoParams");

  /// send multi params to this function
  twoParams.call_js([engine.newString("i am good"), engine.newInt32(2)]);

  /// get sub-object from `testAny`
  var bad = testAny.getProperty("bad");

  /// call function 4 times, orignally is 1;
  bad.call_js([engine.newInt32(1)]);
  bad.call_js([engine.newInt32(1)]);
  bad.call_js([engine.newInt32(1)]);
  bad.call_js([engine.newInt32(1)]);
  var static_val = testAny.getProperty("static_val");
  var sss3 = static_val.toDartString();
  // wait(() => print("static_val is : ${sss3}"));

  // engine.global.getProperty("testFunctionAdd").call_js([engine.newInt32(1)]).js_print();

  var some = Dart_JS_Callback(
      engine: engine,
      name: "some",
      handler: (args, context, this_val) {
        print("args");
        return args[1];
      });

  testAny.addCallback(some);

  testAny.getProperty("some").call_js([engine.newInt32(2), engine.newFloat64(4.33)]).js_print();
}

// function newDeferredHandle(vm) {
// 	const deferred = vm.evalCode(`
// 	const result = {};
// 	result.promise = new Promise((resolve, reject) => {
// 	  result.resolve = resolve
// 	  result.reject = reject
// 	});
// 	result;
//    `)
// 	// should always succeed
// 	return vm.unwrap(deferred)
//   }

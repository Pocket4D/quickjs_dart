import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:quickjs_dart/quickjs_dart.dart';

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

''';

Future getNetworkData(int s, Function func) {
  return Future.delayed(Duration(seconds: s), func);
}

main() async {
  final engine = JSEngine.start();

  // 1. add global function before eval script
  // 1.1 create an callback wrapper
  var testAdd_cb = DartCallback(
      engine: engine,
      name: "testAdd",
      handler: (args, context, this_val) async {
        var some = await getNetworkData(args[0] as int, () => args[0] + 1);
        // var kkk = await getNetworkData(args[0] as int, () => "${args[1]} is my string");
        // print("arg2 result :$kkk");
        return some;
        // await wait2(2);
      });

  // 1.2 create function to global object
  engine.createNewFunction(testAdd_cb.name, testAdd_cb.callback_wrapper);

  // engine.evalScript(r"""global.testAdd(1,"2").then(val=>console.log(`js testAdd(1) : ${val}`));""");

  // 2. eval the global script;
  engine.evalScript(QSCode);

  // 3. test another batch of script

  await test_call_js(engine);

  // await getNetworkData(1, () => engine.newString('123').js_print())
  //     .then((value) => engine.newString('456').js_print());

  // 4. loop the engine to make sure async result are executed
  JSEngine.loop(engine);

  // 5 .stop the engine, should be place to flutter widget's `dispose` method;
  // JSEngine.stop(engine);
}

test_call_js(JSEngine engine) async {
  /// get global object with `testAny`;
  var testAny = engine.global.getProperty("testAny");

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

  // /// call function 4 times, orignally is 1;
  bad.call_js([engine.newInt32(1)]);
  bad.call_js([engine.newInt32(1)]);
  bad.call_js([engine.newInt32(1)]);
  bad.call_js([engine.newInt32(1)]);
  var static_val = testAny.getProperty("static_val");

  print("js static_val is : ${static_val.toDartString()}");

  // // added another callback function
  var some = DartCallback(
      engine: engine,
      name: "some",
      handler: (args, context, this_val) {
        return args[1];
      });

  // // this time add it to some js object;
  testAny.addCallback(some);

  // // call the function use ffi;
  testAny.getProperty("some").call_js([engine.newInt32(2), engine.newFloat64(4.33)]).js_print(
      prepend_message: "dart call js is:");

  // // 2.1 test the previous added function
  engine.evalScript(
      r"""global.testAdd(1,"2").then(val=>console.log(`js async callback testAdd(1,"2")  : ${val}`));""");
}

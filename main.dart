import 'dart:async';
import 'package:quickjs_dart/quickjs_dart.dart';

final jsCode = r'''
// import * as os from 'os';


global.testAny={
  staticVal: 1,
  good:(buffer1,buffer2)=>{
      let a = Array.from(new Uint8Array(buffer1));
      console.log('js good buffer1: ',Utf8ArrayToStr(a));
      let b = Array.from(new Uint8Array(buffer2));
      console.log('js good buffer2: ',Utf8ArrayToStr(b));
  },
  bad:  (val) =>{
    global.testAny.staticVal=  global.testAny.staticVal + val;
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

/// A emulator for requesting network data
Future getNetworkData(int s, Function func) {
  return Future.delayed(Duration(seconds: s), func);
}

main() async {
  final engine = JSEngine(options: JSEngineOptions(printConsole: true));

  /// 1. add global function before eval script
  /// 1.1 create an callback wrapper
  var testAddCallback = DartCallback(
      engine: engine,
      name: "testAdd",
      handler: (args, engine, thisVal) async {
        int waitNum = engine.fromJSVal(args[0]);
        var some = await getNetworkData(waitNum, () => (waitNum + 1));
        return some;
      });

  /// 1.2 create function to global object
  engine.createNewFunction(testAddCallback.name, testAddCallback.callbackWrapper);

  /// 2. eval the global script;
  engine.evalScript(jsCode);

  /// 3. test another batch of script
  await testCallJS(engine);

  /// 4. loop the engine to make sure async result are executed
  JSEngine.loop(engine);

  /// 5 .stop the engine, should be place to flutter widget's `dispose` method;
  // JSEngine.stop(engine);
}

testCallJS(JSEngine engine) async {
  /// get global object with `testAny`;
  var testAny = JSEngine.instance.global.getProperty("testAny");

  /// get sub-object from `testAny`
  var good = testAny.getProperty("good");

  /// construct a params to send
  var sss = [
    {"hello": "2"},
    {"world": "3"}
  ];

  /// use `dart_callJS` to call, with encoded Uint8Array
  good.callJSEncode(sss);

  /// get sub-object from `testAny`
  var twoParams = testAny.getProperty("twoParams");

  /// send multi params to this function
  twoParams.callJS([engine.newString("i am good"), engine.newInt32(2)]);

  /// get sub-object from `testAny`
  var bad = testAny.getProperty("bad");

  /// call function 4 times, orignally is 1;
  bad.callJS([engine.newInt32(1)]);
  bad.callJS([engine.newInt32(1)]);
  bad.callJS([engine.newInt32(1)]);
  bad.callJS([engine.newInt32(1)]);
  var staticVal = testAny.getProperty("staticVal");

  print("js staticVal is : ${staticVal.toDartString()}");

  /// added another callback function
  var some = DartCallback(
      engine: engine,
      name: "some",
      handler: (args, context, thisVal) {
        var some = args[0];
        return some;
      });

  /// this time add it to some js object;
  testAny.addCallback(some);

  /// call the function use ffi;
  testAny.getProperty("some").callJS([engine.newInt32(2), engine.newFloat64(4.33)]).jsPrint(
      prependMessage: "dart call js is:");

  /// 2.1 test the previous added function
  engine.evalScript(
      r"""global.testAdd(1,"2").then(val=>console.log(`js async callback testAdd(1,"2")  : ${val}`));""");
}

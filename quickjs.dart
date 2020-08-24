import 'ffi/ffi.dart';

final QSCode = r'''

global.testAny={
  static_val:2,
  good:(buffer)=>{
      let a = Array.from(new Uint8Array(buffer));
      console.log('data: ',Utf8ArrayToStr(a));
  },
  bad: async (val)=>{
    global.testAny.static_val= global.testAny.static_val+ val;
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
console.log(global.testCallback_1("2"));

''';

main() {
  var engine = JSEngine.start();

  engine.evalScript(QSCode);

  test_call_js(engine);

  // engine.evalScript("global.testCallback_2('2')");

  JSEngine.stop(engine);
}

test_call_js(JSEngine engine) {
  /// get global object with `testAny`;
  var testAny = engine.global.getProperty("testAny");

  /// get sub-object from `testAny`
  var good = testAny.getProperty("good");

  // var bad = testAny.getProperty("bad");

  /// construct a params to send
  var sss = {"hello": "2"};

  /// use `dart_call_js` to call;
  good.call_js(sss);

  // bad.call_js(2);

  /// evalScript directly to call a js script, here `global.testAny.bad` does not decode `Uint8Array` params
  var scriptVal = engine.evalScript("global.testAny.bad(2)");

  print(scriptVal.toDartString());

  var static_val = testAny.getProperty("static_val");

  print(static_val.toDartString());
}

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'value.dart';

List<int> toArray(String msg, [String enc]) {
  if (enc == 'hex') {
    List<int> hexRes = new List();
    msg = msg.replaceAll(new RegExp("[^a-z0-9]"), '');
    if (msg.length % 2 != 0) msg = '0' + msg;
    for (var i = 0; i < msg.length; i += 2) {
      var cul = msg[i] + msg[i + 1];
      var result = int.parse(cul, radix: 16);
      hexRes.add(result);
    }
    return hexRes;
  } else {
    List<int> noHexRes = new List();
    for (var i = 0; i < msg.length; i++) {
      var c = msg.codeUnitAt(i);
      var hi = c >> 8;
      var lo = c & 0xff;
      if (hi > 0) {
        noHexRes.add(hi);
        noHexRes.add(lo);
      } else {
        noHexRes.add(lo);
      }
    }

    return noHexRes;
  }
}

Map<String, dynamic> paramsExecutor([List<JSValue> params]) {
  if (params != null) {
    List<int> addressArray = params.map<int>((element) {
      return element.address;
    }).toList();

    final _data = allocate<Pointer<Pointer>>(count: addressArray.length);

    for (int i = 0; i < addressArray.length; ++i) {
      _data[i] = Pointer.fromAddress(addressArray[i]);
    }
    return {"length": addressArray.length, "data": _data};
  } else {
    final _data2 = allocate<Pointer<Pointer>>(count: 0);
    return {"length": 0, "data": _data2};
  }
}

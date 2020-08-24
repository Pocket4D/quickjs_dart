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

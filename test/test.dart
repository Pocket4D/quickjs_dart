@TestOn('vm')
import 'dart:async';
import 'package:test/test.dart';
import 'package:quickjs_dart/core.dart';

void main() {
  group('Bindings', () {
    test('Use newRuntime() to create JSRuntime pointer', () {
      var rt = newRuntime();
      expect(rt.address is int, equals(true));
    });

    test('Use newContext(Pointer<JSRuntime>) to create JSContext pointer', () {
      var rt = newRuntime();
      var ctx = newContext(rt);
      expect(ctx.address is int, equals(true));
    });

    // test('.trim() removes surrounding whitespace', () {
    //   var string = '  foo ';
    //   expect(string.trim(), equals('foo'));
    // });

    test('Future.value() returns the value', () async {
      var value = await Future.value(10);
      expect(value, equals(10));
    });
  });

  group('int', () {
    // test('.remainder() returns the remainder of division', () {
    //   expect(11.remainder(3), equals(2));
    // });

    // test('.toRadixString() returns a hex string', () {
    //   expect(11.toRadixString(16), equals('b'));
    // });
  });
}

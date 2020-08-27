enum QuickJS_Errors { TypeError }

class QuickJSError {
  QuickJS_Errors _error;
  String _message;
  QuickJSError.typeError(this._message) {
    this._error = QuickJS_Errors.TypeError;
  }
  String throwError() {
    var _common = "JSEngine Error";
    var _ret_string;
    switch (_error) {
      case QuickJS_Errors.TypeError:
        {
          _ret_string = ("$_common # JSValue TypeError, message: type is $_message");
          break;
        }
    }
    return _ret_string;
  }
}

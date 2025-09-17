import 'package:http/http.dart' as http;

// 預設情境（理論上不會被用到，但必須存在）
// 這裡直接丟 UnimplementedError，避免誤用。
http.Client createHttpClient({bool withCredentials = false}) {
  throw UnimplementedError(
    'createHttpClient is not implemented for this platform',
  );
}

import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

// Web：可選擇是否帶上 cookie/credential
http.Client createHttpClient({bool withCredentials = false}) {
  final c = BrowserClient();
  c.withCredentials = withCredentials;
  return c;
}

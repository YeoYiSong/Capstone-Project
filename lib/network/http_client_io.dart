import 'package:http/http.dart' as http;

// Android/iOS/Windows/Linux/桌面：用預設 IO client
http.Client createHttpClient({bool withCredentials = false}) => http.Client();

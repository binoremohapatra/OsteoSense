
import "dart:convert";
import "package:dio/dio.dart";

void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: "https://osteosense-tt0q.onrender.com/api/v1",
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
  ));
  
  final phone = "9" + DateTime.now().millisecondsSinceEpoch.toString().substring(4);
  final password = "password123";
  
  try {
    print("Registering $phone...");
    final regRes = await dio.post("/auth/register", data: {
      "fullName": "Test User",
      "phoneNumber": phone,
      "password": password
    });
    print("Register Success: " + regRes.statusCode.toString());
    
    print("Logging in $phone...");
    final logRes = await dio.post("/auth/login", data: {
      "phoneNumber": phone,
      "password": password
    });
    print("Login Success: " + logRes.statusCode.toString());
  } on DioException catch (e) {
    print("Dio Error: " + (e.response?.statusCode?.toString() ?? "no status"));
    print("Data: " + (e.response?.data?.toString() ?? "no data"));
  }
}


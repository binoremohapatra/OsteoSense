
import "dart:convert";
import "package:dio/dio.dart";

void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: "https://osteosense-tt0q.onrender.com/api/v1",
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
  ));
  
  try {
    print("Sending login request...");
    final res = await dio.post("/auth/login", data: {
      "phoneNumber": "1234567890",
      "password": "wrongpassword"
    });
    print("Success: " + res.data.toString());
  } on DioException catch (e) {
    print("Dio Error type: " + e.type.toString());
    print("Status code: " + (e.response?.statusCode?.toString() ?? "null"));
    print("Data type: " + (e.response?.data?.runtimeType.toString() ?? "null"));
    print("Data: " + (e.response?.data?.toString() ?? "null"));
  } catch (e) {
    print("Other error: " + e.toString());
  }
}


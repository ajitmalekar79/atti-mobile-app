import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PostAuthTocken extends GetxController {
  Future<bool> postAuthTocken(String tocken) async {
    final prefs = await SharedPreferences.getInstance();

    const String apiUrl =
        'https://4xkpihe02c.execute-api.ap-south-1.amazonaws.com/Prod/api/v1/auth/set-user-claims';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'authorization': 'Bearer $tocken',
        },
      );

      if (response.statusCode == 200) {
        await prefs.setString('tocken', tocken);
        print('Post created successfully');
        return true;
      } else {
        // Failed to create post
        print('Failed to create post');
        return false;
      }
    } catch (e) {
      // Exception occurred
      print('Exception: $e');
      return false;
    }
  }
}

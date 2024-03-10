import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'model/detail_submission_model.dart';

class DetailSubmitedFormData extends GetxController {
  Future<List<ItemSubmission>> getsubmitedFormDetail(id, itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final apiToken = prefs.getString('tocken');
    DateTime now = DateTime.now();
    List<ItemSubmission> form_data_submited_list = [];

    try {
      // Map<String, dynamic> postData = {'mobileNo': 123455};
      Map<String, String> headers = {
        'authorization': 'Bearer $apiToken',
      };
      final response = await http.get(
          Uri.parse(
              'https://4xkpihe02c.execute-api.ap-south-1.amazonaws.com/Prod/api/v1/item/${itemId}/item-submission/${id}'),
          headers: headers);
      // final result2 = http.post(Uri.parse(APIConstatnts.loginUrl),
      //     body: json.encode(postData));
      if (response.statusCode == 200) {
        dynamic responseBody = json.decode(response.body);
        if (responseBody is Map<String, dynamic>) {
          // If the response body is a JSON object
          form_data_submited_list = [ItemSubmission.fromJson(responseBody)];
        } else if (responseBody is List<dynamic>) {
          // If the response body is a JSON array
          form_data_submited_list = List<ItemSubmission>.from(
            responseBody.map((x) => ItemSubmission.fromJson(x)),
          );
        }
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Failed to load events');
    }
    return form_data_submited_list;
  }
}

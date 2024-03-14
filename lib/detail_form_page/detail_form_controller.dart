import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model/detail_form_model.dart';

class DetailFormData extends GetxController {
  // var data = FormDetailModel(
  //   name: '',
  //   tagList: [],
  //   createdAt: '',
  //   customDisclosures: [],
  //   submition: [],
  //   property: Property(
  //     id: '',
  //     name: '',
  //     createdAt: '',
  //     temp: '',
  //     location: '',
  //   ),
  //   itemId: '',
  // ).obs;

  Future<List<FormDetailModel>> getFormDetail(itemId, {DateTime? date}) async {
    final prefs = await SharedPreferences.getInstance();
    final apiToken = prefs.getString('tocken');
    List<FormDetailModel> formDataList = [];
    String formattedDate =
        '${DateFormat('yyyy-MM-ddTHH:mm:ss.sss').format(date ?? DateTime.now())}Z';
    try {
      Map<String, String> headers = {
        'authorization': 'Bearer $apiToken',
      };
      final response = await http.get(
          Uri.parse(
              'https://4xkpihe02c.execute-api.ap-south-1.amazonaws.com/Prod/api/v1/item/${itemId}?expected-submission-date=${formattedDate}'),
          headers: headers);
      if (response.statusCode == 200) {
        dynamic responseBody = json.decode(response.body);
        if (responseBody is Map<String, dynamic>) {
          // If the response body is a JSON object
          formDataList = [FormDetailModel.fromJson(responseBody)];
        } else if (responseBody is List<dynamic>) {
          // If the response body is a JSON array
          formDataList = List<FormDetailModel>.from(
            responseBody.map((x) => FormDetailModel.fromJson(x)),
          );
        }
        for (var disclosure in formDataList[0].customDisclosures) {
          if (disclosure.type == 'unique_id') {
            List values = await getValueList(itemId, disclosure.id);
            disclosure.valueList = values;
          }
        }
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Failed to load events');
    }
    return formDataList;
  }

  Future<List> getValueList(itemId, disclosureId) async {
    final prefs = await SharedPreferences.getInstance();
    final apiToken = prefs.getString('tocken');
    List formValueList = [];
    try {
      // Map<String, dynamic> postData = {'mobileNo': 123455};
      Map<String, String> headers = {
        'authorization': 'Bearer $apiToken',
      };
      final response = await http.get(
          Uri.parse(
              'https://4xkpihe02c.execute-api.ap-south-1.amazonaws.com/Prod/api/v1/disclosure/item/${itemId}/custom/${disclosureId}'),
          headers: headers);
      if (response.statusCode == 200) {
        dynamic responseBody = json.decode(response.body);
        formValueList = responseBody['values'];
        for (int i = 0; i < formValueList.length; i++) {
          formValueList[i]['title'] =
              '${formValueList[i]['id']} - ${formValueList[i]['value']}';
        }
      } else {
        return formValueList;
      }
    } catch (e) {
      print(e);
      return formValueList;
    }
    return formValueList;
  }
}

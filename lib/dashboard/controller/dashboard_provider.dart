import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/dashboard_data_model.dart';

class HomeDataListController extends GetxController {
  int pageSize = 1;
  int pageCount = 1;
  Future<List<MyItem>> getList(selectedPage) async {
    final prefs = await SharedPreferences.getInstance();
    final apiToken = prefs.getString('tocken');
    List<MyItem> homedata_list = [];
    try {
      // Map<String, dynamic> postData = {'mobileNo': 123455};
      Map<String, String> headers = {
        'authorization': 'Bearer $apiToken',
      };
      final response = await http.get(
          Uri.parse(
              'https://4xkpihe02c.execute-api.ap-south-1.amazonaws.com/Prod/api/v1/item-list?property_id=all&page=$selectedPage'),
          headers: headers);

      if (response.statusCode == 200) {
        homedata_list.clear();
        homedata_list = List<MyItem>.from(
          json.decode(response.body)?['items']?.map(
                (x) => MyItem.fromJson(x),
              ),
        );
        Map<String, dynamic> data = jsonDecode(response.body);

        // Retrieve values and store in int variables
        pageSize = data['page_size'];
        pageCount = data['count'];
        update();
        // eventListModelList = json.decode(response.body)['data'];
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Failed to load events');
    }
    return homedata_list;
  }
}

  // Function to handle forward arrow button press
  


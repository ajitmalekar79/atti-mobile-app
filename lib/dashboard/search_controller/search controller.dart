import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/dashboard_data_model.dart';

class GetListOnSearchController extends GetxController {
  var currentPage = 1.obs; // Observable for current page
  var minPage = 1.obs; // Observable for minimum page number displayed
  var maxPage = 4.obs;

  Future<List<MyItem>> getListOnSearch(
      searchKey, searchText, selectedPage) async {
    final prefs = await SharedPreferences.getInstance();
    final apiToken = prefs.getString('tocken');
    if (searchKey == 'Tag') {
      searchKey = "tag";
    } else if (searchKey == 'Property') {
      searchKey = "property_name";
    } else {
      searchKey = "item_name";
    }

    List<MyItem> homedata_list = [];
    try {
      // Map<String, dynamic> postData = {'mobileNo': 123455};
      Map<String, String> headers = {
        'authorization': 'Bearer $apiToken',
      };
      final response = await http.get(
          Uri.parse(
              'https://4xkpihe02c.execute-api.ap-south-1.amazonaws.com/Prod/api/v1/item-search?feature=item&search_key=$searchKey&search_value=$searchText&detail-level=full&property_id=all&page=$selectedPage'),
          headers: headers);

      if (response.statusCode == 200) {
        homedata_list.clear();
        homedata_list = json.decode(response.body)?['items'].isEmpty
            ? []
            : List<MyItem>.from(
                json.decode(response.body)?['items']?.map(
                      (x) => MyItem.fromJson(x),
                    ),
              );
        // eventListModelList = json.decode(response.body)['data'];
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Failed to load events');
    }
    return homedata_list;
  }

  void updatePageRange() {
    minPage.value = currentPage.value - 1;
    maxPage.value = currentPage.value + 2;
  }

  // Function to handle back arrow button press
  void onBackArrowPressed() {
    if (minPage.value > 1) {
      minPage.value = minPage.value - 4 < 1 ? 1 : minPage.value - 4;
      maxPage.value = minPage.value + 3;
      // fetchData(minPage.value); // Fetch data for the new range
      updatePageRange();
    }
  }

  // Function to handle forward arrow button press
  void onForwardArrowPressed() {
    if (maxPage.value < currentPage.value) {
      minPage.value = maxPage.value + 1;
      maxPage.value = maxPage.value + 4;
      // fetchData(minPage.value); // Fetch data for the new range
      updatePageRange();
    }
  }
}

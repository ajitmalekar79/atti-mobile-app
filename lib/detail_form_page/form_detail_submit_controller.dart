import 'dart:convert';
import 'dart:io';

import 'package:attheblocks/detail_form_page/detail_form_page.dart' as forData;
import 'package:attheblocks/detail_form_page/model/detail_submission_model.dart';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostFormData extends GetxController {
  Future<bool> submitFormData(
      List<forData.FormData> data, String itemId, DateTime date) async {
    bool isSuccess = false;
    String formattedDate =
        '${DateFormat('yyyy-MM-ddTHH:mm:ss.sss').format(date)}Z';
    List<Map<String, dynamic>> postData = [];
    List<String> imagePaths = [];
    for (var element in data) {
      postData.add(element.toJson());
      if (element.type == 'gallery') {
        imagePaths.addAll(element.value);
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiToken = prefs.getString('tocken');

      final response = await http.post(
          Uri.parse(
              'https://4xkpihe02c.execute-api.ap-south-1.amazonaws.com/Prod/api/v1/item/$itemId/item-submission?submission_date=$formattedDate'),
          headers: {
            'Content-Type': 'application/json',
            'authorization': 'Bearer $apiToken',
          },
          body: jsonEncode(postData));
      if (response.statusCode == 200) {
        // var responseBody = json.decode(response.body);
        // if (responseBody['s3Data'] != null &&
        //     responseBody['s3Data'].isNotEmpty) {
        //   List<S3DataModel> s3dataModels = List<S3DataModel>.from(
        //     responseBody['s3Data'].map((x) => S3DataModel.fromJson(x)),
        //   );
        //   for (var s3Data in s3dataModels) {
        //     Map<String, dynamic>? fileData = postData
        //         .firstWhereOrNull((element) => element['type'] == 'gallery');
        //     if (fileData != null) {
        //       String imagePath = fileData['value'][0];
        //       bool isFileUploaded = await uploadImages(s3Data, imagePath);
        //     }
        //   }
        // }

        // if (imagePath != '') {
        Map<String, dynamic> jsonDataMap = json.decode(response.body);
        List<Map<String, dynamic>> s3Data =
            List<Map<String, dynamic>>.from(jsonDataMap['s3Data']);
        s3Data.forEach((s3Item) {
          if (s3Item.containsKey('fields') &&
              s3Item['fields'] is Map<String, dynamic>) {
            Map<String, String> convertedFields = {};
            s3Item['fields'].forEach((key, value) {
              convertedFields[key] = value.toString();
            });
            s3Item['fields'] = convertedFields;
          }
        });
        uploadImagesData(s3Data, imagePaths);
        // }

        isSuccess = true;
      } else {
        isSuccess = false;

        // throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Failed to load events');
    }
    return isSuccess;
  }

  Future<void> uploadImagesData(s3Data, List<String> imagePaths) async {
    // String uploadUrl = 'YOUR_UPLOAD_URL';
    // List<Map<String, dynamic>> s3Data = [
    //   {
    //     "url":
    //         "https://s3.ap-south-1.amazonaws.com/rt-impact-internal-development",
    //     "fields": {
    //       "key":
    //           "staging/disclosure-images/65ecc7005ec052c457f04e4a/atbi_logo.png",
    //       "bucket": "rt-impact-internal-development",
    //       "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
    //       "X-Amz-Credential":
    //           "AKIA5EDD62YO2LHE6YGG/20240309/ap-south-1/s3/aws4_request",
    //       "X-Amz-Date": "20240309T203056Z",
    //       "Policy":
    //           "eyJleHBpcmF0aW9uIjoiMjAyNC0wMy0wOVQyMDo0MDo1NloiLCJjb25kaXRpb25zIjpbWyJjb250ZW50LWxlbmd0aC1yYW5nZSIsMCwxMDAwMDAwMF0seyJrZXkiOiJzdGFnaW5nL2Rpc2Nsb3N1cmUtaW1hZ2VzLzY1ZWNjNzAwNWVjMDUyYzQ1N2YwNGU0YS9hdGJpX2xvZ28ucG5nIn0seyJidWNrZXQiOiJydC1pbXBhY3QtaW50ZXJuYWwtZGV2ZWxvcG1lbnQifSx7IlgtQW16LUFsZ29yaXRobSI6IkFXUzQtSE1BQy1TSEEyNTYifSx7IlgtQW16LUNyZWRlbnRpYWwiOiJBS0lBNUVERDYyWU8yTEhFNllHRy8yMDI0MDMwOS9hcC1zb3V0aC0xL3MzL2F3czRfcmVxdWVzdCJ9LHsiWC1BbXotRGF0ZSI6IjIwMjQwMzA5VDIwMzA1NloifV19",
    //       "X-Amz-Signature":
    //           "29bd3d4158502734a71f413b7122d3a123542dd59c5f211d872cafc6b48e3599"
    //     }
    //   },
    //   {
    //     "url":
    //         "https://s3.ap-south-1.amazonaws.com/rt-impact-internal-development",
    //     "fields": {
    //       "key":
    //           "staging/disclosure-images/65ecc7005ec052c457f04e4a/account_bg.jpg",
    //       "bucket": "rt-impact-internal-development",
    //       "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
    //       "X-Amz-Credential":
    //           "AKIA5EDD62YO2LHE6YGG/20240309/ap-south-1/s3/aws4_request",
    //       "X-Amz-Date": "20240309T203056Z",
    //       "Policy":
    //           "eyJleHBpcmF0aW9uIjoiMjAyNC0wMy0wOVQyMDo0MDo1NloiLCJjb25kaXRpb25zIjpbWyJjb250ZW50LWxlbmd0aC1yYW5nZSIsMCwxMDAwMDAwMF0seyJrZXkiOiJzdGFnaW5nL2Rpc2Nsb3N1cmUtaW1hZ2VzLzY1ZWNjNzAwNWVjMDUyYzQ1N2YwNGU0YS9hY2NvdW50X2JnLmpwZyJ9LHsiYnVja2V0IjoicnQtaW1wYWN0LWludGVybmFsLWRldmVsb3BtZW50In0seyJYLUFtei1BbGdvcml0aG0iOiJBV1M0LUhNQUMtU0hBMjU2In0seyJYLUFtei1DcmVkZW50aWFsIjoiQUtJQTVFREQ2MllPMkxIRTZZR0cvMjAyNDAzMDkvYXAtc291dGgtMS9zMy9hd3M0X3JlcXVlc3QifSx7IlgtQW16LURhdGUiOiIyMDI0MDMwOVQyMDMwNTZaIn1dfQ==",
    //       "X-Amz-Signature":
    //           "df388e486a89eed682bdca65ded598774f8cfc7db6abc86ec2482a987ef16076"
    //     }
    //   }
    // ];

    for (int i = 0; i < s3Data.length; i++) {
      var request = http.MultipartRequest('POST', Uri.parse(s3Data[i]['url']));
      try {
        // s3Data.forEach((s3Item) {
        if (s3Data[i].containsKey('fields')) {
          request.fields.addAll(s3Data[i]['fields']!);
        }
        // });

        // Add file to the request
        File file = File(imagePaths[i]); // Replace with your file path
        var multipartFile =
            await http.MultipartFile.fromPath('file', file.path);
        request.files.add(multipartFile);

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          print('File uploaded successfully');
          print('Response: ${response.body}');
        } else {
          print('Error uploading file: ${response.statusCode}');
        }
      } catch (e) {
        print('Error uploading file: $e');
      }
    }
  }

  Future<bool> uploadImages(S3DataModel s3data, String filePath) async {
    bool isSuccess = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiToken = prefs.getString('tocken');

      // final response = await http.post(
      //     Uri.parse(
      //         'https://4xkpihe02c.execute-api.ap-south-1.amazonaws.com/Prod/api/v1/item/$itemId/item-submission?submission_date=$formattedDate'),
      //     headers: {
      //       'Content-Type': 'application/json',
      //       'authorization': 'Bearer $apiToken',
      //     },
      //     body: jsonEncode(postData));
      var uri = Uri.parse(s3data.url);
      var request = http.MultipartRequest('POST', uri)
        ..fields['key'] = s3data.fields.key
        ..fields['bucket'] = s3data.fields.bucket
        ..fields['X-Amz-Algorithm'] = s3data.fields.xAmzAlgorithm ?? ''
        ..fields['X-Amz-Credential'] = s3data.fields.xAmzCredential ?? ''
        ..fields['X-Amz-Date'] = s3data.fields.xAmzDate ?? ''
        ..fields['X-Amz-Signature'] = s3data.fields.xAmzSignature ?? ''
        ..fields['Policy'] = s3data.fields.policy ?? ''
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          filePath,
          // contentType: MediaType('image', 'jpg'),
        ))
        ..headers['authorization'] = 'Bearer $apiToken'
        ..headers['Content-Type'] = 'multipart/form-data';
      var response = await request.send();

      if (response.statusCode == 200) {
        isSuccess = true;
      } else {
        isSuccess = false;
        throw Exception('Failed to load events');
      }
    } catch (e) {
      isSuccess = false;
      throw Exception('Failed to load events');
    }
    return isSuccess;
  }
}

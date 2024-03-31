// models/submission.dart

import '../detail_form_page.dart';

// models/submission.dart

import 'dart:convert'; // Import dart:convert to use JSON encoding/decoding

class SubmissionModel {
  final DateTime date;
  final String itemId;
  final List<FormData> formDataList;

  SubmissionModel({
    required this.date,
    required this.itemId,
    required this.formDataList,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'itemId': itemId,
      'formDataList': jsonEncode(formDataList
          .map((formData) => formData.toJson())
          .toList()), // Serialize formDataList to JSON
    };
  }

  factory SubmissionModel.fromMap(Map<String, dynamic> map) {
    return SubmissionModel(
      date: DateTime.parse(map['date']),
      itemId: map['itemId'],
      formDataList: List<FormData>.from(jsonDecode(map['formDataList']).map(
          (formDataMap) => FormData.fromJson(
              formDataMap))), // Deserialize JSON to list of FormData
    );
  }
}

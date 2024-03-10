import 'package:attheblocks/detail_form_page/detail_form_page.dart';
import 'package:flutter/material.dart';

class NextPage extends StatefulWidget {
  final List<FormData> formDatavalues;

  NextPage({required this.formDatavalues});

  @override
  State<NextPage> createState() => _NextPageState();
}

class _NextPageState extends State<NextPage> {
  List<Map<String, dynamic>> jsonList = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    jsonList =
        widget.formDatavalues.map((formData) => formData.toJson()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Form Data')),
      body: Text(jsonList.toString()),
      // body: ListView.builder(
      //   itemCount: widget.formDatavalues.length,
      //   itemBuilder: (context, index) {
      //     final formData = widget.formDatavalues[index];
      //     return ListTile(
      //       title: Text(formData.custom_disclosure_id),
      //       subtitle: _buildSubtitle(formData.value),
      //     );
      //   },
      // ),
    );
  }

  Widget _buildSubtitle(dynamic value) {
    if (value is List) {
      // If value is a list, display its elements as a comma-separated string
      return Text(value.join(', '));
    } else if (value is int || value is double) {
      // If value is a number, display it as a string
      return Text(value.toString());
    } else if (value is Map<String, List<dynamic>>) {
      // If value is a map, display its key-value pairs
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.entries.map((entry) {
          return ListTile(
            title: Text(entry.key),
            subtitle: _buildSubtitle(entry.value),
          );
        }).toList(),
      );
    } else {
      // For other data types (e.g., string), display it as is
      return Text(value);
    }
  }
}

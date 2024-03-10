class ItemSubmission {
  final String itemSubmissionId;
  final List<CustomDisclosureSubmission> customDisclosureSubmissions;
  final List<dynamic> griDisclosureSubmissions;

  ItemSubmission({
    required this.itemSubmissionId,
    required this.customDisclosureSubmissions,
    required this.griDisclosureSubmissions,
  });

  factory ItemSubmission.fromJson(Map<String, dynamic> json) {
    return ItemSubmission(
      itemSubmissionId: json['item_submission_id'],
      customDisclosureSubmissions: json['custom_disclosure_submissions'] != null
          ? List<CustomDisclosureSubmission>.from(
              json['custom_disclosure_submissions']
                  .map((x) => CustomDisclosureSubmission.fromJson(x)))
          : [],
      griDisclosureSubmissions: json['gri_disclosure_submissions'] ?? [],
    );
  }
}

class CustomDisclosureSubmission {
  final String customDisclosureId;
  String? disclosure;
  String? disclosureName;
  var value;
  List? valueList;
  String? type;
  String? timer;

  CustomDisclosureSubmission({
    required this.customDisclosureId,
    this.disclosure,
    this.disclosureName,
    this.value,
    this.valueList,
    this.type,
    this.timer,
  });

  factory CustomDisclosureSubmission.fromJson(Map<String, dynamic> json) {
    return CustomDisclosureSubmission(
      customDisclosureId: json['custom_disclosure_id'],
      disclosure: json['disclosure'],
      disclosureName: json['disclosure_name'],
      value: json['value'],
      valueList:
          json['value_list'] != null ? List.from(json['value_list']) : [],
      type: json['type'],
      timer: json['timer'],
    );
  }
}

class S3DataModel {
  final String url;
  final S3DataFieldsModel fields;

  S3DataModel({
    required this.url,
    required this.fields,
  });

  factory S3DataModel.fromJson(Map<String, dynamic> json) {
    return S3DataModel(
      url: json['url'],
      fields: S3DataFieldsModel.fromJson(json['fields']),
    );
  }
}

class S3DataFieldsModel {
  final String key;
  final String bucket;
  String? xAmzAlgorithm;
  String? xAmzCredential;
  String? xAmzDate;
  String? policy;
  String? xAmzSignature;

  S3DataFieldsModel({
    required this.key,
    required this.bucket,
    this.xAmzAlgorithm,
    this.xAmzCredential,
    this.xAmzDate,
    this.policy,
    this.xAmzSignature,
  });

  factory S3DataFieldsModel.fromJson(Map<String, dynamic> json) {
    return S3DataFieldsModel(
      key: json['key'],
      bucket: json['bucket'],
      xAmzAlgorithm: json['X-Amz-Algorithm'],
      xAmzCredential: json['X-Amz-Credential'],
      xAmzDate: json['X-Amz-Date'],
      policy: json['Policy'],
      xAmzSignature: json['X-Amz-Signature'],
    );
  }
}

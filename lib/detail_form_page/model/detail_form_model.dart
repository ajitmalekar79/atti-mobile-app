class FormDetailModel {
  String name;
  List<String> tagList;
  String createdAt;
  List<CustomDisclosure> customDisclosures;
  List<Submission> submissions;
  Property property;
  String itemId;

  FormDetailModel({
    required this.name,
    required this.tagList,
    required this.createdAt,
    required this.customDisclosures,
    required this.submissions,
    required this.property,
    required this.itemId,
  });

  factory FormDetailModel.fromJson(Map<String, dynamic> json) {
    return FormDetailModel(
      name: json['name'],
      tagList: List<String>.from(json['tag_list'] ?? []),
      createdAt: json['created_at'],
      customDisclosures: json['custom_disclosures'] != null
          ? List<CustomDisclosure>.from(
              json['custom_disclosures'].map(
                (disclosure) => CustomDisclosure.fromJson(disclosure),
              ),
            )
          : [],
      submissions: json['submissions'] != null
          ? List<Submission>.from(
              json['submissions'].map(
                (submission) => Submission.fromJson(submission),
              ),
            )
          : [],
      property: Property.fromJson(json['property']),
      itemId: json['item_id'],
    );
  }
}

class CustomDisclosure {
  String id;
  String disclosure;
  String disclosureName;
  String type;
  List valueList;
  String timer;
  bool required;
  bool isSubmissionExpected;
  List<ComputedDisclosureModel>? computedDisclosureFormula;

  CustomDisclosure({
    required this.id,
    required this.disclosure,
    required this.disclosureName,
    required this.type,
    required this.valueList,
    required this.timer,
    required this.required,
    required this.isSubmissionExpected,
    this.computedDisclosureFormula,
  });

  factory CustomDisclosure.fromJson(Map<String, dynamic> json) {
    return CustomDisclosure(
      id: json['_id'],
      disclosure: json['disclosure'],
      disclosureName: json['disclosure_name'],
      type: json['type'],
      valueList: List.from(json['value_list'] ?? []),
      timer: json['timer'],
      required: json['required'] ?? false,
      isSubmissionExpected: json['is_submission_expected'],
      computedDisclosureFormula: json['computed_disclosure_formula'] != null
          ? List<ComputedDisclosureModel>.from(
              json['computed_disclosure_formula'].map(
                (computedDisclosure) =>
                    ComputedDisclosureModel.fromJson(computedDisclosure),
              ),
            )
          : [],
    );
  }
}

class Submission {
  String id;
  String submissionAt;
  String createdAt;

  Submission({
    required this.id,
    required this.submissionAt,
    required this.createdAt,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['_id'],
      submissionAt: json['submission_at'],
      createdAt: json['created_at'],
    );
  }
}

class Property {
  String id;
  String name;
  String createdAt;
  String temp;
  String location;

  Property({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.temp,
    required this.location,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['_id'],
      name: json['name'],
      createdAt: json['created_at'],
      temp: json['temp'],
      location: json['location'],
    );
  }
}

class ComputedDisclosureModel {
  String? disclosureId;
  String? type;
  String? position;
  String? operator;
  String? value;

  ComputedDisclosureModel({
    this.disclosureId,
    this.type,
    this.position,
    this.operator,
    this.value,
  });

  factory ComputedDisclosureModel.fromJson(Map<String, dynamic> json) {
    return ComputedDisclosureModel(
      disclosureId: json['disclosure_id'],
      type: json['type'],
      position: json['position'],
      operator: json['operator'],
      value: json['value'] != null ? json['value'].toString() : null,
    );
  }
}

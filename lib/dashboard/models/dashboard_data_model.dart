class MyItem {
  final int pageSize;
  final int pageCount;
  final String name;
  final String imageUrl;
  final MyProperty property;
  final List<String> tagList;
  // final double valueEmissions;
  final double percentCompleted;
  final String itemId;

  MyItem({
    required this.pageSize,
    required this.pageCount,
    required this.name,
    required this.imageUrl,
    required this.property,
    required this.tagList,
    // required this.valueEmissions,
    required this.percentCompleted,
    required this.itemId,
  });

  factory MyItem.fromJson(Map<String, dynamic> json) {
    return MyItem(
      pageSize: json['page_size'] ?? 0,
      pageCount: json['count'] ?? 0,
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      property: MyProperty.fromJson(json['property']),
      tagList: List<String>.from(json['tag_list']),
      // valueEmissions: json['value_emissions'].toDouble(),
      percentCompleted: (json['percent_completed'] ?? 0).toDouble(),
      itemId: json['item_id'] ?? '',
    );
  }
}

class MyProperty {
  final String id;
  final String name;

  MyProperty({
    required this.id,
    required this.name,
  });

  factory MyProperty.fromJson(Map<String, dynamic> json) {
    return MyProperty(
      id: json['_id'],
      name: json['name'],
    );
  }
}

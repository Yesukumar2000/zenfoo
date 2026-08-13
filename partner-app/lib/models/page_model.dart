class PageModel {
  final int id;
  final String pageType;
  final String title;
  final String content;

  PageModel({
    required this.id,
    required this.pageType,
    required this.title,
    required this.content,
  });

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'] ?? 0,
      pageType: json['page_type'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page_type': pageType,
      'title': title,
      'content': content,
    };
  }
}

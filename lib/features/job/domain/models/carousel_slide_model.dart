class CarouselSlideModel {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final String actionLabel;
  final String actionLink;
  final bool isActive;
  final int orderIndex;
  final String type; // 'image' or 'video'
  final String navType; // 'internal' or 'external'
  final String navUrl;
  final int? duration; // Duration in seconds

  CarouselSlideModel({
    required this.id,
    required this.imageUrl,
    this.title = '',
    this.description = '',
    this.actionLabel = '',
    this.actionLink = '',
    this.isActive = true,
    this.orderIndex = 0,
    this.type = 'image',
    this.navType = '',
    this.navUrl = '',
    this.duration,
  });

  factory CarouselSlideModel.fromJson(Map<String, dynamic> json) {
    return CarouselSlideModel(
      id: json['id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      actionLabel: json['action_label'] as String? ?? '',
      actionLink: json['action_link'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      orderIndex: json['order_index'] as int? ?? 0,
      type: json['type'] as String? ?? 'image',
      navType: json['nav_type'] as String? ?? '',
      navUrl: json['nav_url'] as String? ?? '',
      duration: json['duration'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'title': title,
      'description': description,
      'action_label': actionLabel,
      'action_link': actionLink,
      'is_active': isActive,
      'order_index': orderIndex,
      'type': type,
      'nav_type': navType,
      'nav_url': navUrl,
      'duration': duration,
    };
  }
}




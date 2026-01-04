class CarouselSlideModel {
  final String id;
  final String imageUrl;
  final String navType; // 'internal', 'external'
  final String navUrl;
  final int orderIndex;
  final bool isActive;

  CarouselSlideModel({
    required this.id,
    required this.imageUrl,
    required this.navType,
    required this.navUrl,
    required this.orderIndex,
    required this.isActive,
  });

  factory CarouselSlideModel.fromJson(Map<String, dynamic> json) {
    return CarouselSlideModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      navType: json['nav_type']?.toString() ?? 'internal',
      navUrl: json['nav_url']?.toString() ?? '',
      orderIndex: json['order_index'] is int
          ? json['order_index']
          : int.tryParse(json['order_index']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] is bool
          ? json['is_active']
          : (json['is_active']?.toString() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'nav_type': navType,
      'nav_url': navUrl,
      'order_index': orderIndex,
      'is_active': isActive,
    };
  }

  CarouselSlideModel copyWith({
    String? id,
    String? imageUrl,
    String? navType,
    String? navUrl,
    int? orderIndex,
    bool? isActive,
  }) {
    return CarouselSlideModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      navType: navType ?? this.navType,
      navUrl: navUrl ?? this.navUrl,
      orderIndex: orderIndex ?? this.orderIndex,
      isActive: isActive ?? this.isActive,
    );
  }
}

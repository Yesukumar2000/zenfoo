import 'package:zenfoo_partner/utils/safe_parser.dart';

class BannerSliderModel {
  final int id;
  final String imageUrl;
  final String? sliderUrl;
  final int status;

  BannerSliderModel({
    required this.id,
    required this.imageUrl,
    this.sliderUrl,
    required this.status,
  });

  bool get isVideo {
    final lower = imageUrl.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm');
  }

  factory BannerSliderModel.fromJson(Map<String, dynamic> json) {
    return BannerSliderModel(
      id: SafeParser.parseInt(json['id']),
      imageUrl: SafeParser.parseString(json['image_url']),
      sliderUrl: SafeParser.parseStringNullable(json['slider_url']),
      status: SafeParser.parseInt(json['status']),
    );
  }
}

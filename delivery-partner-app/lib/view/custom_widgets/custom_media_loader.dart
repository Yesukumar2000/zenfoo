import 'package:zenfoo_partner/view/custom_widgets/full_image_view.dart';
import 'package:zenfoo_partner/view/custom_widgets/full_video_view.dart';

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomMediaLoader extends StatelessWidget {
  final String url;
  final String type; // "image" or "video"

  const CustomMediaLoader({
    super.key,
    required this.url,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // IMAGE
          if (type == "image")
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullImageView(imageUrl: url),
                  ),
                );
              },
              child: Hero(
                tag: url,
                child: Image.asset(
                  url,
                  height: 90,
                  width: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, __) {
                    return Container(
                      height: 90,
                      width: 90,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: Text(
                        "",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: Colors.red, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),

          // VIDEO
          if (type == "video")
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullVideoView(videoUrl: url),
                  ),
                );
              },
              child: Stack(
                children: [
                  Image.asset(
                    "assets/images/videoplaceholder.png",
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: 34,
                        width: 34,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

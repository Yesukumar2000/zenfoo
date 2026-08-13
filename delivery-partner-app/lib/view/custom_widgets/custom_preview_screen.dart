import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class PreviewScreen extends StatefulWidget {
  final String? networkUrl;
  final File? localFile;

  const PreviewScreen({super.key, this.networkUrl, this.localFile});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  bool get isVideo {
    final path = widget.networkUrl ?? widget.localFile!.path;
    return path.endsWith(".mp4") || path.endsWith(".mov");
  }

  @override
  void initState() {
    super.initState();

    if (isVideo) {
      _videoPlayerController = widget.networkUrl != null
          ? VideoPlayerController.networkUrl(Uri.parse(widget.networkUrl!))
          : VideoPlayerController.file(widget.localFile!);

      _videoPlayerController!.initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: true,
            looping: false,
            showControls: true,
            allowFullScreen: true,
            allowMuting: true,
            showControlsOnInitialize: true,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNet = widget.networkUrl != null;

    return CustomScaffold(
      appBar: AppBar(title: Text("Preview")),
      body: Center(
        child: isVideo
            ? _chewieController != null
                ? Chewie(controller: _chewieController!)
                : CircularProgressIndicator()
            : isNet
                ? Image.network(widget.networkUrl!)
                : Image.file(widget.localFile!),
      ),
    );
  }
}

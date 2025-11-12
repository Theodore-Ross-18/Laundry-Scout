import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';


class ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const ImagePreviewScreen({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

      ),
      body: Center(
        child: Hero(
          tag: heroTag ?? imageUrl,
          child: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 100,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ImagePreviewDialog extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const ImagePreviewDialog({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Center(
            child: Hero(
              tag: heroTag ?? imageUrl,
              child: PhotoView(
                imageProvider: NetworkImage(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

        ],
      ),
    );
  }
}

void showImagePreview(BuildContext context, String imageUrl, {String? heroTag}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black87,
    builder: (context) => ImagePreviewDialog(
      imageUrl: imageUrl,
      heroTag: heroTag,
    ),
  );
}

void navigateToImagePreview(BuildContext context, String imageUrl, {String? heroTag}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ImagePreviewScreen(
        imageUrl: imageUrl,
        heroTag: heroTag,
      ),
    ),
  );
}
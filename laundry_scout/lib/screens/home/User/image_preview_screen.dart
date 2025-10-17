import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImagePreviewScreen extends StatelessWidget {
  final String? imageUrl;
  final PlatformFile? imageFile;

  const ImagePreviewScreen({
    super.key,
    this.imageUrl,
    this.imageFile,
  }) : assert(imageUrl != null || imageFile != null, 'Either imageUrl or imageFile must be provided');

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageFile != null) {
      if (kIsWeb) {
        imageWidget = Image.memory(
          imageFile!.bytes!,
          fit: BoxFit.contain,
        );
      } else {
        imageWidget = Image.file(
          File(imageFile!.path!),
          fit: BoxFit.contain,
        );
      }
    } else {
      imageWidget = Image.network(
        imageUrl!,
        fit: BoxFit.contain,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5A35E3)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Hero(
            tag: imageUrl ?? imageFile!.path!, 
            child: imageWidget,
          ),
        ),
      ),
    );
  }
}
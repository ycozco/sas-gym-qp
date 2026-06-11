import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PickedLocalImage {
  PickedLocalImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get size => bytes.length;
}

class LocalImagePicker {
  LocalImagePicker._();

  static final ImagePicker _picker = ImagePicker();

  static Future<PickedLocalImage?> pickImage({
    List<String>? allowedExtensions,
  }) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final name = _normalizeName(file.name);

    if (!_isAllowed(name, allowedExtensions)) {
      throw const FormatException(
        'Selected image does not match the allowed extension list.',
      );
    }

    return PickedLocalImage(name: name, bytes: bytes);
  }

  static bool _isAllowed(String name, List<String>? allowedExtensions) {
    if (allowedExtensions == null || allowedExtensions.isEmpty) {
      return true;
    }

    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) {
      return false;
    }

    final extension = name.substring(dotIndex + 1).toLowerCase();
    final allowed = allowedExtensions.map((item) => item.toLowerCase()).toSet();
    return allowed.contains(extension);
  }

  static String _normalizeName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'selected-image.jpg';
    }
    return trimmed;
  }
}

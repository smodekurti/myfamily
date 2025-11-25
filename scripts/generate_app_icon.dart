import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Script to generate app icon programmatically
/// Creates a 1024x1024 icon with family graphic
/// Based on the blue gradient design with white family graphic
Future<void> main() async {
  const size = 1024;
  
  // Create a new image
  final image = img.Image(width: size, height: size);
  
  // Fill with blue gradient background
  // Light blue center (#4A9EFF) to darker blue edges (#1E5FA8)
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final centerX = size / 2;
      final centerY = size / 2;
      final distance = ((x - centerX) * (x - centerX) + (y - centerY) * (y - centerY)) / (size * size / 4);
      final t = distance.clamp(0.0, 1.0);
      
      // Interpolate between light blue and dark blue
      final r = (74 + (30 - 74) * t).toInt().clamp(0, 255);
      final g = (158 + (95 - 158) * t).toInt().clamp(0, 255);
      final b = (255 + (168 - 255) * t).toInt().clamp(0, 255);
      
      image.setPixel(x, y, img.ColorRgb8(r, g, b));
    }
  }
  
  // Draw family graphic (2 adults + 2 children) in white
  final white = img.ColorRgb8(255, 255, 255);
  
  // Adult 1 (left) - larger
  _drawPerson(image, (size * 0.25).round(), (size * 0.4).round(), (size * 0.12).round(), white);
  
  // Adult 2 (right) - larger
  _drawPerson(image, (size * 0.75).round(), (size * 0.4).round(), (size * 0.12).round(), white);
  
  // Child 1 (left, smaller)
  _drawPerson(image, (size * 0.35).round(), (size * 0.55).round(), (size * 0.08).round(), white);
  
  // Child 2 (right, smaller)
  _drawPerson(image, (size * 0.65).round(), (size * 0.55).round(), (size * 0.08).round(), white);
  
  // Draw "MyFamily" text at the bottom
  // Using simple pixel-based text rendering
  _drawText(image, 'MyFamily', (size * 0.5).round(), (size * 0.75).round(), (size * 0.08).round(), white);
  
  // Save the image
  final assetsDir = Directory('assets/icons');
  if (!await assetsDir.exists()) {
    await assetsDir.create(recursive: true);
  }
  
  final iconFile = File('assets/icons/app_icon.png');
  final pngBytes = Uint8List.fromList(img.encodePng(image));
  await iconFile.writeAsBytes(pngBytes);
  
  print('✅ App icon generated successfully at ${iconFile.path}');
  print('   Size: ${size}x${size} pixels');
  
  // Also create foreground for adaptive icon (just the family graphic on transparent)
  final foregroundImage = img.Image(width: size, height: size);
  // Fill with transparent
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      foregroundImage.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
    }
  }
  
  // Draw family graphic in white
  _drawPerson(foregroundImage, (size * 0.25).round(), (size * 0.4).round(), (size * 0.12).round(), white);
  _drawPerson(foregroundImage, (size * 0.75).round(), (size * 0.4).round(), (size * 0.12).round(), white);
  _drawPerson(foregroundImage, (size * 0.35).round(), (size * 0.55).round(), (size * 0.08).round(), white);
  _drawPerson(foregroundImage, (size * 0.65).round(), (size * 0.55).round(), (size * 0.08).round(), white);
  
  final foregroundFile = File('assets/icons/app_icon_foreground.png');
  final foregroundPngBytes = Uint8List.fromList(img.encodePng(foregroundImage));
  await foregroundFile.writeAsBytes(foregroundPngBytes);
  
  print('✅ App icon foreground generated successfully at ${foregroundFile.path}');
}

void _drawPerson(img.Image image, int centerX, int centerY, int size, img.Color color) {
  // Draw head (filled circle)
  final headRadius = (size * 0.3).round();
  final headY = centerY - (size * 0.15).round();
  
  // Draw filled circle by iterating through pixels
  for (int y = headY - headRadius; y <= headY + headRadius; y++) {
    for (int x = centerX - headRadius; x <= centerX + headRadius; x++) {
      final dx = x - centerX;
      final dy = y - headY;
      if (dx * dx + dy * dy <= headRadius * headRadius) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
  
  // Draw body (rounded rectangle that tapers down)
  final bodyWidth = (size * 0.4).round();
  final bodyHeight = (size * 0.5).round();
  final bodyTop = centerY + (size * 0.1).round();
  final bodyLeft = centerX - bodyWidth ~/ 2;
  final radius = 8;
  
  // Draw filled rectangle with rounded corners
  for (int y = bodyTop; y < bodyTop + bodyHeight; y++) {
    for (int x = bodyLeft; x < bodyLeft + bodyWidth; x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        // Check if we're in a corner that needs rounding
        bool shouldDraw = true;
        
        // Top-left corner
        if (x < bodyLeft + radius && y < bodyTop + radius) {
          final dx = x - (bodyLeft + radius);
          final dy = y - (bodyTop + radius);
          if (dx * dx + dy * dy > radius * radius) {
            shouldDraw = false;
          }
        }
        // Top-right corner
        else if (x >= bodyLeft + bodyWidth - radius && y < bodyTop + radius) {
          final dx = x - (bodyLeft + bodyWidth - radius);
          final dy = y - (bodyTop + radius);
          if (dx * dx + dy * dy > radius * radius) {
            shouldDraw = false;
          }
        }
        // Bottom-left corner
        else if (x < bodyLeft + radius && y >= bodyTop + bodyHeight - radius) {
          final dx = x - (bodyLeft + radius);
          final dy = y - (bodyTop + bodyHeight - radius);
          if (dx * dx + dy * dy > radius * radius) {
            shouldDraw = false;
          }
        }
        // Bottom-right corner
        else if (x >= bodyLeft + bodyWidth - radius && y >= bodyTop + bodyHeight - radius) {
          final dx = x - (bodyLeft + bodyWidth - radius);
          final dy = y - (bodyTop + bodyHeight - radius);
          if (dx * dx + dy * dy > radius * radius) {
            shouldDraw = false;
          }
        }
        
        if (shouldDraw) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}

void _drawText(img.Image image, String text, int centerX, int centerY, int fontSize, img.Color color) {
  // Improved bitmap font rendering for "MyFamily"
  // Using a larger, clearer font pattern
  final charWidth = (fontSize * 0.65).round();
  final charHeight = fontSize;
  final spacing = (fontSize * 0.15).round();
  
  // Calculate total width
  final totalWidth = (text.length * (charWidth + spacing) - spacing).round();
  final startX = centerX - totalWidth ~/ 2;
  
  // Draw each character using improved patterns
  int xPos = startX;
  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    _drawChar(image, char, xPos, centerY - charHeight ~/ 2, charWidth, charHeight, color);
    xPos += charWidth + spacing;
  }
}

void _drawChar(img.Image image, String char, int x, int y, int width, int height, img.Color color) {
  // Improved 7x9 pixel font representation for better readability
  final patterns = _getCharPattern(char);
  if (patterns.isEmpty) return;
  
  final pixelSize = (width / 7).round().clamp(1, width ~/ 7);
  final pixelHeight = (height / 9).round().clamp(1, height ~/ 9);
  
  for (int row = 0; row < patterns.length && row < 9; row++) {
    final pattern = patterns[row];
    for (int col = 0; col < 7; col++) {
      if (pattern & (1 << (6 - col)) != 0) {
        final px = x + (col * pixelSize);
        final py = y + (row * pixelHeight);
        for (int py2 = py; py2 < py + pixelHeight && py2 < image.height; py2++) {
          for (int px2 = px; px2 < px + pixelSize && px2 < image.width; px2++) {
            if (px2 >= 0 && py2 >= 0) {
              image.setPixel(px2, py2, color);
            }
          }
        }
      }
    }
  }
}

List<int> _getCharPattern(String char) {
  // Improved 7x9 bitmap font patterns for better readability
  // Each int represents a row, bits represent pixels (7 bits per row)
  switch (char.toUpperCase()) {
    case 'M':
      return [0x41, 0x63, 0x55, 0x49, 0x41, 0x41, 0x41, 0x41, 0x41];
    case 'Y':
      return [0x41, 0x41, 0x22, 0x14, 0x08, 0x08, 0x08, 0x08, 0x08];
    case 'F':
      return [0x7F, 0x40, 0x40, 0x7C, 0x40, 0x40, 0x40, 0x40, 0x40];
    case 'A':
      return [0x1C, 0x22, 0x41, 0x41, 0x7F, 0x41, 0x41, 0x41, 0x41];
    case 'I':
      return [0x7F, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x7F];
    case 'L':
      return [0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x7F];
    default:
      return [];
  }
}

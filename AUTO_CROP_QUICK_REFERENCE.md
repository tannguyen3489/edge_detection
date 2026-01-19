# Auto-Crop Quick Reference

## Files Created/Modified

### Created Files:
1. **`android/src/main/kotlin/com/sample/edgedetection/processor/AutoCropProcessor.kt`**
   - Auto-crop processing function for Android
   - Uses OpenCV for edge detection and cropping

2. **`ios/Classes/AutoCropProcessor.swift`**
   - Auto-crop processing class for iOS
   - Uses Core Image framework for rectangle detection

3. **`AUTO_CROP_IMPLEMENTATION.md`**
   - Detailed implementation documentation

### Modified Files:
1. **`lib/edge_detection.dart`**
   - Added `autoCrop(Uint8List imageBytes)` method
   - Added `import 'dart:typed_data';`

2. **`android/src/main/kotlin/com/sample/edgedetection/EdgeDetectionPlugin.kt`**
   - Added import for `autoCropImageBytes`
   - Added `auto_crop` case in `onMethodCall()`
   - Added `handleAutoCrop()` method

3. **`ios/Classes/SwiftEdgeDetectionPlugin.swift`**
   - Added `auto_crop` case in `handle()`
   - Added `handleAutoCrop()` method

---

## Method Signature

```dart
static Future<Uint8List> autoCrop(Uint8List imageBytes)
```

**Parameters:**
- `imageBytes` (Uint8List) - Raw image bytes (JPEG or PNG)

**Returns:**
- `Future<Uint8List>` - Auto-cropped image bytes (JPEG format)

**Throws:**
- `PlatformException` with code `'invalid_argument'` if bytes are invalid
- `PlatformException` with code `'crop_failed'` if edge detection fails

**Important (Android Only):**
- ⚠️ OpenCV native library is automatically loaded before processing
- If OpenCV loading fails, error code `'crop_failed'` will be returned
- See `BUG_FIX_OPENCV_LOADING.md` for details

---

## Usage Example

```dart
import 'package:edge_detection/edge_detection.dart';
import 'dart:io';

// Simple example
void cropImage() async {
  try {
    // Get image bytes (from file, camera, network, etc.)
    final imageFile = File('/path/to/image.jpg');
    final imageBytes = await imageFile.readAsBytes();
    
    // Call auto-crop
    final croppedBytes = await EdgeDetection.autoCrop(imageBytes);
    
    // Use cropped bytes (save, display, upload, etc.)
    final croppedFile = File('cropped.jpg');
    await croppedFile.writeAsBytes(croppedBytes);
    
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## Implementation Flow

### Android Flow:
```
Dart autoCrop(imageBytes)
    ↓
EdgeDetectionHandler.handleAutoCrop()
    ↓
AutoCropProcessor.autoCropImageBytes()
    ├─ Decode ByteArray → Bitmap
    ├─ Convert Bitmap → Mat (OpenCV)
    ├─ processPicture() → detect corners
    ├─ cropPicture() → apply perspective transform
    ├─ Convert Mat → Bitmap
    ├─ Compress to JPEG
    └─ Return ByteArray
    ↓
Result callback (success/error)
    ↓
Dart Future resolves with Uint8List
```

### iOS Flow:
```
Dart autoCrop(imageBytes)
    ↓
SwiftEdgeDetectionPlugin.handleAutoCrop()
    ↓
DispatchQueue.global (background thread)
    ├─ AutoCropProcessor.autoCropImageBytes()
    │   ├─ Decode Data → UIImage
    │   ├─ Convert UIImage → CIImage
    │   ├─ CIDetector (rectangle detection)
    │   ├─ CIPerspectiveCorrection filter
    │   ├─ Convert CIImage → UIImage
    │   └─ Compress to JPEG
    │
    └─ DispatchQueue.main (main thread)
        ↓
        Result callback (FlutterStandardTypedData)
    ↓
Dart Future resolves with Uint8List
```

---

## Key Features

✅ **Async Processing** - Runs on background threads (no UI blocking)
✅ **Error Handling** - Consistent error codes across platforms
✅ **No File I/O** - Works entirely with bytes in memory
✅ **Efficient** - JPEG compression reduces memory usage
✅ **Reusable** - Can process images from any source
✅ **No UI Required** - Unlike other edge detection methods
✅ **Proven Algorithms** - Uses existing detection logic

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "crop_failed" error | Image has no clear document edges; ensure good lighting |
| OutOfMemory exception | Large image; consider resizing before calling |
| "invalid_argument" error | Ensure imageBytes is not null and is valid image data |
| Processing takes too long | This is normal for high-res images; runs on background thread |
| UnsatisfiedLinkError (OpenCV native library) | OpenCV library loading issue - see `BUG_FIX_OPENCV_LOADING.md` |
| Thread crash on auto_crop | OpenCV initialization is now automatic; update to latest version |

---

## Performance Tips

1. **Image Size:** Keep images under 2MB for optimal performance
2. **Lighting:** Good lighting improves edge detection
3. **Resolution:** 2-4MP images process fastest
4. **Format:** JPEG is more efficient than PNG for this use case
5. **Quality:** 95% JPEG quality balances size and quality well

---

## Testing Example with Image Picker

```dart
import 'package:image_picker/image_picker.dart';
import 'package:edge_detection/edge_detection.dart';

Future<void> testAutoCrop() async {
  final picker = ImagePicker();
  
  // Pick image
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile == null) return;
  
  try {
    // Read bytes
    final imageBytes = await File(pickedFile.path).readAsBytes();
    print('Original size: ${imageBytes.length} bytes');
    
    // Auto-crop
    final croppedBytes = await EdgeDetection.autoCrop(imageBytes);
    print('Cropped size: ${croppedBytes.length} bytes');
    
    // Show result
    showCroppedImage(croppedBytes);
    
  } on PlatformException catch (e) {
    print('Platform error: ${e.code} - ${e.message}');
  }
}
```


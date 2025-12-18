# Cookie Finder - Tools

This folder contains development and design tools for the Cookie Finder app.

## 📁 Files

### `icon_preview.dart`
A standalone Flutter tool for previewing the app icon design.

#### How to Use:
1. **Quick Preview**: Temporarily change your `main.dart` to use `IconPreviewApp`:
   ```dart
   import 'tools/icon_preview.dart';
   
   void main() {
     runApp(const IconPreviewApp());
   }
   ```

2. **Run the preview**:
   ```bash
   flutter run
   ```

3. **View different variants** and sizes of the icon design

4. **Remember to revert** your `main.dart` after previewing!

#### Features:
- Three icon design variants to choose from
- Size variation preview (36px to 192px)
- Background color tests (light/dark/colored)
- Brand color palette reference

## 🎨 Icon Design Guidelines

### Recommended Design
- **Style**: Circular with gradient background
- **Main Element**: Cookie icon or cookie shape
- **Colors**: 
  - Background gradient: `#CF5A0C` → `#DAA06D`
  - Icon: White (`#FFFFFF`)
  - Chocolate chips: `#5D4037`

### Export Sizes Needed

#### Android
| Density | Size |
|---------|------|
| mdpi | 48x48 |
| hdpi | 72x72 |
| xhdpi | 96x96 |
| xxhdpi | 144x144 |
| xxxhdpi | 192x192 |

#### iOS
| Use Case | Size |
|----------|------|
| iPhone Notification | 20x20, 40x40, 60x60 |
| iPhone Settings | 29x29, 58x58, 87x87 |
| iPhone Spotlight | 40x40, 80x80, 120x120 |
| iPhone App | 120x120, 180x180 |
| iPad App | 76x76, 152x152 |
| iPad Pro App | 167x167 |
| App Store | 1024x1024 |

## 🛠️ Quick Setup with flutter_launcher_icons

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/app_icon.png"
  adaptive_icon_background: "#CF5A0C"
  adaptive_icon_foreground: "assets/app_icon.png"
```

Then run:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## 📝 Notes

- Always test icons on real devices
- Check visibility at small sizes
- Ensure good contrast
- Test on both light and dark backgrounds



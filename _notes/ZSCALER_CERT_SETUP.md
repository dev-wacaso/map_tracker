# Zscaler Certificate Setup for Flutter

## 1. Export Zscaler Certificate (if not already done)
1. Open Chrome/Edge → Go to any HTTPS site
2. Click padlock → Connection is secure → Certificate is valid
3. Certification Path → Select root certificate → View Certificate
4. Details → Copy to File → Base-64 X.509 (.CER)
5. Save as `zscaler.cer`

## 2. Install Certificate on Android Device

### Method A: Using ADB (Recommended for Development)
```bash
# Push certificate to device
adb push zscaler.cer /sdcard/Download/

# Install as system certificate (requires root)
adb shell su -c "mv /sdcard/Download/zscaler.cer /system/etc/security/cacerts/"

# Or install as user certificate (easier, but some apps may not trust it)
adb shell "am start -a android.intent.action.VIEW -d file:///sdcard/Download/zscaler.cer -t application/x-x509-ca-cert"
```

### Method B: Manual Installation (No ADB)
1. Transfer `zscaler.cer` to device (USB, email, etc.)
2. Open Settings → Security → Encryption & credentials → Install from storage
3. Navigate to and select `zscaler.cer`
4. Name it "Zscaler Root CA" and select "VPN and apps" usage
5. Confirm installation

## 3. Alternative: Use Proxy Configuration
If certificate installation doesn't work, configure Flutter to use Zscaler proxy:

Add to your Flutter app (in main.dart or environment):
```dart
import 'dart:io';

void main() {
  // Set proxy if needed
  HttpOverrides.global = MyHttpOverrides();
  runApp(const ProviderScope(child: MapTrackerApp()));
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (url) {
        // Replace with your Zscaler proxy details
        return 'PROXY your-zscaler-proxy:port';
      }
      ..badCertificateCallback = (cert, host, port) => true;
  }
}
```

## 4. Quick Test
After certificate installation, revert the HTTP change in map_screen.dart back to HTTPS:
```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.isquibly.map_tracker',
),
```

## 5. iOS Setup (if needed)
For iOS, add the certificate to the Keychain:
1. Open `zscaler.cer` on Mac
2. Add to System keychain
3. Double-click certificate → Trust → Always Trust

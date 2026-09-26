# 👥 Team Setup Guide - After Pulling from GitHub

## 🚨 Common Issue

**Problem:** Code works on your machine but teammate gets errors after pulling from GitHub.

**Root Cause:** Missing dependencies or build artifacts not synced.

---

## ✅ Step-by-Step Setup for Teammates

### 1. Pull Latest Code
```bash
git pull origin main
```

### 2. Clean Previous Build
```bash
cd store_app
flutter clean
```

### 3. Remove Old Dependencies
```bash
# Delete these folders if they exist:
rm -rf .dart_tool/
rm -rf build/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies
```

### 4. Get All Dependencies
```bash
flutter pub get
```

### 5. Verify Flutter Setup
```bash
flutter doctor -v
```

**Expected Output:**
- ✅ Flutter SDK (3.5.0 or higher)
- ✅ Chrome (for web development)
- ✅ VS Code or Android Studio

### 6. Run the App
```bash
flutter run -d chrome
```

---

## 📦 Required Dependencies

Make sure `pubspec.yaml` has all these (should be in repo):

```yaml
dependencies:
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_messaging: ^15.1.3
  firebase_analytics: ^11.3.3

  # State Management
  provider: ^6.1.2
  riverpod: ^2.5.1
  flutter_riverpod: ^2.5.1
  rxdart: ^0.28.0  # ⚠️ IMPORTANT - Recently added

  # Navigation
  go_router: ^14.3.0

  # UI Components
  fl_chart: ^0.69.0
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0
  cached_network_image: ^3.4.1
  lottie: ^3.1.2

  # ... (rest of dependencies)
```

---

## 🔍 Specific Errors & Solutions

### Error 1: "rxdart package not found"
```bash
# Solution:
flutter pub get
flutter pub upgrade rxdart
```

### Error 2: "Cannot read properties of undefined"
```bash
# Solution:
flutter clean
flutter pub get
flutter run -d chrome --web-renderer html
```

### Error 3: "Build failed" or "Compilation error"
```bash
# Solution:
flutter clean
rm -rf build/
flutter pub get
flutter run -d chrome
```

### Error 4: "Firebase not initialized"
```bash
# Make sure firebase_options.dart exists
# If missing, regenerate:
flutterfire configure
```

### Error 5: "Bad state: Not connected to an application"
```bash
# Solution: Hot restart
Press R in terminal (capital R)
# Or fully restart
```

---

## 🌐 Firebase Configuration

### Each Teammate Needs:

1. **Firebase Project Access**
   - Ask admin to add their Google account
   - Go to: https://console.firebase.google.com
   - Select: store-inventory-sale-manage

2. **Firebase CLI** (if not installed)
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

3. **FlutterFire CLI** (if not installed)
   ```bash
   dart pub global activate flutterfire_cli
   ```

4. **Configure Firebase** (if firebase_options.dart missing)
   ```bash
   cd store_app
   flutterfire configure
   ```

---

## 🧪 Verification Checklist

After setup, verify everything works:

```bash
# 1. Check Flutter version
flutter --version
# Should be: Flutter 3.5.0 or higher

# 2. Check dependencies
flutter pub get
# Should complete without errors

# 3. Check for compile errors
dart analyze
# Should show: "No issues found!" or only warnings

# 4. Run tests (optional)
flutter test
# Should pass all tests

# 5. Run app
flutter run -d chrome
# Should launch without errors
```

---

## 📋 Complete Setup Script

Create this file as `setup.sh` in the project root:

```bash
#!/bin/bash

echo "🚀 Setting up Flutter Store Inventory project..."

# Navigate to store_app
cd store_app

# Clean everything
echo "🧹 Cleaning previous builds..."
flutter clean
rm -rf .dart_tool/
rm -rf build/

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Verify setup
echo "✅ Verifying setup..."
flutter doctor -v

# Run analyze
echo "🔍 Analyzing code..."
flutter analyze

echo ""
echo "✅ Setup complete!"
echo "To run the app: cd store_app && flutter run -d chrome"
```

Make it executable:
```bash
chmod +x setup.sh
```

Then teammates can just run:
```bash
./setup.sh
```

---

## 🎯 Team Best Practices

### Before Pulling:
```bash
# Commit or stash your changes
git stash
git pull origin main
git stash pop
```

### After Pulling:
```bash
cd store_app
flutter pub get  # Always run this
flutter clean    # Run if you see weird errors
```

### Before Pushing:
```bash
# Make sure it compiles
flutter analyze
# Make sure tests pass
flutter test
# Then push
git push origin your-branch
```

---

## 🔧 Environment Setup Differences

### Your Machine (Working):
- ✅ All dependencies cached
- ✅ Build artifacts present
- ✅ Flutter SDK configured
- ✅ Firebase configured

### Teammate's Machine (After Pull):
- ❌ No dependencies cached
- ❌ No build artifacts
- ❌ Might need Flutter SDK update
- ❌ Might need Firebase reconfiguration

**Solution:** Run the setup steps above!

---

## 📱 Platform-Specific Notes

### macOS:
```bash
# If Cocoapods issues:
cd ios
pod install --repo-update
cd ..
```

### Windows:
```bash
# Use PowerShell or Git Bash
# Make sure Flutter is in PATH
```

### Linux:
```bash
# Install Chrome:
sudo apt-get install google-chrome-stable
```

---

## 🆘 Emergency Troubleshooting

### Nuclear Option (If nothing works):
```bash
# 1. Delete everything Flutter-related
cd store_app
rm -rf .dart_tool build .flutter-plugins .flutter-plugins-dependencies

# 2. Delete Flutter cache
flutter pub cache repair

# 3. Reinstall dependencies
flutter pub get

# 4. Rebuild
flutter run -d chrome
```

---

## 📞 Support Checklist

If teammate still has issues, ask them to provide:

```bash
# 1. Flutter version
flutter --version

# 2. Flutter doctor output
flutter doctor -v

# 3. Dependencies status
cd store_app
flutter pub get

# 4. Error message (full output)
flutter run -d chrome 2>&1 | tee error.log

# 5. Git status
git status
git log --oneline -5
```

---

## ✅ Success Indicators

After setup, teammate should see:

1. ✅ `flutter pub get` completes successfully
2. ✅ `flutter analyze` shows no errors (warnings OK)
3. ✅ `flutter run -d chrome` launches app
4. ✅ Login screen appears
5. ✅ Can login and navigate
6. ✅ No console errors (except debug messages)

---

## 📚 Additional Resources

- **Flutter Docs:** https://docs.flutter.dev/get-started/install
- **Firebase Setup:** https://firebase.google.com/docs/flutter/setup
- **Troubleshooting:** https://docs.flutter.dev/testing/common-errors
- **Project Wiki:** [Link to your project wiki if you have one]

---

## 🎓 For New Team Members

### Day 1 Checklist:
- [ ] Install Flutter SDK (3.5.0+)
- [ ] Install VS Code or Android Studio
- [ ] Install Chrome (for web development)
- [ ] Clone repository
- [ ] Run setup script
- [ ] Access Firebase Console
- [ ] Run app successfully
- [ ] Join team communication channel

### Access Needed:
- [ ] GitHub repository access
- [ ] Firebase project access
- [ ] GCP project access (if needed)
- [ ] Team documentation access

---

**Last Updated:** September 25, 2026  
**Maintainer:** Development Team  
**Support:** [Your contact info]

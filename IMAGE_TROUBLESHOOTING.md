# 🔧 Image Loading Troubleshooting Guide

## Problem: Images Not Loading in POS Screen

Let's debug this step by step.

---

## Step 1: Check if Products Exist

Run this command to see your products:

```bash
cd seed
node check_products.js
```

**Expected Output:**
```
📦 Checking products in Firestore...

✅ Found 10 products:

1. Tata Salt
   Category: Groceries
   Price: ₹20
   Image: ❌ No image
─────────────────────────────────
```

**If you see "No products found":**
- You need to create products first using the app
- Or create them via Firebase Console

---

## Step 2: Test Single Image

Add a test image to one product:

```bash
cd seed
node test_single_image.js
```

**This will:**
1. Pick the first product
2. Add a test image URL
3. Tell you what to look for

**Then:**
1. Hot restart your Flutter app (press `r` or `R` in terminal)
2. Go to POS screen
3. Look for that product - should have an image now

**If image shows: ✅ Your setup works!**  
**If not: Continue to Step 3**

---

## Step 3: Check Flutter Console

While running your Flutter app, look for errors in the terminal.

### Common Error Messages:

#### **Error: "No matching host overrides"**
```dart
SocketException: OS Error: No route to host
```

**Fix:** Internet connection issue
```bash
# Check internet
ping google.com

# Try running app again
flutter run
```

#### **Error: "Certificate verify failed"**
```
HandshakeException: Certificate verify failed
```

**Fix:** SSL certificate issue
```dart
// This is usually a simulator/emulator issue
// Try on real device
```

#### **Error: "Failed host lookup"**
```
SocketException: Failed host lookup: 'images.unsplash.com'
```

**Fix:** DNS issue
```bash
# Flush DNS cache (macOS)
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

---

## Step 4: Check Image URLs in Firestore

1. Open **Firebase Console** in browser
2. Go to **Firestore Database**
3. Open **products** collection
4. Click on any product document
5. Check if `imageUrl` field exists

**Should look like:**
```
imageUrl: "https://images.unsplash.com/photo-xxx?w=400"
```

**If empty or missing:**
```bash
# Add images
cd seed
node add_product_images.js
```

---

## Step 5: Test Image URL Directly

Copy an `imageUrl` from Firestore and paste it in your browser.

**Should:**
- ✅ Load an image immediately
- ❌ If 404 error: URL is broken
- ❌ If timeout: Network issue

---

## Step 6: Check Flutter Network Permissions

### **iOS (macOS/iPhone):**

Check `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**If missing, add it:**

```bash
# Open Info.plist
open ios/Runner/Info.plist

# Add the NSAppTransportSecurity section
# Save and rebuild
flutter clean
flutter pub get
flutter run
```

### **Android:**

Check `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Should be there already, but verify.

---

## Step 7: Try Simple Local Test

Let's test with a guaranteed working image:

**Update one product manually:**

1. Firebase Console → Firestore → products → pick one
2. Add/Edit `imageUrl` field:
   ```
   https://via.placeholder.com/400
   ```
3. Save
4. Restart Flutter app
5. Check POS screen

**This URL is super simple and always works.**

**If this works but Unsplash doesn't:**
- Issue is with Unsplash URLs
- Switch to different image source

---

## Step 8: Check Flutter Cache

Sometimes Flutter caches old code:

```bash
# Clean everything
flutter clean

# Get packages again
flutter pub get

# Run app
flutter run
```

---

## Step 9: Check CachedNetworkImage Package

Verify the package is installed:

```bash
cd store_app
flutter pub get
```

Check `pubspec.yaml` has:
```yaml
cached_network_image: ^3.4.1
```

---

## Step 10: Enable Verbose Logging

Add this to see what's happening:

```dart
// In pos_screen.dart, add debug prints

CachedNetworkImage(
  imageUrl: product.imageUrl!,
  fit: BoxFit.cover,
  placeholder: (context, url) {
    print('🔄 Loading image: $url');  // ← Add this
    return Center(child: CircularProgressIndicator());
  },
  errorWidget: (context, url, error) {
    print('❌ Image error: $error');  // ← Add this
    print('   URL was: $url');
    return Center(child: Icon(Icons.inventory_2_rounded));
  },
)
```

Check the Flutter console for these logs.

---

## Quick Fix Checklist

Run these in order:

```bash
# 1. Check products exist
cd seed
node check_products.js

# 2. Add images if needed
node add_product_images.js

# 3. Test single product
node test_single_image.js

# 4. Clean Flutter
cd ../store_app
flutter clean
flutter pub get

# 5. Run app
flutter run

# 6. Hot restart (in Flutter console)
Press 'R'
```

---

## Common Issues & Solutions

### Issue 1: "Only seeing icons, no images"

**Cause:** imageUrl field is empty or null

**Fix:**
```bash
cd seed
node add_product_images.js
```

### Issue 2: "Loading spinner forever"

**Cause:** Network timeout or wrong URL

**Fix:**
```bash
# Test URLs in browser first
# If they work in browser but not app, check:

# iOS
open ios/Runner/Info.plist
# Add NSAppTransportSecurity

# Then
flutter clean && flutter run
```

### Issue 3: "Images show in iOS but not Android"

**Cause:** Android network permissions

**Fix:**
```xml
<!-- In android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
```

### Issue 4: "Error: HandshakeException"

**Cause:** SSL certificate issue (simulator)

**Fix:**
- Use real device instead of simulator
- Or use http:// images (not recommended for production)

### Issue 5: "Images work on some products, not others"

**Cause:** Some URLs are broken

**Fix:**
```bash
# Check which products have issues
node check_products.js

# Fix individual products in Firebase Console
# Or re-run seed script
node add_product_images.js
```

---

## Alternative: Use Placeholder Images

If you want to test quickly with different image sources:

```bash
# Edit seed/add_product_images.js
# Change image URLs to:

const productImages = {
  'Tata Salt': 'https://via.placeholder.com/400/FFB6C1/000000?text=Tata+Salt',
  'Coca Cola': 'https://via.placeholder.com/400/FF0000/FFFFFF?text=Coca+Cola',
  // etc...
};

# Then run
node add_product_images.js
```

These placeholder URLs ALWAYS work.

---

## Still Not Working?

### Last Resort Debug:

1. **Screenshot your POS screen** - Are you seeing:
   - Icons only?
   - Loading spinners?
   - Blank squares?
   - Error messages?

2. **Check Flutter console output** - Any red errors?

3. **Check Firestore** - Do products have `imageUrl` field?

4. **Test in browser** - Copy an imageUrl, paste in browser. Does it load?

5. **Try placeholder.com** - Change ONE product's imageUrl to:
   ```
   https://via.placeholder.com/400
   ```
   Does THIS one work?

---

## Need Help?

Provide these details:

1. Output of `node check_products.js`
2. Flutter console errors (if any)
3. What you see in POS (icons? spinners? blank?)
4. Device type (iOS/Android/Web)
5. Does browser show the image URLs?

---

## Success Indicators

✅ Images should:
- Load within 2-3 seconds first time
- Show loading spinner while downloading
- Display the image after loading
- Cache for instant display next time
- Fall back to icon if URL broken

❌ Red flags:
- Infinite loading spinners
- Only icons, never images
- Blank white squares
- Console errors about network

---

**Most Common Fix:**

```bash
# 90% of the time, this fixes it:

cd seed
node add_product_images.js

cd ../store_app
flutter clean
flutter pub get
flutter run

# Then press 'R' to hot restart
```

Good luck! 🍀

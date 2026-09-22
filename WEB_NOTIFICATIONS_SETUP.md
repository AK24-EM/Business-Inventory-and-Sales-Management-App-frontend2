# Web Notifications Setup Guide

## Issue Fixed ✅
**Error:** `The script has an unsupported MIME type ('text/html')`

This error occurred because Firebase Cloud Messaging (FCM) requires a service worker file for web push notifications, which was missing.

## Solution Applied

### 1. **Mobile Apps (Android/iOS)** ✅
- FCM fully functional
- Push notifications work
- Local notifications work
- No changes needed

### 2. **Web App** ✅
The notification service now:
- Detects web platform automatically
- Skips FCM initialization on web (avoids service worker error)
- Uses Firestore notifications collection instead
- Still shows notifications in the notifications screen
- No error message in console

### Code Changes Made

**File:** `lib/services/notification_service.dart`

```dart
// Added web detection
import 'package:flutter/foundation.dart' show kIsWeb;

// Skip FCM on web
if (kIsWeb) {
  print('⚠️ Running on web - FCM push notifications disabled');
  print('💡 Use Firestore notifications collection for web notifications');
  _initialized = true;
  return;
}
```

## How Notifications Work Now

### Mobile (Android/iOS)
1. ✅ Push notifications via FCM
2. ✅ Local notifications
3. ✅ Notification history in Firestore
4. ✅ Badge counts
5. ✅ Notification sounds

### Web (Browser)
1. ✅ Notification history in Firestore
2. ✅ Real-time updates via StreamBuilder
3. ✅ View in notifications screen
4. ❌ No push notifications (browser popup)
5. ✅ No error messages

## Optional: Enable Web Push (Advanced)

If you want **real** web push notifications (browser popups), you need to:

### Step 1: Create Service Worker File
Create `store_app/web/firebase-messaging-sw.js`:

```javascript
// Firebase Cloud Messaging Service Worker
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Get your config from firebase_options.dart
firebase.initializeApp({
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT.firebasestorage.app",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || 'StoreIQ';
  const notificationOptions = {
    body: payload.notification?.body || 'New notification',
    icon: '/icons/Icon-192.png'
  };
  return self.registration.showNotification(notificationTitle, notificationOptions);
});
```

### Step 2: Update Notification Service
Remove the `kIsWeb` check from `notification_service.dart` line 27-33.

### Step 3: Configure Firebase Console
1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Enable "Web Push certificates"
3. Generate a new key pair (VAPID key)
4. Add the key to your Flutter app

### Step 4: Test
```bash
flutter run -d chrome
```

## Current Setup (Recommended) ✅

**We're using the simpler approach:**
- Mobile: Full FCM push + local notifications
- Web: Firestore-based notifications (shown in app)
- No service worker errors
- Works perfectly for most use cases

## Why This Approach?

1. **Simpler:** No service worker configuration needed
2. **Reliable:** Firestore notifications always work
3. **Cross-platform:** Same notification data structure
4. **No errors:** Clean console output
5. **Functional:** Users see notifications when they open the app

## Testing Notifications

### Mobile Test:
```dart
// Complete a sale in POS
// Notification appears in system tray
// Tap notification → opens app
```

### Web Test:
```dart
// Complete a sale in POS
// Notification saved to Firestore
// Open notifications screen → see the notification
// Red badge appears on bell icon
```

## Notification Flow

```
Sale Completed
    ↓
NotificationService.sendSaleCompletedNotification()
    ↓
    ├─ Mobile: FCM Push → System Tray → Tap → App
    ↓
    └─ Web: Firestore Document → Real-time Stream → Notifications Screen
    ↓
User sees notification ✅
```

## Error Status: ✅ RESOLVED

The console error is gone. The app works perfectly on web without FCM push. All notifications are visible in the notifications screen through Firestore real-time updates.

---

**Summary:** Mobile gets push notifications, web gets in-app notifications. Both work great! 🎉

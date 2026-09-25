# 🔐 GCP/Firebase Team Access Guide

## How to Share Your Firebase Project with Teammates

---

## 📋 Table of Contents
1. [Quick Access via Firebase Console](#quick-access-via-firebase-console)
2. [GCP IAM Access (Full Control)](#gcp-iam-access-full-control)
3. [Recommended Role Assignments](#recommended-role-assignments)
4. [Step-by-Step Instructions](#step-by-step-instructions)
5. [What Each Teammate Needs](#what-each-teammate-needs)
6. [Security Best Practices](#security-best-practices)

---

## 🚀 Quick Access via Firebase Console

### Option 1: Add Users to Firebase Project (Recommended for Most Cases)

**Best For:** Developers, QA, Product Managers

**Steps:**

1. **Go to Firebase Console**
   ```
   https://console.firebase.google.com/project/store-inventory-sale-manage/settings/iam
   ```

2. **Click "Add Member"** (top right)

3. **Enter Teammate's Email**
   - Use their Google account email (Gmail or Google Workspace)
   - Example: `teammate@gmail.com`

4. **Assign Role** (Select one):
   - **Owner** - Full access (add/remove members, billing)
   - **Editor** - Can modify project (recommended for developers)
   - **Viewer** - Read-only access (good for stakeholders)

5. **Click "Add"**

6. **They'll receive an email invitation**
   - They click the link
   - Accept invitation
   - Can now access the project!

---

## 🛡️ GCP IAM Access (Full Control)

### Option 2: Add via Google Cloud Console (More Control)

**Best For:** DevOps, Backend Engineers, System Admins

**Steps:**

1. **Go to GCP Console**
   ```
   https://console.cloud.google.com/iam-admin/iam?project=store-inventory-sale-manage
   ```

2. **Click "GRANT ACCESS"** (top of page)

3. **Enter Details:**
   - **New principals:** teammate@gmail.com
   - **Select a role:** (See recommended roles below)

4. **Click "SAVE"**

---

## 👥 Recommended Role Assignments

### For Different Team Members:

#### **Frontend Developer (Flutter/Mobile)**
**Firebase Console:**
- ✅ Role: **Editor**

**Access to:**
- ✅ Firestore Database (read/write rules)
- ✅ Authentication settings
- ✅ Cloud Storage
- ✅ Hosting
- ✅ Analytics
- ❌ Billing (optional)

**GCP Roles (Alternative):**
```
- Firebase Admin
- Cloud Datastore User
- Storage Object Admin
```

---

#### **Backend Developer**
**Firebase Console:**
- ✅ Role: **Editor** or **Owner**

**GCP Roles:**
```
- Firebase Admin
- Cloud Datastore Owner
- Cloud Functions Developer
- Service Account User
```

---

#### **DevOps Engineer**
**Firebase Console:**
- ✅ Role: **Owner**

**GCP Roles:**
```
- Project Editor (full access)
- Service Account Admin
- Cloud Functions Admin
- Deployment Manager Editor
```

---

#### **QA/Tester**
**Firebase Console:**
- ✅ Role: **Viewer** or **Editor** (if they need to add test data)

**Access to:**
- ✅ View Firestore data
- ✅ View Authentication users
- ✅ View logs
- ❌ Modify production settings

---

#### **Project Manager/Stakeholder**
**Firebase Console:**
- ✅ Role: **Viewer**

**Access to:**
- ✅ View analytics
- ✅ View usage statistics
- ✅ View Firestore data (read-only)
- ❌ Modify anything

---

## 📖 Step-by-Step Instructions for Teammates

### What Your Teammates Need to Do:

1. **Check Email**
   - Look for invitation from "Firebase" or "Google Cloud"
   - Subject: "You've been invited to store-inventory-sale-manage"

2. **Click "Accept Invitation"**

3. **Login with Google Account**
   - If they don't have one, create at: https://accounts.google.com

4. **Access the Project:**

   **Firebase Console:**
   ```
   https://console.firebase.google.com/
   → Select "store-inventory-sale-manage"
   ```

   **GCP Console:**
   ```
   https://console.cloud.google.com/
   → Select "store-inventory-sale-manage" from project dropdown
   ```

---

## 🔧 What Each Developer Needs Access To

### Firebase Services:

✅ **Authentication**
- View/manage users
- Configure sign-in methods
- Set up email templates

✅ **Firestore Database**
- View/edit data
- Modify security rules
- Create/delete collections

✅ **Cloud Storage**
- Upload/download files (images, documents)
- Manage storage rules

✅ **Hosting** (if using Firebase Hosting)
- Deploy web app
- View domains

✅ **Cloud Functions** (if using)
- Deploy functions
- View logs

---

## 🔑 Sharing Service Account Key (For CI/CD)

### For Automated Deployments:

**⚠️ IMPORTANT: Never share service account keys via email or Slack!**

**Secure Methods:**

#### Option 1: Generate Individual Keys
1. Go to: [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts?project=store-inventory-sale-manage)
2. Click on service account
3. Go to "Keys" tab
4. Click "Add Key" → "Create new key"
5. Choose JSON
6. **Share securely:**
   - 1Password / LastPass (shared vault)
   - Encrypted file with password separately
   - Vault systems (HashiCorp Vault)

#### Option 2: Use Environment Variables (Recommended for CI/CD)
```bash
# GitHub Actions Secrets
# GitLab CI/CD Variables
# CircleCI Environment Variables

FIREBASE_SERVICE_ACCOUNT_KEY=<base64-encoded-json>
```

---

## 👨‍💻 Quick Commands for Teammates

### After Getting Access:

#### 1. **Install Firebase CLI**
```bash
npm install -g firebase-tools
```

#### 2. **Login**
```bash
firebase login
```

#### 3. **Select Project**
```bash
firebase use store-inventory-sale-manage
```

#### 4. **Deploy (if needed)**
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Cloud Functions
firebase deploy --only functions

# Deploy Hosting
firebase deploy --only hosting
```

---

## 🎯 Specific Access Scenarios

### Scenario 1: Teammate Needs to Add Test Data

**Give them:**
- Firebase Console **Editor** access
- Share Firestore collection structure
- Share test data script: `seed/seed_inventory.js`

**They can run:**
```bash
cd seed
node seed_inventory.js
```

---

### Scenario 2: Teammate Needs to Debug Production Issues

**Give them:**
- Firebase Console **Viewer** access
- GCP Logging **Logs Viewer** role

**They can:**
- View Firestore data
- Check authentication logs
- View error logs in Cloud Logging

---

### Scenario 3: Teammate Needs to Deploy

**Give them:**
- Firebase Console **Editor** access
- GCP roles:
  - `Cloud Functions Developer`
  - `Firebase Hosting Admin`

**They can:**
```bash
firebase deploy
```

---

## 🔒 Security Best Practices

### ✅ DO:

1. **Use Individual Accounts**
   - Each teammate uses their own Google account
   - Never share personal credentials

2. **Principle of Least Privilege**
   - Give minimum access needed
   - Start with Viewer, upgrade if needed

3. **Use Service Accounts for CI/CD**
   - Not personal accounts
   - Rotate keys regularly

4. **Enable 2FA**
   - Require 2-factor authentication for all members
   - Set at organization level if using Google Workspace

5. **Review Access Regularly**
   - Quarterly audit of who has access
   - Remove ex-teammates immediately

6. **Use Environment-Specific Projects**
   ```
   store-inventory-dev     (for development)
   store-inventory-staging (for testing)
   store-inventory-prod    (for production)
   ```

### ❌ DON'T:

1. ❌ Share service account JSON files via email
2. ❌ Commit service account keys to Git
3. ❌ Give everyone Owner access
4. ❌ Use the same Firebase project for dev and production
5. ❌ Share personal Firebase login credentials

---

## 📧 Email Template to Send Teammates

```
Subject: Access to Store Inventory Firebase Project

Hi [Name],

I've added you to our Firebase project! Here's what you need to know:

Project Name: store-inventory-sale-manage
Your Role: [Editor/Viewer/Owner]

Getting Started:
1. Check your email for an invitation from Firebase
2. Click "Accept Invitation"
3. Go to: https://console.firebase.google.com/
4. Select "store-inventory-sale-manage"

Useful Links:
- Firebase Console: https://console.firebase.google.com/project/store-inventory-sale-manage
- Firestore Database: https://console.firebase.google.com/project/store-inventory-sale-manage/firestore
- Authentication: https://console.firebase.google.com/project/store-inventory-sale-manage/authentication

Documentation:
- Project docs: [Link to your docs]
- Setup guide: GCP_TEAM_ACCESS_GUIDE.md

If you need different access levels, let me know!

Questions? Slack me or check the guide above.

Thanks,
[Your Name]
```

---

## 🛠️ Troubleshooting

### "I don't see the project"
**Solution:**
- Check if invitation was accepted
- Try logging out and back in
- Verify correct Google account
- Check spam folder for invitation email

### "I can't access Firestore"
**Solution:**
- Verify they have Editor or Viewer role
- Check Firestore security rules
- Ensure they selected correct project

### "Deployment fails with permission error"
**Solution:**
- Verify they have Editor role
- Check if Firebase CLI is logged in: `firebase login`
- Verify project selected: `firebase use store-inventory-sale-manage`

---

## 📊 Access Level Comparison

| Feature | Viewer | Editor | Owner |
|---------|--------|--------|-------|
| View Firestore data | ✅ | ✅ | ✅ |
| Modify Firestore data | ❌ | ✅ | ✅ |
| View Analytics | ✅ | ✅ | ✅ |
| Deploy code | ❌ | ✅ | ✅ |
| Modify security rules | ❌ | ✅ | ✅ |
| Add/remove users | ❌ | ❌ | ✅ |
| Manage billing | ❌ | ❌ | ✅ |
| Delete project | ❌ | ❌ | ✅ |

---

## 🚀 Quick Reference Commands

```bash
# Check current project
firebase projects:list

# Switch project
firebase use store-inventory-sale-manage

# Check your access level
firebase auth:export test.json
# (Will fail if you don't have sufficient access)

# View project info
gcloud config get-value project
gcloud projects describe store-inventory-sale-manage
```

---

## 📱 Mobile App Testing

### For teammates to test the mobile app:

**They need:**
1. ✅ Access to Firebase project (Viewer minimum)
2. ✅ Flutter SDK installed
3. ✅ Project codebase (from Git)
4. ✅ Firebase configuration files:
   - `google-services.json` (Android)
   - `GoogleService-Info.plist` (iOS)

**Steps:**
```bash
# Clone repo
git clone [your-repo-url]

# Get dependencies
cd store_app
flutter pub get

# Run app
flutter run
```

---

## 🎓 Training Checklist

**Send this to new teammates:**

- [ ] Accepted Firebase invitation
- [ ] Can access Firebase Console
- [ ] Can view Firestore data
- [ ] Installed Firebase CLI
- [ ] Logged in with `firebase login`
- [ ] Selected project with `firebase use`
- [ ] Cloned code repository
- [ ] Can run app locally
- [ ] Understands project structure
- [ ] Read project documentation

---

## 🔗 Important Links

### Your Project:
- Firebase Console: https://console.firebase.google.com/project/store-inventory-sale-manage
- GCP Console: https://console.cloud.google.com/home/dashboard?project=store-inventory-sale-manage
- IAM Settings: https://console.firebase.google.com/project/store-inventory-sale-manage/settings/iam

### Firebase Documentation:
- Adding Team Members: https://firebase.google.com/docs/projects/iam/overview
- Roles & Permissions: https://firebase.google.com/docs/projects/iam/roles-predefined-product

---

## ✅ Checklist: Adding a New Teammate

- [ ] Get their Google account email
- [ ] Decide appropriate role (Viewer/Editor/Owner)
- [ ] Add via Firebase Console or GCP IAM
- [ ] Send welcome email with instructions
- [ ] Verify they received invitation
- [ ] Confirm they can access project
- [ ] Share relevant documentation
- [ ] Add to team communication channels
- [ ] Add to project management tools

---

**Last Updated:** September 24, 2026  
**Project:** store-inventory-sale-manage  
**Owner:** [Your Name]

---

## 💡 Quick Summary

**To add a teammate RIGHT NOW:**

1. Go to: https://console.firebase.google.com/project/store-inventory-sale-manage/settings/iam
2. Click **"Add Member"**
3. Enter their email: `teammate@gmail.com`
4. Select role: **Editor** (for developers)
5. Click **"Add"**
6. Done! They'll get an email. ✅

That's it! They can now access your Firebase project! 🎉

# 🔥 Firebase Setup Guide - MODI License System

## Step 1: Firebase Project Banao

1. **Browser mein jao:** https://console.firebase.google.com/
2. **"Create a project"** click karo
3. **Project name:** `modi-licenses` (ya jo bhi naam)
4. **Google Analytics:** ❌ Disable kar do (zaruri nahi)
5. **"Create Project"** → Wait 30 seconds

---

## Step 2: Firestore Database Enable Karo

1. **Left menu** mein → **"Build"** → **"Firestore Database"**
2. **"Create database"** button click karo
3. **"Start in test mode"** ✅ select karo
4. **Location:** `asia-south1` (Mumbai/India)
5. **"Enable"** click karo → Wait 1 minute

---

## Step 3: Web App Add Karo

1. **Project Overview** (home icon) pe jao
2. **"</>"** (Web) icon click karo (center mein hoga)
3. **App nickname:** `modi-admin`
4. ❌ Firebase Hosting mat enable karo
5. **"Register app"** click karo

---

## Step 4: Configuration Copy Karo

Firebase SDK code dikhega, usme se ye values copy karo:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXX",      ← Ye copy karo
  authDomain: "modi-licenses.firebaseapp.com",
  projectId: "modi-licenses",                 ← Ye copy karo
  storageBucket: "modi-licenses.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456"       ← Ye copy karo
};
```

---

## Step 5: Admin Panel Use Karo

1. **`LICENSE_ADMIN_PANEL.html`** file browser mein open karo
2. Firebase config values paste karo:
   - API Key
   - Project ID
   - App ID
3. **"Connect to Firebase"** button click karo
4. **Done! Ab keys generate kar sakte ho!** 🎉

---

## Step 6: App mein Firebase Config Add Karo

File: `lib/firebase_config.dart` open karo aur values replace karo:

```dart
static const String apiKey = 'YOUR_ACTUAL_API_KEY';
static const String projectId = 'YOUR_ACTUAL_PROJECT_ID';
static const String appId = 'YOUR_ACTUAL_APP_ID';
// ... baaki values bhi
```

---

## 🎯 Usage

### Admin Panel (Browser se):
1. `LICENSE_ADMIN_PANEL.html` open karo
2. Customer ka naam likho (optional)
3. Demo / Trial / Lifetime button click karo
4. Key copy karo → WhatsApp se customer ko bhejo

### Customer App mein:
1. Customer key enter karega
2. Firebase se verify hogi
3. Valid hai → App unlock! ✅

---

## 📊 Features

| Feature | Description |
|---------|-------------|
| **Generate Keys** | Demo (7d), Trial (30d), Lifetime |
| **View History** | Kon, kab, konsi key |
| **Copy Key** | One-click copy |
| **Revoke License** | Kisi ka license cancel karo |
| **Stats** | Total, Active, Unused count |

---

## ❓ Common Issues

### "Permission denied" error
→ Firestore rules check karo, "test mode" mein hona chahiye

### "Project not found"
→ Project ID sahi check karo

### Keys generate nahi ho rahi
→ Internet connection check karo

---

## 🔒 Security (Production ke liye)

Test mode 30 din ke baad expire hoga. Production ke liye Firestore Rules set karo:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /licenses/{key} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

---

## 💰 Cost

**Firebase Free Tier:**
- 50,000 reads/day ✅
- 20,000 writes/day ✅
- 1 GB storage ✅

**Matlab 5000+ customers FREE mein handle kar sakte ho!**

# 🗺️ Quick Google Maps API Setup

## ⚠️ The Problem
Your app shows: **"Error getting location: Failed to query location from network service"**

**Why?** The Google Maps API key is missing!

---

## 🚀 Quick Fix (5 Minutes)

### Step 1: Get Your API Key
1. **Go to:** [Google Cloud Console](https://console.cloud.google.com/)
2. **Sign in** with your Google account
3. **Create a new project** (or select existing one)
   - Click "Select a project" → "New Project"
   - Name it: "Laundry Scout" → Click "Create"

### Step 2: Enable Required APIs
1. **Search for:** "Maps SDK for Android" → Click it → Click "Enable"
2. **Search for:** "Geocoding API" → Click it → Click "Enable"
3. **Search for:** "Places API" → Click it → Click "Enable"

### Step 3: Create API Key
1. **Go to:** "Credentials" (left sidebar)
2. **Click:** "+ Create Credentials" → "API Key"
3. **Copy** the API key that appears

### Step 4: Add Key to Your App
1. **Open:** `android/app/src/main/AndroidManifest.xml`
2. **Find this line:**
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
   ```
3. **Replace** `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key

### Step 5: Test It
1. **Run:** `flutter clean && flutter pub get`
2. **Run:** `flutter run`
3. **Check:** Location screen should work now! ✅

---

## 🔒 Security (Optional but Recommended)

### Restrict Your API Key
1. **Go back to:** Google Cloud Console → Credentials
2. **Click** on your API key
3. **Under "Application restrictions":**
   - Select "Android apps"
   - Add package name: `com.example.laundry_scout`
4. **Under "API restrictions":**
   - Select "Restrict key"
   - Choose: Maps SDK for Android, Geocoding API, Places API
5. **Click:** "Save"

---

## 💰 Billing Setup

⚠️ **Important:** Google requires a billing account, but offers $200 free credits monthly.

1. **Go to:** "Billing" in Google Cloud Console
2. **Add** a payment method
3. **Don't worry:** You likely won't be charged with normal app usage

---

## 🆘 Troubleshooting

**Still getting errors?**

✅ **Check:** Billing is enabled  
✅ **Check:** All 3 APIs are enabled  
✅ **Check:** API key is correctly pasted (no extra spaces)  
✅ **Check:** You ran `flutter clean && flutter pub get`  

**Need help?** The error should disappear once the API key is properly configured!

---

## 📱 What This Fixes

- ✅ Location screen will load properly
- ✅ Map will display correctly
- ✅ Nearby laundry services will show
- ✅ Address lookup will work
- ✅ No more "network service" errors

**That's it!** Your Laundry Scout app should now work perfectly! 🎉
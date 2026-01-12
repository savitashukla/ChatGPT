# 🚨 QUICK FIX - App Running in Offline Mode

## Problem
Your Gemini API key has been **LEAKED** and **DISABLED** by Google.

## Solution (5 minutes)

### 1️⃣ Get New API Key
Go to: **https://aistudio.google.com/app/apikey**
- Click "Create API Key"
- Copy the new key

### 2️⃣ Update .env.local
Open: `.env.local` file in your project root
Replace:
```bash
GEMINI_API_KEY=YOUR_NEW_GEMINI_API_KEY_HERE
```
With your actual new key

### 3️⃣ Restart App
**MUST USE THE SCRIPT:**
```bash
./run_web.sh
```
(Don't run from IDE - it won't load the API key!)

### 4️⃣ Test
```bash
./test_gemini_key.sh
```
Should show: `✅ SUCCESS!`

---

## Why This Happened
Your API key `AIzaSyAjpojPBLDGvIbONJ1yjJFckSMwmZUZl6U` was exposed publicly (possibly committed to GitHub or shared in a screenshot).

## Prevent This
- ✅ `.env.local` is already in `.gitignore` 
- ❌ Never commit API keys
- ❌ Never share API keys in screenshots
- ✅ Add API restrictions in Google Cloud Console

---

**Full details:** See `FIX_OFFLINE_MODE_ISSUE.md`


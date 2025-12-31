# 🔐 Secure API Key Configuration Guide

This guide shows how to securely manage your OpenAI and Gemini API keys without hardcoding them in your Flutter app.

## 🚨 Security Overview

**BEFORE**: API keys were hardcoded in source code (❌ INSECURE)
```dart
// DON'T DO THIS - Keys exposed in source code!
static String apiKey = "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";
```

**AFTER**: API keys are loaded from environment variables (✅ SECURE)
```dart
// SECURE - Keys loaded at runtime from environment
static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
```

## 📋 Quick Setup

### 1. Get Your API Keys

**Gemini API Key:**
- Visit: https://aistudio.google.com/app/apikey
- Create a new API key
- Copy the key (starts with `AIza...`)

**OpenAI API Key (optional):**
- Visit: https://beta.openai.com/account/api-keys
- Create a new API key
- Copy the key (starts with `sk-...`)

### 2. Create Environment File

```bash
# Copy the example file
cp .env.example .env.local

# Edit with your actual keys
nano .env.local
```

Update `.env.local` with your actual API keys:
```bash
# Replace with your actual keys
OPENAI_API_KEY=sk-your-actual-openai-key-here
GEMINI_API_KEY=AIza-your-actual-gemini-key-here
```

### 3. Run Your App Securely

```bash
# Use the secure runner script
./run_dev.sh

# Or run manually
flutter run \
  --dart-define=OPENAI_API_KEY=your_key \
  --dart-define=GEMINI_API_KEY=your_key
```

## 🛠️ Development Workflow

### Daily Development
```bash
# Just run this command - it handles everything securely
./run_dev.sh
```

### Building for Release
```bash
# Android APK
./build_release.sh apk

# Android App Bundle
./build_release.sh appbundle

# iOS
./build_release.sh ios

# Web
./build_release.sh web
```

## 🔧 Advanced Configuration

### Multiple Environments

Create different environment files for different stages:

**Development**: `.env.local`
```bash
OPENAI_API_KEY=sk-dev-key-here
GEMINI_API_KEY=AIza-dev-key-here
```

**Production**: `.env.production`
```bash
OPENAI_API_KEY=sk-prod-key-here
GEMINI_API_KEY=AIza-prod-key-here
```

### CI/CD Integration

For GitHub Actions, Bitrise, Codemagic, etc.:

1. Add secrets to your CI/CD platform:
   - `OPENAI_API_KEY`
   - `GEMINI_API_KEY`

2. Use in your build pipeline:
```yaml
# GitHub Actions example
- name: Build Release APK
  run: flutter build apk --release --dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}
```

## ⚡ Error Resolution

### 403 Forbidden Error Fix

The 403 error you were experiencing is now handled with better error messages:

```dart
// New error handling shows specific causes:
if (response.statusCode == 403) {
  throw Exception(
    '403 PERMISSION_DENIED: Check API key validity, billing, API enablement, key restrictions, and model access.'
  );
}
```

**Common 403 causes and fixes:**
- ❌ Invalid API key → Generate a new one
- ❌ Billing disabled → Enable billing in Google Cloud Console
- ❌ API not enabled → Enable "Generative Language API"
- ❌ Key restrictions → Remove app restrictions temporarily
- ❌ Wrong model → Use `gemini-1.5-flash-latest`

### Troubleshooting Commands

```bash
# Check if keys are loaded correctly
echo $GEMINI_API_KEY

# Test API access
curl -H "Content-Type: application/json" \
     -d '{"contents":[{"parts":[{"text":"Hello"}]}]}' \
     "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=YOUR_KEY"

# Run with verbose logging
./run_dev.sh --verbose
```

## 🛡️ Security Best Practices

### ✅ DO:
- ✅ Use environment variables for API keys
- ✅ Add `.env.local` to `.gitignore`
- ✅ Use different keys for development vs production
- ✅ Rotate API keys regularly
- ✅ Restrict API keys to specific APIs only
- ✅ Monitor API usage in Google Cloud Console

### ❌ DON'T:
- ❌ Hardcode API keys in source code
- ❌ Commit `.env.local` to version control
- ❌ Share API keys in chat/email
- ❌ Use production keys for development
- ❌ Leave unrestricted API keys

## 📁 File Structure

```
HelpAI/
├── .env.example          # Template for environment variables
├── .env.local           # Your actual keys (git-ignored)
├── .env.production      # Production keys (git-ignored)
├── .gitignore           # Protects sensitive files
├── run_dev.sh           # Secure development runner
├── build_release.sh     # Secure release builder
└── lib/
    └── app/
        └── data/
            └── app_constants.dart  # Secure key loading
```

## 🚀 What Changed

1. **Removed hardcoded API keys** from `app_constants.dart`
2. **Added secure environment variable loading** with `String.fromEnvironment()`
3. **Enhanced error handling** for 403 and other API errors
4. **Created development scripts** for easy secure running
5. **Added build scripts** for production deployment
6. **Protected sensitive files** with `.gitignore`
7. **Updated Gemini model** to stable `gemini-1.5-flash-latest`

Your app is now secure and production-ready! 🎉

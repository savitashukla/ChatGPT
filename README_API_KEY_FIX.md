## 🚨 IMMEDIATE ACTION REQUIRED

Your app is in offline mode because **your Gemini API key was leaked and disabled by Google**.

### Quick Fix (2 minutes):

```bash
# Run this interactive script - it will guide you through everything:
./setup_new_key.sh
```

**OR** manually:

1. Get new key: https://aistudio.google.com/app/apikey
2. Update `.env.local` with new key
3. Restart: `./run_web.sh`

---

### Why This Happened

Your API key `AIzaSyAjpojPBLDGvIbONJ1yjJFckSMwmZUZl6U` was exposed publicly and Google disabled it for security.

### What Was Fixed

✅ Added API key diagnostics to help debug issues
✅ Created test script: `./test_gemini_key.sh`
✅ Created setup script: `./setup_new_key.sh`
✅ Removed leaked key from `.env.local`
✅ Added detailed error messages
✅ Created documentation: `QUICK_FIX.md` and `FIX_OFFLINE_MODE_ISSUE.md`

---

**For full details, see: `QUICK_FIX.md`**


#!/bin/bash

# Interactive script to help set up a new Gemini API key

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║           🔑 Gemini API Key Setup Helper                  ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}⚠️  Your current API key has been LEAKED and DISABLED${NC}"
echo -e "${YELLOW}    You need to create a NEW API key to use online mode.${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1
echo -e "${GREEN}Step 1: Get Your New API Key${NC}"
echo -e "   1. Open this URL in your browser:"
echo -e "      ${CYAN}https://aistudio.google.com/app/apikey${NC}"
echo ""
echo -e "   2. Click '${YELLOW}Create API Key${NC}' or '${YELLOW}Get API Key${NC}'"
echo ""
echo -e "   3. Copy the API key to your clipboard"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Open browser automatically on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${CYAN}Opening browser for you...${NC}"
    open "https://aistudio.google.com/app/apikey" 2>/dev/null || true
    echo ""
fi

# Wait for user
echo -e "${YELLOW}Press ENTER when you have copied your new API key...${NC}"
read

echo ""
echo -e "${GREEN}Step 2: Enter Your New API Key${NC}"
echo -e "${YELLOW}Paste your API key here (it will be saved to .env.local):${NC}"
echo -n "> "
read NEW_API_KEY

# Validate input
if [ -z "$NEW_API_KEY" ] || [ "$NEW_API_KEY" = "your_gemini_api_key_here" ]; then
    echo -e "${RED}❌ Invalid API key. Please try again.${NC}"
    exit 1
fi

# Check length (Gemini keys are typically 39 characters starting with AIza)
if [ ${#NEW_API_KEY} -lt 30 ]; then
    echo -e "${YELLOW}⚠️  Warning: API key seems too short. Are you sure it's correct? (y/n)${NC}"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo -e "${CYAN}Updating .env.local file...${NC}"

# Update .env.local
cat > .env.local << EOF
# API Keys - Your actual keys for development
# This file is git-ignored for security

# Get your OpenAI API key from: https://beta.openai.com/account/api-keys
OPENAI_API_KEY=your_openai_api_key_here

# Get your Gemini API key from: https://aistudio.google.com/app/apikey
GEMINI_API_KEY=$NEW_API_KEY
EOF

echo -e "${GREEN}✅ API key saved to .env.local${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 3: Test the key
echo -e "${GREEN}Step 3: Testing Your API Key${NC}"
echo -e "${CYAN}Testing connection to Gemini API...${NC}"
echo ""

./test_gemini_key.sh

# Step 4: Instructions
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Step 4: Restart Your App${NC}"
echo -e "${YELLOW}IMPORTANT: You MUST restart the app with the run script:${NC}"
echo ""
echo -e "   ${CYAN}./run_web.sh${NC}      (for web)"
echo -e "   ${CYAN}./run_dev.sh${NC}      (for mobile/desktop)"
echo ""
echo -e "${YELLOW}⚠️  Do NOT run from IDE - it won't load the new API key!${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Security tips
echo -e "${CYAN}🛡️  Security Tips:${NC}"
echo -e "   ✅ Add API restrictions in Google Cloud Console"
echo -e "   ✅ Never commit .env.local to Git"
echo -e "   ✅ Don't share your API key in screenshots"
echo -e "   ✅ Rotate your keys periodically"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   Setup Complete! 🎉                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""


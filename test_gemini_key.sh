#!/bin/bash

# Test Gemini API Key
# This script tests if your Gemini API key is valid by making a simple API call

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    🔑 Gemini API Key Tester${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Load API key from .env.local
if [ ! -f ".env.local" ]; then
    echo -e "${RED}❌ Error: .env.local file not found${NC}"
    echo -e "${YELLOW}Please create .env.local with your GEMINI_API_KEY${NC}"
    exit 1
fi

# Extract API key
export $(cat .env.local | grep GEMINI_API_KEY | xargs)

if [ -z "$GEMINI_API_KEY" ] || [ "$GEMINI_API_KEY" = "your_gemini_api_key_here" ]; then
    echo -e "${RED}❌ GEMINI_API_KEY is not set or still has placeholder value${NC}"
    echo -e "${YELLOW}Please set your actual Gemini API key in .env.local${NC}"
    exit 1
fi

echo -e "${GREEN}✅ API key loaded from .env.local${NC}"
echo -e "   Key preview: ${GEMINI_API_KEY:0:10}..."
echo ""

# Test the API key with a simple request
echo -e "${YELLOW}🔍 Testing API key with Gemini API...${NC}"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [{
        "text": "Say hello in one word"
      }]
    }]
  }' \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}")

# Extract status code and body
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo -e "${BLUE}Response Status: ${HTTP_CODE}${NC}"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ SUCCESS! Your Gemini API key is working correctly!${NC}"
    echo ""
    echo -e "${BLUE}Response:${NC}"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Your API key is valid and the app should work in online mode.${NC}"
    echo -e "${GREEN}If app is still offline, please restart it using:${NC}"
    echo -e "${GREEN}   ./run_web.sh${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
elif [ "$HTTP_CODE" = "400" ]; then
    echo -e "${RED}❌ BAD REQUEST (400)${NC}"
    echo -e "${YELLOW}The API key format might be incorrect or the request is malformed.${NC}"
    echo ""
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
elif [ "$HTTP_CODE" = "403" ]; then
    echo -e "${RED}❌ PERMISSION DENIED (403)${NC}"
    echo -e "${YELLOW}Possible issues:${NC}"
    echo -e "  1. API key is invalid or expired"
    echo -e "  2. Gemini API is not enabled for your project"
    echo -e "  3. Billing is not set up"
    echo -e "  4. API key has restrictions (IP, HTTP referrer, etc.)"
    echo -e "  5. Model 'gemini-2.5-flash' might not be available"
    echo ""
    echo -e "${BLUE}Error details:${NC}"
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
    echo ""
    echo -e "${YELLOW}Please check:${NC}"
    echo -e "  🔗 https://aistudio.google.com/app/apikey"
    echo -e "  🔗 https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com"
elif [ "$HTTP_CODE" = "429" ]; then
    echo -e "${RED}❌ RATE LIMIT EXCEEDED (429)${NC}"
    echo -e "${YELLOW}You've made too many requests. Please wait and try again.${NC}"
    echo ""
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ UNEXPECTED ERROR (${HTTP_CODE})${NC}"
    echo ""
    echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
fi

echo ""


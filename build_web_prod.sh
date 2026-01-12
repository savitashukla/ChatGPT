#!/bin/bash

# Flutter Web Production Build Script
# This script builds your Flutter web app for production with secure API key handling

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🌐 Building Flutter Web App for Production...${NC}"

# Check for production environment file
if [ -f ".env.production" ]; then
    echo -e "${YELLOW}📋 Loading production environment variables...${NC}"
    export $(cat .env.production | grep -v '^#' | xargs)
elif [ -f ".env.local" ]; then
    echo -e "${YELLOW}📋 Using local environment variables for build...${NC}"
    export $(cat .env.local | grep -v '^#' | xargs)
else
    echo -e "${RED}❌ No environment file found. Checking for CI/CD variables...${NC}"
fi

# Check if API keys are available
if [ -z "$GEMINI_API_KEY" ]; then
    echo -e "${RED}❌ GEMINI_API_KEY not found. Please either:${NC}"
    echo "   1. Create .env.production with your production keys"
    echo "   2. Set GEMINI_API_KEY environment variable"
    echo "   3. Configure them in your CI/CD pipeline"
    exit 1
fi

# Validate keys are not placeholder values
if [ "$GEMINI_API_KEY" = "your_gemini_api_key_here" ]; then
    echo -e "${RED}❌ GEMINI_API_KEY contains placeholder value. Please set actual production key.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ API keys validated${NC}"
echo -e "${GREEN}✅ Gemini API Key: ${GEMINI_API_KEY:0:10}...${NC}"

# Clean previous build
echo -e "${BLUE}🧹 Cleaning previous build...${NC}"
flutter clean

# Get dependencies
echo -e "${BLUE}📦 Getting dependencies...${NC}"
flutter pub get

# Build web app
echo -e "${BLUE}🌐 Building web app for production...${NC}"
flutter build web --release \
    --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY:-}" \
    --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"

echo -e "${GREEN}✅ Web app built successfully!${NC}"
echo -e "${GREEN}📂 Output directory: build/web/${NC}"
echo -e ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "   1. Test the build locally: cd build/web && python3 -m http.server 8000"
echo -e "   2. Deploy to your hosting platform (Firebase, Netlify, Vercel, etc.)"
echo -e ""
echo -e "${GREEN}🎉 Build completed successfully!${NC}"


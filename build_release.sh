#!/bin/bash

# Flutter Production Build Script with Environment Variables
# This script builds your Flutter app for production with secure API key handling

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔨 Building Flutter app for production...${NC}"

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

# Check if API keys are available (from env files or CI/CD)
if [ -z "$OPENAI_API_KEY" ] && [ -z "$GEMINI_API_KEY" ]; then
    echo -e "${RED}❌ No API keys found. Please either:${NC}"
    echo "   1. Create .env.production with your production keys"
    echo "   2. Set OPENAI_API_KEY and GEMINI_API_KEY environment variables"
    echo "   3. Configure them in your CI/CD pipeline"
    exit 1
fi

# Validate keys are not placeholder values
if [ "$OPENAI_API_KEY" = "your_openai_api_key_here" ] || [ "$GEMINI_API_KEY" = "your_gemini_api_key_here" ]; then
    echo -e "${RED}❌ API keys contain placeholder values. Please set actual production keys.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ API keys validated${NC}"

# Determine build target
TARGET=${1:-"apk"}

case $TARGET in
    "apk")
        echo -e "${BLUE}📱 Building Android APK...${NC}"
        flutter build apk --release \
            --dart-define=OPENAI_API_KEY="$OPENAI_API_KEY" \
            --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
        echo -e "${GREEN}✅ APK built successfully: build/app/outputs/flutter-apk/app-release.apk${NC}"
        ;;
    "appbundle")
        echo -e "${BLUE}📱 Building Android App Bundle...${NC}"
        flutter build appbundle --release \
            --dart-define=OPENAI_API_KEY="$OPENAI_API_KEY" \
            --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
        echo -e "${GREEN}✅ App Bundle built successfully: build/app/outputs/bundle/release/app-release.aab${NC}"
        ;;
    "ios")
        echo -e "${BLUE}🍎 Building iOS app...${NC}"
        flutter build ios --release \
            --dart-define=OPENAI_API_KEY="$OPENAI_API_KEY" \
            --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
        echo -e "${GREEN}✅ iOS app built successfully${NC}"
        ;;
    "web")
        echo -e "${BLUE}🌐 Building web app...${NC}"
        flutter build web --release \
            --dart-define=OPENAI_API_KEY="$OPENAI_API_KEY" \
            --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
        echo -e "${GREEN}✅ Web app built successfully: build/web/${NC}"
        ;;
    *)
        echo -e "${RED}❌ Invalid target: $TARGET${NC}"
        echo "Usage: ./build_release.sh [apk|appbundle|ios|web]"
        echo "Default: apk"
        exit 1
        ;;
esac

echo -e "${GREEN}🎉 Build completed successfully!${NC}"

#!/bin/bash

# Flutter Web Development Runner with Environment Variables
# This script loads API keys from .env.local and runs the Flutter web app securely

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🌐 Starting Flutter Web App with secure environment variables...${NC}"

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo -e "${RED}❌ Error: .env.local file not found${NC}"
    echo -e "${YELLOW}📝 Please create .env.local file with your API keys:${NC}"
    echo "   cp .env.example .env.local"
    echo "   # Then edit .env.local with your actual API keys"
    exit 1
fi

# Load environment variables from .env.local
echo -e "${YELLOW}📋 Loading environment variables from .env.local...${NC}"
export $(cat .env.local | grep -v '^#' | xargs)

# Validate that required keys are set
if [ -z "$GEMINI_API_KEY" ] || [ "$GEMINI_API_KEY" = "your_gemini_api_key_here" ]; then
    echo -e "${RED}❌ GEMINI_API_KEY is not set or still has placeholder value${NC}"
    echo "Please set your actual Gemini API key in .env.local"
    exit 1
fi

echo -e "${GREEN}✅ API keys loaded successfully${NC}"
echo -e "${GREEN}✅ Gemini API Key: ${GEMINI_API_KEY:0:10}...${NC}"

# Run Flutter web with dart-define parameters
echo -e "${YELLOW}🔧 Running Flutter Web App...${NC}"
flutter run -d chrome \
    --dart-define=OPENAI_API_KEY="$OPENAI_API_KEY" \
    --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
    "$@"


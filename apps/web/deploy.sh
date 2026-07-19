#!/bin/bash

# HenaQena cPanel Deployment Script
# Run from cPanel Terminal in apps/web directory
# cd ~/henaqena-app/apps/web && bash deploy.sh

set -e

echo "=== HenaQena Deployment Script ==="
echo ""

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
API_DIR="$APP_DIR/apps/api"
WEB_DIR="$APP_DIR/apps/web"

echo "📁 Project Directory: $APP_DIR"
echo "API Directory: $API_DIR"
echo "Web Directory: $WEB_DIR"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Update from Git
echo -e "${YELLOW}=== Step 1: Updating from Git ===${NC}"
cd $APP_DIR
if [ -d ".git" ]; then
  echo "Pulling latest changes..."
  git pull origin main
else
  echo "❌ Git repository not found. Clone first:"
  echo "git clone https://github.com/aarheemfrj/henaqena.git"
  exit 1
fi

# Step 2: Setup API
echo -e "${YELLOW}=== Step 2: Setting up API ===${NC}"
cd $API_DIR

echo "📝 Creating .env file..."
cat > .env << 'ENVEOF'
DATABASE_URL="postgresql://henaqena:VafyoU9mfkSlqLs4Doad@localhost:5432/henaqena?schema=public"
PORT=4000
ADMIN_API_KEY="Hleo2soAkResU7iprTLW"
UPLOADS_DIR="/home/maalsoft-henaqena/uploads"
PUBLIC_API_BASE_URL="https://henaqena.maalsoft.com/api"
CORS_ORIGINS="https://henaqena.maalsoft.com"
STORAGE_DRIVER="local"
ENABLE_BACKGROUND_JOBS="true"
ENVEOF

echo "📦 Installing API dependencies..."
npm install --production

echo "🔨 Building API..."
npm run build

echo "🗄️  Running Prisma migrations..."
npm run prisma:migrate

echo "📂 Creating uploads directory..."
mkdir -p /home/maalsoft-henaqena/uploads
chmod 755 /home/maalsoft-henaqena/uploads

# Step 3: Setup Web
echo -e "${YELLOW}=== Step 3: Setting up Web ===${NC}"
cd $WEB_DIR

echo "📝 Creating .env.local file..."
cat > .env.local << 'ENVEOF'
NEXT_PUBLIC_API_BASE_URL="https://henaqena.maalsoft.com/api"
PORT="3100"
ADMIN_API_KEY="Hleo2soAkResU7iprTLW"
ENVEOF

echo "📦 Installing Web dependencies..."
npm install --production

echo "🔨 Building Web..."
npm run build

# Step 4: Start Services
echo -e "${YELLOW}=== Step 4: Starting Services ===${NC}"

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
  echo "📥 Installing PM2 globally..."
  npm install -g pm2
fi

echo "🚀 Starting API service..."
cd $API_DIR
pm2 delete henaqena-api 2>/dev/null || true
pm2 start dist/server.js --name "henaqena-api"

echo "🚀 Starting Web service..."
cd $WEB_DIR
pm2 delete henaqena-web 2>/dev/null || true
pm2 start npm --name "henaqena-web" -- start

echo "💾 Saving PM2 config..."
pm2 save

# Final status
echo ""
echo -e "${GREEN}=== ✅ Deployment Complete! ===${NC}"
echo ""
echo "📊 Running Services:"
pm2 list
echo ""
echo "📋 Next Steps:"
echo "  1. Check API: curl http://localhost:4000/health"
echo "  2. Check Web: curl http://localhost:3100"
echo "  3. View logs: pm2 logs"
echo "  4. Configure reverse proxy in cPanel"
echo ""
echo "🔗 API will be at: https://henaqena.maalsoft.com/api"
echo "🌐 Web will be at: https://henaqena.maalsoft.com"
echo ""

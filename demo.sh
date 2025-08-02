#!/bin/bash

# GymPad Demo Script
# This script demonstrates the deep linking functionality of the GymPad app

echo "🏋️  GymPad Demo - Deep Link Testing"
echo "=================================="
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Navigate to the app directory
cd "$(dirname "$0")"

echo "📱 Starting GymPad in web mode..."
echo "   App will be available at: http://localhost:8080"
echo ""

# Start the app in background
flutter run -d chrome --web-port=8080 &
FLUTTER_PID=$!

# Wait for the app to start
echo "⏳ Waiting for app to start..."
sleep 10

echo "🔗 Testing Deep Links:"
echo ""

# Test URLs
echo "1. Bicep Curls at Elite Fitness Center:"
echo "   https://gympad-e44fc.web.app/gymId=\"GYM_ABC\"&equipmentId=\"123\""
echo ""

echo "2. Tricep Extensions at Urban Strength Hub:"
echo "   https://gympad-e44fc.web.app/gymId=\"GYM_XYZ\"&equipmentId=\"456\""
echo ""

echo "3. Cable Machine (Multi-exercise) at Elite Fitness Center:"
echo "   https://gympad-e44fc.web.app/gymId=\"GYM_ABC\"&equipmentId=\"40938\""
echo ""

echo "📝 Instructions:"
echo "   1. Copy one of the URLs above"
echo "   2. Open a new browser tab"
echo "   3. Paste the URL and press Enter"
echo "   4. The GymPad exercise screen should open automatically"
echo ""

echo "🛑 Press Ctrl+C to stop the demo"

# Wait for user to stop
trap "echo ''; echo '🏁 Stopping GymPad demo...'; kill $FLUTTER_PID; exit 0" INT
wait

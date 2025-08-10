#!/bin/bash

# GymPad Demo Script
# This script launches the GymPad app in web mode.

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

echo "Open http://localhost:8080 in your browser."

echo "🛑 Press Ctrl+C to stop the demo"

# Wait for user to stop
trap "echo ''; echo '🏁 Stopping GymPad demo...'; kill $FLUTTER_PID; exit 0" INT
wait

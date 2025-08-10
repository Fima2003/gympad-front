# gympad

A new Flutter project.

## Getting Started

# GymPad

A Flutter application that enables gym-goers to track their workout performance using NFC technology. This MVP saves workout data locally.

## Features

### Current Implementation
- **Exercise Tracking**: Timer, weight selection, and rep counting
- **Local Data Storage**: Saves workout data using SharedPreferences
- **Clean UI**: Follows the specified design system with Bebas Neue and Kanit fonts
- **Cross-Platform**: Works on Android, iOS, and Web

### App Flow
1. **Home Screen**: Shows "Ready to scan" interface
2. **Exercise Screen**: 
   - Displays gym info and exercise name
   - Timer functionality (start/stop)
   - Weight selector (2.5kg increments, default 15kg)
   - Reps selector modal after stopping timer
   - Workout sets table
   - Start new set / Finish exercise buttons
3. **Well Done Screen**: 
   - Shows completed workout summary
   - WhatsApp review button
   - Local data disclaimer

## Design System

### Colors
- Primary: `#0B4650` (Dark teal)
- Accent: `#E6FF2B` (Bright yellow-green)
- Background: `#F9F7F2` (Light cream)
- Text Secondary: `#898A8D` (Gray)

### Typography
- **Titles**: Bebas Neue (italics for big titles)
- **Body Text**: Kanit
- **No gradients**: Solid colors only

## Technical Stack

- **Flutter**: Cross-platform framework
- **shared_preferences**: Local data storage
 
- **google_fonts**: Typography
- **url_launcher**: WhatsApp integration

## Setup & Installation

1. **Prerequisites**:
   ```bash
   flutter --version  # Ensure Flutter is installed
   ```

2. **Install Dependencies**:
   ```bash
   cd gympad
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   # For Android/iOS (with device connected)
   flutter run
   
   # For Web
   flutter run -d chrome
   
   # For macOS
   flutter run -d macos
   ```

 

## Data Structure

### Mock Data Files
- `assets/mock_data/gyms.json`: Gym information (name, image)
- `assets/mock_data/exercises.json`: Exercise details (name, description, image)
- `assets/mock_data/equipment.json`: Equipment to exercise mapping

### Local Storage
- Workout data is saved locally using SharedPreferences
- Key format: `workout_data`
- Data includes: set number, reps, weight, time per set

## Development

### Project Structure
```
lib/
├── constants/
│   └── app_styles.dart          # Colors, typography, theme
├── models/
│   ├── gym.dart                 # Gym data model
│   ├── exercise.dart            # Exercise data model
│   ├── equipment.dart           # Equipment data model
│   └── workout_set.dart         # Workout set data model
├── screens/
│   ├── exercise_screen.dart     # Main workout interface
│   └── well_done_screen.dart    # Completion screen
├── services/
│   ├── data_service.dart        # Mock data loading
│   ├── storage_service.dart     # Local data persistence
│   └── storage_service.dart     # Local data persistence
├── widgets/
│   ├── reps_selector.dart       # Modal rep counter
│   ├── weight_selector.dart     # Horizontal weight picker
│   ├── workout_sets_table.dart  # Completed sets display
│   └── workout_timer.dart       # Set timer widget
└── main.dart                    # App entry point
```

### Running Tests
```bash
flutter test
```

## Future Enhancements

1. **NFC Integration**: Add actual NFC reading capability
2. **Backend Integration**: Connect to real gym/exercise database
3. **User Accounts**: Authentication and cloud data sync
4. **Analytics**: Track usage and send metrics
5. **Offline Support**: Better offline functionality
6. **Exercise Instructions**: Video guides and form tips

## Troubleshooting

### Common Issues

1. **Deep links not working**: Ensure proper URL format and app_links configuration
2. **Fonts not loading**: Run `flutter pub get` and restart the app
3. **Data not persisting**: Check SharedPreferences permissions
4. **Timer issues**: Ensure proper state management in WorkoutTimer widget

### Development Tips

1. **Hot Reload**: Use `r` in terminal for quick development iterations
2. **Debug Mode**: Check console logs for deep link parsing
3. **Asset Loading**: Verify asset paths in pubspec.yaml
4. **State Management**: Use setState carefully in timer components

---

**Built with ❤️ for gym enthusiasts**

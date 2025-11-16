# Workout Notification System - Testing Guide

## Overview
This document describes how to test the workout notification system that shows notifications when the user leaves the app during a workout.

## Features Implemented

### Break Notifications
When user is in a rest/break period and leaves the app:
- **Title**: "REST TIME • MM:SS" (countdown timer)
- **Content**: Next exercise name and suggested weight/reps
- **Color**: Dark gray (#1a1a1a) - matches break screen background
- **Actions**:
  - **+30s button**: Adds 30 seconds to the rest timer
  - **Skip button**: Skips the rest and goes to next exercise
- **Tap behavior**: Returns to app showing the break screen

### Set Notifications
When user is performing a set and leaves the app:
- **Title**: "SET IN PROGRESS • MM:SS" (elapsed time counter)
- **Content**: Exercise name, current set number, total sets
- **Color**: Light beige (#F9F7F2) - matches set screen background
- **Actions**:
  - **Action button**: Text changes based on context:
    - "Finish Set" - when more sets remain for this exercise
    - "Finish Exercise" - when this is the last set of the exercise
    - "Finish Workout" - when this is the last set of the workout
- **Tap behavior**: Returns to app showing the set screen

## Testing Instructions

### Prerequisites
1. Build and install the app on a physical device (notifications work better on real devices)
2. Grant notification permissions when prompted
3. Start a custom or free workout

### Test Case 1: Break Notification Basic Display
1. Start a workout (custom workout recommended)
2. Complete a set to enter break/rest period
3. Press the home button or switch to another app
4. **Expected**: Notification appears showing:
   - Countdown timer
   - Next exercise name
   - Weight/reps if available
   - +30s and Skip buttons

### Test Case 2: Break Notification Timer Update
1. Follow steps 1-3 from Test Case 1
2. Wait and observe the notification
3. **Expected**: Timer counts down every second

### Test Case 3: Break Notification +30s Action
1. Follow steps 1-3 from Test Case 1
2. Tap the "+30s" button in the notification
3. Return to the app
4. **Expected**: Rest timer has 30 extra seconds added

### Test Case 4: Break Notification Skip Action
1. Follow steps 1-3 from Test Case 1
2. Tap the "Skip" button in the notification
3. **Expected**: App opens and goes to the next set/exercise

### Test Case 5: Set Notification Basic Display
1. Start a workout
2. Begin a set (timer starts counting up)
3. Press the home button
4. **Expected**: Notification appears showing:
   - Elapsed time counting up
   - Exercise name
   - Set X of Y
   - Finish button with appropriate text

### Test Case 6: Set Notification Timer Update
1. Follow steps 1-3 from Test Case 5
2. Wait and observe the notification
3. **Expected**: Timer counts up every second

### Test Case 7: Set Notification Finish Button
1. Follow steps 1-3 from Test Case 5
2. Tap the finish button in the notification
3. **Expected**: App opens showing the current set screen
4. User can then complete the set by tapping finish button in app

### Test Case 8: Set Notification Button Text Variations
Test with different workout states:
- **First set of multi-set exercise**: Should show "Finish Set"
- **Last set of exercise with more exercises**: Should show "Finish Exercise"
- **Last set of last exercise**: Should show "Finish Workout"

### Test Case 9: Notification Tap (Not Action Button)
1. Follow either break or set notification setup
2. Tap the notification body (not the action buttons)
3. **Expected**: App opens and shows the appropriate screen

### Test Case 10: Return to App (No Action)
1. Follow either break or set notification setup
2. Return to app without tapping notification
3. **Expected**: Notification disappears, app shows current workout state

### Test Case 11: Multiple Background/Foreground Cycles
1. Start a workout
2. Go to background during break - verify notification
3. Return to foreground - verify notification disappears
4. Start next set
5. Go to background - verify set notification appears
6. Return to foreground
7. **Expected**: All transitions work smoothly

### Test Case 12: Workout Completion
1. During last set, go to background
2. Return to app and complete workout
3. **Expected**: Notification disappears when workout completes

## Android-Specific Testing

### Notification Channels
On Android 8.0+, verify that notification channels are created:
1. Long-press the notification
2. Tap notification settings
3. **Expected**: Two channels visible:
   - "Workout Break"
   - "Workout Set"

### Permissions
On Android 13+, verify permission request:
1. Install fresh app
2. Start a workout and go to background
3. **Expected**: Permission dialog appears (first time only)

## iOS-Specific Testing

### Permissions
1. Install fresh app
2. Start a workout and go to background
3. **Expected**: Permission dialog appears (first time only)

### Notification Actions
iOS has limited support for notification actions. Verify:
1. Actions appear in notifications
2. Tapping actions works correctly

## Troubleshooting

### Notifications Not Appearing
- Check notification permissions in device settings
- Verify app is not in battery optimization mode
- Check app logs for initialization errors

### Timer Not Updating
- Verify app lifecycle changes are detected
- Check background timer is running
- Look for errors in logs

### Actions Not Working
- Check that workout bloc is receiving events
- Verify app returns to foreground after action tap
- Check logs for action handling errors

## Implementation Details

### Files Modified/Created
- `lib/services/notification_service.dart` - Core notification service
- `lib/notifications/notifications_handler.dart` - Lifecycle integration
- `lib/main.dart` - Initialization with blocs
- `android/app/src/main/AndroidManifest.xml` - Permissions

### Key Classes
- `NotificationService`: Handles notification display and updates
- `NotificationsHandler`: Integrates with app lifecycle and workout state
- Listens to `WorkoutRunRest` and `WorkoutRunInSet` states

### Notification IDs
- Break notification: 100
- Set notification: 101

### Action IDs
- `add_30s`: Add 30 seconds to rest
- `skip_break`: Skip rest period
- `finish_set`: Finish current set

## Known Limitations

1. **Reps Dialog**: The "Finish" action button cannot directly open the reps dialog from background. User must tap finish button again in the app.

2. **iOS Action Limits**: iOS may limit the number of notification actions displayed.

3. **Background Updates**: Notification updates happen every second, which is battery-efficient but not frame-perfect.

4. **Isolate Communication**: Background notification taps use a separate isolate on some platforms, which limits direct callback functionality.

## Future Enhancements

Possible improvements for future versions:
1. Add workout progress to notification (e.g., "Set 5 of 12 total")
2. Support for custom notification sounds
3. Vibration patterns for different phases
4. Quick actions for common weights/reps
5. Workout statistics in notification expanded view

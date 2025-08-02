# Gympad

**Efim Rubin**  
*July 2025*

---

## Introduction

This is the MVP of the application that will enable people who go to the gym to track their performance with a much better experience using NFC technology. For the MVP we are going to build a very simple backend-less app that will have the capability of scanning the NFC tag and opening the necessary webpage. In the future, this will become a cross-platform application for both Android and iOS. The name of the application is **GymPad**.

---

## App's Behavior

### Exercise screen

| Feature ID | Expected Behavior | What a User Should See |
|------------|-------------------|-------------------------|
| 1. Open singular exercise | Upon opening a link `https://gympad-e44fc.web.app/gymId="gymID"&equipmentId="equipmentId"`, the gym's data from the assets should be loaded: icon and a name; and the equipment data: name of the exercise performed on this equipment. +1 should be sent to a simple backend to increase the amount of users that entered the webapp. | An app bar with Gym's data on the left (icon and then name). The main screen should contain: a) title of the exercise taken from equipment, b) timer (mm:ss), c) weight horizontal scroller with increases of 2.5kg, default to 15kg, d) button 'Start Set'. |
| 2. Start Set | Upon pressing the 'Start Set', the timer should set off. The 'Start Set' button should switch to 'Stop Set'. | The color of the button, text on the button, and the timer going off |
| 3. Stop Set | Upon pressing 'Stop Set', timer should stop, and a new widget 'Reps' should appear | A modal window with title 'How many reps, champ?'; 2 buttons on the left '-2', '-1'; a main container with number of reps defaulting to 8; and 2 buttons on the right '+1', '+2'. Button on the bottom: 'Save'. |
| 4. Select reps | Pressing on '-2' button decreases the number in the main container by 2, and analogously with the other 3 buttons in the modal window | The number in the main container should change |
| 5. Saving the set | When 'Save' is pressed in the modal window, the modal window should close. | Modal window closes and a new table appears at the bottom of the page with columns: Set number, #reps, weight, time. The page becomes scrollable. Two buttons appear instead of 'Start Set'/'Stop Set': 'Start a new set' and 'Finish exercise'. |
| 6. Start a new set | Upon pressing 'Start a new set', same behavior as in feature 2. Timer resets. | Same view as in feature 2, but now with an extra table at the bottom. |
| 7. Finish exercise | Upon pressing 'Finish exercise', the data of all sets should be stored locally on the user's device under the exercise ID. The user is moved to a 'Well Done' page with the exercise ID as argument. | Move to 'Well Done' screen |

---

### Well Done Screen

| Feature ID | Expected Behavior | What a User Should See |
|------------|-------------------|-------------------------|
| 1. Enter Well Done Screen | Upon entering Well Done screen, send +1 to a simple backend to increase the amount of users that finished the exercise with this app; load the local data by exercise ID. | Well Done screen: big title saying *'Well Done, big guy!'*, a table of sets; a button at the bottom "Send a review"; small text below: *"This is a test application. We hope you enjoyed it! All of the data is going to be saved on your device, and not transferred anywhere."* |
| 2. Send a review | Pressing 'Send a review' opens a WhatsApp conversation with me | Just opens a WhatsApp conversation with me |

---

## App's Visual Style

1. Utilize the following colors:
   - `#0B4650`
   - `#E6FF2B`
   - `#F9F7F2`
   - `#898A8D`
2. Use the following fonts (accessible via Google Fonts):
   - **Bebas Neue** or **Special Gothic Expanded One** for titles (make it easy to switch between them)
   - **Kanit** for the rest of the text
3. Big titles should be in *Italica*
4. Everything should be solid — no gradients
5. Use color theory to ensure good visual harmony in the app

---

## Technological Stack

1. `Flutter`  
2. `shared_preferences`  
3. `numberpicker`
4. `app_links`
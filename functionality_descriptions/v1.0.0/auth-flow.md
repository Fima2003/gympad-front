# Gympad. FrontEnd

**Yukhym Rubin**  
*01.08.2025*

---

## About

This is the flow of authorization in the frontend.

---
## Authorization Flow

| Feature ID | Expected Behavior | What a User Should See |
|------------|-------------------|-------------------------|
|1.1 Check local user| Upon opening an application, the system should check if there is locally saved userId and gymId. If the fields exist, then navigate to main screen. Otherwise, navigate to the Login/SignUp Page. | Not applicable. Done during Splash screen |
|1.2. Login/SignUp Page | Not applicable. Just a UI description | A page with a sport visual, and a button Sign-In with Google |
|1.3. Sign-In | by pressing on sing-in with google button(use [google_sign_in](https://pub.dev/packages/google_sign_in) flutter package), the user should be sent to a google sign in page. A standard Google Sign-Up. then, the details should be sent to the https://be.gympad.co/sign-up. After, the user should be sent to the main page | Standard Google Sign up |

---

## App's Visual Style

1. Utilize the following colors:
   - `#0B4650`
   - `#E6FF2B`
   - `#F9F7F2`
   - `#898A8D`
2. Use the following fonts (accessible via Google Fonts):
   - **Bebas Neue** for titles
   - **Kanit** for the rest of the text
3. Big titles should be in *Italica*
4. Everything should be solid — no gradients
5. Use color theory to ensure good visual harmony in the app

---

## Technological Stack

1. `Flutter`  
2. `google_sign_in`
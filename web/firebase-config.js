// Firebase configuration for web
// Get these values from Firebase Console → Project Settings → Your apps → Web app
const firebaseConfig = {
    apiKey: "YOUR_FIREBASE_API_KEY",
    authDomain: "your-project-id.firebaseapp.com",
    projectId: "your-project-id",
    storageBucket: "your-project-id.appspot.com",
    messagingSenderId: "YOUR_PROJECT_NUMBER",
    appId: "YOUR_WEB_APP_ID"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig); 
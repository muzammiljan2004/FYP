// Imports
importScripts('https://www.gstatic.com/firebasejs/9.2.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.2.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker
// "Default" Firebase configuration (from auto-generated firebase-options.js)
firebase.initializeApp({
  apiKey: "AIzaSyCptuN6Tz-K-OHxkuffQNtYzsPBu7u6VVY",
  authDomain: "wego-app-c0a8d.firebaseapp.com",
  projectId: "wego-app-c0a8d",
  storageBucket: "wego-app-c0a8d.appspot.com",
  messagingSenderId: "279686141911",
  appId: "1:279686141911:web:a25a84d877720b34385d92",
  measurementId: "G-ZG7LS19R52"
});

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle,
    notificationOptions);
}); 
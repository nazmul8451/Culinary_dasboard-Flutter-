// Give the service worker access to Firebase Messaging.
// Note that you can only use Firebase Messaging here. Other Firebase libraries
// are not available in the service worker.
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing in
// your app's Firebase config object.
// https://firebase.google.com/docs/web/setup#config-object
firebase.initializeApp({
  apiKey: 'AIzaSyAOkE2mGZdOePZUuKnM8s-6OIadOHiu9CE',
  authDomain: 'culinarytalesapp.firebaseapp.com',
  databaseURL: 'https://culinarytalesapp-default-rtdb.firebaseio.com',
  projectId: 'culinarytalesapp',
  storageBucket: 'culinarytalesapp.firebasestorage.app',
  messagingSenderId: '888497741298',
  appId: '1:888497741298:web:79d8aac5be12c69221df6b',
  measurementId: 'G-SWP6CX1E3B'
});

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png' // Ensure this icon exists or remove line
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

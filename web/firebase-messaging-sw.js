importScripts('https://www.gstatic.com/firebasejs/9.6.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCy5z_1clQqsR6XMKUsaquGZRV6Eq_JJhY',
  authDomain: 'sample-firebase-ai-app-456c6.firebaseapp.com',
  projectId: 'sample-firebase-ai-app-456c6',
  storageBucket: 'sample-firebase-ai-app-456c6.firebasestorage.app',
  messagingSenderId: '295791005487',
  appId: '1:295791005487:web:6a550067901b187b6a1bda',
});

const messaging = firebase.messaging(); 
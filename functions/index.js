const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotificationOnNewDoc = functions.firestore
    .document("notifications/{notificationId}")
    .onCreate(async (snap, context) => {
        const data = snap.data();
        const fcmToken = data.fcmToken;
        const title = data.title || "Notification";
        const body = data.body || "";
        if (!fcmToken) {
            console.log("No FCM token found, skipping notification.");
            return null;
        }

        const message = {
            notification: {
                title: title,
                body: body,
            },
            token: fcmToken,
            data: {
                type: data.type || "",
                recipientId: data.recipientId || "",
            },
        };

        try {
            const response = await admin.messaging().send(message);
            console.log("Successfully sent message:", response);
            return null;
        } catch (error) {
            console.error("Error sending message:", error);
            return null;
        }
    });

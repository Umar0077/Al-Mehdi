const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Chat notification function when new message is created
 * @param {Object} event - The function event
 */
exports.sendChatNotification = onDocumentCreated(
    "chatRooms/{chatRoomId}/messages/{messageId}",
    async (event) => {
        const snap = event.data;
        if (!snap) return;
        const messageData = snap.data();
        const {senderId, senderName, text} = messageData;

        if (!text || !senderId) {
            console.warn("❗ Missing senderId or message text.");
            return;
        }

        try {
            // 1. Get chatRoom details
            const chatRoomRef = db.collection("chatRooms")
                .doc(event.params.chatRoomId);
            const chatRoomSnap = await chatRoomRef.get();
            if (!chatRoomSnap.exists) {
                console.error("❌ Chat room not found");
                return;
            }
            const chatRoomData = chatRoomSnap.data();
            const participants = chatRoomData.participants;
            if (!participants || participants.length !== 2) {
                console.error("❌ Invalid participants list");
                return;
            }
            // 2. Determine receiverId (the user who is NOT the sender)
            const receiverId = participants.find((uid) => uid !== senderId);
            if (!receiverId) {
                console.error("❌ Could not determine receiver");
                return;
            }
            // 3. Get receiver's FCM token from either 'teachers' or 'students'
            let userDoc = await db.collection("teachers").doc(receiverId).get();
            if (!userDoc.exists) {
                userDoc = await db.collection("students").doc(receiverId).get();
            }
            if (!userDoc.exists) {
                console.error(`❌ User with ID ${receiverId} not found`);
                return;
            }
            const fcmTokens = userDoc.get("fcmToken");

            if (!fcmTokens || fcmTokens.length === 0) {
                console.warn(`❗ No FCM tokens for user: ${receiverId}`);
                return;
            }

            // 4. Send notification to each FCM token
            const promises = fcmTokens.map(async (token) => {
                const message = {
                    token: token,
                    notification: {
                        title: `New message from ${senderName}`,
                        body: text,
                    },
                    data: {
                        chatRoomId: event.params.chatRoomId,
                        senderId: senderId,
                        senderName: senderName || "Unknown",
                        messageId: event.params.messageId,
                        type: "chat",
                    },
                    android: {
                        notification: {
                            channelId: "chat_notifications",
                        },
                    },
                };

                try {
                    const response = await admin.messaging().send(message);
                    console.log("✅ Successfully sent message:", response);
                    return response;
                } catch (error) {
                    console.error("❌ Error sending message:", error);
                    throw error;
                }
            });

            await Promise.all(promises);
            console.log("✅ All notifications sent successfully");
        } catch (error) {
            console.error("❌ Error in sendChatNotification:", error);
        }
    }
);

/**
 * Class notification function when new class is created
 * @param {Object} event - The function event
 */
exports.sendClassNotification = onDocumentCreated("classes/{classId}",
    async (event) => {
        const snap = event.data;
        if (!snap) return;

        const classData = snap.data();
        const classId = event.params.classId;

        const {
            title,
            teacherId,
            subject,
            scheduledDateTime,
            description,
        } = classData;

        if (!title || !teacherId) {
            console.warn("❗ Missing required class data");
            return;
        }

        try {
            // Get teacher info
            const teacherDoc = await db.collection("teachers")
                .doc(teacherId).get();

            if (!teacherDoc.exists) {
                console.error("❌ Teacher not found");
                return;
            }

            const teacherData = teacherDoc.data();
            const teacherName = teacherData.name || "Unknown Teacher";

            // Format scheduled time
            let timeString = "TBD";
            if (scheduledDateTime && scheduledDateTime.toDate) {
                timeString = scheduledDateTime.toDate()
                    .toLocaleString("en-US", {
                        weekday: "short",
                        month: "short",
                        day: "numeric",
                        hour: "numeric",
                        minute: "2-digit",
                        hour12: true,
                    });
            }

            const notificationTitle = `New Class: ${title}`;
            const notificationBody = `${teacherName} scheduled ${subject ||
                "a class"} on ${timeString}`;

            console.log(`📚 Sending class notification for: ${title}`);

            // Get all students
            const studentsSnapshot = await db.collection("students").get();

            for (const studentDoc of studentsSnapshot.docs) {
                const studentData = studentDoc.data();
                const fcmTokens = studentData.fcmToken || [];

                if (fcmTokens.length > 0) {
                    for (const token of fcmTokens) {
                        const message = {
                            token: token,
                            notification: {
                                title: notificationTitle,
                                body: notificationBody,
                            },
                            data: {
                                classId: classId,
                                teacherId: teacherId,
                                type: "class_scheduled",
                                subject: subject || "",
                                scheduledDateTime: scheduledDateTime ?
                                    scheduledDateTime.toDate().toISOString() : "",
                            },
                            android: {
                                notification: {
                                    channelId: "class_notifications",
                                    sound: "default",
                                    badge: "1",
                                },
                            },
                            apns: {
                                payload: {
                                    aps: {
                                        sound: "default",
                                        badge: 1,
                                        "content-available": 1,
                                    },
                                },
                            },
                        };

                        try {
                            await admin.messaging().send(message);
                        } catch (error) {
                            console.error("Error sending to student:", error);
                        }
                    }
                }

                // Store in-app notification
                try {
                    await db.collection("students").doc(studentDoc.id)
                        .collection("notifications").add({
                            title: notificationTitle,
                            body: notificationBody,
                            type: "class_scheduled",
                            classId: classId,
                            isRead: false,
                            createdAt: admin.firestore.FieldValue
                                .serverTimestamp(),
                        });
                } catch (error) {
                    console.error("Error storing notification:", error);
                }
            }

            console.log("✅ Class notifications sent");
        } catch (error) {
            console.error("❌ Error in sendClassNotification:", error);
        }
    }
);

/**
 * Scheduled function to check for class reminders
 * Runs every 1 minute to check for classes starting in ~5 minutes
 */
exports.checkClassReminders = onSchedule("every 1 minutes", async (event) => {
    const now = new Date();
    const fiveMinutesLater = new Date(now.getTime() + 5 * 60 * 1000);

    console.log("Checking for class reminders at:", now.toISOString());

    try {
        // Query classes collection for classes starting in ~5 minutes
        const classesSnapshot = await admin.firestore()
            .collection("classes")
            .where("scheduledDateTime", ">=", now)
            .where("scheduledDateTime", "<=", fiveMinutesLater)
            .get();

        for (const classDoc of classesSnapshot.docs) {
            const classData = classDoc.data();
            const classId = classDoc.id;

            // Check if reminder already sent
            const reminderQuery = admin.firestore()
                .collection("class_reminder_logs")
                .where("classId", "==", classId)
                .where("reminderType", "==", "class_reminder");

            const reminderLogsSnapshot = await reminderQuery.get();

            if (reminderLogsSnapshot.empty) {
                // Send reminder and log it
                await sendClassReminder(classId, classData);

                // Log the reminder
                await admin.firestore()
                    .collection("class_reminder_logs")
                    .add({
                        classId: classId,
                        reminderType: "class_reminder",
                        sentAt: admin.firestore.FieldValue.serverTimestamp(),
                        classDetails: {
                            title: classData.title || "Class",
                            teacherName: classData.teacherName || "Unknown",
                            scheduledDateTime: classData.scheduledDateTime,
                            subject: classData.subject || "N/A",
                        },
                    });

                console.log(`Reminder sent for class: ${classId}`);
            }
        }
    } catch (error) {
        console.error("Error in checkClassReminders:", error);
    }
});

/**
 * Function to send class reminder notification
 * @param {string} classId - The ID of the class
 * @param {Object} classData - The class data from Firestore
 */
async function sendClassReminder(classId, classData) {
    const title = classData.title || "Class Reminder";
    const scheduledDateTime = classData.scheduledDateTime;
    let scheduledTime = "Unknown time";

    if (scheduledDateTime && scheduledDateTime.toDate) {
        scheduledTime = scheduledDateTime.toDate().toLocaleTimeString("en-US", {
            hour: "2-digit",
            minute: "2-digit",
        });
    }

    const messageBody = `Your class "${title}" is starting in 5 minutes at ` +
        `${scheduledTime}`;

    try {
        // Get students enrolled in this class
        const enrollmentsSnapshot = await admin.firestore()
            .collection("enrollments")
            .where("classId", "==", classId)
            .get();

        // Get teacher information
        const teacherId = classData.teacherId;
        if (teacherId) {
            await sendReminderToUser(teacherId, title, messageBody,
                "teacher", classId);
        }

        // Send to all enrolled students
        for (const enrollmentDoc of enrollmentsSnapshot.docs) {
            const enrollmentData = enrollmentDoc.data();
            const studentId = enrollmentData.studentId;

            if (studentId) {
                await sendReminderToUser(studentId, title, messageBody,
                    "student", classId);
            }
        }

        console.log(`Class reminder sent for class: ${classId}`);
    } catch (error) {
        console.error(`Error sending class reminder for ${classId}:`, error);
    }
}

/**
 * Helper function to send reminder to individual user
 * @param {string} userId - The user ID
 * @param {string} title - The notification title
 * @param {string} body - The notification body
 * @param {string} userType - The type of user (student/teacher/admin)
 * @param {string} classId - The class ID
 */
async function sendReminderToUser(userId, title, body, userType, classId) {
    try {
        // Determine collection based on user type
        let collection = "students";
        if (userType === "teacher") {
            collection = "teachers";
        } else if (userType === "admin") {
            collection = "admin";
        }

        // Get user document
        const userDoc = await admin.firestore()
            .collection(collection).doc(userId).get();

        if (!userDoc.exists) {
            console.log(`User not found: ${userId} in ${collection}`);
            return;
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (fcmToken) {
            // Send FCM notification for when app is closed/background
            const message = {
                token: fcmToken,
                notification: {
                    title: title,
                    body: body,
                },
                data: {
                    type: "class_reminder",
                    classId: classId,
                    userId: userId,
                    userType: userType,
                    priority: "high",
                },
                android: {
                    notification: {
                        channelId: "class_reminders",
                        priority: "high",
                        sound: "default",
                        badge: "1",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                            "content-available": 1,
                        },
                    },
                },
            };

            try {
                const response = await admin.messaging().send(message);
                console.log("FCM notification sent successfully:", response);
            } catch (fcmError) {
                console.error("Error sending FCM notification:", fcmError);
            }

            // Store in-app notification
            try {
                await admin.firestore().collection(collection).doc(userId)
                    .collection("notifications").add({
                        title: title,
                        body: body,
                        type: "class_reminder",
                        classId: classId,
                        isRead: false,
                        createdAt: admin.firestore
                            .FieldValue.serverTimestamp(),
                        priority: "high",
                    });
            } catch (notifError) {
                console.error("Error storing in-app notification:",
                    notifError);
            }
        }

        console.log(`Reminder sent to ${userType}: ${userId}`);
    } catch (error) {
        console.error(`Error sending reminder to ${userId}:`, error);
    }
}

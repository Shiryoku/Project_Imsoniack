const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

// IoT Data Endpoint
// URL will be: https://us-central1-project-imsoniack-1.cloudfunctions.net/storeIoTData
exports.storeIoTData = onRequest({ region: "asia-southeast1" }, async (request, response) => {
    // 1. Security Check: API Key
    const apiKey = request.headers['x-api-key'];
    const VALID_KEY = "IMS-IOT-SECRET-2026"; // <--- YOUR SECURE API KEY

    if (apiKey !== VALID_KEY) {
        logger.warn("Unauthorized access attempt", { headers: request.headers });
        response.status(401).send("Unauthorized: Invalid API Key");
        return;
    }


    // 2. Data Validation
    const data = request.body;
    if (!data || Object.keys(data).length === 0) {
        response.status(400).send("Bad Request: No JSON data provided");
        return;
    }

    // --- SLEEP SCORE CALCULATION (Simplified) ---
    // 1. Calculate Movement (Vector Magnitude deviation from 9.8 gravity)
    let movementScore = 100;
    if (data.accel) {
        const { x, y, z } = data.accel;
        const magnitude = Math.sqrt(x * x + y * y + z * z);
        const deviation = Math.abs(magnitude - 9.8); // 0 means perfect stillness

        // If deviation > 1.5 m/s^2, it's significant movement (awake/restless)
        if (deviation > 1.5) movementScore = 40;
        else if (deviation > 0.5) movementScore = 70;
        else movementScore = 95; // Very still
    }

    // 4. Noise Filtering (New)
    // If user is moving significantly, optical readings are likely noise.
    if (data.accel) {
        const { x, y, z } = data.accel;
        const magnitude = Math.sqrt(x * x + y * y + z * z);
        const deviation = Math.abs(magnitude - 9.8);

        // Threshold: 3.0 m/s^2 deviation implies active movement (shaking/walking)
        if (deviation > 3.0) {
            logger.info("High movement detected, discarding optical readings", { deviation });
            data.heart_rate = null;
            data.spo2 = null;
        }
    }

    // 5. Impossible Value Filtering
    // Reject biological outliers (unless in emergency mode, but here we prioritize clean data)
    if (data.heart_rate > 200 || data.heart_rate < 30) {
        data.heart_rate = null;
    }
    if (data.spo2 > 100 || data.spo2 < 50) {
        data.spo2 = null;
    }

    // 2. Calculate Heart Rate Score (Resting range assumed 50-90)
    let hrScore = 100;
    const hr = data.heart_rate || 0; // Usage of 0 if null
    if (hr > 0) {
        if (hr < 40 || hr > 110) hrScore = 50; // Strange/Active
        else if (hr > 90) hrScore = 70; // Slightly elevated
        else if (hr >= 50 && hr <= 90) hrScore = 95; // Optimal Resting
    } else {
        hrScore = 0; // No valid HR
    }

    // 3. Weighted Average (60% Movement, 40% HR)
    const sleepScore = Math.round((movementScore * 0.6) + (hrScore * 0.4));

    // --- SLEEP STAGE CLASSIFICATION (New) ---
    let sleepStage = "Light"; // Default

    // Awake: High movement
    if (movementScore <= 40) {
        sleepStage = "Awake";
    }
    // Deep Sleep: Very still AND low heart rate
    else if (movementScore >= 95 && hr < 60) {
        sleepStage = "Deep";
    }
    // REM Sleep: Still BUT active heart rate (Standard proxy)
    else if (movementScore >= 95 && hr >= 60) {
        sleepStage = "REM";
    }
    // Light Sleep: Moderate movement or stillness with normal HR (all other cases)
    else {
        sleepStage = "Light";
    }

    // Add scores to data object
    data.sleep_score = sleepScore;
    data.sleep_stage = sleepStage;
    // ---------------------------------------------


    try {
        // 3. Store in Firestore
        // 3. Store in Firestore
        let timestamp = admin.firestore.FieldValue.serverTimestamp();

        // Allow backdating if custom_timestamp is provided
        if (data.custom_timestamp) {
            timestamp = admin.firestore.Timestamp.fromDate(new Date(data.custom_timestamp));
            delete data.custom_timestamp;
        }

        const writeResult = await admin.firestore().collection('iot_data').add({
            ...data,
            server_timestamp: timestamp
        });

        logger.info("IoT Data saved", { id: writeResult.id, data: data });
        response.json({ result: `Data saved successfully`, docId: writeResult.id });
    } catch (error) {
        logger.error("Error writing document: ", error);
        response.status(500).send("Internal Server Error");
    }
});

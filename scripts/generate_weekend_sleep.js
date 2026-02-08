const https = require('https');
require('dotenv').config();

// --- CONFIGURATION ---
const API_KEY = process.env.IOT_API_KEY || "IMS-IOT-SECRET-2026"; // Fallback only for testing
const HOSTNAME = 'asia-southeast1-project-imsoniack-1.cloudfunctions.net';
const PATH = '/storeIoTData';

// Helper to calculate the previous Friday at 10 PM
function getPreviousFriday() {
    const date = new Date();
    const day = date.getDay();
    const diff = (day + 2) % 7; // Calculate difference to get to last Friday
    date.setDate(date.getDate() - diff);
    date.setHours(22, 0, 0, 0); // Friday 10:00 PM
    return date;
}

const startTime = getPreviousFriday();
// If today is Friday (before 10pm) or earlier in week, this might go back 1 week. 
// Just ensuring it's in the past. 
if (startTime > new Date()) {
    startTime.setDate(startTime.getDate() - 7);
}

const endTime = new Date(startTime);
endTime.setDate(endTime.getDate() + 1); // Saturday
endTime.setHours(6, 0, 0, 0); // 6:00 AM

console.log(`Generating data from ${startTime.toISOString()} to ${endTime.toISOString()}`);

// --- DATA GENERATION ---
const dataPoints = [];
let currentTime = new Date(startTime);

while (currentTime <= endTime) {
    // Generate "Good Sleep" Data
    // HR: 50 - 70 (Resting)
    const hr = Math.floor(Math.random() * (70 - 50 + 1)) + 50;

    // SpO2: 97 - 100
    const spo2 = Math.floor(Math.random() * (100 - 97 + 1)) + 97;

    // Movement: Minimal (Z ~ 9.8, others ~0)
    // Small noise +/- 0.05
    const z = 9.8 + (Math.random() * 0.1 - 0.05);
    const x = (Math.random() * 0.1 - 0.05);
    const y = (Math.random() * 0.1 - 0.05);

    dataPoints.push({
        custom_timestamp: currentTime.toISOString(), // ISO string for the backend to parse
        heart_rate: hr,
        spo2: spo2,
        temperature: 36.5 + (Math.random() * 0.2), // 36.5 - 36.7
        accel: { x, y, z }
    });

    // Advance 1 minute
    currentTime.setMinutes(currentTime.getMinutes() + 1);
}

console.log(`Prepared ${dataPoints.length} data points.`);

// --- SENDING LOOP ---
// We'll send them sequentially to avoid overwhelming the server (or hitting rate limits)
async function sendData(index = 0) {
    if (index >= dataPoints.length) {
        console.log("All data sent successfully!");
        return;
    }

    const payload = JSON.stringify(dataPoints[index]);

    const options = {
        hostname: HOSTNAME,
        path: PATH,
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'x-api-key': API_KEY,
            'Content-Length': payload.length
        }
    };

    const req = https.request(options, (res) => {
        // Optional: print '.' for progress every 10 requests
        if (index % 10 === 0) process.stdout.write('.');

        if (res.statusCode !== 200) {
            console.error(`\nError at index ${index}: Status ${res.statusCode}`);
        }

        // Consume response to free memory
        res.on('data', () => { });
        res.on('end', () => {
            // Next
            sendData(index + 1);
        });
    });

    req.on('error', (e) => {
        console.error(`\nRequest error: ${e.message}`);
    });

    req.write(payload);
    req.end();
}

console.log("Starting upload...");
sendData();

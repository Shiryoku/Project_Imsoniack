const https = require('https');
require('dotenv').config();

const data = JSON.stringify({
    heart_rate: 75,
    spo2: 98,
    temperature: 36.5,
    accel: {
        x: 0.1,
        y: 0.2,
        z: 9.8
    }
});

const options = {
    hostname: 'asia-southeast1-project-imsoniack-1.cloudfunctions.net',
    path: '/storeIoTData',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length,
        'x-api-key': process.env.IOT_API_KEY
    }
};

const req = https.request(options, (res) => {
    console.log(`StatusCode: ${res.statusCode}`);

    res.on('data', (d) => {
        process.stdout.write(d);
    });
});

req.on('error', (error) => {
    console.error(error);
});

req.write(data);
req.end();

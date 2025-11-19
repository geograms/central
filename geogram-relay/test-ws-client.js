const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:45679/');
const CALLSIGN = 'TEST1';

ws.on('open', function open() {
    console.log('   Connected to WebSocket');

    // Send REGISTER message
    const registerMsg = {
        type: 'REGISTER',
        callsign: CALLSIGN
    };
    console.log('   Sending REGISTER:', JSON.stringify(registerMsg));
    ws.send(JSON.stringify(registerMsg));
});

ws.on('message', function message(data) {
    console.log('   Received:', data.toString());
    const msg = JSON.parse(data.toString());

    if (msg.type === 'REGISTER') {
        console.log('   ✓ Device registered successfully:', msg.callsign);

        // Now test PING/PONG
        setTimeout(() => {
            const pingMsg = { type: 'PING' };
            console.log('   Sending PING');
            ws.send(JSON.stringify(pingMsg));
        }, 100);
    } else if (msg.type === 'PONG') {
        console.log('   ✓ Received PONG response');

        // Test HTTP_REQUEST handling
        setTimeout(() => {
            console.log('   Waiting for HTTP_REQUEST...');
        }, 100);

        // Close after 2 seconds
        setTimeout(() => {
            ws.close();
        }, 2000);
    } else if (msg.type === 'HTTP_REQUEST') {
        console.log('   ✓ Received HTTP_REQUEST:', msg.method, msg.path);

        // Send HTTP_RESPONSE
        const response = {
            type: 'HTTP_RESPONSE',
            requestId: msg.requestId,
            statusCode: 200,
            responseHeaders: JSON.stringify({'Content-Type': 'application/json'}),
            responseBody: JSON.stringify({message: 'Hello from device'})
        };
        console.log('   Sending HTTP_RESPONSE');
        ws.send(JSON.stringify(response));
    }
});

ws.on('error', function error(err) {
    console.error('   ✗ WebSocket error:', err.message);
    process.exit(1);
});

ws.on('close', function close() {
    console.log('   WebSocket closed');
    process.exit(0);
});

// Timeout after 5 seconds
setTimeout(() => {
    console.error('   ✗ Test timeout');
    ws.close();
    process.exit(1);
}, 5000);

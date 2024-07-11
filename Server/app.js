const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 }, () => {
    console.log("Signaling server is now listening on port 8080");
});

const clients = new Map();

function getPair(client) {
    for (let [key, value] of clients) {
        if (value === null) {
            return key;
        }
    }
    return null;
}

// Broadcast to the paired client
wss.broadcast = (ws, data) => {
    const pairedClient = clients.get(ws);
    if (pairedClient && pairedClient.readyState === WebSocket.OPEN) {
        pairedClient.send(data);
    }
};

wss.on('connection', (ws) => {
    const pair = getPair(ws);
    if (pair) {
        clients.set(pair, ws);
        clients.set(ws, pair);
        ws.send("Paired with another client");
        pair.send("Paired with another client");
    } else {
        clients.set(ws, null);
        ws.send("Waiting for a pair");
    }

    console.log(`Client connected. Total connected clients: ${wss.clients.size}`);
    
    ws.onmessage = (message) => {
        console.log(message.data + "\n");
        wss.broadcast(ws, message.data);
    };

    ws.onclose = () => {
        const pairedClient = clients.get(ws);
        if (pairedClient) {
            pairedClient.send("Your pair has disconnected");
            clients.set(pairedClient, null);
        }
        clients.delete(ws);
        console.log(`Client disconnected. Total connected clients: ${wss.clients.size}`);
    };
});

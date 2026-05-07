const express = require('express');
const db = require('./db');
const config = require('./config');

const app = express();

// Middleware to parse JSON and Form Data
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// HTML Template Helper
const renderHtml = (title, body) => `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>${title}</title>
</head>
<body>
    ${body}
</body>
</html>
`;

// Helper for content negotiation
function wantsHtml(req) {
    // If the client explicitly prefers JSON over HTML, return false
    return req.accepts(['html', 'json']) === 'html';
}

// Root endpoint: Returns list of business logic endpoints (respects Accept header)
app.get('/', (req, res) => {
    const endpoints = [
        { method: 'GET', path: '/items', desc: 'List inventory items' },
        { method: 'POST', path: '/items', desc: 'Create new inventory item' },
        { method: 'GET', path: '/items/:id', desc: 'Get item details' },
        { method: 'GET', path: '/health/alive', desc: 'Liveness check' },
        { method: 'GET', path: '/health/ready', desc: 'Readiness check' }
    ];

    if (wantsHtml(req)) {
        const listItems = endpoints.map(e => 
            `<li><b>${e.method}</b> <a href="${e.path.replace('/:id', '')}">${e.path}</a> - ${e.desc}</li>`
        ).join('');
        
        const formHtml = `
            <h2>Create New Item</h2>
            <form action="/items" method="POST">
                <label>Name: <input type="text" name="name" required></label><br><br>
                <label>Quantity: <input type="number" name="quantity" required></label><br><br>
                <button type="submit">Create Item</button>
            </form>
        `;
        
        res.send(renderHtml('Simple Inventory API', `<h1>Available Endpoints</h1><ul>${listItems}</ul><hr>${formHtml}`));
    } else {
        res.json(endpoints);
    }
});

// Health checks
app.get('/health/alive', (req, res) => {
    res.status(200).send('OK');
});

app.get('/health/ready', async (req, res) => {
    try {
        await db.query('SELECT 1');
        res.status(200).send('OK');
    } catch (err) {
        res.status(500).send(`Database error: ${err.message}`);
    }
});

// GET /items -> returns list of items (id, name)
app.get('/items', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT id, name FROM inventory_items');
        
        if (wantsHtml(req)) {
            const tableRows = rows.map(r => `<tr><td>${r.id}</td><td><a href="/items/${r.id}">${r.name}</a></td></tr>`).join('');
            const table = `<table border="1" cellpadding="5" cellspacing="0">
                <tr><th>ID</th><th>Name</th></tr>
                ${tableRows}
            </table>`;
            res.send(renderHtml('Inventory Items', `<h1>Inventory Items</h1>${table}<br><a href="/">Back to Operations</a>`));
        } else {
            res.json(rows);
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST /items -> create new item
app.post('/items', async (req, res) => {
    const { name, quantity } = req.body;
    
    if (!name || quantity === undefined) {
        return res.status(400).send('Name and quantity are required');
    }

    try {
        const [result] = await db.query('INSERT INTO inventory_items (name, quantity) VALUES (?, ?)', [name, quantity]);
        
        if (wantsHtml(req)) {
            // Redirect back to items page if submitted via HTML form
            res.redirect('/items');
        } else {
            res.status(201).json({ id: result.insertId, name, quantity });
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET /items/:id -> full item details
app.get('/items/:id', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT id, name, quantity, created_at FROM inventory_items WHERE id = ?', [req.params.id]);
        
        if (rows.length === 0) {
            return res.status(404).send('Item not found');
        }
        
        const item = rows[0];
        
        if (wantsHtml(req)) {
            const details = `
                <table border="1" cellpadding="5" cellspacing="0">
                    <tr><th>Field</th><th>Value</th></tr>
                    <tr><td><b>ID</b></td><td>${item.id}</td></tr>
                    <tr><td><b>Name</b></td><td>${item.name}</td></tr>
                    <tr><td><b>Quantity</b></td><td>${item.quantity}</td></tr>
                    <tr><td><b>Created At</b></td><td>${item.created_at}</td></tr>
                </table>
            `;
            res.send(renderHtml('Item Details', `<h1>Item Details: ${item.name}</h1>${details}<br><a href="/items">Back to Items list</a>`));
        } else {
            res.json(item);
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Start server
// Handle Systemd socket activation seamlessly
if (process.env.LISTEN_FDS && parseInt(process.env.LISTEN_FDS, 10) > 0) {
    // fd 3 is automatically assigned by systemd
    app.listen({ fd: 3 }, () => {
        console.log('App started successfully via systemd socket activation.');
    });
} else {
    // Standard execution via command line
    const port = config.appPort;
    app.listen(port, '127.0.0.1', () => {
        console.log(`App started payload successfully. Listening on http://127.0.0.1:${port}`);
    });
}

const mysql = require('mysql2/promise');
const config = require('../src/config');

async function migrate() {
    console.log(`Starting database migration on ${config.dbHost}:${config.dbPort}...`);
    let connection;
    try {
        // Connect to the database using the provided credentials
        connection = await mysql.createConnection({
            host: config.dbHost,
            port: config.dbPort,
            user: config.dbUser,
            password: config.dbPass,
            database: config.dbName
        });

        // Create the necessary tables if they don't exist (Idempotency)
        const createTableQuery = `
            CREATE TABLE IF NOT EXISTS inventory_items (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                quantity INT NOT NULL DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `;
        
        await connection.query(createTableQuery);

        console.log('Migration completed successfully. Table "inventory_items" is ready.');
    } catch (err) {
        console.error('Migration failed:', err.message);
        process.exit(1);
    } finally {
        if (connection) {
            await connection.end();
        }
    }
}

migrate();

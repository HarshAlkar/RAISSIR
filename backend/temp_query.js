const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT) || 5432,
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'root',
    database: process.env.DB_NAME || 'cretipoint',
});

async function run() {
    try {
        const res = await pool.query('SELECT * FROM admins');
        console.log('ADMINS:', JSON.stringify(res.rows, null, 2));
    } catch (err) {
        console.error('ERROR:', err.message);
    } finally {
        await pool.end();
    }
}
run();

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
        const tables = ['users', 'certificates', 'admins'];
        for (const table of tables) {
            const res = await pool.query(`
                SELECT column_name, data_type 
                FROM information_schema.columns 
                WHERE table_name = $1
            `, [table]);
            console.log(`STRUCTURE OF ${table}:`, JSON.stringify(res.rows, null, 2));
        }
    } catch (err) {
        console.error('ERROR:', err.message);
    } finally {
        await pool.end();
    }
}
run();

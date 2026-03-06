const { Pool } = require('pg');
require('dotenv').config();

let pool;

if (process.env.DATABASE_URL) {
    // ── Neon / Cloud PostgreSQL (SSL required) ──────────────────────────────
    pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false },
        max: 10,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 10000,
    });
    console.log('Using cloud PostgreSQL (DATABASE_URL)');
} else {
    // ── Local PostgreSQL ───────────────────────────────────────────────────
    pool = new Pool({
        host: process.env.DB_HOST || 'localhost',
        port: Number(process.env.DB_PORT) || 5432,
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'root',
        database: process.env.DB_NAME || 'cretipoint',
        ssl: false,
    });
    console.log('Using local PostgreSQL');
}

pool.on('error', (err) => {
    console.error('Unexpected DB pool error:', err.message);
});

// ── Schema creation ────────────────────────────────────────────────────────

async function ensureDatabaseExists() {
    // Only needed for local Postgres (cloud DBs already exist)
    if (process.env.DATABASE_URL) return;

    const DB_NAME = process.env.DB_NAME || 'cretipoint';
    const adminPool = new Pool({
        host: process.env.DB_HOST || 'localhost',
        port: Number(process.env.DB_PORT) || 5432,
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'root',
        database: 'postgres',
    });
    try {
        const result = await adminPool.query(
            'SELECT 1 FROM pg_database WHERE datname = $1',
            [DB_NAME]
        );
        if (result.rowCount === 0) {
            await adminPool.query(`CREATE DATABASE "${DB_NAME}"`);
            console.log(`Database ${DB_NAME} created`);
        }
    } finally {
        await adminPool.end();
    }
}

async function ensureTablesExist() {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS users (
            id             SERIAL PRIMARY KEY,
            name           VARCHAR(100)  NOT NULL,
            email          VARCHAR(100)  UNIQUE NOT NULL,
            password       TEXT          NOT NULL,
            roll_number    VARCHAR(50),
            role           VARCHAR(20)   NOT NULL DEFAULT 'student',
            department     VARCHAR(100),
            employee_id    VARCHAR(50),
            mentor_id      INTEGER,
            created_at     TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
        )
    `);

    await pool.query(`
        CREATE TABLE IF NOT EXISTS certificates (
            id                   SERIAL PRIMARY KEY,
            student_id           INTEGER  REFERENCES users(id) ON DELETE CASCADE,
            event_name           VARCHAR(255) NOT NULL,
            organizing_institute VARCHAR(255) NOT NULL,
            event_date           DATE,
            participation_type   VARCHAR(50),
            certificate_type     VARCHAR(100),
            certificate_file     VARCHAR(255),
            description          TEXT,
            status               VARCHAR(50)  DEFAULT 'pending',
            mentor_remark        TEXT,
            points               INTEGER      DEFAULT 0,
            verified_by          INTEGER      REFERENCES users(id),
            verified_at          TIMESTAMP,
            created_at           TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
        )
    `);

    // Safe migrations for existing tables
    const safeAddColumns = [
        `ALTER TABLE users ADD COLUMN IF NOT EXISTS department   VARCHAR(100)`,
        `ALTER TABLE users ADD COLUMN IF NOT EXISTS employee_id  VARCHAR(50)`,
        `ALTER TABLE users ADD COLUMN IF NOT EXISTS mentor_id    INTEGER`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS participation_type VARCHAR(50)`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS description         TEXT`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS certificate_type    VARCHAR(100)`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS certificate_file    VARCHAR(255)`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS status              VARCHAR(50)`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS points              INTEGER`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS mentor_remark       TEXT`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS verified_by         INTEGER`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS verified_at         TIMESTAMP`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP`,
    ];

    for (const sql of safeAddColumns) {
        try { await pool.query(sql); } catch (_) { /* column already exists */ }
    }

    // Ensure correct defaults
    try { await pool.query(`ALTER TABLE certificates ALTER COLUMN status SET DEFAULT 'pending'`); } catch (_) { }
    try { await pool.query(`ALTER TABLE certificates ALTER COLUMN points  SET DEFAULT 0`); } catch (_) { }
}

async function initDatabase() {
    await ensureDatabaseExists();
    await ensureTablesExist();
    await pool.query('SELECT 1'); // connectivity check
    console.log('PostgreSQL Connected');
}

// Expose readiness promise so server waits for DB before listening
const ready = initDatabase().catch((err) => {
    console.error('PostgreSQL init error:', err);
    throw err;
});
pool.ready = ready;

module.exports = pool;

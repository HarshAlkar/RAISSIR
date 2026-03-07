const { Pool } = require('pg');
require('dotenv').config();

let pool;

/**
 * STEP 2 & 3: FIX DATABASE CONNECTION CODE & HANDLE CLOUD + LOCAL
 * We support both DATABASE_URL (Cloud/Neon) and individual DB_* (Local) variables.
 */
const poolConfig = process.env.DATABASE_URL
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false },
        max: 10,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 10000,
    }
    : {
        host: process.env.DB_HOST || 'localhost',
        port: Number(process.env.DB_PORT) || 5432,
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'root',
        database: process.env.DB_NAME || 'cretipoint',
        ssl: false,
    };

pool = new Pool(poolConfig);

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
            role           VARCHAR(50)   NOT NULL DEFAULT 'student',
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
            event_name           VARCHAR(500) NOT NULL,
            organizing_institute VARCHAR(500) NOT NULL,
            event_date           DATE,
            participation_type   VARCHAR(100),
            certificate_type     VARCHAR(100),
            certificate_file     TEXT,
            description          TEXT,
            status               VARCHAR(50)  DEFAULT 'pending',
            mentor_remark        TEXT,
            points               INTEGER      DEFAULT 0,
            verified_by          INTEGER      REFERENCES users(id),
            verified_at          TIMESTAMP,
            created_at           TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
        )
    `);

    await pool.query(`
        CREATE TABLE IF NOT EXISTS admins (
            id         SERIAL PRIMARY KEY,
            name       VARCHAR(100) NOT NULL,
            email      VARCHAR(100) UNIQUE NOT NULL,
            password   TEXT         NOT NULL,
            created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
        )
    `);

    // Safe migrations for existing tables
    const safeAddColumns = [
        `ALTER TABLE users ADD COLUMN IF NOT EXISTS status       VARCHAR(50)  DEFAULT 'active'`,
        `ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image VARCHAR(500) DEFAULT '/uploads/profile/default.png'`,
        `ALTER TABLE users ADD COLUMN IF NOT EXISTS department   VARCHAR(200)`,
        `ALTER TABLE users ADD COLUMN IF NOT EXISTS employee_id  VARCHAR(100)`,
        `ALTER TABLE users ADD COLUMN IF NOT EXISTS mentor_id    INTEGER`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS participation_type VARCHAR(100)`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS description         TEXT`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS certificate_type    VARCHAR(100)`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS certificate_file    TEXT`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS status              VARCHAR(50)`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS points              INTEGER`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS mentor_remark       TEXT`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS verified_by         INTEGER`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS verified_at         TIMESTAMP`,
        `ALTER TABLE certificates ADD COLUMN IF NOT EXISTS created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP`,
        `ALTER TABLE certificates ALTER COLUMN participation_type TYPE VARCHAR(100)`,
        `ALTER TABLE certificates ALTER COLUMN certificate_type   TYPE VARCHAR(100)`,
        `ALTER TABLE certificates ALTER COLUMN event_name         TYPE VARCHAR(500)`,
        `ALTER TABLE certificates ALTER COLUMN organizing_institute TYPE VARCHAR(500)`,
        `ALTER TABLE certificates ALTER COLUMN certificate_file   TYPE TEXT`,
    ];

    for (const sql of safeAddColumns) {
        try { await pool.query(sql); } catch (_) { /* column already exists */ }
    }

    try { await pool.query(`ALTER TABLE certificates ALTER COLUMN status SET DEFAULT 'pending'`); } catch (_) { }
    try { await pool.query(`ALTER TABLE certificates ALTER COLUMN points  SET DEFAULT 0`); } catch (_) { }

    // Seed initial admin if none exists
    const adminCheck = await pool.query('SELECT 1 FROM admins LIMIT 1');
    if (adminCheck.rowCount === 0) {
        const bcrypt = require('bcryptjs');
        const hashedPassword = await bcrypt.hash('admin123', 10);
        await pool.query(
            'INSERT INTO admins (name, email, password) VALUES ($1, $2, $3)',
            ['System Admin', 'admin@certitrack.com', hashedPassword]
        );
        console.log('✅ Initial admin created (admin@certitrack.com / admin123)');
    }
}

/**
 * STEP 5: PREVENT BACKEND CRASH
 * Wrap initialization in try/catch to log error but not kill server if possible.
 */
async function initDatabase(retries = 3) {
    try {
        console.log("Initializing database connection...");
        await ensureDatabaseExists();
        await ensureTablesExist();

        // Connectivity check
        await pool.query('SELECT 1');

        /**
         * STEP 4: ADD DATABASE CONNECTION LOG
         */
        const mode = process.env.DATABASE_URL ? "Cloud (Neon)" : "Local";
        console.log(`✅ Connected to PostgreSQL database [Mode: ${mode}]`);
    } catch (err) {
        if (err.code === 'ENOTFOUND' && retries > 0) {
            console.warn(`⚠️ DNS Error: Could not resolve Neon host. Retrying... (${retries} attempts left)`);
            await new Promise(res => setTimeout(res, 3000));
            return initDatabase(retries - 1);
        }

        console.error('❌ Database Initialization Error:', err.message);

        // If Cloud DB fails, we don't automatically fall back in code (to avoid data inconsistency),
        // but we log it clearly so the user knows what's wrong.
        if (err.code === 'ENOTFOUND') {
            console.warn('⚠️ Final DNS Failure: Node.js cannot find the Neon host. Please check your internet connection or verify your DATABASE_URL in the .env file.');
        } else if (err.code === 'ECONNREFUSED') {
            console.warn('⚠️ Connection Refused: The database server rejected the connection. Check if your DB is running and credentials are correct.');
        }
    }
}

// Expose readiness promise
const ready = initDatabase();
pool.ready = ready;

module.exports = pool;


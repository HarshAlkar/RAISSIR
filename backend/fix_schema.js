require('dotenv').config();
const { Pool } = require('pg');

const neon = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

async function fixSchema() {
    const fixes = [
        // Fix all VARCHAR columns that are too small
        `ALTER TABLE certificates ALTER COLUMN participation_type TYPE VARCHAR(100)`,
        `ALTER TABLE certificates ALTER COLUMN certificate_type   TYPE VARCHAR(100)`,
        `ALTER TABLE certificates ALTER COLUMN status             TYPE VARCHAR(50)`,
        `ALTER TABLE certificates ALTER COLUMN certificate_file   TYPE TEXT`,
        `ALTER TABLE certificates ALTER COLUMN event_name         TYPE VARCHAR(500)`,
        `ALTER TABLE certificates ALTER COLUMN organizing_institute TYPE VARCHAR(500)`,
        `ALTER TABLE users ALTER COLUMN role       TYPE VARCHAR(50)`,
        `ALTER TABLE users ALTER COLUMN department TYPE VARCHAR(200)`,
    ];

    for (const sql of fixes) {
        try {
            await neon.query(sql);
            console.log('✅ ' + sql.substring(0, 80));
        } catch (e) {
            console.log('⚠️  Skip (already ok):', e.message.substring(0, 60));
        }
    }

    // Verify final column sizes
    const result = await neon.query(`
        SELECT column_name, data_type, character_maximum_length
        FROM information_schema.columns
        WHERE table_name = 'certificates'
        ORDER BY ordinal_position
    `);
    console.log('\n=== certificates table columns ===');
    result.rows.forEach(r => {
        console.log(`  ${r.column_name.padEnd(25)} ${r.data_type}(${r.character_maximum_length || '∞'})`);
    });

    await neon.end();
    console.log('\n✅ Schema fix complete!');
}

fixSchema().catch(e => { console.error('ERROR:', e.message); neon.end(); });

const pool = require('./db');
const bcrypt = require('bcryptjs');

async function seed() {
    console.log("🚀 Seeding Admin Account...");

    // Wait for DB to be ready
    if (pool.ready) await pool.ready;

    const name = "System Admin";
    const email = "admin@certitrack.com";
    const password = "admin123"; // You can change this

    try {
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const result = await pool.query(
            'INSERT INTO admins (name, email, password) VALUES ($1, $2, $3) ON CONFLICT (email) DO NOTHING RETURNING id',
            [name, email, hashedPassword]
        );

        if (result.rows.length > 0) {
            console.log("✅ Admin created successfully!");
            console.log("--------------------------------");
            console.log("Email:    admin@certitrack.com");
            console.log("Password: admin123");
            console.log("--------------------------------");
        } else {
            console.log("ℹ️ Admin already exists with this email.");
        }
    } catch (err) {
        console.error("❌ Seeding failed:", err.message);
    } finally {
        process.exit();
    }
}

seed();

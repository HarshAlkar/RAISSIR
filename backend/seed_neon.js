require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const neon = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

async function seed() {
    const studentPass = await bcrypt.hash('student123', 10);
    const mentorPass = await bcrypt.hash('mentor123', 10);

    // Seed student account
    await neon.query(`
        INSERT INTO users (name, email, password, role, roll_number, department)
        VALUES ($1, $2, $3, 'student', 'VU4F2324035', 'Information Technology')
        ON CONFLICT (email) DO UPDATE SET password=$3, role='student', name=$1
    `, ['Siddhesh Student', 'student@pvppcoe.ac.in', studentPass]);

    // Seed mentor account
    await neon.query(`
        INSERT INTO users (name, email, password, role, department, employee_id)
        VALUES ($1, $2, $3, 'mentor', 'Information Technology', 'EMP001')
        ON CONFLICT (email) DO UPDATE SET password=$3, role='mentor', name=$1
    `, ['Dr Rahul Sharma', 'mentor@pvppcoe.ac.in', mentorPass]);

    // Also migrate local user: Harsh (mentor)
    const harshMentorPass = await bcrypt.hash('mentor123', 10);
    await neon.query(`
        INSERT INTO users (name, email, password, role, department, employee_id)
        VALUES ($1, $2, $3, 'mentor', 'Information Technology', 'EMP002')
        ON CONFLICT (email) DO UPDATE SET password=$3, role='mentor', name=$1
    `, ['Harsh', 'harsh@pvppcoe.ac.in', harshMentorPass]);

    const harshStudentPass = await bcrypt.hash('student123', 10);
    await neon.query(`
        INSERT INTO users (name, email, password, role, roll_number, department)
        VALUES ($1, $2, $3, 'student', 'VU4F2324001', 'Information Technology')
        ON CONFLICT (email) DO UPDATE SET password=$3, role='student', name=$1
    `, ['Harsh Alkar', 'harsh@gmail.com', harshStudentPass]);

    const rows = await neon.query('SELECT id, name, email, role FROM users ORDER BY role, id');
    console.log('\n========== NEON DB USERS ==========');
    rows.rows.forEach(r => {
        console.log(`ID:${r.id} | ${r.role.toUpperCase().padEnd(7)} | ${r.email}`);
    });
    console.log('====================================\n');

    await neon.end();
}

seed().catch(e => {
    console.error('ERROR:', e.message);
    neon.end();
});

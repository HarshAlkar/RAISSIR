require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const pool = require('./db');
const requireRole = require('./middleware/roleMiddleware');

process.on('uncaughtException', (err) => {
    console.error('Uncaught Exception:', err);
});

process.on('unhandledRejection', (err) => {
    console.error('Unhandled Rejection:', err);
});

const app = express();
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Authentication middleware
const auth = (req, res, next) => {
    let token = req.header('Authorization');
    if (!token) {
        return res.status(401).json({ msg: 'No token provided, authorization denied' });
    }

    if (token.startsWith('Bearer ')) {
        token = token.slice(7, token.length);
    }

    try {
        const secret = process.env.JWT_SECRET || 'super_secret_key';
        const decoded = jwt.verify(token, secret);
        req.user = decoded;
        next();
    } catch (err) {
        console.error("JWT Verification Error:", err.message);
        return res.status(401).json({ msg: 'Token is not valid' });
    }
};

// Multer storage for image upload
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/certificates/')
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9)
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname))
    }
});
const upload = multer({ storage: storage });

const fs = require('fs');
const uploadDir = 'uploads/certificates/';
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// ----- AUTH APIs -----

app.post('/api/auth/register', async (req, res) => {
    try {
        const { name, email, password, role = 'student', roll_number, department, mentor_id, employee_id } = req.body;

        const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
        if (existing.rows.length > 0) {
            return res.status(400).json({ msg: 'User already exists' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const insertResult = await pool.query(
            `INSERT INTO users (name, email, password, role, roll_number, department, mentor_id, employee_id)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
             RETURNING id, name, email, role, roll_number, department, mentor_id, employee_id`,
            [name, email, hashedPassword, role, roll_number, department || null, mentor_id || null, employee_id || null]
        );

        const user = insertResult.rows[0];

        res.status(201).json({
            msg: 'User registered successfully',
            user,
        });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

app.post('/api/auth/mentor-signup', async (req, res) => {
    try {
        const { name, email, password, department, employee_id } = req.body;

        if (!name || !email || !password || !department || !employee_id) {
            return res.status(400).json({ msg: 'Missing required fields' });
        }

        const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
        if (existing.rows.length > 0) {
            return res.status(400).json({ msg: 'User already exists' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        await pool.query(
            `INSERT INTO users (name, email, password, department, employee_id, role)
             VALUES ($1, $2, $3, $4, $5, 'mentor')`,
            [name, email, hashedPassword, department, employee_id]
        );

        res.status(201).json({ message: 'Mentor account created successfully' });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        const userResult = await pool.query(
            'SELECT id, name, email, password, role, roll_number FROM users WHERE email = $1',
            [email]
        );

        if (userResult.rows.length === 0) {
            return res.status(400).json({ msg: 'Invalid credentials' });
        }

        const user = userResult.rows[0];
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ msg: 'Invalid credentials' });
        }

        const payload = { id: user.id, role: user.role ? user.role.toLowerCase() : 'student' };
        const secret = process.env.JWT_SECRET || 'super_secret_key';
        const token = jwt.sign(payload, secret, { expiresIn: '7d' });

        res.json({
            token,
            user: {
                id: user.id,
                email: user.email,
                role: user.role ? user.role.toLowerCase() : 'student',
                name: user.name,
                roll_number: user.roll_number,
            },
        });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/auth/profile', auth, async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT id, name, email, role, roll_number, department FROM users WHERE id = $1',
            [req.user.id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ msg: 'User not found' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// Token validation endpoint — Flutter calls this on startup to check if stored token is still valid
// Supports both /api/auth/verify-token and /api/auth/verify
async function verifyTokenHandler(req, res) {
    try {
        const result = await pool.query(
            'SELECT id, name, email, role, roll_number, department FROM users WHERE id = $1',
            [req.user.id]
        );
        if (result.rows.length === 0) {
            return res.status(401).json({ valid: false, msg: 'User not found' });
        }
        res.json({ valid: true, user: result.rows[0] });
    } catch (err) {
        console.error('verify-token error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
}
app.get('/api/auth/verify-token', auth, verifyTokenHandler);
app.get('/api/auth/verify', auth, verifyTokenHandler);


// Get list of mentors for registration dropdown
app.get('/api/mentors', async (req, res) => {
    try {
        const result = await pool.query('SELECT id, name, department FROM users WHERE role = $1 ORDER BY name ASC', ['mentor']);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

// ----- STUDENT APIs -----

app.get('/api/student/profile', auth, requireRole('student'), async (req, res) => {
    try {
        const student = await pool.query(
            'SELECT id, name, email, roll_number, department FROM users WHERE id = $1',
            [req.user.id]
        );
        if (student.rows.length === 0) {
            return res.status(404).json({ msg: 'Student not found' });
        }
        const studentData = { ...student.rows[0], role: 'student' };
        res.json(studentData);
    } catch (err) {
        console.error('Student profile error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/student/dashboard', auth, requireRole('student'), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                u.name,
                u.roll_number AS student_id,
                COALESCE((SELECT COUNT(*) FROM certificates c WHERE c.student_id = u.id), 0)::int AS total_uploaded,
                COALESCE((SELECT COUNT(*) FROM certificates c WHERE c.student_id = u.id AND c.status = 'approved'), 0)::int AS approved,
                COALESCE((SELECT COUNT(*) FROM certificates c WHERE c.student_id = u.id AND c.status = 'pending'), 0)::int AS pending,
                COALESCE((SELECT SUM(c.points) FROM certificates c WHERE c.student_id = u.id), 0)::int AS credits
             FROM users u
             WHERE u.id = $1`,
            [req.user.id]
        );

        if (result.rows.length === 0) {
            return res.json({
                name: null,
                student_id: null,
                total_uploaded: 0,
                approved: 0,
                pending: 0,
                credits: 0,
                totalUploaded: 0,
            });
        }

        const row = result.rows[0];

        res.json({
            name: row.name,
            student_id: row.student_id,
            total_uploaded: Number.isFinite(row.total_uploaded) ? row.total_uploaded : parseInt(row.total_uploaded, 10) || 0,
            approved: Number.isFinite(row.approved) ? row.approved : parseInt(row.approved, 10) || 0,
            pending: Number.isFinite(row.pending) ? row.pending : parseInt(row.pending, 10) || 0,
            credits: Number.isFinite(row.credits) ? row.credits : parseInt(row.credits, 10) || 0,
            // camelCase for existing Flutter client
            totalUploaded: Number.isFinite(row.total_uploaded) ? row.total_uploaded : parseInt(row.total_uploaded, 10) || 0,
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/student/recent-certificates', auth, requireRole('student'), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT 
                event_name AS "eventName",
                organizing_institute AS "organizingInstitute",
                TO_CHAR(event_date, 'DD Mon YYYY') AS "eventDate",
                COALESCE(participation_type, '') AS "participationType",
                status AS "status"
             FROM certificates
             WHERE student_id = $1
             ORDER BY created_at DESC
             LIMIT 3`,
            [req.user.id]
        );

        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

// ── Upload Certificate ──────────────────────────────────────────────────────
app.post('/api/student/upload-certificate', auth, requireRole('student'), upload.single('certificate_file'), async (req, res) => {
    try {
        const studentId = req.user.id;

        const {
            participation_type,
            event_name,
            organizing_institute,
            event_date,
            certificate_type,
            description,
        } = req.body;

        // Validate required fields
        if (!event_name || !organizing_institute || !event_date || !certificate_type || !participation_type) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        if (!req.file) {
            return res.status(400).json({ error: 'Certificate file is required' });
        }

        // Convert date from MM/DD/YYYY (Flutter format) to YYYY-MM-DD (PostgreSQL)
        let formattedDate = event_date;
        if (/^\d{2}\/\d{2}\/\d{4}$/.test(event_date)) {
            const [month, day, year] = event_date.split('/');
            formattedDate = `${year}-${month}-${day}`;
        }

        const filePath = req.file.filename; // stored filename in uploads/certificates/

        const result = await pool.query(
            `INSERT INTO certificates
                (student_id, event_name, organizing_institute, event_date,
                 certificate_type, participation_type, certificate_file,
                 status, points, mentor_remark, created_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending', 0, NULL, NOW())
             RETURNING id`,
            [
                studentId,
                event_name,
                organizing_institute,
                formattedDate,
                certificate_type,
                participation_type,
                filePath,
            ]
        );

        console.log(`Certificate uploaded by student ${studentId}: id=${result.rows[0].id}`);

        res.status(201).json({
            message: 'Certificate uploaded successfully. Awaiting mentor verification.',
            certificateId: result.rows[0].id,
        });
    } catch (err) {
        console.error('Upload certificate error:', err.message);
        res.status(500).json({ error: 'Server error: ' + err.message });
    }
});

// Simple DB test endpoint
app.get('/api/test-db', async (req, res) => {
    try {
        const result = await pool.query('SELECT NOW()');
        res.json({ now: result.rows[0].now });
    } catch (err) {
        console.error('DB test error:', err);
        res.status(500).json({ error: 'DB test failed', details: err.message });
    }
});

// Simple API health test endpoint
app.get('/api/test', (req, res) => {
    res.json({ message: 'Backend working' });
});

// ----- MENTOR APIs -----

app.get('/api/mentor/profile', auth, requireRole('mentor'), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, name, email, department, employee_id, role
             FROM users WHERE id = $1`,
            [req.user.id]
        );
        if (result.rows.length === 0) {
            console.warn(`Mentor profile not found: user_id=${req.user.id} (token may be stale)`);
            return res.status(404).json({
                msg: 'Mentor profile not found. Please logout and register again.',
            });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error('Mentor profile error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/mentor/dashboard', auth, requireRole('mentor'), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                u.name AS mentor_name,
                COALESCE(u.department, '') AS department,
                COALESCE(COUNT(DISTINCT s.id), 0)::int AS students,
                COALESCE(COUNT(c.id) FILTER (WHERE c.status = 'pending'), 0)::int AS pending,
                COALESCE(COUNT(c.id) FILTER (WHERE c.status = 'approved'), 0)::int AS approved,
                COALESCE(COUNT(c.id) FILTER (WHERE c.status = 'rejected'), 0)::int AS rejected
             FROM users u
             LEFT JOIN users s
               ON s.mentor_id = u.id AND s.role = 'student'
             LEFT JOIN certificates c
               ON c.student_id = s.id
             WHERE u.id = $1
             GROUP BY u.id`,
            [req.user.id]
        );

        if (result.rows.length === 0) {
            return res.json({
                mentor_name: null,
                department: '',
                students: 0,
                pending: 0,
                approved: 0,
                rejected: 0,
            });
        }

        const row = result.rows[0];
        res.json({
            mentor_name: row.mentor_name,
            department: row.department,
            students: row.students,
            pending: row.pending,
            approved: row.approved,
            rejected: row.rejected,
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/mentor/activity', auth, requireRole('mentor'), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                s.name AS student_name,
                c.event_name AS event_name,
                TO_CHAR(c.created_at, 'YYYY-MM-DD') AS date,
                c.status AS status
             FROM certificates c
             JOIN users s ON s.id = c.student_id
             WHERE s.mentor_id = $1
             ORDER BY c.created_at DESC
             LIMIT 10`,
            [req.user.id]
        );

        res.json({ activity: result.rows });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/mentor/verification-analytics', auth, requireRole('mentor'), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                COALESCE(COUNT(*) FILTER (WHERE verified_by = $1), 0)::int AS reviewed,
                COALESCE(COUNT(*) FILTER (WHERE verified_by = $1 AND status = 'approved'), 0)::int AS approved,
                COALESCE(COUNT(*) FILTER (WHERE verified_by = $1 AND status = 'rejected'), 0)::int AS rejected,
                COALESCE(COUNT(*) FILTER (WHERE status = 'pending'), 0)::int AS pending
             FROM certificates`,
            [req.user.id]
        );

        const row = result.rows[0] || { reviewed: 0, approved: 0, rejected: 0, pending: 0 };
        const reviewed = row.reviewed || 0;
        const approved = row.approved || 0;
        const rejected = row.rejected || 0;
        const pending = row.pending || 0;
        const completed = approved + rejected;
        const progress = reviewed > 0 ? Math.round((completed / reviewed) * 100) : 0;

        res.json({
            reviewed,
            approved,
            rejected,
            pending,
            progress,
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/mentor/monthly-verification', auth, requireRole('mentor'), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                DATE_TRUNC('week', verified_at) AS week,
                COUNT(*)::int AS total
             FROM certificates
             WHERE verified_by = $1 AND verified_at IS NOT NULL
             GROUP BY week
             ORDER BY week`,
            [req.user.id]
        );

        // Map chronological weeks to W1..W4 labels
        const weekly = result.rows.map((row, index) => ({
            week: `W${index + 1}`,
            count: row.total || 0,
        }));

        res.json({ weekly });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/mentor/recent-activity', auth, requireRole('mentor'), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                u.name AS student_name,
                c.event_name,
                c.status,
                c.mentor_remark
             FROM certificates c
             JOIN users u ON u.id = c.student_id
             WHERE c.verified_by = $1
             ORDER BY c.verified_at DESC NULLS LAST, c.created_at DESC
             LIMIT 10`,
            [req.user.id]
        );

        res.json({ activity: result.rows });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/mentor/students', auth, requireRole('mentor'), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                u.id,
                u.name,
                u.roll_number,
                COALESCE(u.department, '') AS department,
                COALESCE(COUNT(c.id), 0)::int AS submitted,
                COALESCE(COUNT(*) FILTER (WHERE c.status = 'approved'), 0)::int AS approved,
                COALESCE(COUNT(*) FILTER (WHERE c.status = 'pending'), 0)::int AS pending
             FROM users u
             LEFT JOIN certificates c ON u.id = c.student_id
             WHERE u.role = 'student' AND u.mentor_id = $1
             GROUP BY u.id
             ORDER BY u.name ASC`,
            [req.user.id]
        );

        res.json({ students: result.rows });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/mentor/student-certificates/:studentId', auth, requireRole('mentor'), async (req, res) => {
    try {
        const studentId = Number(req.params.studentId);
        if (!Number.isFinite(studentId)) {
            return res.status(400).json({ msg: 'Invalid student id' });
        }

        // Ensure mentor can only access their own assigned students
        const allowed = await pool.query(
            `SELECT id FROM users WHERE id = $1 AND role = 'student' AND mentor_id = $2`,
            [studentId, req.user.id]
        );
        if (allowed.rowCount === 0) {
            return res.status(404).json({ msg: 'Student not found' });
        }

        const result = await pool.query(
            `SELECT
                id,
                student_id,
                event_name,
                organizing_institute,
                event_date,
                certificate_type,
                certificate_file,
                status,
                points,
                mentor_remark,
                created_at
             FROM certificates
             WHERE student_id = $1
             ORDER BY created_at DESC`,
            [studentId]
        );

        res.json({ certificates: result.rows });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/mentor/certificate/:certificateId', auth, requireRole('mentor'), async (req, res) => {
    try {
        const certificateId = Number(req.params.certificateId);
        if (!Number.isFinite(certificateId)) return res.status(400).json({ msg: 'Invalid certificate id' });

        const result = await pool.query(
            `SELECT
                c.id, c.student_id, u.name as student_name, u.roll_number,
                c.event_name, c.organizing_institute as issuer, TO_CHAR(c.event_date, 'YYYY-MM-DD') as date,
                c.participation_type as category, c.certificate_type as type,
                c.certificate_file as image, c.status, c.points, c.mentor_remark
             FROM certificates c
             JOIN users u ON c.student_id = u.id
             WHERE c.id = $1 AND u.mentor_id = $2`,
            [certificateId, req.user.id]
        );

        if (result.rowCount === 0) return res.status(404).json({ msg: 'Certificate not found' });
        res.json({ certificate: result.rows[0] });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.post('/api/mentor/approve-certificate', auth, requireRole('mentor'), async (req, res) => {
    try {
        const { certificate_id } = req.body;
        if (!certificate_id) return res.status(400).json({ msg: 'Missing certificate_id' });

        // Get certificate to determine points based on participation_type
        const certResult = await pool.query(
            `SELECT c.id, c.participation_type FROM certificates c
             JOIN users u ON c.student_id = u.id
             WHERE c.id = $1 AND u.mentor_id = $2`,
            [certificate_id, req.user.id]
        );

        if (certResult.rowCount === 0) return res.status(404).json({ msg: 'Certificate not found or unauthorized' });

        const cert = certResult.rows[0];
        const participationType = (cert.participation_type || '').toLowerCase();
        let points = 0;
        if (participationType.includes('inside')) points = 1;
        else if (participationType.includes('outside')) points = 5;
        // Adjust points logic if needed. As specified: inside = 1, outside = 5. Assume it contains the word.

        await pool.query(
            `UPDATE certificates
             SET status = 'approved', points = $1, verified_by = $2, verified_at = NOW()
             WHERE id = $3`,
            [points, req.user.id, certificate_id]
        );

        res.json({ msg: 'Certificate approved successfully', points });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.post('/api/mentor/reject-certificate', auth, requireRole('mentor'), async (req, res) => {
    try {
        const { certificate_id, remark } = req.body;
        if (!certificate_id) return res.status(400).json({ msg: 'Missing certificate_id' });

        const certResult = await pool.query(
            `SELECT c.id FROM certificates c
             JOIN users u ON c.student_id = u.id
             WHERE c.id = $1 AND u.mentor_id = $2`,
            [certificate_id, req.user.id]
        );

        if (certResult.rowCount === 0) return res.status(404).json({ msg: 'Certificate not found or unauthorized' });

        await pool.query(
            `UPDATE certificates
             SET status = 'rejected', mentor_remark = $1, verified_by = $2, verified_at = NOW(), points = 0
             WHERE id = $3`,
            [remark || null, req.user.id, certificate_id]
        );

        res.json({ msg: 'Certificate rejected successfully' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.get('/api/student/certificates', auth, requireRole('student'), async (req, res) => {
    try {
        const status = typeof req.query.status === 'string' ? req.query.status.trim().toLowerCase() : undefined;
        let query = 'SELECT id, student_id, event_name, organizing_institute, event_date, certificate_type, certificate_file, status, points, mentor_remark, created_at FROM certificates WHERE student_id = $1';
        let values = [req.user.id];

        if (status) {
            query += ' AND status = $2';
            values.push(status);
        }

        query += ' ORDER BY created_at DESC';

        let certs = [];
        try {
            const result = await pool.query(query, values);
            certs = result.rows;
        } catch (dbErr) {
            console.error("DB Error. Using fallback data:", dbErr.message);
            // Fallback mock data
            certs = [
                {
                    "id": 1,
                    "event_name": "National Tech Symposium",
                    "organizing_institute": "Tech Dept",
                    "event_date": "12 Oct 2023",
                    "certificate_type": "Seminar",
                    "certificate_file": null,
                    "status": "approved",
                    "points": 5,
                    "mentor_remark": null
                },
                {
                    "id": 2,
                    "event_name": "Workshop on AI",
                    "organizing_institute": "AI Lab",
                    "event_date": "05 Nov 2023",
                    "certificate_type": "Workshop",
                    "certificate_file": null,
                    "status": "pending",
                    "points": 0,
                    "mentor_remark": null
                },
                {
                    "id": 3,
                    "event_name": "Leadership Summit",
                    "organizing_institute": "Business Dept",
                    "event_date": "20 Sep 2023",
                    "certificate_type": "Conference",
                    "certificate_file": null,
                    "status": "rejected",
                    "points": 0,
                    "mentor_remark": "Image not clear. Please re-upload."
                }
            ];

            if (status) {
                certs = certs.filter(c => c.status === status);
            }
        }

        res.json({ certificates: certs });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to load certificates.' });
    }
});

app.post('/api/student/upload-certificate', auth, requireRole('student'), upload.single('certificate_file'), async (req, res) => {
    try {
        const { event_name, organizing_institute, event_date, participation_type, certificate_type, description, roll_number } = req.body;
        const certificate_file = req.file ? req.file.path.replace(/\\/g, '/') : null;
        const status = 'pending';
        const points = 0; // points are awarded only after mentor approval

        const insertResult = await pool.query(
            `INSERT INTO certificates
             (student_id, event_name, organizing_institute, event_date, participation_type, certificate_type, certificate_file, description, status, points)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'pending', 0)
             RETURNING id, student_id, event_name, organizing_institute, event_date, participation_type, certificate_type, certificate_file, description, status, points, mentor_remark, created_at`,
            [
                req.user.id,
                event_name,
                organizing_institute,
                event_date || null,
                participation_type || null,
                certificate_type || null,
                certificate_file,
                description || null,
            ]
        );

        res.status(201).json({
            msg: 'Certificate uploaded successfully. Waiting for mentor verification.',
            certificate: insertResult.rows[0],
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to upload certificate. Please try again.' });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN APIS  (do NOT touch anything above this comment)
// ─────────────────────────────────────────────────────────────────────────────

// Admin auth middleware — only role=admin JWTs pass
const adminAuth = (req, res, next) => {
    let token = req.header('Authorization');
    if (!token) return res.status(401).json({ msg: 'No token, authorization denied' });
    if (token.startsWith('Bearer ')) token = token.slice(7);
    try {
        const secret = process.env.JWT_SECRET || 'super_secret_key';
        const decoded = jwt.verify(token, secret);
        if (decoded.role !== 'admin') {
            return res.status(403).json({ msg: 'Access denied: admins only' });
        }
        req.user = decoded;
        next();
    } catch (err) {
        return res.status(401).json({ msg: 'Token is not valid' });
    }
};

// POST /api/admin/login
app.post('/api/admin/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        if (!email || !password) return res.status(400).json({ msg: 'Email and password are required' });

        const result = await pool.query('SELECT * FROM admins WHERE email = $1', [email]);
        if (result.rows.length === 0) return res.status(400).json({ msg: 'Invalid credentials' });

        const admin = result.rows[0];
        const isMatch = await bcrypt.compare(password, admin.password);
        if (!isMatch) return res.status(400).json({ msg: 'Invalid credentials' });

        const secret = process.env.JWT_SECRET || 'super_secret_key';
        const token = jwt.sign({ id: admin.id, role: 'admin', name: admin.name }, secret, { expiresIn: '7d' });

        res.json({
            token,
            user: { id: admin.id, name: admin.name, email: admin.email, role: 'admin' },
        });
    } catch (err) {
        console.error('Admin login error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// POST /api/admin/seed  — create the first admin account (run once)
app.post('/api/admin/seed', async (req, res) => {
    try {
        const { name, email, password, secret_key } = req.body;
        if (secret_key !== (process.env.ADMIN_SEED_KEY || 'certitrack_admin_2024')) {
            return res.status(403).json({ msg: 'Invalid secret key' });
        }
        const existing = await pool.query('SELECT id FROM admins WHERE email = $1', [email]);
        if (existing.rows.length > 0) return res.status(400).json({ msg: 'Admin already exists' });

        const salt = await bcrypt.genSalt(10);
        const hashed = await bcrypt.hash(password, salt);
        await pool.query('INSERT INTO admins (name, email, password) VALUES ($1, $2, $3)', [name, email, hashed]);
        res.status(201).json({ msg: 'Admin created successfully' });
    } catch (err) {
        console.error('Admin seed error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/admin/dashboard
app.get('/api/admin/dashboard', adminAuth, async (req, res) => {
    try {
        const [studentsRes, mentorsRes, certsRes, pendingRes] = await Promise.all([
            pool.query("SELECT COUNT(*) FROM users WHERE role = 'student'"),
            pool.query("SELECT COUNT(*) FROM users WHERE role = 'mentor'"),
            pool.query("SELECT COUNT(*) FROM certificates"),
            pool.query("SELECT COUNT(*) FROM certificates WHERE status = 'pending'"),
        ]);

        res.json({
            total_students: parseInt(studentsRes.rows[0].count, 10),
            total_mentors: parseInt(mentorsRes.rows[0].count, 10),
            total_certificates: parseInt(certsRes.rows[0].count, 10),
            pending_verifications: parseInt(pendingRes.rows[0].count, 10),
        });
    } catch (err) {
        console.error('Admin dashboard error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/admin/recent-activity
app.get('/api/admin/recent-activity', adminAuth, async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                u.name AS student_name,
                c.event_name AS event,
                c.status,
                c.verified_at,
                c.created_at
             FROM certificates c
             JOIN users u ON u.id = c.student_id
             WHERE c.status IN ('approved', 'rejected')
             ORDER BY COALESCE(c.verified_at, c.created_at) DESC
             LIMIT 10`
        );
        res.json(result.rows);
    } catch (err) {
        console.error('Admin recent-activity error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/admin/students?search=alice
app.get('/api/admin/students', adminAuth, async (req, res) => {
    try {
        const search = req.query.search ? `%${req.query.search}%` : null;

        let query = `
            SELECT
                u.id,
                u.name,
                COALESCE(u.roll_number, '') AS roll_number,
                COALESCE(u.department, '') AS department,
                COALESCE(u.status, 'active') AS status,
                COALESCE(u.profile_image, '/uploads/profile/default.png') AS profile_image,
                COALESCE(COUNT(c.id), 0)::int AS submitted,
                COALESCE(COUNT(c.id) FILTER (WHERE c.status = 'approved'), 0)::int AS approved,
                COALESCE(COUNT(c.id) FILTER (WHERE c.status = 'pending'), 0)::int AS pending,
                COALESCE(COUNT(c.id) FILTER (WHERE c.status = 'rejected'), 0)::int AS rejected
             FROM users u
             LEFT JOIN certificates c ON u.id = c.student_id
             WHERE u.role = 'student'
        `;

        const values = [];
        if (search) {
            query += ` AND (u.name ILIKE $1 OR u.roll_number ILIKE $1)`;
            values.push(search);
        }

        query += ` GROUP BY u.id ORDER BY u.name ASC`;

        const result = await pool.query(query, values);
        res.json({ students: result.rows });
    } catch (err) {
        console.error('Admin students error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// PATCH /api/admin/student-status/:id
app.patch('/api/admin/student-status/:id', adminAuth, async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        if (!['active', 'disabled'].includes(status)) {
            return res.status(400).json({ msg: 'Invalid status' });
        }

        const result = await pool.query(
            'UPDATE users SET status = $1 WHERE id = $2 AND role = $3 RETURNING id',
            [status, id, 'student']
        );

        if (result.rows.length === 0) return res.status(404).json({ msg: 'Student not found' });
        res.json({ msg: `Student account ${status} successfully` });
    } catch (err) {
        console.error('Admin student status update error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// POST /api/admin/assign-mentor
app.post('/api/admin/assign-mentor', adminAuth, async (req, res) => {
    try {
        const { student_id, mentor_id } = req.body;
        if (!student_id || !mentor_id) return res.status(400).json({ msg: 'IDs are required' });

        // Verify mentor exists and is actually a mentor
        const mentorCheck = await pool.query('SELECT id FROM users WHERE id = $1 AND role = $2', [mentor_id, 'mentor']);
        if (mentorCheck.rows.length === 0) return res.status(400).json({ msg: 'Invalid mentor ID' });

        await pool.query('UPDATE users SET mentor_id = $1 WHERE id = $2 AND role = $3', [mentor_id, student_id, 'student']);
        res.json({ msg: 'Mentor assigned successfully' });
    } catch (err) {
        console.error('Admin assign mentor error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/admin/student-certificates/:studentId
app.get('/api/admin/student-certificates/:studentId', adminAuth, async (req, res) => {
    try {
        const { studentId } = req.params;
        const result = await pool.query(
            `SELECT
                id,
                event_name,
                organizing_institute,
                TO_CHAR(event_date, 'DD Mon YYYY') AS event_date,
                participation_type,
                certificate_type,
                status,
                points,
                COALESCE(mentor_remark, '') AS mentor_remark,
                created_at
             FROM certificates
             WHERE student_id = $1
             ORDER BY created_at DESC`,
            [studentId]
        );
        res.json({ certificates: result.rows });
    } catch (err) {
        console.error('Admin student certificates error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/admin/mentors?search=smith&filter=active
app.get('/api/admin/mentors', adminAuth, async (req, res) => {
    try {
        const { search, filter } = req.query;
        let query = `
            SELECT
                u.id,
                u.name,
                COALESCE(u.department, '') AS department,
                COALESCE(u.employee_id, '') AS employee_id,
                COALESCE(u.status, 'active') AS status,
                COALESCE(u.profile_image, '/uploads/profile/default.png') AS profile_image,
                COUNT(DISTINCT s.id)::int AS students_assigned,
                COUNT(c.id)::int AS reviewed,
                COUNT(CASE WHEN c.status='approved' THEN 1 END)::int AS approved,
                COUNT(CASE WHEN c.status='rejected' THEN 1 END)::int AS rejected
            FROM users u
            LEFT JOIN users s ON s.mentor_id = u.id AND s.role = 'student'
            LEFT JOIN certificates c ON c.verified_by = u.id
            WHERE u.role = 'mentor'
        `;

        const values = [];
        let valueCount = 1;

        if (search) {
            query += ` AND (u.name ILIKE $${valueCount} OR u.department ILIKE $${valueCount} OR u.employee_id ILIKE $${valueCount})`;
            values.push(`%${search}%`);
            valueCount++;
        }

        if (filter === 'active') {
            query += ` AND u.status = 'active'`;
        } else if (filter === 'pending') {
            // Logic for 'pending' mentors if applicable, or just inactive
            query += ` AND u.status = 'inactive'`;
        }

        query += ` GROUP BY u.id ORDER BY u.name ASC`;

        const result = await pool.query(query, values);
        res.json({ mentors: result.rows });
    } catch (err) {
        console.error('Admin mentors error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/admin/mentor-students/:mentorId
app.get('/api/admin/mentor-students/:mentorId', adminAuth, async (req, res) => {
    try {
        const { mentorId } = req.params;
        const result = await pool.query(
            `SELECT id, name, roll_number, department, status, profile_image 
             FROM users 
             WHERE mentor_id = $1 AND role = 'student'
             ORDER BY name ASC`,
            [mentorId]
        );
        res.json({ students: result.rows });
    } catch (err) {
        console.error('Admin mentor students error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// POST /api/admin/reassign-students
app.post('/api/admin/reassign-students', adminAuth, async (req, res) => {
    try {
        const { mentor_id, student_ids } = req.body;
        if (!mentor_id || !Array.isArray(student_ids) || student_ids.length === 0) {
            return res.status(400).json({ msg: 'Mentor ID and Student IDs array are required' });
        }

        // Verify mentor exists
        const mentorCheck = await pool.query('SELECT id FROM users WHERE id = $1 AND role = $2', [mentor_id, 'mentor']);
        if (mentorCheck.rows.length === 0) return res.status(400).json({ msg: 'Invalid mentor ID' });

        await pool.query(
            'UPDATE users SET mentor_id = $1 WHERE id = ANY($2) AND role = $3',
            [mentor_id, student_ids, 'student']
        );

        res.json({ msg: `${student_ids.length} students reassigned successfully` });
    } catch (err) {
        console.error('Admin reassign error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// PATCH /api/admin/mentor-status/:id
app.patch('/api/admin/mentor-status/:id', adminAuth, async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        if (!['active', 'inactive'].includes(status)) {
            return res.status(400).json({ msg: 'Invalid status' });
        }

        const result = await pool.query(
            'UPDATE users SET status = $1 WHERE id = $2 AND role = $3 RETURNING id',
            [status, id, 'mentor']
        );

        if (result.rows.length === 0) return res.status(404).json({ msg: 'Mentor not found' });
        res.json({ msg: `Mentor account ${status} successfully` });
    } catch (err) {
        console.error('Admin mentor status error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// POST /api/admin/register-mentor
app.post('/api/admin/register-mentor', adminAuth, async (req, res) => {
    try {
        const { name, email, department, employee_id, password } = req.body;
        if (!name || !email || !password) {
            return res.status(400).json({ msg: 'Name, email, and password are required' });
        }

        const userExists = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
        if (userExists.rows.length > 0) return res.status(400).json({ msg: 'User already exists' });

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        await pool.query(
            `INSERT INTO users (name, email, password, department, employee_id, role, status) 
             VALUES ($1, $2, $3, $4, $5, 'mentor', 'active')`,
            [name, email, hashedPassword, department, employee_id]
        );

        res.json({ msg: 'Mentor registered successfully' });
    } catch (err) {
        console.error('Admin register mentor error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/admin/certificates?status=approved|pending|rejected
app.get('/api/admin/certificates', adminAuth, async (req, res) => {
    try {
        const status = typeof req.query.status === 'string' ? req.query.status.trim().toLowerCase() : null;
        const validStatuses = ['approved', 'pending', 'rejected'];

        let query = `
            SELECT
                c.id,
                u.name AS student_name,
                COALESCE(u.roll_number, '') AS roll_number,
                COALESCE(u.department, '') AS department,
                c.event_name,
                c.organizing_institute,
                TO_CHAR(c.event_date, 'DD Mon YYYY') AS event_date,
                COALESCE(c.participation_type, '') AS participation_type,
                COALESCE(c.certificate_type, '') AS certificate_type,
                c.status,
                c.points,
                COALESCE(c.mentor_remark, '') AS mentor_remark,
                c.created_at
             FROM certificates c
             JOIN users u ON u.id = c.student_id
        `;
        const values = [];
        if (status && validStatuses.includes(status)) {
            query += ' WHERE c.status = $1';
            values.push(status);
        }
        query += ' ORDER BY c.created_at DESC';

        const result = await pool.query(query, values);
        res.json({ certificates: result.rows });
    } catch (err) {
        console.error('Admin certificates error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/admin/analytics
app.get('/api/admin/analytics', adminAuth, async (req, res) => {
    try {
        const [totalRes, approvedRes, monthlyRes] = await Promise.all([
            pool.query("SELECT COUNT(*) FROM certificates"),
            pool.query("SELECT COUNT(*) FROM certificates WHERE status = 'approved'"),
            pool.query(`
                SELECT
                    TO_CHAR(DATE_TRUNC('month', created_at), 'Mon') AS month,
                    COUNT(*)::int AS uploads
                FROM certificates
                WHERE created_at >= NOW() - INTERVAL '6 months'
                GROUP BY DATE_TRUNC('month', created_at)
                ORDER BY DATE_TRUNC('month', created_at) ASC
            `),
        ]);

        const total = parseInt(totalRes.rows[0].count, 10);
        const approved = parseInt(approvedRes.rows[0].count, 10);
        const approvalRate = total > 0 ? Math.round((approved / total) * 100) : 0;

        res.json({
            total_certificates: total,
            total_approved: approved,
            approval_rate: approvalRate,
            monthly_uploads: monthlyRes.rows,
        });
    } catch (err) {
        console.error('Admin analytics error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/admin/student/:id  — single student detail with mentor name + cert stats
app.get('/api/admin/student/:id', adminAuth, async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            `SELECT
                u.id,
                u.name,
                COALESCE(u.email, '') AS email,
                COALESCE(u.roll_number, '') AS roll_number,
                COALESCE(u.department, '') AS department,
                COALESCE(u.status, 'active') AS status,
                COALESCE(u.profile_image, '/uploads/profile/default.png') AS profile_image,
                COALESCE(m.name, 'Not Assigned') AS mentor_name,
                COALESCE(u.mentor_id, 0)::int AS mentor_id,
                COALESCE(COUNT(c.id), 0)::int AS submitted,
                COALESCE(COUNT(c.id) FILTER (WHERE c.status = 'approved'), 0)::int AS approved,
                COALESCE(COUNT(c.id) FILTER (WHERE c.status = 'pending'), 0)::int AS pending,
                COALESCE(COUNT(c.id) FILTER (WHERE c.status = 'rejected'), 0)::int AS rejected,
                COALESCE(SUM(c.points) FILTER (WHERE c.status = 'approved'), 0)::int AS total_points
             FROM users u
             LEFT JOIN users m ON m.id = u.mentor_id AND m.role = 'mentor'
             LEFT JOIN certificates c ON c.student_id = u.id
             WHERE u.id = $1 AND u.role = 'student'
             GROUP BY u.id, m.name`,
            [id]
        );
        if (result.rows.length === 0) return res.status(404).json({ msg: 'Student not found' });
        res.json({ student: result.rows[0] });
    } catch (err) {
        console.error('Admin single student error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/admin/certificate/:id  — single certificate detail with image file
app.get('/api/admin/certificate/:id', adminAuth, async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            `SELECT
                c.id,
                u.name AS student_name,
                COALESCE(u.roll_number, '') AS roll_number,
                COALESCE(u.department, '') AS department,
                c.event_name,
                c.organizing_institute,
                TO_CHAR(c.event_date, 'DD Mon YYYY') AS event_date,
                COALESCE(c.participation_type, '') AS participation_type,
                COALESCE(c.certificate_type, '') AS certificate_type,
                COALESCE(c.certificate_file, '') AS certificate_file,
                c.status,
                c.points,
                COALESCE(c.mentor_remark, '') AS mentor_remark,
                c.created_at
             FROM certificates c
             JOIN users u ON u.id = c.student_id
             WHERE c.id = $1`,
            [id]
        );
        if (result.rows.length === 0) return res.status(404).json({ msg: 'Certificate not found' });
        res.json({ certificate: result.rows[0] });
    } catch (err) {
        console.error('Admin single certificate error:', err.message);
        res.status(500).json({ error: 'Server error' });
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// END ADMIN APIS
// ─────────────────────────────────────────────────────────────────────────────

app.use((err, req, res, next) => {
    console.error('Server Error:', err);
    if (res.headersSent) {
        return next(err);
    }
    res.status(500).json({
        message: 'Internal server error',
        error: err.message || 'Unexpected error',
    });
});

const PORT = process.env.PORT || 5000;
async function start() {
    try {
        if (pool && typeof pool.ready?.then === 'function') {
            await pool.ready;
        }

        app.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
        });
    } catch (err) {
        console.error('Failed to start backend:', err?.message || err);
    }
}

start();

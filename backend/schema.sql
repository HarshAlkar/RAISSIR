CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    roll_number VARCHAR(50),
    mentor_id INTEGER,
    department VARCHAR(100),
    employee_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS certificates (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES users(id),
    event_name VARCHAR(255) NOT NULL,
    organizing_institute VARCHAR(255) NOT NULL,
    event_date DATE,
    participation_type VARCHAR(50),
    certificate_type VARCHAR(100),
    certificate_file VARCHAR(255),
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    mentor_remark TEXT,
    points INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

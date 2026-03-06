module.exports = {
    apps: [
        {
            name: 'certitrack-backend',
            script: 'server.js',
            watch: false,               // set to true to auto-restart on file changes
            ignore_watch: ['node_modules', 'uploads'],
            instances: 1,
            autorestart: true,          // auto-restart if it crashes
            max_restarts: 10,           // max crash-restart attempts
            restart_delay: 2000,        // wait 2 seconds before restarting
            env: {
                NODE_ENV: 'development',
                PORT: 5000,
            },
            error_file: './logs/pm2-error.log',
            out_file: './logs/pm2-out.log',
            merge_logs: true,
            log_date_format: 'YYYY-MM-DD HH:mm:ss',
        },
    ],
};

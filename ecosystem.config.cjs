module.exports = {
  apps: [{
    name: 'mugharred-backend',
    script: './backend/dist/server.js',
    instances: 1,
    exec_mode: 'fork',
    cwd: '/home/reda/development/mugharred',
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    error_file: './backend/logs/err.log',
    out_file: './backend/logs/out.log',
    log_file: './backend/logs/combined.log',
    time: true,
    watch: false,
    max_memory_restart: '1G'
  }]
}
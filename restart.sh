#!/bin/bash
# Restart script for Smokeshop application

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Load environment variables from .env.production
if [ -f .env.production ]; then
    export $(grep -v '^#' .env.production | xargs)
fi

echo "Stopping existing Node.js processes..."
pkill -f 'node.*server.js' || true
sleep 2

echo "Starting application..."
cd "$(dirname "$0")"
nohup node server.js > app.log 2>&1 &
sleep 2

echo "Checking process..."
if ps aux | grep -q '[n]ode.*server.js'; then
    echo "Application started successfully"
    ps aux | grep '[n]ode.*server.js'
else
    echo "Warning: Process not found, checking logs..."
    tail -5 app.log
fi

exit 0

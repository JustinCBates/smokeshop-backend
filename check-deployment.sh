#!/bin/bash
# Script to check deployment status on Hostinger

echo "=== Checking Node.js Process ==="
ps aux | grep -E '[n]ode.*server.js' || echo "Node.js not running"

echo -e "\n=== Checking Port 3000 ==="
if command -v lsof &> /dev/null; then
    lsof -i :3000 || echo "Port 3000 not in use"
elif command -v netstat &> /dev/null; then
    netstat -tulpn | grep :3000 || echo "Port 3000 not in use"
else
    echo "Cannot check port (lsof/netstat not available)"
fi

echo -e "\n=== Recent Application Log ==="
if [ -f app.log ]; then
    echo "Last 20 lines of app.log:"
    tail -20 app.log
else
    echo "app.log not found"
fi

echo -e "\n=== Testing Local Connection ==="
if command -v curl &> /dev/null; then
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:3000/ || echo "Cannot connect to localhost:3000"
else
    echo "curl not available"
fi

echo -e "\n=== File Permissions ==="
ls -la server.js .next/ 2>/dev/null | head -10

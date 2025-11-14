#!/bin/bash

echo "Testing MCP Server..."

echo "1. Testing manifest endpoint:"
curl -s http://localhost:8080/manifest | head -c 100
echo "..."

echo -e "\n2. Testing simple command execution:"
curl -s -X POST http://localhost:8080/tools/runCommand \
  -H "Content-Type: application/json" \
  -d '{"command": "Get-Date | ConvertTo-Json"}'

echo -e "\n3. Testing error handling:"
curl -s -X POST http://localhost:8080/tools/runCommand \
  -H "Content-Type: application/json" \
  -d '{"command": "throw \"Test error\""}'

echo -e "\n4. Testing with empty command:"
curl -s -X POST http://localhost:8080/tools/runCommand \
  -H "Content-Type: application/json" \
  -d '{}'

echo -e "\nAll tests completed."
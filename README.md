# PowerShell MCP Server

[![Build and Push to Docker Hub](https://github.com/NopeNix/PowerShell-MCP-Server/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/NopeNix/PowerShell-MCP-Server/actions/workflows/build-and-push.yml)
[![Docker Image Size](https://img.shields.io/docker/image-size/nopenix/powershell-mcp-server/latest)](https://hub.docker.com/r/nopenix/powershell-mcp-server)
[![License](https://img.shields.io/github/license/NopeNix/PowerShell-MCP-Server)](LICENSE)

A self-hosted Model Context Protocol (MCP) server implemented in PowerShell using the Pode web framework. This lightweight service enables AI agents to discover and execute PowerShell commands in a structured, secure manner.

## 🚀 Quick Start

```bash
# Pull and run the pre-built Docker image
docker run -d -p 8080:8080 --name mcp-server nopenix/powershell-mcp-server:latest

# Or deploy with Docker Compose
curl -O https://raw.githubusercontent.com/NopeNix/PowerShell-MCP-Server/main/docker-compose.yml
docker-compose up -d
```

## 🧩 About Model Context Protocol (MCP)

The Model Context Protocol (MCP) is an emerging standard that enables AI systems to dynamically discover and interact with tools and services. This implementation provides:

- **Tool Discovery**: Automatic manifest generation for AI agent integration
- **Structured I/O**: Consistent JSON input/output formats
- **Error Handling**: Detailed error reporting with stack traces
- **Performance Metrics**: Execution timing and resource utilization

## ⚠️ Critical Security Notice

**This server enables Remote Code Execution (RCE) and MUST only be used in secure, isolated environments.**

❌ **NEVER expose this service to the public internet**

✅ **Recommended deployment scenarios:**
- Internal development environments
- Private networks with strict access controls
- Air-gapped systems for specialized tooling

## 🛠️ Core Features

- **PowerShell Command Execution**: Run any PowerShell command with structured results
- **Comprehensive Error Reporting**: Full exception details including stack traces
- **Performance Monitoring**: Execution time measurement
- **MCP Manifest Discovery**: Auto-generated tool manifests for AI agents
- **Docker Containerization**: Lightweight, portable deployment
- **Multi-Architecture Support**: AMD64 and ARM64 images available

## 📡 API Endpoints

### `GET /manifest`
Returns the MCP manifest for AI agent discovery.

```json
{
  "protocols": [
    {
      "name": "command-execution",
      "description": "Execute PowerShell commands on phil.laptop",
      "endpoints": [
        {
          "name": "runCommand",
          "description": "Run a PowerShell command and get output + errors",
          "method": "POST",
          "url": "http://phil.nbg.nopenix.de:8080/tools/runCommand",
          "parameters": [
            {
              "name": "command",
              "type": "string",
              "required": true,
              "description": "The PowerShell command or script to execute"
            }
          ]
        }
      ]
    }
  ]
}
```

### `POST /tools/runCommand`
Executes a PowerShell command and returns structured output.

#### Request
```json
{
  "command": "Get-Process | Select-Object -First 3 Name, CPU | ConvertTo-Json"
}
```

#### Success Response
```json
{
  "command": "Get-Process | Select-Object -First 3 Name, CPU | ConvertTo-Json",
  "success": true,
  "stdout": "{\n  \"Name\": \"pwsh\",\n  \"CPU\": 14.49\n}",
  "stderr": null,
  "exitCode": 0,
  "timestamp": "2025-11-14T13:16:19.6415836+00:00",
  "executionTimeMs": 39
}
```

#### Error Response
```json
{
  "command": "throw \"Test error\"",
  "success": false,
  "stdout": null,
  "stderr": {
    "message": "Test error",
    "script": "",
    "line": 1,
    "command": "throw \"Test error\"",
    "stackTrace": "at <ScriptBlock>, <No file>: line 1\n..."
  },
  "exitCode": 1,
  "timestamp": "2025-11-14T13:16:26.7543678+00:00",
  "executionTimeMs": 5
}
```

## 🐳 Deployment Options

### Option 1: Docker Run
```bash
docker run -d -p 8080:8080 --name mcp-server nopenix/powershell-mcp-server:latest
```

### Option 2: Docker Compose
```yaml
version: '3.8'
services:
  mcp-server:
    image: nopenix/powershell-mcp-server:latest
    container_name: mcp-server
    ports:
      - "8080:8080"
    restart: unless-stopped
```

### Option 3: Build from Source
```bash
git clone https://github.com/NopeNix/PowerShell-MCP-Server.git
cd PowerShell-MCP-Server
docker build -t mcp-server .
docker run -d -p 8080:8080 mcp-server
```

## 🔬 Testing

### Verify Service Health
```bash
# Check if service is running
curl -f http://localhost:8080/manifest > /dev/null && echo "Service OK" || echo "Service DOWN"

# Get manifest
curl http://localhost:8080/manifest

# Run sample command
curl -X POST http://localhost:8080/tools/runCommand \
  -H "Content-Type: application/json" \
  -d '{"command": "Get-Date | ConvertTo-Json"}'
```

### Advanced Testing Script
```bash
# Create test script
cat > test-mcp.sh << 'EOF'
#!/bin/bash
echo "Testing MCP Server..."
echo "1. Testing manifest endpoint:"
curl -s http://localhost:8080/manifest | head -c 100
echo -e "\n\n2. Testing simple command execution:"
curl -s -X POST http://localhost:8080/tools/runCommand \
  -H "Content-Type: application/json" \
  -d '{"command": "Get-Date | ConvertTo-Json"}'
echo -e "\n\n3. Testing error handling:"
curl -s -X POST http://localhost:8080/tools/runCommand \
  -H "Content-Type: application/json" \
  -d '{"command": "throw \"Test error\""}'
echo -e "\n\nAll tests completed."
EOF

chmod +x test-mcp.sh
./test-mcp.sh
```

## 🔒 Security Hardening

### Essential Security Measures
1. **Network Isolation**: Deploy in private networks only
2. **Authentication**: Implement API keys or JWT tokens
3. **Authorization**: Restrict command allowlists
4. **Rate Limiting**: Prevent abuse and DoS attacks
5. **Logging**: Monitor all command executions
6. **Updates**: Regularly update base Docker images

### Example Nginx Reverse Proxy Configuration
```nginx
server {
    listen 443 ssl;
    server_name mcp.yourdomain.com;
    
    # SSL configuration
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    
    location / {
        # API key authentication
        if ($http_authorization !~* "Bearer secret-api-key") {
            return 403;
        }
        
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 🤖 AI Integration Examples

### Claude Desktop Configuration
```json
{
  "tools": [
    {
      "name": "powershell-executor",
      "type": "computer",
      "computer": {
        "command_execution": {
          "url": "http://localhost:8080/tools/runCommand",
          "manifest_url": "http://localhost:8080/manifest"
        }
      }
    }
  ]
}
```

### Custom AI Agent Integration
```python
import requests
import json

def execute_powershell_command(command):
    url = "http://localhost:8080/tools/runCommand"
    payload = {"command": command}
    headers = {"Content-Type": "application/json"}
    
    response = requests.post(url, data=json.dumps(payload), headers=headers)
    result = response.json()
    
    if result["success"]:
        return result["stdout"]
    else:
        raise Exception(f"Command failed: {result['stderr']['message']}")

# Example usage
try:
    output = execute_powershell_command("Get-Process | Select-Object -First 5 Name, CPU")
    print(output)
except Exception as e:
    print(f"Error: {e}")
```

## 🏗️ Development

### Prerequisites
- Docker 20.10+
- PowerShell 7.0+ (for local development)
- Git

### Local Development Setup
```bash
# Clone repository
git clone https://github.com/NopeNix/PowerShell-MCP-Server.git
cd PowerShell-MCP-Server

# Run development server
docker-compose up -d

# View logs
docker-compose logs -f

# Stop server
docker-compose down
```

### Project Structure
```
PowerShell-MCP-Server/
├── mcp-server.ps1        # Main PowerShell server implementation
├── Dockerfile            # Docker image definition
├── docker-compose.yml    # Deployment configuration
├── .github/workflows/    # CI/CD pipelines
├── test-mcp.sh           # Test script
├── .gitignore            # Git ignore rules
└── README.md             # This file
```

## 🔄 Continuous Integration

This project uses GitHub Actions for automated building and deployment:

- **Build Trigger**: Push to `main` branch or weekly schedule
- **Platforms**: Multi-architecture (AMD64, ARM64)
- **Registry**: Docker Hub (`nopenix/powershell-mcp-server`)
- **Tags**: `latest`, commit SHA prefixes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Pode](https://github.com/Badgerati/Pode) - PowerShell web framework
- [Microsoft PowerShell](https://github.com/PowerShell/PowerShell) - Cross-platform automation engine
- Anthropic for pioneering the Model Context Protocol concept

## 📞 Support

For issues, questions, or contributions, please [open an issue](https://github.com/NopeNix/PowerShell-MCP-Server/issues) on GitHub.
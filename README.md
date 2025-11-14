# PowerShell MCP Server

[![Build and Push to Docker Hub](https://github.com/NopeNix/PowerShell-MCP-Server/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/NopeNix/PowerShell-MCP-Server/actions/workflows/build-and-push.yml)
[![Docker Image Size](https://img.shields.io/docker/image-size/nopenix/powershell-mcp-server/latest)](https://hub.docker.com/r/nopenix/powershell-mcp-server)
[![License](https://img.shields.io/github/license/NopeNix/PowerShell-MCP-Server)](LICENSE)

A self-hosted Model Context Protocol (MCP) server that provides a sandboxed PowerShell environment for AI assistants.

## 🚀 Quick Start

```bash
# Run the server (it will be available at http://localhost:8080)
docker run -d -p 8080:8080 --name mcp-server nopenix/powershell-mcp-server:latest
```

That's it! Your server is now running and ready to connect to AI tools.

## 💡 What Is This For?

This server provides a **sandboxed PowerShell environment** that AI assistants can use to:

- ✅ Run PowerShell commands in an isolated environment
- ✅ Get organized results with success/failure information  
- ✅ Handle errors gracefully and report them clearly
- ✅ See command output in a format that's easy for AI to understand
- ✅ Learn PowerShell syntax and capabilities

**Important Note**: This runs in a **containerized, isolated environment** - it does NOT have direct access to your host system's files, processes, or resources. It's perfect for learning PowerShell, testing commands safely, or running PowerShell-specific tasks in a controlled environment.

## 🏗️ Under The Hood

This server is built on:
- **Base Image**: Microsoft's official PowerShell Docker image (`mcr.microsoft.com/powershell:latest`)
- **Web Framework**: [Pode](https://badgerati.github.io/Pode/) - A cross-platform PowerShell framework for REST APIs, Web Sites, and TCP/UDP servers
- **Container Size**: Lightweight (~400MB) for fast downloads and minimal resource usage
- **Isolation**: Runs in a secure container with no host filesystem access by default

The container includes:
- PowerShell 7+ with full .NET support
- Common PowerShell modules pre-installed
- Pode web framework for HTTP handling
- Structured JSON response formatting
- Built-in logging and error handling
- **OpenAPI specification** at `/openapi.yaml` for API documentation

## 🤖 Connect to AI Assistants

### OpenWebUI Integration

1. Make sure your PowerShell MCP Server is running at `http://localhost:8080`
2. In OpenWebUI, go to **Admin Settings → External Tools**
3. Click **+ Add Server**
4. Set **Type** to **MCP (Streamable HTTP)**
5. Enter **Server URL**: `http://localhost:8080`
6. Click **Save** and restart OpenWebUI if prompted

Now you can ask OpenWebUI to run PowerShell commands!

### VS Code Continue Integration

1. Make sure your PowerShell MCP Server is running at `http://localhost:8080`
2. In VS Code, open the Continue extension settings
3. Add the MCP server to your configuration (specific steps may vary by Continue version)

### Claude Desktop Integration

1. Make sure your PowerShell MCP Server is running at `http://localhost:8080`  
2. In Claude Desktop settings, look for "Tools" or "External Tools"
3. Add a new MCP tool with URL: `http://localhost:8080`
4. Save and restart Claude

## 🔧 How to Use

Once connected, you can ask your AI assistant to run PowerShell commands such as:

```
"Show me how to list files in PowerShell"
"Generate a random password using PowerShell"
"How do I work with JSON in PowerShell?"
"Show me PowerShell examples for string manipulation"
"What are the built-in PowerShell variables?"
"Help me understand PowerShell pipelines"
"What PowerShell commands are available for working with dates?"
```

Since this is a sandboxed environment, it's safe for experimentation and learning!

## 🛡️ Security & Safety

✅ **Sandboxed Environment**: Runs in an isolated container, protecting your host system
✅ **Safe Experimentation**: Perfect for learning PowerShell without risk
✅ **Controlled Access**: No direct access to host files or processes
✅ **Clear Logging**: All commands executed are logged for visibility

## 📝 Logging

The server provides comprehensive logging:

- **Request Logging**: All HTTP requests with status codes
- **Error Logging**: Detailed error information when commands fail
- **Operation Logging**: Clear messages showing what's happening

To view logs:
```bash
# View container logs
docker logs mcp-server
```

Sensitive information in logs is automatically masked.

## 🧪 Testing Your Setup

You can test that your server is working with simple curl commands:

```bash
# Test basic connectivity
curl http://localhost:8080/test

# Check available capabilities
curl http://localhost:8080/capabilities

# List available tools
curl http://localhost:8080/tools/list

# View OpenAPI specification
curl http://localhost:8080/openapi.yaml

# Run a simple command
curl -X POST http://localhost:8080/tools/runCommand \
  -H "Content-Type: application/json" \
  -d '{"command":"Get-Date"}'
```

## 🐳 Alternative Deployment

If you prefer docker-compose:

```bash
# Download the compose file
curl -O https://raw.githubusercontent.com/NopeNix/PowerShell-MCP-Server/main/docker-compose.yml

# Start the service
docker-compose up -d
```

To view logs with docker-compose:
```bash
docker-compose logs -f
```
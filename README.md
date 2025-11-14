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
- **Logging**: Comprehensive request and error logging

## 📝 Logging

This server implements comprehensive logging using Pode's built-in logging capabilities:

- **Request Logging**: All HTTP requests are logged with status codes and response times
- **Error Logging**: Errors in command execution are logged with detailed information
- **Security Logging**: Potentially sensitive information (passwords, keys, secrets) is automatically masked
- **Level-based Logging**: Different log levels (Info, Warn, Error) for various events

Logs are output to the terminal/stdout, making them easily accessible in Docker environments.

Example log entries:
```
[INFO] Test endpoint accessed
[INFO] Executing command: Get-Date
[WARN] Missing 'command' in request body
[ERROR] Invalid JSON in request body: Unexpected token ...
```

## 🧪 Testing Endpoints

You can test the server functionality with curl:

```bash
# Test basic endpoint
curl http://localhost:8080/test

# Check capabilities
curl http://localhost:8080/capabilities

# List available tools
curl http://localhost:8080/tools/list

# Check legacy manifest
curl http://localhost:8080/manifest

# Execute a command (be careful with this!)
curl -X POST http://localhost:8080/tools/runCommand \
  -H "Content-Type: application/json" \
  -d '{"command":"Get-Date"}'
```

To view logs:
```bash
# Docker logs
docker logs mcp-command-server

# Or with docker-compose
docker-compose logs -f
```

## 🔒 Security Notes

Commands executed through this service run with the same permissions as the server process. Ensure proper isolation and access controls when deploying in production environments.
FROM mcr.microsoft.com/powershell:latest
RUN pwsh -c "Install-Module Pode -Force -Scope CurrentUser"
WORKDIR /app
COPY mcp-server.ps1 .
EXPOSE 8080
CMD ["pwsh", "-File", "mcp-server.ps1"]
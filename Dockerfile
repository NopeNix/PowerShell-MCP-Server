FROM mcr.microsoft.com/powershell:latest
RUN pwsh -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Name Pode -Force -Scope CurrentUser"
WORKDIR /app
COPY mcp-server.ps1 .
COPY server.psd1 .
EXPOSE 8080
CMD ["pwsh", "-File", "mcp-server.ps1"]
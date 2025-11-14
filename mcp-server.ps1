# mcp-server.ps1
# Full MCP-compatible command execution server
# Runs on Pode, returns structured output + full error details
Import-Module Pode

Start-PodeServer {
    Add-PodeEndpoint -Address * -Port 8080 -Protocol Http
    
    # Setup logging to terminal
    New-PodeLoggingMethod -Terminal | Enable-PodeRequestLogging
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging
    
    # Simple test endpoint
    Add-PodeRoute -Method Get -Path '/test' -ScriptBlock {
        Write-Host "Test endpoint accessed"
        Write-PodeJsonResponse -Value @{ message = "Test endpoint working" }
    }
    
    # MCP Capabilities Endpoint
    Add-PodeRoute -Method Get -Path '/capabilities' -ScriptBlock {
        Write-Host "Capabilities endpoint accessed"
        $capabilities = @{
            capabilities = @{
                tools = @{
                    listChanged = $true
                }
            }
        }
        Write-PodeJsonResponse -Value $capabilities
    }
    
    # MCP Tools List Endpoint
    Add-PodeRoute -Method Get -Path '/tools/list' -ScriptBlock {
        Write-Host "Tools list endpoint accessed"
        $tools = @{
            tools = @(
                @{
                    name = "runCommand"
                    title = "PowerShell Command Executor"
                    description = "Execute PowerShell commands and get structured output"
                    inputSchema = @{
                        type = "object"
                        properties = @{
                            command = @{
                                type = "string"
                                description = "The PowerShell command or script to execute"
                            }
                        }
                        required = @("command")
                    }
                }
            )
        }
        Write-PodeJsonResponse -Value $tools
    }
    
    # Legacy Manifest Endpoint (keep this working)
    Add-PodeRoute -Method Get -Path '/manifest' -ScriptBlock {
        Write-Host "Manifest endpoint accessed"
        $manifest = @{
            protocols = @(
                @{
                    name        = "command-execution"
                    description = "Execute PowerShell commands"
                    endpoints   = @(
                        @{
                            name        = "runCommand"
                            description = "Run a PowerShell command and get output + errors"
                            method      = "POST"
                            url         = "http://localhost:8080/tools/runCommand"
                            parameters  = @(
                                @{
                                    name        = "command"
                                    type        = "string"
                                    required    = $true
                                    description = "The PowerShell command or script to execute"
                                }
                            )
                        }
                    )
                }
            )
        }
        Write-PodeJsonResponse -Value $manifest
    }
    
    # Legacy Tool Endpoint: Run Command
    Add-PodeRoute -Method Post -Path '/tools/runCommand' -ScriptBlock {
        Write-Host "RunCommand endpoint accessed"
        # Parse JSON body manually to ensure compatibility across clients
        $payload = $WebEvent.Data
        if ($WebEvent.Headers.'Content-Type' -and $WebEvent.Headers.'Content-Type' -like '*application/json*') {
            $body = $WebEvent.RequestBody
            if ($body) {
                try {
                    $payload = $body | ConvertFrom-Json -ErrorAction Stop
                }
                catch {
                    Write-Host "Invalid JSON in request body: $($_.Exception.Message)"
                    Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Invalid JSON in request body" }
                    return
                }
            }
        }

        $command = $payload.command
        
        if (-not $command) {
            Write-Host "Missing 'command' in request body"
            Write-PodeJsonResponse -StatusCode 400 -Value @{
                error = "Missing 'command' in request body"
            }
            return
        }
        
        Write-Host "Executing command: $command"
        
        $result = @{
            command           = $command
            success           = $false
            stdout            = $null
            stderr            = $null
            exitCode          = $null
            timestamp         = (Get-Date).ToString("o")
            executionTimeMs   = $null
        }
        
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $output = Invoke-Expression -Command $command 2>&1
            $sw.Stop()
            $result.executionTimeMs = $sw.ElapsedMilliseconds

            $stdoutItems = @($output | Where-Object {
                $_ -is [string] -or $_.GetType().Name -eq 'String'
            })
            $stdout = if ($stdoutItems.Count -gt 0) { $stdoutItems -join "`n" } else { "" }

            $stderrItems = @($output | Where-Object {
                $_ -is [System.Management.Automation.ErrorRecord]
            })

            $stderr = if ($stderrItems.Count -gt 0) {
                $stderrItems | ForEach-Object {
                    @{
                        message     = $_.Exception.Message
                        script      = $_.InvocationInfo.ScriptName
                        line        = $_.InvocationInfo.ScriptLineNumber
                        command     = $_.InvocationInfo.Line.Trim()
                        stackTrace  = $_.ScriptStackTrace
                    }
                }
            }
            
            $result.stdout = $stdout
            $result.stderr = if ($stderr) { $stderr } else { $null }
            $result.exitCode = if ($stderr) { 1 } else { 0 }
            $result.success = -not $stderr
            
            if ($stderr) {
                Write-Host "Command executed with errors: $command"
            } else {
                Write-Host "Command executed successfully: $command"
            }
        }
        catch {
            $sw.Stop()
            $result.executionTimeMs = $sw.ElapsedMilliseconds
            $result.stderr = @{
                message        = $_.Exception.Message
                innerException = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { $null }
                script         = $_.InvocationInfo.ScriptName
                line           = $_.InvocationInfo.ScriptLineNumber
                command        = $_.InvocationInfo.Line
                stackTrace     = $_.ScriptStackTrace
            }
            $result.exitCode = 1
            $result.success = $false
            
            Write-Host "Command execution failed: $command - Error: $($_.Exception.Message)"
        }
        
        Write-PodeJsonResponse -Value $result
    }
    
    Write-Host "MCP Server started successfully"
}
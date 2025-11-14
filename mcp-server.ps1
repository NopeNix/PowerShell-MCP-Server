# mcp-server.ps1
# Full MCP-compatible command execution server
# Runs on Pode, returns structured output + full error details
Import-Module Pode

Start-PodeServer {
    Add-PodeEndpoint -Address * -Port 8080 -Protocol Http
    # MCP Manifest Endpoint
    # Required for AI agent discovery
    Add-PodeRoute -Method Get -Path '/manifest' -ScriptBlock {
        $manifest = @{
            protocols = @(
                @{
                    name        = "command-execution"
                    description = "Execute PowerShell commands on phil.laptop"
                    endpoints   = @(
                        @{
                            name        = "runCommand"
                            description = "Run a PowerShell command and get output + errors"
                            method      = "POST"
                            url         = "http://phil.nbg.nopenix.de:8080/tools/runCommand"
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
    
    # MCP Tool Endpoint: Run Command
    Add-PodeRoute -Method Post -Path '/tools/runCommand' -ScriptBlock {
        # Parse JSON body manually to ensure compatibility across clients
        $payload = $WebEvent.Data
        if ($WebEvent.Headers.'Content-Type' -and $WebEvent.Headers.'Content-Type' -like '*application/json*') {
            $body = $WebEvent.RequestBody
            if ($body) {
                try {
                    $payload = $body | ConvertFrom-Json -ErrorAction Stop
                }
                catch {
                    Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Invalid JSON in request body" }
                    return
                }
            }
        }

        $command = $payload.command
        
        if (-not $command) {
            Write-PodeJsonResponse -StatusCode 400 -Value @{
                error = "Missing 'command' in request body"
            }
            return
        }
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
        }
        
        Write-PodeJsonResponse -Value $result
    }
}

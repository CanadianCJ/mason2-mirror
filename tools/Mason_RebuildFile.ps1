Param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $true)]
    [ValidateSet("backend", "frontend", "generic")]
    [string]$Role
)

$BridgeUrl = "http://127.0.0.1:8484/api/chat"

if (-not (Test-Path -LiteralPath $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

# 1) Backup the file
$timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = "$FilePath.$timestamp.bak"

Copy-Item -LiteralPath $FilePath -Destination $backupPath -Force
Write-Host "Backup saved to $backupPath"

# 2) Read file & base64-encode content so JSON is always safe
$fileContent = Get-Content -LiteralPath $FilePath -Raw
$bytes       = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
$base64      = [Convert]::ToBase64String($bytes)

# 3) Role description for Mason
$roleDescription = switch ($Role) {
    "backend" {
        "backend FastAPI server for Athena (Python server.py in Mason2 root)"
    }
    "frontend" {
        "frontend HTML/JS file for Athena console (index.html in Mason2 root or Mason2\\MasonConsole)"
    }
    default {
        "generic code/config file in the Mason2 project"
    }
}

# 4) Build prompt for Mason
$prompt = @"
You are Mason's build assistant.

File role: $roleDescription
File path: $FilePath

The current file content is BASE64-ENCODED between BEGIN_BASE64 and END_BASE64.

Tasks:
1. Decode the base64 content.
2. Analyze and FIX the file so it correctly serves the described role, according to my Athena spec.
3. Return ONLY the full, final file content as plain text.
   - Do NOT return base64.
   - Do NOT wrap it in markdown fences like ``` or ```python.
   - Do NOT add explanations or comments outside the code.

BEGIN_BASE64
$base64
END_BASE64
"@

# 5) Load spec (if present) and prepend into the message
$specPath = "C:\Users\Chris\Desktop\Mason2\Athena_Spec.txt"
if (Test-Path -LiteralPath $specPath) {
    $spec = Get-Content -LiteralPath $specPath -Raw
    $prompt = @"
You also have the following Athena spec. Follow it as closely as possible.

=== ATHENA SPEC START ===
$spec
=== ATHENA SPEC END ===

$prompt
"@
}

# 6) Build JSON body in the same shape other tools use
$bodyObject = @{
    message = $prompt
    mode    = "smart"
}

$bodyJson = $bodyObject | ConvertTo-Json -Depth 8

# Optional: debug last request body
$debugPath = Join-Path (Split-Path $FilePath -Parent) "Mason_RebuildFile_LastRequest.json"
$bodyJson | Out-File -FilePath $debugPath -Encoding UTF8

# 7) Call Mason bridge
try {
    $response = Invoke-WebRequest `
        -Uri $BridgeUrl `
        -Method POST `
        -ContentType "application/json" `
        -Body $bodyJson

    $raw = $response.Content

    # Try to parse JSON, but fall back to raw text
    $data = $null
    try {
        $data = $raw | ConvertFrom-Json
    } catch {
        $data = $null
    }

    $newContent = $null

    if ($data -ne $null) {
        if ($data.reply) {
            $newContent = $data.reply
        } elseif ($data.output) {
            $newContent = $data.output
        } elseif ($data.message) {
            $newContent = $data.message
        }
    }

    if (-not $newContent) {
        # No structured fields – assume raw content is the file
        $newContent = $raw
    }

    if (-not $newContent -or -not $newContent.Trim()) {
        Write-Error "Bridge reply was empty; NOT overwriting file. Raw response:"
        Write-Host $raw
        return
    }

    # 8) Overwrite the file with Mason's rebuilt version
    $newContent | Out-File -FilePath $FilePath -Encoding UTF8

    Write-Host "File rebuilt successfully by Mason:"
    Write-Host "  Target : $FilePath"
    Write-Host "  Backup : $backupPath"
}
catch {
    Write-Error ("Error calling Mason bridge at {0} : {1}" -f $BridgeUrl, $_.Exception.Message)
}

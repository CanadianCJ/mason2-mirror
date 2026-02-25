function Read-DotEnv([string]$path){
  $h=@{}; if(-not(Test-Path $path)){ return $h }
  Get-Content $path | ForEach-Object {
    $line=$_.Trim()
    if($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)){ return }
    $eq=$line.IndexOf('=')
    if($eq -gt 0){
      $k=$line.Substring(0,$eq).Trim()
      $v=$line.Substring($eq+1).Trim()
      $h[$k]=$v
    }
  }
  return $h
}
function Out-Jsonl($path,$obj){
  New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
  ($obj | ConvertTo-Json -Compress) | Add-Content -LiteralPath $path -Encoding UTF8
}

$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$cfg = Join-Path $Base 'config'
$rep = Join-Path $Base 'reports'
$schemaPath = Join-Path $cfg 'env.schema.json'
$envPath = Join-Path $cfg '.env'
$summaryPath = Join-Path $rep 'config_validation.jsonl'

$schema = Get-Content -Raw -LiteralPath $schemaPath | ConvertFrom-Json
$envMap = Read-DotEnv $envPath

# Apply defaults from schema if missing
foreach($prop in $schema.properties.PSObject.Properties.Name){
  $def = $schema.properties.$prop.default
  if($def -ne $null -and -not $envMap.ContainsKey($prop)){ $envMap[$prop] = [string]$def }
}

# Validate enums & ranges (lightweight)
$errors=@()
foreach($prop in $schema.properties.PSObject.Properties.Name){
  $val = $envMap[$prop]
  $spec = $schema.properties.$prop

  if($spec.enum){
    if($null -ne $val -and ($spec.enum -notcontains $val)){
      $errors += ("Invalid value for $($prop): '$($val)' (allowed: " + ($spec.enum -join ',') + ")")
    }
  }
  if($spec.type -eq 'integer' -and $null -ne $val){
    if(-not ($val -as [int] -ne $null)){ $errors += "Non-integer value for $($prop): '$($val)'" }
    if($spec.minimum -ne $null -and [int]$val -lt $spec.minimum){ $errors += "$($prop) below minimum $($spec.minimum)" }
    if($spec.maximum -ne $null -and [int]$val -gt $spec.maximum){ $errors += "$($prop) above maximum $($spec.maximum)" }
  }
  if($spec.pattern -and $val){
    if(-not [Text.RegularExpressions.Regex]::IsMatch($val,$spec.pattern)){
      $errors += "Value for $($prop) does not match pattern"
    }
  }
}
foreach($req in $schema.required){ if(-not $envMap.ContainsKey($req)){ $errors += "Missing required: $($req)" } }

# OS build & locale (advisory)
$os = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion')
$build = [int]$os.CurrentBuild
$culture = (Get-Culture).Name

$result = @{
  ts=(Get-Date).ToString('s')
  kind='env_validation'
  ok = ($errors.Count -eq 0)
  errors = $errors
  env = $envMap
  os_build = $build
  locale  = $culture
}
Out-Jsonl $summaryPath $result
if($errors.Count -gt 0){
  Write-Warning ("Env validation failed:`n - " + ($errors -join "`n - "))
}else{
  Write-Host "[ OK ] .env validated"
}

# VoiceShell-Min.ps1 — offline TTS/STT, wake word "mason", push-to-talk fallback
Add-Type -AssemblyName System.Speech
$ErrorActionPreference='Continue'
$base="$env:MASON2_BASE"; $rep=Join-Path $base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$tts = New-Object System.Speech.Synthesis.SpeechSynthesizer
$rec = New-Object System.Speech.Recognition.SpeechRecognitionEngine
$rec.SetInputToDefaultAudioDevice()
$rec.LoadGrammar( (New-Object System.Speech.Recognition.DictationGrammar) )
$gb = New-Object System.Speech.Recognition.GrammarBuilder 'mason'
$gw = New-Object System.Speech.Recognition.Grammar $gb
$rec.LoadGrammar($gw)

function Speak([string]$text){ try{ $tts.Speak($text) }catch{} }
function LogIn([string]$text){
  $obj=@{ts=(Get-Date).ToString('s'); kind='voice'; text=$text}
  Add-Content (Join-Path $rep 'voice_in.jsonl') ($obj | ConvertTo-Json -Compress)
}
Write-Host "[Voice] Press ENTER for push-to-talk; say 'mason' to wake; Ctrl+C to exit."
Speak "Voice shell ready."
while($true){
  if([Console]::KeyAvailable){
    $k=[Console]::ReadKey($true)
    if($k.Key -eq 'Enter'){
      $res=$rec.Recognize([TimeSpan]'0:0:04')
      if($res -and $res.Text){ LogIn $res.Text; Speak "Heard $($res.Text)" }
    }
  }
  $res=$rec.Recognize([TimeSpan]'0:0:02')
  if($res -and $res.Text -match '^(?i)mason$'){ Speak "I'm listening"; $ptt=$rec.Recognize([TimeSpan]'0:0:04'); if($ptt){ LogIn $ptt.Text; Speak "Got it" } }
}
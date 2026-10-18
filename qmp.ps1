param(
  [string[]]$Exec,
  [string[]]$Hmp,
  [string]$Screen = '',
  [int]$Port = 55557,
  [int]$TimeoutMs = 12000
)

function Get-JsonObjects([string]$text) {
  $objs = @()
  $depth = 0; $start = -1; $inStr = $false; $esc = $false
  for ($i=0; $i -lt $text.Length; $i++) {
    $c = $text[$i]
    if ($inStr) {
      if ($esc) { $esc = $false }
      elseif ($c -eq '\') { $esc = $true }
      elseif ($c -eq '"') { $inStr = $false }
      continue
    }
    if ($c -eq '"') { $inStr = $true; continue }
    if ($c -eq '{') { if ($depth -eq 0) { $start = $i }; $depth++ }
    elseif ($c -eq '}') { $depth--; if ($depth -eq 0 -and $start -ge 0) { $objs += $text.Substring($start, $i-$start+1); $start = -1 } }
  }
  return $objs
}

try {
  $client = New-Object System.Net.Sockets.TcpClient
  $client.Connect('127.0.0.1', $Port)
  $stream = $client.GetStream()
  $stream.ReadTimeout = 1000
  $buf = New-Object byte[] 65536
  $acc = New-Object System.Text.StringBuilder

  function Pump([int]$ms) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $ms) {
      try {
        if ($stream.DataAvailable) {
          $n = $stream.Read($buf,0,$buf.Length)
          if ($n -gt 0) { [void]$acc.Append([Text.Encoding]::UTF8.GetString($buf,0,$n)) }
        } else { Start-Sleep -Milliseconds 40 }
      } catch { Start-Sleep -Milliseconds 40 }
    }
  }

  Pump 1500
  Write-Output ("GREETING: " + ($acc.ToString().Trim()))

  function SendRaw($json) {
    $b = [Text.Encoding]::UTF8.GetBytes($json + "`n")
    $stream.Write($b,0,$b.Length); $stream.Flush()
  }

  $json = @{
    execute = 'qmp_capabilities'
  } | ConvertTo-Json -Compress
  SendRaw $json
  [void]$acc.Clear(); Pump $TimeoutMs
  Write-Output ("CAPS: " + ($acc.ToString().Trim()))

  foreach ($e in $Exec) {
    $j = @{ execute = $e } | ConvertTo-Json -Compress
    SendRaw $j
    [void]$acc.Clear(); Pump $TimeoutMs
    Write-Output ("EXEC $e : " + ($acc.ToString().Trim()))
  }
  foreach ($h in $Hmp) {
    $j = @{ execute = 'human-monitor-command'; arguments = @{ 'command-line' = $h } } | ConvertTo-Json -Compress -Depth 6
    SendRaw $j
    [void]$acc.Clear(); Pump $TimeoutMs
    Write-Output ("HMP [$h] : " + ($acc.ToString().Trim()))
  }
  if ($Screen) {
    $j = @{ execute = 'screendump'; arguments = @{ filename = $Screen } } | ConvertTo-Json -Compress -Depth 6
    SendRaw $j
    [void]$acc.Clear(); Pump $TimeoutMs
    Write-Output ("SCREENDUMP: " + ($acc.ToString().Trim()))
  }
  try { $client.Client.Shutdown([System.Net.Sockets.SocketShutdown]::Both) } catch {}
  $client.Close()
} catch {
  Write-Output ("QMP2 FAIL: " + $_.Exception.Message)
}

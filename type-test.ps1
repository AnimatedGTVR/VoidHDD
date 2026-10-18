param([string]$Text)
$client = New-Object Net.Sockets.TcpClient('127.0.0.1',55567)
$stream = $client.GetStream()
$stream.ReadTimeout = 5000
$reader = New-Object IO.StreamReader($stream)
$writer = New-Object IO.StreamWriter($stream)
$writer.AutoFlush = $true
try {
  $null = $reader.ReadLine()
  $writer.WriteLine('{"execute":"qmp_capabilities"}')
  $null = $reader.ReadLine()
  foreach ($character in ($Text + "`n").ToCharArray()) {
    $key = [string]$character
    if ($key -eq "`n") { $key = 'ret' }
    if ($key -eq '-') { $key = 'minus' }
    if ($key -eq ' ') { $key = 'spc' }
    if ($key -eq '/') { $key = 'slash' }
    if ($key -eq '.') { $key = 'dot' }
    if ($key -eq ',') { $key = 'comma' }
    if ($key -eq ':') { $key = 'shift-semicolon' }
    if ($key -eq '>') { $key = 'shift-dot' }
    if ($key -eq '&') { $key = 'shift-7' }
    if ($key -eq '@') { $key = 'shift-2' }
    if ($key -eq '=') { $key = 'equal' }
    if ($key -eq '_') { $key = 'shift-minus' }
    if ($key -cmatch '^[A-Z]$') { $key = 'shift-' + $key.ToLower() }
    $request = @{execute='human-monitor-command'; arguments=@{'command-line'="sendkey $key"}} | ConvertTo-Json -Compress
    $writer.WriteLine($request)
    $null = $reader.ReadLine()
    Start-Sleep -Milliseconds 100
  }
} finally { $client.Dispose() }

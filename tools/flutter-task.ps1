param([ValidateSet('check','apk','web')][string]$Task = 'check')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$toolPath = Join-Path $projectRoot '.tooling\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $toolPath)) { throw '请安装 Flutter，并将本脚本的工具路径调整为你的 SDK 路径。' }
# Flutter 原生编译工具在部分 Windows 版本上不支持中文路径。
$mapping = & subst.exe
if (Test-Path 'B:\') {
  if (-not ($mapping -match [regex]::Escape($projectRoot))) { throw 'B: 已被使用，请为本脚本选择其他空闲盘符。' }
} else { & subst.exe B: $projectRoot }
Set-Location B:\
$env:PUB_CACHE = 'B:\.tooling\pub-cache'
$env:GRADLE_USER_HOME = 'B:\.tooling\gradle-cache'
$projectJdk = Get-ChildItem -LiteralPath 'B:\.tooling\jdk21' -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if ($projectJdk) { $env:JAVA_HOME = $projectJdk.FullName }
$env:ANDROID_HOME = 'B:\.tooling\android-sdk'
switch ($Task) {
  'check' {
    & .\.tooling\flutter\bin\flutter.bat analyze
    if ($LASTEXITCODE -ne 0) { throw '代码分析未通过' }
    & .\.tooling\flutter\bin\flutter.bat test
  }
  'apk' { & .\.tooling\flutter\bin\flutter.bat build apk --release }
  'web' { & .\.tooling\flutter\bin\flutter.bat build web --release --no-web-resources-cdn }
}
if ($LASTEXITCODE -ne 0) { throw 'Flutter 任务失败，请检查上方输出。' }

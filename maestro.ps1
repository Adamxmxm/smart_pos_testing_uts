# PowerShell runner for Maestro CLI
if (-not $env:JAVA_HOME -or -not (Test-Path $env:JAVA_HOME)) {
    $env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
}
& "$HOME\.maestro\bin\maestro.bat" @args

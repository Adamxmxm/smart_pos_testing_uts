@echo off
if not defined JAVA_HOME (
    set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
)
if not exist "%JAVA_HOME%" (
    set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
)
"%USERPROFILE%\.maestro\bin\maestro.bat" %*

@echo off
REM Build Pico Lab Power Mode LSPosed module.
REM Requires: JDK 26+, r8.jar, apktool.jar, platform.keystore (see build_mod.bat in pico4-winlimit for the shared toolchain).
setlocal
set REPO=%~dp0
set MOD=%REPO%app
set PKGDIR=com\peaklab\powermode
set APKNAME=picolab-power

REM -- toolchain (edit these paths to match your environment) --
set JAVA="C:\Program Files\Java\jdk-26.0.1\bin\java.exe"
set JAVAC="C:\Program Files\Java\jdk-26.0.1\bin\javac.exe"
set R8="C:\Users\wzy\.openclaw\workspace\pico4\r8.jar"
set APKTOOL="C:\Users\wzy\.openclaw\workspace\pico4\tools\apktool.jar"
set JARSIGNER="C:\Program Files\Java\jdk-26.0.1\bin\jarsigner.exe"
set KEYSTORE="C:\Users\wzy\.openclaw\workspace\pico4\work\platform.keystore"

echo === 1. compile ===
if exist "%MOD%\build\classes" rmdir /s /q "%MOD%\build\classes"
mkdir "%MOD%\build\classes"
dir /s /b "%MOD%\stub\*.java" "%MOD%\src\*.java" > "%MOD%\build\sources.txt"
%JAVAC% --release 8 -encoding UTF-8 -nowarn -d "%MOD%\build\classes" @"%MOD%\build\sources.txt"
if errorlevel 1 ( echo COMPILE FAILED & exit /b 1 )

echo === 2. dex ===
if exist "%MOD%\build\dex" rmdir /s /q "%MOD%\build\dex"
mkdir "%MOD%\build\dex"
dir /s /b "%MOD%\build\classes\%PKGDIR%\*.class" > "%MOD%\build\classlist.txt"
%JAVA% -cp "%R8%" com.android.tools.r8.D8 --min-api 29 --output "%MOD%\build\dex" "@%MOD%\build\classlist.txt"
if errorlevel 1 ( echo D8 FAILED & exit /b 1 )
copy /y "%MOD%\build\dex\classes.dex" "%MOD%\classes.dex" >nul

echo === 3. package ===
%JAVA% -jar "%APKTOOL%" b "%MOD%" -o "%MOD%\build\%APKNAME%-unsigned.apk" >nul 2>&1
if errorlevel 1 ( echo APKTOOL FAILED & exit /b 1 )

echo === 4. sign ===
copy /y "%MOD%\build\%APKNAME%-unsigned.apk" "%MOD%\build\%APKNAME%.apk" >nul
%JARSIGNER% -keystore "%KEYSTORE%" -storepass android -keypass android "%MOD%\build\%APKNAME%.apk" platform >nul 2>&1
if errorlevel 1 ( echo SIGN FAILED & exit /b 1 )

echo BUILD OK -^> %MOD%\build\%APKNAME%.apk
endlocal

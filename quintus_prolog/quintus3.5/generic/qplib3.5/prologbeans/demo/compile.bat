@echo off

rem Compile the sample code for MS Windows

SETLOCAL

rem The user can set the environment variable PBJARDIR to override
rem the location of prologbeans.jar

if "%PBJARDIR%"=="" set PBJARDIR=..\..\..\java3.5

javac -classpath "%PBJARDIR%\prologbeans.jar;." EvaluateGUI.java


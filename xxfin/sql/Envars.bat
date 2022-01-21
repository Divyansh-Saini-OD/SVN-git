@echo off

rem --- E-MAIL LIBRARIES ---
set CLASSPATH=c:\TAX\TWETaxObligation\lib\activation.jar;c:\TAX\TWETaxObligation\lib\mail.jar;%CLASSPATH%

rem --- ORACLE LIBRARIES ---
set CLASSPATH=c:\TAX\TWETaxObligation\OracleDrivers\classes12.zip;%CLASSPATH%

rem --- TAX BATCH LIBRARIES ---
set CLASSPATH=c:\TAX\TWETaxObligation;c:\TAX\TWETaxObligation\lib;c:\TAX\TWETaxObligation\eTWETaxObligation.jar;%CLASSPATH%

rem --- SYSTEM PATH ---
set PATH=C:\program files\ava\jdk1.5.0_06\bin;C:\program files\ava\jdk1.5.0_06\lib;c:\TAX\TWETaxObligation\lib;%PATH%

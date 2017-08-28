@ECHO OFF
for /l %%i IN (3000,1,3009) DO (
NET STOP sms_%%i
NET START sms_%%i
)

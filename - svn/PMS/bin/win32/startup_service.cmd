@ECHO OFF
SET NET_METHOD=%1
SET SRV_NAME=%2
SET RAILS_PORT=%3

NET %NET_METHOD% "%SRV_NAME%_%RAILS_PORT%"

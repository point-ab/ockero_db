@echo off
cd /d C:\Projekt\ockero_db\ockero_data_ingest
set PYTHONIOENCODING=utf-8
call venv\Scripts\activate
ockero-run > C:\Projekt\ockero_db\logs\ockero-data-ingest-log.log 2>&1
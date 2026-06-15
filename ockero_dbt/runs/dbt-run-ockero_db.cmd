@echo off
cd /d C:\Projekt\ockero_db\ockero_dbt
set PYTHONIOENCODING=utf-8
call venv\Scripts\activate
dbt run --profiles-dir C:\Projekt\ockero_db\ockero_dbt > C:\Projekt\ockero_db\logs\ockero-dbt-ockero_db.log 2>&1
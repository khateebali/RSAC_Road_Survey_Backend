# Run this yourself in PowerShell whenever you change backend code, or when
# the backend has stopped responding (health check shows DOWN or connection
# refused). Doesn't need Claude — this is the same sequence Claude runs.
#
# What it does, in order:
#   1. Makes sure the SSH tunnel to db-primary (the real Postgres server) is
#      up on localhost:15432 — the tunnel dies whenever this machine sleeps
#      or a terminal closes, so it's the #1 reason the backend looks "down."
#   2. Kills any old backend process still holding port 8070.
#   3. Rebuilds and starts the backend fresh (application-local.properties
#      profile — connects through the tunnel, not any local Postgres).

$tunnelUp = Get-NetTCPConnection -LocalPort 15432 -State Listen -ErrorAction SilentlyContinue
if (-not $tunnelUp) {
    Write-Host "SSH tunnel to db-primary is down — reconnecting..." -ForegroundColor Yellow
    # Port 6432 = PgBouncer on db-primary, not direct Postgres (5432). The
    # backend connects through the "gnn_survey_app" pool, matching the same
    # pattern nv_allnndb's own apps already use on this server.
    Start-Process ssh -ArgumentList "-f", "-N", "-L", "15432:localhost:6432", "db-primary" -NoNewWindow
    Start-Sleep -Seconds 2
} else {
    Write-Host "SSH tunnel already up." -ForegroundColor Green
}

$existing = Get-NetTCPConnection -LocalPort 8070 -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Stopping the backend process already using port 8070..." -ForegroundColor Yellow
    Stop-Process -Id $existing.OwningProcess -Force
    Start-Sleep -Seconds 1
}

Write-Host "Starting the backend (Ctrl+C to stop)..." -ForegroundColor Green
& ".\mvnw.cmd" spring-boot:run "-Dspring-boot.run.profiles=local"

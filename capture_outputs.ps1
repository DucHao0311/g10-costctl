# capture_outputs.ps1
# Chạy tất cả costctl commands và lưu output thật vào realCLI_output/
# Usage: .\capture_outputs.ps1 [-AppTag "Application=HealthBot"] [-Days 7]

param(
    [string]$AppTag = "Application=HealthBot",
    [int]$Days = 7
)

$date = Get-Date -Format "yyyy-MM-dd"
$out = "realCLI_output"

Write-Host "=== costctl real output capture — $date ===" -ForegroundColor Cyan
Write-Host "Output dir: $out" -ForegroundColor Cyan
Write-Host ""

# ---- list ec2 ----
Write-Host "[1/7] list ec2 (no filter)..." -ForegroundColor Yellow
python costctl.py list ec2 | Tee-Object -FilePath "$out\list_ec2_$date.txt"
Write-Host ""

# ---- list ec2 --missing-tag Application ----
Write-Host "[2/7] list ec2 --missing-tag Application..." -ForegroundColor Yellow
python costctl.py list ec2 --missing-tag Application | Tee-Object -FilePath "$out\list_ec2_missing_app_$date.txt"
Write-Host ""

# ---- list s3 ----
Write-Host "[3/7] list s3..." -ForegroundColor Yellow
python costctl.py list s3 | Tee-Object -FilePath "$out\list_s3_$date.txt"
Write-Host ""

# ---- list volume ----
Write-Host "[4/7] list volume..." -ForegroundColor Yellow
python costctl.py list volume | Tee-Object -FilePath "$out\list_volume_$date.txt"
Write-Host ""

# ---- list rds ----
Write-Host "[5/7] list rds..." -ForegroundColor Yellow
python costctl.py list rds | Tee-Object -FilePath "$out\list_rds_$date.txt"
Write-Host ""

# ---- cost ----
Write-Host "[6/7] cost --tag $AppTag --days $Days..." -ForegroundColor Yellow
$tagSlug = $AppTag -replace "=", "_"
python costctl.py cost --tag $AppTag --days $Days | Tee-Object -FilePath "$out\cost_${tagSlug}_$date.txt"
Write-Host ""

# ---- migrate-gp3 dry-run ----
Write-Host "[7/7] migrate-gp3 (dry-run)..." -ForegroundColor Yellow
python costctl.py migrate-gp3 | Tee-Object -FilePath "$out\migrate_gp3_dryrun_$date.txt"
Write-Host ""

Write-Host "=== Done! Files saved to $out\ ===" -ForegroundColor Green
Get-ChildItem $out | Format-Table Name, Length, LastWriteTime

param(
    [int]$Espera = 20
)

$Passo = "$($Espera * 3)s"
$PassoLongo = "$($Espera * 2 + 10)s"

New-Item -ItemType Directory -Force -Path logs | Out-Null

Write-Host ""
Write-Host "1. Funcionamento normal"

docker compose --profile sensores down
docker compose up -d --build
Start-Sleep -Seconds $Espera

docker compose ps
docker compose logs kafka-init | Out-File -FilePath "logs\criacao-topico.log" -Encoding utf8
& "$PSScriptRoot\save-logs.ps1" -Nome funcionamento-normal -Desde $Passo

Write-Host ""
Write-Host "2. Balanceamento com 3 consumers"

& "$PSScriptRoot\scale-consumer.ps1" -Quantidade 3
Start-Sleep -Seconds $Espera

& "$PSScriptRoot\topic-info.ps1" | Out-File -FilePath "logs\balanceamento-grupo.log" -Encoding utf8
& "$PSScriptRoot\save-logs.ps1" -Nome balanceamento -Desde $Passo

Write-Host ""
Write-Host "3. Rebalanço ao derrubar um consumer"

& "$PSScriptRoot\stop-consumer.ps1"
Start-Sleep -Seconds $Espera

& "$PSScriptRoot\topic-info.ps1" | Out-File -FilePath "logs\rebalanco-grupo.log" -Encoding utf8
& "$PSScriptRoot\save-logs.ps1" -Nome rebalanco-consumer -Desde $Passo

Write-Host ""
Write-Host "4. Failover ao derrubar o kafka1"

& "$PSScriptRoot\topic-info.ps1" | Out-File -FilePath "logs\failover-topico-antes.log" -Encoding utf8

& "$PSScriptRoot\stop-broker.ps1" -Broker kafka1
Start-Sleep -Seconds $Espera
& "$PSScriptRoot\topic-info.ps1" | Out-File -FilePath "logs\failover-topico-durante.log" -Encoding utf8

& "$PSScriptRoot\start-broker.ps1" -Broker kafka1
Start-Sleep -Seconds $Espera
& "$PSScriptRoot\topic-info.ps1" | Out-File -FilePath "logs\failover-topico-depois.log" -Encoding utf8

& "$PSScriptRoot\save-logs.ps1" -Nome failover-broker -Desde $PassoLongo

Write-Host ""
Write-Host "5. Elasticidade de 1 para 3 consumers"

& "$PSScriptRoot\scale-consumer.ps1" -Quantidade 1
Start-Sleep -Seconds $Espera

& "$PSScriptRoot\scale-consumer.ps1" -Quantidade 3
Start-Sleep -Seconds $Espera

& "$PSScriptRoot\save-logs.ps1" -Nome elasticidade -Desde $PassoLongo

Write-Host ""
Write-Host "6. Múltiplos sensores"

& "$PSScriptRoot\start-sensores.ps1"
Start-Sleep -Seconds $Espera

& "$PSScriptRoot\save-logs.ps1" -Nome multiplos-sensores -Desde $Passo

Write-Host ""
Write-Host "Testes concluídos. Logs gerados:"

Get-ChildItem logs
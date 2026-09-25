param(
    [string]$Broker = "kafka1"
)

Write-Host "Iniciando broker $Broker..."

docker compose start $Broker

Write-Host "Broker $Broker iniciado."
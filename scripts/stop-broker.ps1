param(
    [string]$Broker = "kafka1"
)

Write-Host "Parando broker $Broker..."

docker compose stop $Broker

Write-Host "Broker $Broker parado."
Write-Host "Observe os logs: o producer e os consumers continuam usando os outros brokers."
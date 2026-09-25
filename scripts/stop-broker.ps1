param(
    [string]$Broker = "kafka1"
)

Write-Host "Parando broker $Broker..."

docker compose stop $Broker

Write-Host "Broker $Broker parado."
param(
    [switch]$Parar
)

if ($Parar) {
    Write-Host "Removendo os sensores extras..."

    docker compose --profile sensores stop producer-2 producer-3
    docker compose --profile sensores rm -f producer-2 producer-3

    Write-Host "Sensores extras removidos."
    exit
}

Write-Host "Subindo os sensores extras (sensor-02 e sensor-03)..."

docker compose --profile sensores up -d --no-deps producer-2 producer-3

Write-Host "Agora são 3 producers enviando para o mesmo tópico."
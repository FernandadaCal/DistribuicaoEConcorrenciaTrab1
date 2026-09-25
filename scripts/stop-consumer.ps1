$ConsumerId = docker ps `
    --filter "label=com.docker.compose.service=consumer" `
    --format "{{.ID}}" |
    Select-Object -First 1

if (-not $ConsumerId) {
    Write-Host "Nenhum consumer em execução."
    exit
}

Write-Host "Parando consumer $ConsumerId..."

docker stop $ConsumerId

Write-Host "Consumer parado."
Write-Host "Observe os logs dos outros consumers para verificar o rebalanço."
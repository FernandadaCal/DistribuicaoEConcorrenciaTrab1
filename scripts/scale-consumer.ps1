param(
    [int]$Quantidade = 3
)

Write-Host "Alterando quantidade de consumers para $Quantidade..."

docker compose up -d --scale consumer=$Quantidade consumer

Write-Host "$Quantidade consumers em execução."
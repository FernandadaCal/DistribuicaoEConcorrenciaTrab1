param(
    [Parameter(Mandatory = $true)]
    [string]$Nome,

    [string]$Desde = "2m",

    [string[]]$Servico = @("producer", "consumer")
)

New-Item -ItemType Directory -Force -Path logs | Out-Null

$Arquivo = "logs\$Nome.log"

docker compose --profile sensores logs --no-color --timestamps --since $Desde @Servico |
    Out-File -FilePath $Arquivo -Encoding utf8

Write-Host "Logs salvos em $Arquivo"
param(
    [string[]]$Servico = @("consumer")
)

docker compose --profile sensores logs -f @Servico
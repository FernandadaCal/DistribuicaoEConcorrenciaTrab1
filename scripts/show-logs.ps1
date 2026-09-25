param(
    [string]$Servico = "consumer"
)

docker compose logs -f $Servico
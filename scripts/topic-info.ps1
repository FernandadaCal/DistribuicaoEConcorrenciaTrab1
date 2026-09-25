docker exec kafka1 /opt/kafka/bin/kafka-topics.sh `
    --bootstrap-server kafka1:19092 `
    --describe `
    --topic dados-sensores

Write-Host ""
Write-Host "Partições de cada consumer do grupo:"

docker exec kafka1 /opt/kafka/bin/kafka-consumer-groups.sh `
    --bootstrap-server kafka1:19092 `
    --describe `
    --group processadores-sensores
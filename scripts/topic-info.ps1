docker exec kafka2 /opt/kafka/bin/kafka-topics.sh `
    --bootstrap-server kafka2:19092 `
    --describe `
    --topic dados-sensores

Write-Host ""
Write-Host "Partições de cada consumer do grupo:"

docker exec kafka2 /opt/kafka/bin/kafka-consumer-groups.sh `
    --bootstrap-server kafka2:19092 `
    --describe `
    --group processadores-sensores
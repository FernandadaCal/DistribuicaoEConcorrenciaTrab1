# Relatório - Sistema de Monitoramento de Sensores com Kafka

Disciplina: Distribuição e Concorrência
Alunos: Fernanda da Cal Figueiredo e Pedro Vanini de Souza Lage


## 1. Arquitetura

A ideia do trabalho é simular sensores de uma fábrica mandando dados pro Kafka
e ter consumidores lendo esses dados e avisando quando a temperatura passa do limite.

O que a gente montou:

- 3 brokers Kafka (kafka1, kafka2 e kafka3). Usamos o modo KRaft, então não
  precisou de ZooKeeper, os próprios brokers fazem o papel de controller.
- Um tópico chamado `dados-sensores` com 3 partições e fator de replicação 2.
  O tópico é criado sozinho por um container chamado `kafka-init` quando o sistema sobe.
- Producers em Python que fingem ser sensores. Eles geram temperatura e vibração
  aleatórias e mandam um JSON a cada 2 segundos.
- Consumers em Python, todos no mesmo consumer group (`processadores-sensores`).
  Eles leem as mensagens, imprimem no log e se a temperatura for maior que 80 °C
  imprimem um [ALERTA].

Tudo roda em Docker com docker compose.

```text
 producer   (sensor-01) ─┐                                   ┌─ consumer-1
 producer-2 (sensor-02)  ├──► tópico dados-sensores ─────────┼─ consumer-2   grupo:
 producer-3 (sensor-03) ─┘    3 partições, replicação 2      └─ consumer-3   processadores-sensores
                              │
                   ┌──────────┼──────────┐
                kafka1     kafka2     kafka3     (3 brokers + controllers KRaft)
```

## 2. Como cada parte funciona

### 2.1 Brokers

Cada broker tem duas portas: uma interna (kafkaN:19092) que os containers usam
pra falar entre si, e uma externa (localhost:29092, 39092 e 49092) caso a gente
queira acessar de fora do docker. O tópico interno de offsets tá com replicação 3,
então se um broker cair o consumer group não perde onde parou.

### 2.2 Producers

O `producer/producer.py` gera os valores dentro das faixas que estão no `.env`
e manda com `KafkaProducer.send()`. A gente chama o `.get()` no resultado pra
esperar a confirmação e pegar em qual partição e offset a mensagem caiu, e isso
é impresso no log. Como a mensagem não tem chave, o Kafka vai distribuindo entre
as partições.

### 2.3 Consumers e consumer group

O `consumer/consumer.py` cria um `KafkaConsumer` no tópico com
`group_id=processadores-sensores`. Como estão todos no mesmo grupo, o Kafka
garante que cada partição só é lida por um consumer de cada vez, e é isso que dá
o paralelismo e o balanceamento. No log o consumer aparece com o hostname do
container pra gente conseguir diferenciar um do outro.

### 2.4 Partições e replicação

- 3 partições, então dá pra ter até 3 consumers trabalhando ao mesmo tempo.
- Replicação 2, então cada partição tem um líder em um broker e uma cópia em outro.
  Se um broker cair, outro vira líder e nada se perde.

## 3. Testes que fizemos

| Teste                 | Como fizemos                                             | Log                             |
|-----------------------|----------------------------------------------------------|---------------------------------|
| Funcionamento normal  | `docker compose up -d --build`                           | `logs/funcionamento-normal.log` |
| Balanceamento         | `scale-consumer.ps1 -Quantidade 3`                       | `logs/balanceamento.log`        |
| Rebalanço             | `stop-consumer.ps1` com 3 consumers rodando              | `logs/rebalanco-consumer.log`   |
| Failover              | `stop-broker.ps1 -Broker kafka1` e depois `start-broker` | `logs/failover-broker.log`      |
| Múltiplos sensores    | `start-sensores.ps1` (sobe o sensor-02 e o sensor-03)    | `logs/multiplos-sensores.log`   |
| Elasticidade          | `scale-consumer.ps1 -Quantidade 1` e depois `3`          | `logs/elasticidade.log`         |

O `topic-info.ps1` gera mais alguns arquivos com a saída do
`kafka-topics --describe` e do `kafka-consumer-groups --describe` em cada momento
do teste: `balanceamento-grupo.log`, `rebalanco-grupo.log`,
`failover-topico-antes.log`, `failover-topico-durante.log`,
`failover-topico-depois.log`, `elasticidade-grupo-antes.log` e
`elasticidade-grupo-depois.log`. Tudo isso sai de uma vez rodando
`scripts/run-tests.ps1`.

## 4. O que funcionou

Basicamente tudo que foi pedido: o cluster com 3 brokers, o tópico sendo criado
sozinho, o envio e consumo com alerta, o balanceamento, o rebalanço, o failover,
a elasticidade e os múltiplos sensores.

## 5. O que não funcionou

- O componente de banco de dados ou logger do enunciado ficou incompleto. O
  consumer só imprime os dados processados e os alertas no stdout, não grava em
  banco nem em arquivo. O que fica guardado pra análise depois é o log do Docker
  salvo pelo `save-logs.ps1` na pasta `logs/`.
- O producer usa o `acks` padrão do kafka-python, que é 1: o líder confirma antes
  de replicar. Com replicação 2 e `min.insync.replicas=1`, se o líder caísse
  exatamente entre confirmar e replicar, a mensagem poderia se perder. Nos nossos
  testes não vimos perda, mas não é garantia.
- O consumer usa commit automático de offset, que é o padrão. No rebalanço isso
  pode fazer uma mensagem ser processada duas vezes, ou o offset ser commitado
  antes do processamento. A gente não tratou isso com commit manual.
- Os brokers não têm volume, então `docker compose down` apaga os dados do
  cluster e o tópico é recriado do zero no próximo `up`.

## 6. Problemas que tivemos e como resolvemos

| Problema | Por que acontecia | O que fizemos |
|----------|-------------------|---------------|
| O tópico não era criado pelo `kafka-init` | O `command` tava como string no compose, então o docker quebrava por espaço e o `sh -c` só rodava um `echo` e saía com sucesso | Passamos o script como um item único de lista e colocamos ele pra esperar os 3 brokers antes de criar |
| Producer e consumer davam erro ao subir (`NoBrokersAvailable`) | Subiam antes do Kafka estar pronto e a gente tinha que dar restart na mão | `depends_on` esperando o `kafka-init` terminar e `restart: on-failure` |
| Escalar consumers religava o broker que a gente tinha parado | O `docker compose up` sobe as dependências junto | Colocamos `--no-deps` nos scripts e no Makefile |
| Vários producers com o mesmo `SENSOR_ID` | Com `--scale producer` todos usavam o mesmo `.env` | Criamos os serviços `producer-2` e `producer-3` no compose, cada um com seu id |
| Os logs dos testes saíam quase vazios | O Python guarda o `print` em buffer quando o stdout não é um terminal, então as linhas do producer e do consumer só apareciam no `docker logs` muito depois | Colocamos `ENV PYTHONUNBUFFERED=1` nos dois Dockerfiles, e o `save-logs.ps1` passou a salvar só os serviços da aplicação em vez de todos |

## 7. Conclusão

O trabalho ajudou a entender na prática como o Kafka distribui mensagens, faz o balanceamento entre consumers e mantém o sistema funcionando mesmo quando algum consumer ou broker cai. Também foi possível testar a escalabilidade do sistema e observar como o grupo se reorganiza automaticamente conforme novos consumers e producers são adicionados.
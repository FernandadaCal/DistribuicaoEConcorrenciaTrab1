# Alunos: Fernanda da Cal Figueiredo e Pedro Vanini de Souza Lage
# Matriculas: 2312090 e 2310605

# Sistema de Monitoramento de Sensores com Kafka

Trabalho da disciplina de Distribuição e Concorrência.

## Descrição

O sistema simula sensores de uma fábrica que publicam leituras de temperatura e
vibração em um cluster Apache Kafka. Um grupo de consumidores processa as
mensagens em paralelo e emite alertas quando a temperatura ultrapassa um limite.

O objetivo é demonstrar, na prática, balanceamento de carga, elasticidade,
rebalanço de consumidores e tolerância a falhas em um sistema distribuído
baseado em mensageria.

## Tecnologias

- Python 3.12 (`kafka-python`, `python-dotenv`)
- Apache Kafka 4.x em modo KRaft (sem ZooKeeper)
- Docker e Docker Compose

## Arquitetura

```text
 producer   (sensor-01) ─┐                                   ┌─ consumer-1
 producer-2 (sensor-02)  ├──► tópico dados-sensores ─────────┼─ consumer-2   grupo:
 producer-3 (sensor-03) ─┘    3 partições, replicação 2      └─ consumer-3   processadores-sensores
                              │
                   ┌──────────┼──────────┐
                kafka1     kafka2     kafka3     (3 brokers + controllers KRaft)
```

Cada serviço do `docker-compose.yml`:

- `kafka1`, `kafka2` e `kafka3`: os 3 brokers do cluster. Cada um também
  participa do quórum KRaft, por isso não existe ZooKeeper;
- `kafka-init`: espera os 3 brokers responderem e cria o tópico
  `dados-sensores` com 3 partições e fator de replicação 2;
- `producer`: sensor simulado, gera uma leitura a cada `SENSOR_INTERVAL`
  segundos;
- `producer-2` e `producer-3`: sensores extras usados no teste de múltiplos
  producers, só sobem com o profile `sensores`;
- `consumer`: processa as leituras e emite `[ALERTA]` acima de
  `TEMPERATURE_LIMIT`. Pode ser escalado de 1 a 3 instâncias.

Como o tópico tem 3 partições, até 3 consumers do mesmo grupo trabalham em
paralelo, cada um responsável por uma partição. Com fator de replicação 2, cada
partição tem cópia em dois brokers, então a queda de qualquer broker não
interrompe o sistema.

## Pré-requisitos

- Git
- Docker Desktop (com o Docker Engine em execução)
- Opcional: `make` (no Windows todos os comandos também existem em `scripts/*.ps1`)

## Instalação

```powershell
git clone <URL_DO_REPOSITORIO>
cd DistribuicaoEConcorrenciaTrab1
Copy-Item .env.example .env
```

## Configuração

Todas as variáveis ficam no `.env`, que não é versionado. O `.env.example` tem
os valores padrão:

- `KAFKA_TOPIC`: tópico usado pelo producer e pelo consumer (`dados-sensores`);
- `KAFKA_CONSUMER_GROUP`: grupo dos consumers (`processadores-sensores`);
- `SENSOR_ID`: identificação do sensor (`sensor-01`);
- `SENSOR_INTERVAL`: intervalo entre as leituras, em segundos (`2`);
- `TEMPERATURE_MIN` e `TEMPERATURE_MAX`: faixa de temperatura gerada (`20` e `100`);
- `VIBRATION_MIN` e `VIBRATION_MAX`: faixa de vibração gerada (`0` e `10`);
- `TEMPERATURE_LIMIT`: acima disso o consumer emite alerta (`80`).

Dentro da rede do Compose, `KAFKA_BOOTSTRAP_SERVERS` é sobrescrito pelo
`docker-compose.yml` para `kafka1:19092,kafka2:19092,kafka3:19092`.

## Como executar

```powershell
docker compose up -d --build      # ou: make up
docker compose ps                 # ou: make status
```

Esperado: `kafka1`, `kafka2`, `kafka3`, `producer` e `consumer` em execução e
`kafka-init` com status `Exited (0)`. O tópico é criado automaticamente pelo
`kafka-init`; producer e consumer só iniciam depois que ele termina.

Conferir o tópico:

```powershell
.\scripts\topic-info.ps1          # ou: make topic
```

## Como visualizar logs

```powershell
docker compose logs -f producer consumer   # ou: make logs
.\scripts\show-logs.ps1 consumer           # ou: make logs-consumer
.\scripts\show-logs.ps1 producer           # ou: make logs-producer
docker compose logs kafka-init             # ou: make logs-init
```

Formato das linhas:

```text
[PRODUCER sensor-01] Topico=dados-sensores | Particao=2 | Offset=41 | Temperatura=87.3 °C | Vibracao=4.1
[CONSUMER a1b2c3d4e5f6] Particao=2 | Offset=41 | Sensor=sensor-01 | Temperatura=87.3 °C | Vibracao=4.1
[ALERTA] Consumer=a1b2c3d4e5f6 | Sensor=sensor-01 | Temperatura=87.3 °C
```

Para salvar evidências em `logs/<nome>.log`:

```powershell
.\scripts\save-logs.ps1 -Nome funcionamento-normal -Desde 2m
.\scripts\run-tests.ps1   # roda a sequência completa de testes e salva todos os logs
```

## Testes

### Balanceamento de carga

```powershell
.\scripts\scale-consumer.ps1 -Quantidade 3     # ou: make scale-three
.\scripts\show-logs.ps1 consumer
```

Cada consumer passa a receber mensagens de uma única partição (`Particao=0`,
`1` e `2`), mostrando a divisão de carga. `.\scripts\topic-info.ps1` mostra a
atribuição partição → consumer.

### Rebalanço (queda de consumer)

Com 3 consumers rodando:

```powershell
.\scripts\stop-consumer.ps1                    # ou: make stop-consumer
.\scripts\show-logs.ps1 consumer
```

O Kafka detecta a saída do consumer e redistribui a partição dele para um dos
consumers restantes, que passa a logar duas partições. Nenhuma mensagem é perdida.

### Failover (queda de broker)

```powershell
.\scripts\stop-broker.ps1 -Broker kafka1       # ou: make stop-broker
.\scripts\topic-info.ps1
.\scripts\show-logs.ps1 producer,consumer
.\scripts\start-broker.ps1 -Broker kafka1      # ou: make start-broker
```

Com fator de replicação 2, as partições cujo líder estava no `kafka1` elegem um
novo líder nos outros brokers. Producer e consumers continuam funcionando.
Ao religar o broker, ele volta para o ISR (in-sync replicas).

### Elasticidade

```powershell
.\scripts\scale-consumer.ps1 -Quantidade 1     # ou: make scale-one
.\scripts\scale-consumer.ps1 -Quantidade 3     # ou: make scale-three
```

Com 1 consumer, ele processa as 3 partições. Ao escalar para 3, o grupo
rebalanceia e cada consumer fica com uma partição, sem parar o sistema.

### Múltiplos sensores

```powershell
.\scripts\start-sensores.ps1                   # ou: make sensores
.\scripts\show-logs.ps1 producer,producer-2,producer-3,consumer
.\scripts\start-sensores.ps1 -Parar            # ou: make sensores-down
```

Sobe `sensor-02` e `sensor-03`. Os consumers passam a receber leituras dos três
sensores no mesmo tópico.

## Roteiro de demonstração

1. Mostrar a arquitetura (diagrama acima).
2. `docker compose up -d --build` e `docker compose ps`.
3. `show-logs.ps1 producer,consumer`: Producer → Kafka → Consumer e alertas.
4. `scale-consumer.ps1 -Quantidade 3`: balanceamento por partição.
5. `stop-consumer.ps1`: rebalanço.
6. `stop-broker.ps1` / `topic-info.ps1` / `start-broker.ps1`: failover.
7. `scale-consumer.ps1 -Quantidade 1` e depois `3`: elasticidade.
8. `start-sensores.ps1`: múltiplos sensores.

## Como encerrar o ambiente

```powershell
docker compose stop                      # para sem remover
docker compose --profile sensores down   # remove containers e rede (ou: make down)
```

Após `down` o cluster sobe do zero no próximo `up` e o `kafka-init` recria o
tópico automaticamente.

## Estrutura de pastas

```text
.
├── consumer/
│   ├── consumer.py         # recebe, processa e emite alertas
│   ├── Dockerfile
│   └── requirements.txt
├── producer/
│   ├── producer.py         # simula um sensor e publica no Kafka
│   ├── Dockerfile
│   └── requirements.txt
├── scripts/                # atalhos em PowerShell, rodados da raiz do projeto
│   ├── scale-consumer.ps1
│   ├── stop-consumer.ps1
│   ├── stop-broker.ps1
│   ├── start-broker.ps1
│   ├── start-sensores.ps1
│   ├── show-logs.ps1
│   ├── topic-info.ps1
│   ├── save-logs.ps1
│   └── run-tests.ps1       # roda todos os testes e salva os logs
├── logs/                   # evidências dos testes (gerados com save-logs)
├── docker-compose.yml      # 3 brokers, kafka-init, producer(s) e consumer
├── Makefile
├── .env.example
├── RELATORIO.md
└── Readme.md
```

## Problemas conhecidos e soluções adotadas

- o tópico não era criado automaticamente. O `command` do `kafka-init` estava
  escrito como string, e o Compose faz o split por espaços, então o `sh -c`
  recebia só `echo` como script e saía com sucesso sem criar nada. Foi corrigido
  passando o script como item único de lista e esperando os 3 brokers antes de
  criar o tópico;
- producer e consumer subiam antes do Kafka estar pronto. Agora dependem do
  `kafka-init` com `condition: service_completed_successfully` e têm
  `restart: on-failure`, então não é mais preciso rodar
  `docker compose restart producer consumer`;
- `docker compose up --scale` religava um broker parado. Os scripts e o
  Makefile usam `--no-deps` ao escalar consumers, para não atrapalhar o teste
  de failover;
- na primeira execução o download das imagens pode levar alguns minutos.
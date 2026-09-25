# Guia para continuar e finalizar o projeto

Este guia considera que a parte funcional principal já foi implementada e testada.

## O que já foi validado

Já foi testado com sucesso:

- cluster Kafka com 3 brokers;
- tópico `dados-sensores`;
- 3 partições;
- fator de replicação 2;
- Producer enviando dados;
- Consumer recebendo e processando dados;
- alertas para temperatura alta;
- balanceamento de carga entre consumers;
- rebalanço após queda de consumer;
- failover após queda de broker;
- múltiplos sensores/producers;
- elasticidade de 1 para 3 consumers.

Não é necessário repetir todos esses testes agora. O foco é terminar e organizar o projeto.

---

# 1. Como subir o projeto em outra máquina

## Pré-requisitos

Instalar:

- Git
- Docker Desktop

Depois de instalar o Docker Desktop, abrir o programa e esperar o Docker ficar totalmente iniciado.

## Clonar o repositório

```powershell
git clone <URL_DO_REPOSITORIO>
cd DistribuicaoEConcorrenciaTrab1
```

## Criar o `.env`

O `.env` não deve ficar versionado.

Enquanto o `.env.example` ainda não existir, pedir para a Fernanda o conteúdo atual do `.env`.

Depois que o `.env.example` for criado:

```powershell
Copy-Item .env.example .env
```

## Subir os containers

Na raiz do projeto:

```powershell
docker compose up -d --build
```

Verificar:

```powershell
docker compose ps
```

O esperado é ver, no mínimo:

```text
kafka1
kafka2
kafka3
producer
consumer
```

## Se o tópico ainda não for criado automaticamente

Problema conhecido: o `kafka-init` ainda precisa ser corrigido.

Caso `dados-sensores` não exista:

```powershell
docker exec kafka1 /opt/kafka/bin/kafka-topics.sh `
  --bootstrap-server kafka1:19092 `
  --create `
  --if-not-exists `
  --topic dados-sensores `
  --partitions 3 `
  --replication-factor 2
```

## Se Producer ou Consumer falharem ao iniciar

Pode acontecer de eles tentarem se conectar antes de o Kafka estar pronto.

Se aparecer `KafkaTimeoutError` ou `Unable to bootstrap`:

```powershell
docker compose restart producer consumer
```

Para conferir funcionamento:

```powershell
docker compose logs --since=1m producer consumer
```

---

# 2. O que ainda falta fazer

## 2.1 Corrigir o `kafka-init`

Objetivo:

```powershell
docker compose up -d --build
```

deve criar automaticamente o tópico `dados-sensores`, sem comando manual.

O `kafka-init` deve:

1. esperar os brokers Kafka ficarem disponíveis;
2. criar `dados-sensores`;
3. usar 3 partições;
4. usar fator de replicação 2;
5. usar `--if-not-exists`.

---

## 2.2 Melhorar a inicialização de Producer e Consumer

Hoje eles podem subir antes do Kafka e falhar.

Adicionar lógica de retry para:

- tentar conectar ao Kafka;
- esperar alguns segundos em caso de falha;
- tentar novamente sem encerrar o container.

Objetivo: não precisar mais executar:

```powershell
docker compose restart producer consumer
```

manualmente.

---

## 2.3 Criar `.env.example`

Criar um arquivo:

```text
.env.example
```

com todas as variáveis necessárias, mas sem informações privadas.

Exemplo de variáveis:

```env
KAFKA_BOOTSTRAP_SERVERS=
KAFKA_TOPIC=dados-sensores
KAFKA_CONSUMER_GROUP=processadores-sensores
SENSOR_ID=sensor-01
SENSOR_INTERVAL=2
TEMPERATURE_MIN=20
TEMPERATURE_MAX=100
VIBRATION_MIN=0
VIBRATION_MAX=10
TEMPERATURE_LIMIT=80
```

O `.env` real deve continuar no `.gitignore`.

---

## 2.4 Revisar os scripts PowerShell

Revisar a pasta `scripts/`.

Os scripts devem facilitar:

- parar broker;
- iniciar broker;
- parar consumer;
- escalar consumers;
- mostrar logs.

Confirmar que todos funcionam a partir da raiz do projeto.

---

## 2.5 Revisar o Makefile

O Makefile deve oferecer comandos simples para as principais operações.

Exemplos:

```text
make up
make down
make build
make logs
make logs-consumer
make logs-producer
make scale-one
make scale-three
make stop-broker
make start-broker
make status
```

Importante: o professor pediu Makefile mesmo que no Windows os testes sejam feitos diretamente com Docker/PowerShell.

---

## 2.6 Salvar logs dos testes

Depois que o ambiente estiver estável, repetir apenas os testes necessários para gerar evidências.

Salvar logs separados, por exemplo:

```text
logs/
├── funcionamento-normal.log
├── balanceamento.log
├── rebalanco-consumer.log
├── failover-broker.log
├── multiplos-sensores.log
└── elasticidade.log
```

Esses arquivos devem mostrar claramente:

- Producer enviando;
- Consumer recebendo;
- partições distribuídas;
- consumer caindo e outro assumindo;
- broker caindo e sistema continuando;
- múltiplos sensores;
- escala de 1 para 3 consumers.

---

## 2.7 Finalizar o README

O README final deve conter:

- descrição do projeto;
- arquitetura;
- pré-requisitos;
- instalação;
- configuração;
- como executar;
- como visualizar logs;
- como testar balanceamento;
- como testar rebalanço;
- como testar failover;
- como testar elasticidade;
- como encerrar o ambiente;
- estrutura de pastas;
- problemas conhecidos, se ainda existirem.

---

## 2.8 Fazer o relatório

O relatório deve registrar:

- arquitetura usada;
- funcionamento dos brokers;
- produtores;
- consumers;
- consumer group;
- partições;
- replicação;
- balanceamento;
- elasticidade;
- failover;
- rebalanço;
- testes realizados;
- o que funcionou;
- problemas encontrados;
- soluções adotadas;
- prints e trechos de logs.

---

## 2.9 Preparar a apresentação

Separar uma demonstração curta com esta ordem:

```text
1. Mostrar arquitetura
2. Subir o sistema
3. Mostrar Producer → Kafka → Consumer
4. Mostrar balanceamento
5. Mostrar queda de consumer e rebalanço
6. Mostrar queda de broker e failover
7. Mostrar elasticidade
8. Mostrar múltiplos sensores
```

Todos do grupo devem entender cada parte do sistema.

---

# 3. Estado ideal antes da entrega

Ao final, uma pessoa deve conseguir clonar e executar apenas:

```powershell
git clone <URL_DO_REPOSITORIO>
cd DistribuicaoEConcorrenciaTrab1
Copy-Item .env.example .env
docker compose up -d --build
```

E o sistema deve:

- criar os 3 brokers;
- criar automaticamente o tópico;
- subir Producer;
- subir Consumer;
- conectar tudo sem restart manual.

Depois:

```powershell
docker compose ps
```

e:

```powershell
docker compose logs -f producer consumer
```

devem ser suficientes para comprovar que o sistema está funcionando.

---

# 4. Para parar o ambiente

Parar sem remover:

```powershell
docker compose stop
```

Remover containers e rede:

```powershell
docker compose down
```

Durante o desenvolvimento, enquanto o `kafka-init` ainda não estiver corrigido, prefira `docker compose stop`.

"""
Consumer responsável por receber e processar
os dados enviados pelos sensores através do Kafka.
"""

import json
import os
import socket

from dotenv import load_dotenv
from kafka import KafkaConsumer


load_dotenv()


KAFKA_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS").split(",")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC")
CONSUMER_GROUP = os.getenv("KAFKA_CONSUMER_GROUP")

TEMPERATURE_LIMIT = float(os.getenv("TEMPERATURE_LIMIT"))

CONSUMER_ID = socket.gethostname()


def processar_dados(dados, partition, offset):
    """
    Processa uma leitura recebida de um sensor e
    identifica possíveis anomalias de temperatura.
    """

    sensor_id = dados.get("sensor_id")
    temperatura = dados.get("temperatura")
    vibracao = dados.get("vibracao")

    print(
        f"[CONSUMER {CONSUMER_ID}] "
        f"Particao={partition} | "
        f"Offset={offset} | "
        f"Sensor={sensor_id} | "
        f"Temperatura={temperatura} °C | "
        f"Vibracao={vibracao}"
    )

    if temperatura > TEMPERATURE_LIMIT:
        print(
            f"[ALERTA] Consumer={CONSUMER_ID} | "
            f"Sensor={sensor_id} | "
            f"Temperatura={temperatura} °C"
        )


def criar_consumer():
    """
    Cria e retorna um consumidor conectado
    ao cluster Kafka.
    """

    return KafkaConsumer(
        KAFKA_TOPIC,
        bootstrap_servers=KAFKA_SERVERS,
        group_id=CONSUMER_GROUP,
        auto_offset_reset="earliest",
        value_deserializer=lambda value: json.loads(
            value.decode("utf-8")
        ),
    )


def main():
    """
    Inicializa o consumidor e processa continuamente
    as mensagens recebidas do Kafka.
    """

    print(f"Consumer iniciado: {CONSUMER_ID}")
    print(f"Topico: {KAFKA_TOPIC}")
    print(f"Grupo: {CONSUMER_GROUP}")

    consumer = criar_consumer()

    for mensagem in consumer:
        processar_dados(
            mensagem.value,
            mensagem.partition,
            mensagem.offset,
        )


if __name__ == "__main__":
    main()
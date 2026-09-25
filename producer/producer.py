"""
Producer responsável por simular os sensores da fábrica
e enviar os dados gerados para o Apache Kafka.
"""

import json
import os
import random
import time
from datetime import datetime

from dotenv import load_dotenv
from kafka import KafkaProducer


load_dotenv()


KAFKA_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS").split(",")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC")

SENSOR_ID = os.getenv("SENSOR_ID")

SENSOR_INTERVAL = float(os.getenv("SENSOR_INTERVAL"))

TEMPERATURE_MIN = float(os.getenv("TEMPERATURE_MIN"))
TEMPERATURE_MAX = float(os.getenv("TEMPERATURE_MAX"))

VIBRATION_MIN = float(os.getenv("VIBRATION_MIN"))
VIBRATION_MAX = float(os.getenv("VIBRATION_MAX"))


def gerar_dados_sensor():
    """
    Gera valores aleatórios de temperatura e vibração
    para simular um sensor de uma máquina industrial.
    """

    return {
        "sensor_id": SENSOR_ID,
        "temperatura": round(
            random.uniform(TEMPERATURE_MIN, TEMPERATURE_MAX),
            2,
        ),
        "vibracao": round(
            random.uniform(VIBRATION_MIN, VIBRATION_MAX),
            2,
        ),
        "timestamp": datetime.now().isoformat(),
    }


def criar_producer():
    """
    Cria e retorna uma conexão com o cluster Kafka.
    """

    return KafkaProducer(
        bootstrap_servers=KAFKA_SERVERS,
        value_serializer=lambda value: json.dumps(value).encode("utf-8"),
    )


def main():
    """
    Gera continuamente dados do sensor e os envia
    para o tópico Kafka configurado.
    """

    print(f"Sensor {SENSOR_ID} iniciado.")

    producer = criar_producer()

    while True:
        dados = gerar_dados_sensor()

        resultado = producer.send(
            KAFKA_TOPIC,
            value=dados,
        )

        metadata = resultado.get(timeout=10)

        print(
            f"[PRODUCER {SENSOR_ID}] "
            f"Topico={metadata.topic} | "
            f"Particao={metadata.partition} | "
            f"Offset={metadata.offset} | "
            f"Temperatura={dados['temperatura']} °C | "
            f"Vibracao={dados['vibracao']}"
        )

        time.sleep(SENSOR_INTERVAL)


if __name__ == "__main__":
    main()
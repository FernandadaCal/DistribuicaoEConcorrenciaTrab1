up:
	docker compose up -d --build

down:
	docker compose --profile sensores down

build:
	docker compose build

logs:
	docker compose --profile sensores logs -f

logs-consumer:
	docker compose logs -f consumer

logs-producer:
	docker compose --profile sensores logs -f producer producer-2 producer-3

logs-init:
	docker compose logs kafka-init

scale-one:
	docker compose up -d --no-deps --scale consumer=1 consumer

scale-three:
	docker compose up -d --no-deps --scale consumer=3 consumer

stop-consumer:
	docker stop $$(docker ps --filter "label=com.docker.compose.service=consumer" --format "{{.ID}}" | head -n 1)

stop-broker:
	docker compose stop kafka1

start-broker:
	docker compose start kafka1

sensores:
	docker compose --profile sensores up -d --no-deps producer-2 producer-3

sensores-down:
	docker compose --profile sensores stop producer-2 producer-3
	docker compose --profile sensores rm -f producer-2 producer-3

topic:
	docker exec kafka2 /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka2:19092 --describe --topic dados-sensores

status:
	docker compose --profile sensores ps
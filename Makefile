up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build

logs:
	docker compose logs -f

logs-consumer:
	docker compose logs -f consumer

logs-producer:
	docker compose logs -f producer

scale-one:
	docker compose up -d --scale consumer=1 consumer

scale-three:
	docker compose up -d --scale consumer=3 consumer

stop-broker:
	docker compose stop kafka1

start-broker:
	docker compose start kafka1

status:
	docker compose ps
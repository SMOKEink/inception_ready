# LOGIN   = aachata
# DATA    = /home/$(LOGIN)/data
DATA    = $(HOME)/data
COMPOSE = docker compose -f srcs/docker-compose.yml

all: up

up:
	mkdir -p $(DATA)/mariadb $(DATA)/wordpress
	$(COMPOSE) up -d --build
# -d : detach , --build : rebiuld images every times even if they exist
down:
	$(COMPOSE) down

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

clean:
	$(COMPOSE) down --rmi all

fclean:
	$(COMPOSE) down --rmi all -v
	sudo rm -rf $(DATA)

re: fclean all

.PHONY: all down ps logs clean fclean


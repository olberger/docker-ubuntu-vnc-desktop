.PHONY: build run

REPO  ?= dorowu/ubuntu-desktop-lxde-vnc
TAG   ?= latest
IMAGE ?= debian:buster
# LOCALBUILD ?= 1
LOCALBUILD ?=
FLAVOR ?= lxde
ARCH ?= amd64

templates = Dockerfile image/etc/supervisor/conf.d/supervisord.conf

build: $(templates)
	docker build -t $(REPO):$(TAG) .

run:
	docker run --rm \
		-p 6080:80 -p 6081:443 \
		-v ${PWD}:/src:ro \
		-e USER=doro -e PASSWORD=mypassword \
		-e ALSADEV=hw:2,0 \
		-e SSL_PORT=443 \
		-v ${PWD}/ssl:/etc/nginx/ssl \
		--device /dev/snd \
		--name ubuntu-desktop-lxde-test \
		$(REPO):$(TAG)

shell:
	docker exec -it ubuntu-desktop-lxde-test bash

gen-ssl:
	mkdir -p ssl
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout ssl/nginx.key -out ssl/nginx.crt

clean:
	rm -f $(templates)
		
%: %.j2 flavors/$(FLAVOR).yml
	docker run -v $(shell pwd):/data vikingco/jinja2cli \
		-D flavor=$(FLAVOR) \
		-D image=$(IMAGE) \
		-D localbuild=$(LOCALBUILD) \
		-D arch=$(ARCH) \
		$< flavors/$(FLAVOR).yml > $@ || rm $@

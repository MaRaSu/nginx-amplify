.PHONY: build push

build:
	docker build -t registry.finomena.fi/c/nginx-amplify:latest .
	docker tag registry.finomena.fi/c/nginx-amplify:latest registry.finomena.fi/c/nginx-amplify:0.2.1

push:
	docker push registry.finomena.fi/c/nginx-amplify:0.2.1

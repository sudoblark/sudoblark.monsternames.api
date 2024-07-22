execute-behaviour-tests:
	( \
		docker-compose rm -f; \
		docker-compose pull; \
		docker-compose up --build -d; \
		python3 -m venv venv; \
		source ./venv/bin/activate; \
		pip3 install behave requests asserts; \
		python -m behave; \
		docker-compose stop -t 1; \
		rm -rf ./venv; \
	)

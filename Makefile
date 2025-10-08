.PHONY: clean

up:
	sed -i "" "s/^export GENESIS_TIMESTAMP=.*/export GENESIS_TIMESTAMP=$$(date +%s)/" values.env
	docker-compose up

clean:
	docker-compose down -v
	rm -rf geth-data teku-data eth-devnet-genesis

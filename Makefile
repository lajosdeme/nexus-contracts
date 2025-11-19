include .env

export $(shell sed 's/=.*//' .env)

deploy:
	forge script script/Deploy.s.sol:Deploy --rpc-url $(RPC_URL) --sender $(SENDER) --broadcast

deploy-sim:
	forge script script/Deploy.s.sol:Deploy --rpc-url $(RPC_URL) --sender $(SENDER)
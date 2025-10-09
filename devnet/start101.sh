
rm -r gethdata/geth/*
rm -r gethdata/geth.ipc
rm -r gethdata2/geth/*
rm -r gethdata2/geth.ipc
rm -r validatordatafiles/*
rm -r beacondatafiles/*
rm -r validatordata*
rm -r beacondata*
rm -r Log
rm -r script/old_count.txt
rm /dev/shm/counter.dat
# rm -r script/transaction_count.txt


mkdir Log
mkdir validatordatafiles
mkdir beacondatafiles

sleep 3

# 构建代码
echo "===========Building beacon-chain================"
cd ./prysm_mev_0 && go build -o=../beacon-chain-test ./cmd/beacon-chain                                                        
go build -o=../validator-test0 ./cmd/validator            
go build -o=../prysmctl ./cmd/prysmctl
cd ..

cd ./prysm_mev_1 && go build -o=../beacon-chain-test1 ./cmd/beacon-chain
go build -o=../validator-test1 ./cmd/validator
cd ..

cd ./prysm_mev_2 && go build -o=../validator-test2 ./cmd/validator
cd ..
cd ./prysm_mev_3 && go build -o=../validator-test3 ./cmd/validator
cd ..


echo "===========Start execution layer================"
./prysmctl testnet generate-genesis --fork capella --num-validators 1200 --genesis-time-delay 50 --chain-config-file config.yml --geth-genesis-json-in genesis.json  --geth-genesis-json-out genesis.json --output-ssz genesis.ssz

./geth-test --datadir=gethdata init genesis.json
./geth-test --datadir=gethdata2 init genesis.json

sleep 3
nohup ./geth-test --http --http.api eth,net,web3 --ws --ws.api eth,net,web3 --authrpc.jwtsecret jwt.hex --datadir gethdata --nodiscover --syncmode full --password password.txt --allow-insecure-unlock --unlock 0x123463a4b065722e99115d6c222f267d9cabb524 --discovery.port 30304 --port 30304 --http.port 8547 --ws.port 8548 --authrpc.port 8552 &> Log/exe.log &
nohup ./geth-test --http --http.api eth,net,web3 --ws --ws.api eth,net,web3 --authrpc.jwtsecret jwt2.hex --datadir gethdata2 --nodiscover --syncmode full --password password.txt --allow-insecure-unlock --unlock 0x0E829892aD3964024C0e15854e663A7c900D174B --discovery.port 30305 --port 30305 --http.port 8549 --ws.port 8550 --authrpc.port 8553 &> Log/exe2.log &
sleep 15

echo "===========Start node0=============="
nohup ./beacon-chain-test --datadir beacondatafiles/beacondata --monitoring-port 7075 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata/geth.ipc --p2p-udp-port 12020 --p2p-tcp-port 13020 --grpc-gateway-port 3520 --rpc-port 4020 --verbosity debug --disable-peer-scorer  &> Log/beacon.log &

sleep 10
# 运行 curl 命令并将输出保存到变量
output=$(curl -s localhost:7075/p2p)

# 使用 grep 和 awk 提取以 /ip4/ 开头的部分
peer_address=$(echo "$output" | grep -o "/ip4/[^ ]*")
peer_address_tcp=$(echo "$peer_address" | cut -d',' -f1)

# 将提取到的部分设置为环境变量 PEER
export PEER=$peer_address_tcp
echo "[PEER] is set to: $PEER"

echo "===========Start node1=============="
nohup ./beacon-chain-test --datadir beacondatafiles/beacondata_1 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata/geth.ipc --peer=$PEER --p2p-udp-port 12001 --p2p-tcp-port 13001 --grpc-gateway-port 3501 --rpc-port 4001 --verbosity debug &> Log/beacon_1.log &

nohup ./validator-test0 --datadir validatordatafiles/validatordata_1 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=0 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4001 --grpc-gateway-port=3501 --verbosity debug &> Log/val_1.log &

echo "===========Start node2=============="
nohup ./beacon-chain-test --datadir beacondatafiles/beacondata_2  --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata/geth.ipc --peer=$PEER --p2p-udp-port 12002 --p2p-tcp-port 13002 --grpc-gateway-port 3502 --rpc-port 4002 --verbosity debug &> Log/beacon_2.log &

nohup ./validator-test0 --datadir validatordatafiles/validatordata_2 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=100 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4002 --grpc-gateway-port=3502 --verbosity debug &> Log/val_2.log &

echo "===========Start node3=============="
nohup ./beacon-chain-test --datadir beacondatafiles/beacondata_3  --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata/geth.ipc --peer=$PEER --p2p-udp-port 12003 --p2p-tcp-port 13003 --grpc-gateway-port 3503 --rpc-port 4003 --verbosity debug &> Log/beacon_3.log &

nohup ./validator-test0 --datadir validatordatafiles/validatordata_3 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=200 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4003 --grpc-gateway-port=3503 --verbosity debug &> Log/val_3.log &

echo "===========Start node4=============="
nohup ./beacon-chain-test --datadir beacondatafiles/beacondata_4  --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata/geth.ipc --peer=$PEER --p2p-udp-port 12004 --p2p-tcp-port 13004 --grpc-gateway-port 3504 --rpc-port 4004 --verbosity debug &> Log/beacon_4.log &

nohup ./validator-test1 --datadir validatordatafiles/validatordata_4 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=300 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4004 --grpc-gateway-port=3504 --verbosity debug &> Log/val_4.log &


# 只能连五个节点
sleep 5

output1=$(curl -s localhost:7075/p2p)
# 使用 grep 提取以 /ip4/ 开头的部分，并获取第一行
peer_address2=$(echo "$output1" | grep -o "/ip4/[^ ]*" | sed -n '5p')
# export PEER=$peer_address2
# echo "[PEER] is set to: $PEER"
if [ -n "$peer_address2" ]; then
    export PEER=$peer_address2
    echo "[PEER] is set to: $PEER"
else
    echo "Failed to get peer address."
fi

echo "===========Start node5=============="
nohup ./beacon-chain-test --datadir beacondatafiles/beacondata_5  --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata/geth.ipc --peer=$PEER --p2p-udp-port 12005 --p2p-tcp-port 13005 --grpc-gateway-port 3505 --rpc-port 4005 --verbosity debug &> Log/beacon_5.log &

nohup ./validator-test1 --datadir validatordatafiles/validatordata_5 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=400 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4005 --grpc-gateway-port=3505 --verbosity debug &> Log/val_5.log &


echo "===========Start node6=============="
nohup ./beacon-chain-test --datadir beacondatafiles/beacondata_6  --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata2/geth.ipc --peer=$PEER --p2p-udp-port 12006 --p2p-tcp-port 13006 --grpc-gateway-port 3506 --rpc-port 4006 --verbosity debug &> Log/beacon_6.log &

nohup ./validator-test1 --datadir validatordatafiles/validatordata_6 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=500 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4006 --grpc-gateway-port=3506 --verbosity debug &> Log/val_6.log &

peer_address3=$(echo "$output1" | grep -o "/ip4/[^ ]*" | sed -n '4p')
if [ -n "$peer_address3" ]; then
    export PEER=$peer_address3
    echo "[PEER] is set to: $PEER"
else
    echo "Failed to get peer address."
fi

echo "===========Start node7=============="
nohup ./beacon-chain-test --datadir beacondatafiles/beacondata_7  --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata2/geth.ipc --peer=$PEER --p2p-udp-port 12007 --p2p-tcp-port 13007 --grpc-gateway-port 3507 --rpc-port 4007 --verbosity debug &> Log/beacon_7.log &

nohup ./validator-test2 --datadir validatordatafiles/validatordata_7 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=600 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4007 --grpc-gateway-port=3507 --verbosity debug &> Log/val_7.log &

peer_address3=$(echo "$output1" | grep -o "/ip4/[^ ]*" | sed -n '3p')
if [ -n "$peer_address3" ]; then
    export PEER=$peer_address3
    echo "[PEER] is set to: $PEER"
else
    echo "Failed to get peer address."
fi

echo "===========Start node8=============="
nohup ./beacon-chain-test --datadir beacondatafiles/beacondata_8  --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata2/geth.ipc --peer=$PEER --p2p-udp-port 12008 --p2p-tcp-port 13008 --grpc-gateway-port 3508 --rpc-port 4008 --verbosity debug &> Log/beacon_8.log &

nohup ./validator-test2 --datadir validatordatafiles/validatordata_8 --accept-terms-of-use --interop-num-validators 200 --interop-start-index=700 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4008 --grpc-gateway-port=3508 --verbosity debug &> Log/val_8.log &

sleep 5
# output2=$(curl -s localhost:7075/p2p)
# 使用 grep 提取以 /ip4/ 开头的部分，并获取第一行
peer_address3=$(echo "$output1" | grep -o "/ip4/[^ ]*" | sed -n '2p')
# if [ "$peer_address3" == "$output1" ]; then
#     peer_address2=$(echo "$output1" | grep -o "/ip4/[^ ]*" | sed -n '4p')
# fi

if [ -n "$peer_address3" ]; then
    export PEER=$peer_address3
    echo "[PEER] is set to: $PEER"
else
    echo "Failed to get peer address."
fi


echo "===========Start node9=============="
nohup ./beacon-chain-test --datadir beacondatafiles/beacondata_9  --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata2/geth.ipc --peer=$PEER --p2p-udp-port 12009 --p2p-tcp-port 13009 --grpc-gateway-port 3509 --rpc-port 4009 --verbosity debug &> Log/beacon_9.log &

nohup ./validator-test3 --datadir validatordatafiles/validatordata_9 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=900 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4009 --grpc-gateway-port=3509  --verbosity debug &> Log/val_9.log &

# peer_address3=$(echo "$output1" | grep -o "/ip4/[^ ]*" | sed -n '6p')
# if [ -n "$peer_address3" ]; then
#     export PEER=$peer_address3
#     echo "[PEER] is set to: $PEER"
# else
#     echo "Failed to get peer address."
# fi
echo "===========Start node10=============="
nohup ./beacon-chain-test --datadir beacondatafiles/beacondata_10  --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata2/geth.ipc --peer=$PEER --p2p-udp-port 12010 --p2p-tcp-port 13010 --grpc-gateway-port 3510 --rpc-port 4010 --verbosity debug &> Log/beacon_10.log &

nohup ./validator-test3 --datadir validatordatafiles/validatordata_10 --accept-terms-of-use --interop-num-validators 200 --interop-start-index=1000 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4010 --grpc-gateway-port=3510 --verbosity debug &> Log/val_10.log &


# rm -r gethdata/geth/*
# rm -r gethdata/geth.ipc
# rm -r gethdata2/geth/
# rm -r gethdata2/geth.ipc
# rm -r gethdata3/geth/
# rm -r gethdata3/geth.ipc
# rm -r validatordatafiles/*
# rm -r beacondatafiles/*
# rm -r validatordata*
# rm -r beacondata*
# rm -r Log


# mkdir Log
# mkdir validatordatafiles
# mkdir beacondatafiles

# sleep 3

# # 构建代码
# echo "===========Building beacon-chain================"
# cd ./prysm && go build -o=../beacon-chain-test ./cmd/beacon-chain
# go build -o=../validator-test ./cmd/validator
# go build -o=../prysmctl ./cmd/prysmctl
# cd ..

# cd ./prysm && go build -o=../beacon-chain ./cmd/beacon-chain
# go build -o=../validator ./cmd/validator
# cd ..


# echo "===========Start execution layer================"
# ./prysmctl testnet generate-genesis --fork capella --num-validators 1000 --genesis-time-delay 50 --chain-config-file config.yml --geth-genesis-json-in genesis.json  --geth-genesis-json-out genesis.json --output-ssz genesis.ssz

# ./geth --datadir=gethdata init genesis.json
# ./geth --datadir=gethdata2 init genesis.json
# ./geth --datadir=gethdata3 init genesis.json

# nohup ./geth --http --http.api eth,net,web3 --ws --ws.api eth,net,web3 --authrpc.jwtsecret jwt.hex --datadir gethdata --nodiscover --syncmode full --password password.txt --allow-insecure-unlock --unlock 0x123463a4b065722e99115d6c222f267d9cabb524 &> Log/exe.log &
# nohup ./geth --http --http.api eth,net,web3 --ws --ws.api eth,net,web3 --authrpc.jwtsecret jwt2.hex --datadir gethdata2 --nodiscover --syncmode full --password password.txt --allow-insecure-unlock --unlock 0x0E829892aD3964024C0e15854e663A7c900D174B --discovery.port 30304 --port 30304 --http.port 8547 --ws.port 8548 --authrpc.port 8552 &> Log/exe2.log &
# # nohup ./geth --http --http.api eth,net,web3 --ws --ws.api eth,net,web3 --authrpc.jwtsecret jwt2.hex --datadir gethdata3 --nodiscover --syncmode full --password password.txt --allow-insecure-unlock --discovery.port 30305 --port 30305 --http.port 8549 --ws.port 8550 --authrpc.port 8553 &> Log/exe3.log &


# sleep 3

# echo "===========Start node0=============="
# nohup ./beacon-chain --datadir beacondatafiles/beacondata --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata/geth.ipc --verbosity debug --disable-peer-scorer  &> Log/beacon.log &

# sleep 2
# # 运行 curl 命令并将输出保存到变量
# output=$(curl -s localhost:8080/p2p)

# # 使用 grep 和 awk 提取以 /ip4/ 开头的部分
# peer_address=$(echo "$output" | grep -o "/ip4/[^ ]*")
# # peer_address_tcp=$(echo "$peer_address" | cut -d',' -f1)

# # 将提取到的部分设置为环境变量 PEER
# export PEER=$peer_address
# echo "[PEER] is set to: $PEER"

# echo "===========Start node1=============="
# nohup ./beacon-chain-test --datadir beacondatafiles/beacondata_1 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata/geth.ipc --peer=$PEER --p2p-udp-port 12001 --p2p-tcp-port 13001 --grpc-gateway-port 3501 --rpc-port 4001 --verbosity debug --enable-tracing --trace-sample-fraction 1 &> Log/beacon_1.log &

# nohup ./validator --datadir validatordatafiles/validatordata_1 --accept-terms-of-use --interop-num-validators 99 --interop-start-index=0 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4001 --grpc-gateway-port=3501 --verbosity debug &> Log/val_1.log &
# nohup ./validator-test --datadir validatordatafiles/validatordata_1_1 --accept-terms-of-use --interop-num-validators 1 --interop-start-index=99 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4001 --grpc-gateway-port=3501 --verbosity debug &> Log/val_1_1.log &
# # nohup ./validator --datadir validatordatafiles/validatordata_1 --accept-terms-of-use --interop-num-validators 12000 --interop-start-index=0 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4001 --grpc-gateway-port=3501 --verbosity debug &

# echo "===========Start node2=============="
# nohup ./beacon-chain --datadir beacondatafiles/beacondata_2 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata/geth.ipc --peer=$PEER --p2p-udp-port 12002 --p2p-tcp-port 13002 --grpc-gateway-port 3502 --rpc-port 4002 --verbosity debug &> Log/beacon_2.log &

# nohup ./validator --datadir validatordatafiles/validatordata_2 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=100 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4002 --grpc-gateway-port=3502 --verbosity debug &> Log/val_2.log &
# # nohup ./validator --datadir validatordatafiles/validatordata_2 --accept-terms-of-use --interop-num-validators 12000 --interop-start-index=12000 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4002 --grpc-gateway-port=3502 --verbosity debug &

# echo "===========Start node3=============="
# nohup ./beacon-chain --datadir beacondatafiles/beacondata_3 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata/geth.ipc --peer=$PEER --p2p-udp-port 12003 --p2p-tcp-port 13003 --grpc-gateway-port 3503 --rpc-port 4003 --verbosity debug &> Log/beacon_3.log &

# nohup ./validator --datadir validatordatafiles/validatordata_3 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=200 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4003 --grpc-gateway-port=3503 --verbosity debug &> Log/val_3.log &
# # nohup ./validator --datadir validatordatafiles/validatordata_3 --accept-terms-of-use --interop-num-validators 12000 --interop-start-index=24000 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4003 --grpc-gateway-port=3503 --verbosity debug &

# # 只能连五个节点
# sleep 3

# output=$(curl -s localhost:8080/p2p)
# # 使用 grep 提取以 /ip4/ 开头的部分，并获取第一行
# peer_address2=$(echo "$output" | grep -o "/ip4/[^ ]*" | sed -n '2p')
# # export PEER=$peer_address2
# # echo "[PEER] is set to: $PEER"
# if [ -n "$peer_address2" ]; then
#     export PEER=$peer_address2
#     echo "[PEER] is set to: $PEER"
# else
#     echo "Failed to get peer address."
# fi

# echo "===========Start node4=============="
# nohup ./beacon-chain --datadir beacondatafiles/beacondata_4 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt2.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata/geth.ipc --peer=$PEER --p2p-udp-port 12004 --p2p-tcp-port 13004 --grpc-gateway-port 3504 --rpc-port 4004 --verbosity debug &> Log/beacon_4.log &

# nohup ./validator --datadir validatordatafiles/validatordata_4 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=300 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4004 --grpc-gateway-port=3504 --verbosity debug &> Log/val_4.log &
# # nohup ./validator --datadir validatordatafiles/validatordata_4 --accept-terms-of-use --interop-num-validators 12000 --interop-start-index=36000 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4004 --grpc-gateway-port=3504 --verbosity debug &

# echo "===========Start node5=============="
# nohup ./beacon-chain --datadir beacondatafiles/beacondata_5 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt2.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata/geth.ipc --peer=$PEER --p2p-udp-port 12005 --p2p-tcp-port 13005 --grpc-gateway-port 3505 --rpc-port 4005 --verbosity debug &> Log/beacon_5.log &

# nohup ./validator --datadir validatordatafiles/validatordata_5 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=400 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4005 --grpc-gateway-port=3505 --verbosity debug &> Log/val_5.log &
# # nohup ./validator --datadir validatordatafiles/validatordata_5 --accept-terms-of-use --interop-num-validators 12000 --interop-start-index=48000 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4005 --grpc-gateway-port=3505 --verbosity debug &

# #--------------------------------------------------------------
# # 只能连五个节点
# sleep 3

# # output=$(curl -s localhost:8080/p2p)
# # 使用 grep 提取以 /ip4/ 开头的部分，并获取第一行
# peer_address2=$(echo "$output" | grep -o "/ip4/[^ ]*" | sed -n '3p')
# # export PEER=$peer_address2
# # echo "[PEER] is set to: $PEER"
# if [ -n "$peer_address2" ]; then
#     export PEER=$peer_address2
#     echo "[PEER] is set to: $PEER"
# else
#     echo "Failed to get peer address."
# fi

# echo "===========Start node6=============="
# nohup ./beacon-chain --datadir beacondatafiles/beacondata_6 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt2.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata2/geth.ipc --peer=$PEER --p2p-udp-port 12006 --p2p-tcp-port 13006 --grpc-gateway-port 3506 --rpc-port 4006 --verbosity debug &> Log/beacon_6.log &

# nohup ./validator --datadir validatordatafiles/validatordata_6 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=500 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4006 --grpc-gateway-port=3506 --verbosity debug &> Log/val_6.log &
# # nohup ./validator --datadir validatordatafiles/validatordata_6 --accept-terms-of-use --interop-num-validators 12000 --interop-start-index=60000 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4006 --grpc-gateway-port=3506 --verbosity debug &

# echo "===========Start node7=============="
# nohup ./beacon-chain --datadir beacondatafiles/beacondata_7 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt2.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata2/geth.ipc --peer=$PEER --p2p-udp-port 12007 --p2p-tcp-port 13007 --grpc-gateway-port 3507 --rpc-port 4007 --verbosity debug &> Log/beacon_7.log &

# nohup ./validator --datadir validatordatafiles/validatordata_7 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=600 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4007 --grpc-gateway-port=3507 --verbosity debug &> Log/val_7.log &
# # nohup ./validator --datadir validatordatafiles/validatordata_7 --accept-terms-of-use --interop-num-validators 12000 --interop-start-index=72000 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4007 --grpc-gateway-port=3507 --verbosity debug &

# echo "===========Start node8=============="
# nohup ./beacon-chain --datadir beacondatafiles/beacondata_8 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt2.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata2/geth.ipc --peer=$PEER --p2p-udp-port 12008 --p2p-tcp-port 13008 --grpc-gateway-port 3508 --rpc-port 4008 --verbosity debug &> Log/beacon_8.log &

# nohup ./validator --datadir validatordatafiles/validatordata_8 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=700 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4008 --grpc-gateway-port=3508 --verbosity debug &> Log/val_8.log &
# # nohup ./validator --datadir validatordatafiles/validatordata_8 --accept-terms-of-use --interop-num-validators 12000 --interop-start-index=84000 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4008 --grpc-gateway-port=3508 --verbosity debug &

# # output=$(curl -s localhost:8080/p2p)
# # 使用 grep 提取以 /ip4/ 开头的部分，并获取第一行
# peer_address3=$(echo "$output" | grep -o "/ip4/[^ ]*" | sed -n '4p')
# # export PEER=$peer_address3
# # echo "[PEER] is set to: $PEER" 
# if [ -n "$peer_address3" ]; then
#     export PEER=$peer_address3
#     echo "[PEER] is set to: $PEER"
# else
#     echo "Failed to get peer address."
# fi


# echo "===========Start node9=============="
# nohup ./beacon-chain --datadir beacondatafiles/beacondata_9 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt2.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata2/geth.ipc --peer=$PEER --p2p-udp-port 12009 --p2p-tcp-port 13009 --grpc-gateway-port 3509 --rpc-port 4009 --verbosity debug &> Log/beacon_9.log &

# nohup ./validator --datadir validatordatafiles/validatordata_9 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=800 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4009 --grpc-gateway-port=3509  --verbosity debug &> Log/val_9.log &
# # nohup ./validator --datadir validatordatafiles/validatordata_9 --accept-terms-of-use --interop-num-validators 12000 --interop-start-index=96000 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4009 --grpc-gateway-port=3509  --verbosity debug &

# echo "===========Start node10=============="
# nohup ./beacon-chain --datadir beacondatafiles/beacondata_10 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt2.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata2/geth.ipc --peer=$PEER --p2p-udp-port 12010 --p2p-tcp-port 13010 --grpc-gateway-port 3510 --rpc-port 4010 --verbosity debug &> Log/beacon_10.log &

# nohup ./validator --datadir validatordatafiles/validatordata_10 --accept-terms-of-use --interop-num-validators 100 --interop-start-index=900 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4010 --grpc-gateway-port=3510 --verbosity debug &> Log/val_10.log &
# # nohup ./validator --datadir validatordatafiles/validatordata_10 --accept-terms-of-use --interop-num-validators 10000 --interop-start-index=108000 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4010 --grpc-gateway-port=3510 --verbosity debug &

# # echo "===========Start node11=============="
# # nohup ./beacon-chain --datadir beacondatafiles/beacondata_11 --min-sync-peers 0 --genesis-state genesis.ssz --bootstrap-node= --interop-eth1data-votes --chain-config-file config.yml --contract-deployment-block 0 --chain-id 32382 --accept-terms-of-use --jwt-secret jwt2.hex --suggested-fee-recipient 0x123463a4B065722E99115D6c222f267d9cABb524 --minimum-peers-per-subnet 0 --enable-debug-rpc-endpoints --execution-endpoint gethdata3/geth.ipc --peer=$PEER --p2p-udp-port 12011 --p2p-tcp-port 13011 --grpc-gateway-port 3511 --rpc-port 4011 --verbosity debug &> Log/beacon_11.log &

# # nohup ./validator --datadir validatordatafiles/validatordata_11 --accept-terms-of-use --interop-num-validators 1000 --interop-start-index=19000 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4011 --grpc-gateway-port=3511 --verbosity debug &> Log/val_11.log &
# # nohup ./validator-test --datadir validatordatafiles/validatordata_11 --accept-terms-of-use --interop-num-validators 2000 --interop-start-index=118000 --chain-config-file config.yml --beacon-rpc-provider=127.0.0.1:4011 --grpc-gateway-port=3511 --verbosity debug &

# # sleep 3


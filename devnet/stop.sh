#! /bin/bash

ps -aux|grep geth-test| grep -v grep| awk '{print $2}'| xargs kill -9
ps -aux|grep beacon-chain-test| grep -v grep| awk '{print $2}'| xargs kill -9
ps -aux|grep beacon-chain-normal| grep -v grep| awk '{print $2}'| xargs kill -9
ps -aux|grep validator-test| grep -v grep| awk '{print $2}'| xargs kill -9


# rm -r beacondata/

# rm -r beacondata_bro/
# rm -r validatordata/

# rm -r beacondata_test/
# rm -r validatordata_test/

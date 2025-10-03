# Timing Game Repository

<font size=4> 

This project is based on the following paper and its four main findings:

Kunyi Ji, Zhongxiang Liu, Rujia Li, Xin Wang, Wei Wang, Teng Huang and Sisi Duan. "An Empirical Study of Strategic Timing Games in Ethereum." .

Four findings of the paper:

- Our analysis using on-chain data shows that it is highly likely that some staking pools (each staking pool consists of collective stakes of many users), such as Kiln are playing timing games, and playing timing games is indeed profitable. 
- Our analysis using both on-chain data and local empirical analysis shows that the main factor that affects the success rate of timing games is the time of delaying proposing the blocks. Specifically, delaying the block for a longer period of time is indeed more profitable, as it is often the case that a block with a higher MEV can be obtained. However, delaying the block for an even longer period of time has a risk of making the block reorganized and not included in the canonical chain, due to the honest reorg mechanism being made effective on Nov 2023. 
- Our extensive local empirical analysis shows that two factors are closely related to the profit of playing the timing games: time of delaying blocks, and total available MEVs (called global MEV in this work). Specifically, longer delays generally increase the profit but also have the risk of losing all rewards. Meanwhile, the global MEV is closely related to the MEV each validator can get, but playing the game is still profitable regardless of the global MEV.
- Our extensive local empirical analysis shows that any validator (or staking pool) can gain more profit by playing the timing game. However, the strategic advantage decreases as more validators adopt the same strategies. We further validate our empirical analysis via a game-theoretic analysis for a game between timing game players and non-players. Our study shows that an equilibrium exists when all validators play the timing games. 

We use the open-source Ethereum codebase to build a local testnet. The versions are: Prysm (v6.0.4) for the consensus and validators, and Geth (v1.42.12) for execution layer.  The test network consists of up to 10,000 validators and five beacon nodes. 

</font>


## Run the Testnet Step by Step
We establish 1200 validators for testing. 

* First, clone the repository.
```shell
git clone repository
```

* Next, start the testnet. The script will start one execution client geth, five beacon clients and four validator clients.
```shell
./start.sh
```
* Stop the testnet after running for some time. 
```
./stop.sh
```


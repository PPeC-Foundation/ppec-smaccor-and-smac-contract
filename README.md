# ppec-smaccor-and-smac-contract
PPeC's SmACCor and SmAC - solidity contracts
## smartads.sol
This files contains the entire smart ads contract 
## smaccorv1.sol
This file contains only instructions for the SmACCor
## smacv1.sol
This file contains only instruction for the SmAC
## Compiling error
For this contract to verify on etherscan you have to parse the value passed in the constructor `AdCreator` (uint256 minReward_, uint256 minBalance_)
### ERROR 
![etherscan missing constructor arguments error](https://github.com/PPeC-Foundation/ppec-smaccor-and-smac-contract/blob/main/ethererrorh.png)
(But we were unable to locate a matching bytecode (err_code_2))
### SOLUTION : parse values
![etherscan constructor arguments field](https://github.com/PPeC-Foundation/ppec-smaccor-and-smac-contract/blob/main/ethererror.png)
- minReward: if you enter 100 (0000000000000000000000000000000000000000000000000000000000000064)
- minBalance: if you enter 600 (0000000000000000000000000000000000000000000000000000000000000258)
## Constructor Arguments Used (ABI-encoded):
### 00000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000258
Use this link to parse your values : https://abi.hashex.org/

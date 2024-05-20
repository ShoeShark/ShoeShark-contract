## Foundry

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# 积分合约

### **定义积分规则和上限**

**首先，为不同类型的用户行为定义积分规则。例如，每日签到、用户互动（如点赞、评论）和内容发布等。对于每种行为，设置一个积分值以及每日或每周的积分上限。**

**示例规则：**

**每日签到：+5积分，每日上限为5积分。用户互动：+2积分，每日上限为10积分。内容发布：+10积分，每周上限为30积分。**

暂定为积分系统在数据库中管理, 可以通过chianlink服务定期获取并自动执行代币奖励分发


# 平台代币合约
### **基本信息**

**代币名称: ShoeShark Token (SST)代币符号: SST小数位数: 通常为18，以便与以太坊上的大多数代币保持一致。总供应量: 根据项目需求和代币经济模型设定。例如，10亿SST。**


积分合约
IntegralRewards.sol
代币合约
ShoeSharkToken.sol
Nft合约
ShoeSharkNft.sol

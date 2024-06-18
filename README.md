# Faucet Smart Contract Documentation

## Overview

The Faucet smart contract is designed to distribute tokens to users upon request. It provides a mechanism for distributing tokens to specific addresses and tracking the last time tokens were distributed to an address or a specific fid. This documentation outlines the functionality, usage, and testing of the Faucet contract.

## Contract Structure

The Faucet contract consists of the following components:

- **State Variables:**
  - `lastDripTimestampByAddress`: Tracks the last time tokens were dripped to an address.
  - `lastDripTimestampByFid`: Tracks the last time tokens were dripped to a specific fid.
- **Events:**

  - `TokensDripped`: Triggered when tokens are successfully dripped to an address.
  - `TokensReceived`: Triggered when the contract receives tokens.

- **Functions:**
  - `constructor`: Initializes the contract and sets the owner.
  - `receive`: Default fallback function to receive Ether.
  - `fallback`: Fallback function to receive Ether.
  - `dripTokensToAddress`: Allows the owner to drip tokens to a specified address.
  - `withdraw`: Allows the owner to withdraw Ether from the contract.

## Deployed Contract

### Arbitrum Sepolia

0x2aAB66f75ae1C34e5bDEF6fcfC58a641F2d3D9ed

### Base Sepolia

0x2aAB66f75ae1C34e5bDEF6fcfC58a641F2d3D9ed

## Mode Sepolia

0x2aAB66f75ae1C34e5bDEF6fcfC58a641F2d3D9ed

## Usage

### Build

```bash
 forge build
```

### Test

```bash
 forge test
```

### Format

```bash
 forge fmt
```

### Gas Snapshots

```bash
 forge snapshot
```

### Anvil

```bash
 anvil
```

### Cast

```bash
 cast <subcommand>
```

## Deploy

Create a copy of .env.sample and fill the details with your RPCs.

```bash
source .env.local
```

### Importing Private Key

We will encrypt our private keys into a JSON format.

```bash
  cast wallet import defaultKey --interactive
```

You will then be promtpted to enter Private Key and a Password whenever you want to use it.

Check if the wallet is configured.

```bash
  cast wallet list
```

### Base

```bash
 forge create --rpc-url $BASE_SEPOLIA_RPC  --account defaultKey  --etherscan-api-key $BASESCAN_SEPOLIA_API_KEY --verify src/Faucet.sol:Faucet
```

### Arbitrum

```bash
 forge create --rpc-url $ARBITRUM_SEPOLIA_RPC   --account defaultKey   --etherscan-api-key $ARBISCAN_SEPOLIA_API_KEY --verify src/Faucet.sol:Faucet
```

### Mode

```bash
forge create --rpc-url https://sepolia.mode.network --account defaultKey --verify --verifier blockscout --verifier-url https://sepolia.explorer.mode.network/api\? src/Faucet.sol:Faucet --priority-gas-price 1
```

### Any Network

```bash
 forge create --rpc-url $RPC   --account defaultKey   --etherscan-api-key $ETHERSCAN_API_KEY --verify src/Faucet.sol:Faucet
```

### Fund the contract

```bash
cast send <contract-address> --value 10ether -r $NETWORK_RPC  --account defaultKey   --etherscan-api-key $NETWORK_API_KEY
```

### Help

```bash

forge --help
anvil --help
cast --help
```

#### Mode Error

It is possible you get the error

`server returned an error response: error code -32000: transaction underpriced: gas tip cap 0, minimum needed 1`

while posting transaction to Mode Sepolia. It is because the gas estimation is not done properly.

Solve it by adding a custom priority gas fee

`--priority-gas-price 1`

## Tests

The Faucet contract is thoroughly tested to ensure its functionality. Test cases cover various scenarios such as dripping tokens, preventing multiple drips within 24 hours, balance thresholds, event emission, and ownership control.

## File Structure

`.
├── README.md
├── foundry.toml
├── remappings.txt
├── env.local
├── env.sample
├── script
│   └── Faucet.sol
├── src
│   └── Faucet.sol
└── test
    └── Faucet.t.sol`

## Documentation

For more detailed documentation, refer to the [Foundry Book](https://book.getfoundry.sh/).

## Dependencies

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts): Used for the `Ownable` contract.

## License

This contract is licensed under the MIT License.

## Author

@HAPPYS1NGH

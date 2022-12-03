<img align="right" width="150" height="150" top="100" src="./assets/logo.png">

# Ampleforth Property Tests • [![ci](https://github.com/pmerkleplant/ampleforth-property-tests/actions/workflows/unit-tests.yml/badge.svg)](https://github.com/pmerkleplant/ampleforth-property-tests/actions/workflows/unit-tests.yml) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

> A project to collect and test properties of Ampleforth's [AMPL](https://docs.ampleforth.org/learn/about-the-ampleforth-protocol) token.


## Overview

This repo offers an executable, property-based test suite for Ampleforth's AMPL token.

The `AMPLProp` contract provides functions to check whether a property of the AMPL token in a current state is held.

The `AMPLTest` contract uses the foundry fuzzer to first create a pseudo-random state for the AMPL token, and
afterwards checks via the `AMPLProp` contract whether the properties hold.


## Properties

> **Note**
>
> Any contributions to add more properties to the project are highly welcome!

The project currently tests the following properties:

**Rebase Properties**:

- The gon-AMPL conversion rate is the (fixed) scaled total supply divided by the (elastic) total supply
- The rebase operation is non-dilutive, i.e. does not change the wallet wealth distribution

**Total Supply Properties**:

- The total supply never exceeds the defined max supply
- The total supply is never zero
- The sum of all balances never exceeds the total supply
    - Note that rebase tokens can not guarantee that the sum of all balances _equals_ the total supply
    - For more info, see [here](https://github.com/ampleforth/ampleforth-contracts/blob/ab5abe27fc5b107d9acacd9199809760f35a2ac7/contracts/UFragments.sol#L35-L37)

**Transfer Properties**:

- A transfer of _x_ AMPLs from user _A_ to user _B_ results in _A_'s external balance being decreased by precisely _x_
  AMPLs and _B_'s external balance being increased by precisely _x_ AMPLs
- A transfer of zero AMPL is always possible
- Calling the `tranferAllFrom` function reverts when the balance of the owner is non-zero and the allowance of the spender
  is zero
    - Note that this is independent of the scaled balance of the owner!


## Usage

The project uses the Foundry toolchain. You can find installation instructions [here](https://getfoundry.sh/).

Clone repo:
```bash
$ git clone https://github.com/pmerkleplant/ampleforth-property-tests
```

Install dependencies:
```bash
$ cd ampleforth-property-tests
$ forge install
```

Run test suite:
```bash
$ forge test
```

Run test suite with full stack trace:
```bash
forge test -vvvv
```

## License

[GNU General Public License v3.0 (c) 2022 merkleplant](./LICENSE)

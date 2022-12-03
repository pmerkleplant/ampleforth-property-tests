// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

import {UFragments as AMPL} from "ampleforth-contracts/UFragments.sol";

import {AMPLProp} from "test/AMPL.p.sol";

contract AMPLTest is AMPLProp {
    struct State {
        // Privileged addresses
        address owner;
        address monetaryPolicy;
        // Rebases
        int[] supplyDeltas;
        // List of addresses that could have a non-zero balance
        // Note that owner can also have a non-zero balance
        address[] users;
        // List of transfers tried to execute
        uint[] transfers;
    }

    function setUp() public virtual {}

    function setUpAMPL(State memory state) public {
        _assumeValidState(state);

        ampl = new AMPL();
        ampl.initialize(state.owner);

        vm.prank(state.owner);
        ampl.setMonetaryPolicy(state.monetaryPolicy);

        // Try to execute all transfers from owner to users.
        for (uint i; i < state.transfers.length; i++) {
            vm.prank(state.owner);
            try ampl.transfer(state.users[i], state.transfers[i]) {} catch {}
        }

        // Try to execute list of rebases.
        for (uint i; i < state.supplyDeltas.length; i++) {
            vm.prank(state.monetaryPolicy);
            try ampl.rebase(1, state.supplyDeltas[i]) {} catch {}
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 REBASE
    //////////////////////////////////////////////////////////////*/

    function test_prop_ConversionRate(State memory state) public {
        setUpAMPL(state);
        prop_ConversionRate(state.users);
    }

    function test_prop_RebaseIsNonDilutive(State memory state) public {
        setUpAMPL(state);

        // Cache the scaled balances for each user.
        uint[] memory scaledBalancesBefore = new uint[](state.users.length);
        for (uint i; i < state.users.length; i++) {
            scaledBalancesBefore[i] = ampl.scaledBalanceOf(state.users[i]);
        }

        // Execute a rebase.
        uint halfOfSupply = ampl.totalSupply() / 2;
        int supplyDelta = halfOfSupply < MAX_SUPPLY ? int(halfOfSupply) : -1 * int(halfOfSupply);

        vm.prank(state.monetaryPolicy);
        ampl.rebase(1, supplyDelta);

        // Get the scaled balances for each user.
        uint[] memory scaledBalancesAfter = new uint[](state.users.length);
        for (uint i; i < state.users.length; i++) {
            scaledBalancesAfter[i] = ampl.scaledBalanceOf(state.users[i]);
        }

        prop_RebaseIsNonDilutive(scaledBalancesBefore, scaledBalancesAfter);
    }

    /*//////////////////////////////////////////////////////////////
                              TOTAL SUPPLY
    //////////////////////////////////////////////////////////////*/

    function test_prop_TotalSupplyNeverExceedsMaxSupply(State memory state) public {
        setUpAMPL(state);
        prop_TotalSupplyNeverExceedsMaxSupply();
    }

    function test_prop_TotalSupplyNeverZero(State memory state) public {
        setUpAMPL(state);
        prop_TotalSupplyNeverZero();
    }

    function test_prop_SumOfAllBalancesNeverExceedsMaxSupply(State memory state) public {
        setUpAMPL(state);
        prop_SumOfAllBalancesNeverExceedsMaxSupply(state.owner, state.users);
    }

    /*//////////////////////////////////////////////////////////////
                                TRANSFER
    //////////////////////////////////////////////////////////////*/

    function test_prop_ExternalBalanceIsPreciseAfterTransfer(State memory state) public {
        setUpAMPL(state);
        prop_ExternalBalanceIsPreciseAfterTransfer(state.owner, state.users);
    }

    function test_prop_TransferAllFromRevertsIfAllowanceIsInsufficient(State memory state) public {
        setUpAMPL(state);
        prop_TransferAllFromRevertsIfAllowanceIsInsufficient(state.users);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) usersCache;

    function _assumeValidState(State memory state) internal {
        vm.assume(state.owner != address(0));
        vm.assume(state.monetaryPolicy != address(0));

        // User assumptions.
        vm.assume(state.users.length != 0);
        vm.assume(state.users.length < 10e9);
        for (uint i; i < state.users.length; i++) {
            // Make sure user is neither owner nor monetary policy.
            vm.assume(state.users[i] != state.owner);
            vm.assume(state.users[i] != state.monetaryPolicy);

            // Make sure user is valid recipient.
            vm.assume(state.users[i] != address(0));
            vm.assume(state.users[i] != address(ampl));

            // Make sure user is unique.
            vm.assume(!usersCache[state.users[i]]);
            usersCache[state.users[i]] = true;
        }

        // Transfer assumptions.
        vm.assume(state.transfers.length != 0);
        vm.assume(state.transfers.length <= state.users.length);

        // Rebase assumptions.
        vm.assume(state.supplyDeltas.length != 0);
        vm.assume(state.supplyDeltas.length < 1000);
    }
}

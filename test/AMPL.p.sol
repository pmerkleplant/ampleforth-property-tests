// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.6;

import "forge-std/Test.sol";

import {UFragments as AMPL} from "ampleforth-contracts/UFragments.sol";

abstract contract AMPLProp is Test {
    AMPL ampl;

    // Constants copied from AMPL.
    uint constant MAX_SUPPLY = type(uint128).max;

    /*//////////////////////////////////////////////////////////////
                                 REBASE
    //////////////////////////////////////////////////////////////*/

    /// @dev The gon-AMPL conversion rate is the (fixed) scaled total supply divided by the (elastic) total supply.
    function prop_ConversionRate(address[] memory users) public {
        uint gonsPerAMPL = ampl.scaledTotalSupply() / ampl.totalSupply();

        for (uint i; i < users.length; i++) {
            uint gonBalance = ampl.scaledBalanceOf(users[i]);
            uint amplBalance = ampl.balanceOf(users[i]);

            assertEq(gonBalance / gonsPerAMPL, amplBalance);
        }
    }

    /// @dev A rebase operation is non-dilutive, i.e. does not change the wallet wealth distribution.
    function prop_RebaseIsNonDilutive(uint[] memory scaledBalancesBefore, uint[] memory scaledBalancesAfter) public {
        for (uint i; i < scaledBalancesBefore.length; i++) {
            assertEq(scaledBalancesBefore[i], scaledBalancesAfter[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              TOTAL SUPPLY
    //////////////////////////////////////////////////////////////*/

    /// @dev The total supply never exceeded the defined max supply.
    function prop_TotalSupplyNeverExceedsMaxSupply() public {
        assertTrue(ampl.totalSupply() <= MAX_SUPPLY);
    }

    /// @dev The total supply is never zero.
    function prop_TotalSupplyNeverZero() public {
        assertTrue(ampl.totalSupply() != 0);
    }

    /// @dev The sum of all balances never exceeds the total supply.
    function prop_SumOfAllBalancesNeverExceedsMaxSupply(address owner, address[] memory users) public {
        uint sum = ampl.balanceOf(owner);
        for (uint i; i < users.length; i++) {
            sum += ampl.balanceOf(users[i]);
        }

        assertTrue(sum <= ampl.totalSupply());
    }

    /*//////////////////////////////////////////////////////////////
                                TRANSFER
    //////////////////////////////////////////////////////////////*/

    /// @dev A transfer of x AMPLs from A to B results in A's external balance being decreased by precisely
    ///      x AMPLs and B's external balance being increased by precisely x AMPLs.
    function prop_ExternalBalanceIsPreciseAfterTransfer(address owner, address[] memory users) public {
        uint before = ampl.balanceOf(owner);

        for (uint i; i < users.length; i++) {
            uint wantIncrease = ampl.balanceOf(users[i]);

            vm.prank(users[i]);
            ampl.transfer(owner, wantIncrease);

            assertEq(ampl.balanceOf(users[i]), 0);

            assertEq(before + wantIncrease, ampl.balanceOf(owner));
            before += wantIncrease;
        }
    }

    /// @dev A transfer of zero AMPL is always possible, independent of whether the `transfer` or `transferFrom`
    ///      function is used.
    function prop_ZeroTransferAlwaysPossible(address[] memory users) public {
        address user;
        for (uint i; i < users.length; i++) {
            user = users[i];

            vm.startPrank(user);
            {
                ampl.transfer(user, 0);
                ampl.transferFrom(user, user, 0);
            }
            vm.stopPrank();
        }
    }

    /// @dev Function `transferAllFrom` reverts if scaledBalanceOf owner is not zero while allowance from owner to
    ///      spender is zero.
    /// @dev Bug: The AMPL token has a bug in this function and does not revert in case the balanceOf owner is zero
    ///           but the scaledBalanceOf owner is non-zero. This is independent of the spender's allowance.
    function prop_TransferAllFromRevertsIfAllowanceIsInsufficient(address[] memory users) public {
        address spender;
        address owner;
        address receiver;
        for (uint i; i < users.length; i++) {
            // Send tokens from yourself to yourself via transferFrom. Note that a user does not have allowance set for
            // themself.
            spender = users[i];
            owner = users[i];
            receiver = users[i];

            // Expect a revert if the scaledBalance, i.e. gon balance, of the owner is unequal to zero.
            bool expectRevert = ampl.scaledBalanceOf(owner) != 0;

            // Bug: It's enough for the AMPL balance to be non-zero.
            expectRevert = ampl.balanceOf(owner) != 0;

            if (expectRevert) {
                vm.expectRevert();
            }
            vm.prank(spender);
            ampl.transferAllFrom(owner, receiver);
        }
    }
}

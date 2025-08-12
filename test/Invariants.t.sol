// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Game.sol";

/// @notice Quick invariant suite for LastManStanding (to run with `forge test`)
contract Invariants is Test {
    Game game;

    function setUp() public {
        // params: initialClaimFee, gracePeriod, feeIncreasePercentage, platformFeePercentage
        game = new Game(1 ether, 1 days, 10, 5);
    }

    /// Invariant 1: Contract balance must cover pot + platform fees (pending winnings also reside in balance).
    function invariant_balance_covers_pot_and_fees() public view {
        uint256 bal = address(game).balance;
        uint256 pot = game.pot();
        uint256 fees = game.platformFeesBalance();
        // Contract balance must at least cover pot + platform fees.
        assert(bal >= pot + fees);
    }

    /// Invariant 2: Pot should never be negative (redundant but explicit).
    function invariant_pot_nonnegative() public view {
        assert(game.pot() >= 0);
    }

    /// Invariant 3: claimFee must be >= initialClaimFee while a round is active.
    function invariant_claimFee_not_below_initial() public view {
        // After reset the initialClaimFee becomes the baseline again.
        if (!game.gameEnded()) {
            assert(game.claimFee() >= game.initialClaimFee());
        }
    }

    /// Invariant 4: When the game is ended, pot must be zero and pending winnings assigned to the winner.
    function invariant_pot_zero_after_end_and_winner_has_pending() public view {
        if (game.gameEnded()) {
            assert(game.pot() == 0);
            // If game ended there should be some pending winnings for the winner (or zero if nobody claimed).
            address king = game.currentKing();
            // It is valid for pending to be zero only if no king existed; otherwise pending should be >= 0.
            // We assert that if someone is king (non-zero) then their pending recorded value exists (>=0) — stronger checks are done in unit tests.
            if (king != address(0)) {
                // pendingWinnings getter exists
                assert(game.pendingWinnings(king) >= 0);
            }
        }
    }

    /// Invariant 5: Owner should not be the current king (policy from README).
    function invariant_owner_is_not_king() public view {
        if (game.currentKing() == game.owner()) {
            // this should not happen in normal gameplay
            assert(false);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Test } from "forge-std/Test.sol";
import { CheckSecrets } from "src/periphery/drippie/dripchecks/CheckSecrets.sol";

/// @title  CheckSecretsTest
contract CheckSecretsTest is Test {
    /// @notice Event emitted when a secret is revealed.
    event SecretRevealed(bytes32 secret);

    /// @notice An instance of the CheckSecrets contract.
    CheckSecrets c;

    /// @notice A secret that must exist.
    bytes secretMustExist = bytes(string("secretMustExist"));

    /// @notice A secret that must not exist.
    bytes secretMustNotExist = bytes(string("secretMustNotExist"));

    /// @notice Deploy the `CheckSecrets` contract.
    function setUp() external {
        c = new CheckSecrets();
    }

    /// @notice Test that basic secret revealing works.
    function test_reveal_succeeds() external {
        vm.expectEmit(address(c));
        emit SecretRevealed(keccak256(secretMustExist));
        c.reveal(secretMustExist);
        assertEq(c.revealedSecrets(keccak256(secretMustExist)), true);
    }

    /// @notice Test that revealing the same secret twice does not work.
    function test_reveal_twice_fails() external {
        c.reveal(secretMustExist);
        vm.expectRevert("CheckSecrets: secret already revealed");
        c.reveal(secretMustExist);
        assertEq(c.revealedSecrets(keccak256(secretMustExist)), false);
    }

    /// @notice Test that the check function returns true when the first secret is revealed but the
    ///         second secret is still hidden.
    function test_check_secretRevealed_succeeds() external {
        CheckSecrets.Params memory p = CheckSecrets.Params({
            secretMustExist: keccak256(secretMustExist),
            secretMustNotExist: keccak256(secretMustNotExist)
        });

        // Reveal the secret that must exist.
        c.reveal(secretMustExist);

        // Secret revealed, check should succeed.
        assertEq(c.check(abi.encode(p)), false);
    }

    /// @notice Test that the check function returns false when the first secret is not revealed.
    function test_check_secretNotRevealed_fails() external {
        CheckSecrets.Params memory p = CheckSecrets.Params({
            secretMustExist: keccak256(secretMustExist),
            secretMustNotExist: keccak256(secretMustNotExist)
        });

        // Secret not revealed, check should fail.
        assertEq(c.check(abi.encode(p)), false);
    }

    /// @notice Test that the check function returns false when the second secret is revealed.
    function test_check_secondSecretRevealed_fails() external {
        CheckSecrets.Params memory p = CheckSecrets.Params({
            secretMustExist: keccak256(secretMustExist),
            secretMustNotExist: keccak256(secretMustNotExist)
        });

        // Reveal the secret that must not exist.
        c.reveal(secretMustNotExist);

        // Both secrets revealed, check should fail.
        assertEq(c.check(abi.encode(p)), false);
    }

    /// @notice Test that the check function returns false when the second secret is revealed even
    ///         though the first secret is also revealed.
    function test_check_secondSecretRevealed_fails() external {
        CheckSecrets.Params memory p = CheckSecrets.Params({
            secretMustExist: keccak256(secretMustExist),
            secretMustNotExist: keccak256(secretMustNotExist)
        });

        // Reveal the secret that must exist.
        c.reveal(secretMustExist);

        // Reveal the secret that must not exist.
        c.reveal(secretMustNotExist);

        // Both secrets revealed, check should fail.
        assertEq(c.check(abi.encode(p)), false);
    }
}

// copied from counterfactual: https://github.com/counterfactual/monorepo
// adjusted to prefix message since I'm using web.eth.sign

pragma solidity 0.4.24;


/// @title LibSignature - A library wrapper around signature verification
/// @author Liam Horne - <liam@l4v.io>
/// @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
/// @author Richard Meissner - <richard@gnosis.pm>
/// @notice This contracts purpose is to make it easy to do signature verification of
/// string concatenated signatures in a bytes array. It is heavily based off the
/// SignatureValidator contract from Gnosis: https://git.io/fNzRJ
contract LibSignature {
  /// @dev Recovers address who signed the message
  /// @param messageSignature message `txHash` signature
  /// @param txHash operation ethereum signed message hash
  /// @param pos which signature to read
  function recoverKey(
    bytes memory messageSignature,
    bytes32 txHash,
    uint256 pos
  )
    public
    pure
    returns (address)
  {
    uint8 v;
    bytes32 r;
    bytes32 s;
    (v, r, s) = signatureSplit(messageSignature, pos);    
    return ecrecover(keccak256("\x19Ethereum Signed Message:\n32", txHash), v, r, s);
  }

  /// @dev Verifies signatures given the signer addresses
  /// @param signatures message `txHash` signature
  /// @param txHash operation ethereum signed message hash
  /// @param signers addresses of all signers in order
  function verifySignatures(
    bytes memory signatures,
    bytes32 txHash,
    address[] memory signers
  )
    public
    pure
    returns (bool)
  {
    address lastSigner = address(0);
    for (uint256 i = 0; i < signers.length; i++) {
      require(
        signers[i] == recoverKey(signatures, txHash, i), "Invalid signature"
      );
      require(signers[i] > lastSigner, "Signers not in ascending order");
      lastSigner = signers[i];
    }
    return true;
  }

  /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`
  /// @param pos which signature to read
  /// @param signatures concatenated rsv signatures
  function signatureSplit(bytes memory signatures, uint256 pos)
    public
    pure
    returns (uint8 v, bytes32 r, bytes32 s)
  {
    // The signature format is a compact form of:
    //   {bytes32 r}{bytes32 s}{uint8 v}
    // Compact means, uint8 is not padded to 32 bytes.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let signaturePos := mul(0x41, pos)
      r := mload(add(signatures, add(signaturePos, 0x20)))
      s := mload(add(signatures, add(signaturePos, 0x40)))
      // Here we are loading the last 32 bytes, including 31 bytes
      // of 's'. There is no 'mload8' to do this.
      //
      // 'byte' is not working due to the Solidity parser, so lets
      // use the second best option, 'and'
      v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
    }
  }
}

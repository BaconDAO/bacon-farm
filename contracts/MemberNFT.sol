// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IFarm.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a burner role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and burner
 * roles, as well as the default admin role, which will let it grant both minter
 * and burner roles to other accounts.
 */
contract MemberNFT is Context, AccessControl, Ownable, ERC1155 {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    mapping(uint256 => IFarm) public farmsMap;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract.
     */
    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function setFarms(uint256[] memory ids, address[] memory farms)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            farmsMap[ids[i]] = IFarm(farms[i]);
        }
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "MemberNFT: must have minter role to mint"
        );

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "MemberNFT: must have minter role to mint"
        );

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` of tokens for `account`, of token type `id`.
     *
     * See {ERC1155-_burn}.
     *
     * Requirements:
     *
     * - the caller must have the `BURNER_ROLE`.
     */
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public virtual {
        require(
            hasRole(BURNER_ROLE, _msgSender()),
            "MemberNFT: must have burner role to burn"
        );

        _burn(account, id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {burn}.
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual {
        require(
            hasRole(BURNER_ROLE, _msgSender()),
            "MemberNFT: must have burner role to burn"
        );

        _burnBatch(account, ids, amounts);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        if (from != address(0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                if (address(farmsMap[i]) != address(0)) {
                    uint256 NFTCost = farmsMap[i].NFTCost();
                    farmsMap[i].transferStake(
                        from,
                        to,
                        amounts[i].mul(NFTCost)
                    );
                }
            }
        }
    }
}

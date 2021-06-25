// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPostKeeper {
    /*
    * @dev post content need to sell or buy
    */
    function post(
        bytes32[] title, 
        bytes32[] contact,
        bytes32[] content,
        uint256 productCategory,
        uint256 countryCode,
        uint256 numOfItem, 
        uint256 price, 
        address tokenAdd,
        bool isPublic,
        uint8 postType) external;

    /*
     * @dev update post
     */
    function update(
        bytes32[] title,
        bytes32[] contact,
        bytes32[] content,
        uint256 productCategory,
        uint256 countryCode,
        uint256 numOfItem,
        uint256 startContentIndexChanged,
        uint256 price,
        address tokenAdd,
        bool isPublic,
        uint8 postType) external;

    /*
     * @dev get Post content
     */
    function getPost() view external returns(
        bytes32[] title, 
        bytes32[] contact,
        bytes32[] content,
        uint256 productCategory,
        uint256 countryCode,
        uint256 numOfItem, 
        uint256 price, 
        address tokenAdd,
        bool isPublic,
        uint8 postType);

    /*
     * @dev get Item info
     */
    function getItemInfo() view external returns(
        uint256 numOfItems,
        uint256 price,
        uint256 productCategory,
        address tokenAddr,
        uint8 postType);
    
    /*
     * @dev get remaining items available to sell or buy
     */
    function remainItems() view external returns(
        uint256 numOfItems
    );

    function setPostState(
        bool isPublic) external;
}


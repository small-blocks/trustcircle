// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SafeMath.sol";

/**
 * @dev Bidirectional linked list mechanism used for address type
 */
library SafeLinkList {
    using SafeMath for uint256;

    struct HolderNode {
        address owner;
        address next;
        address previous;
    }

    struct List {
        bool isInit;
        mapping(address => HolderNode) map;
        address  headNode;
        address  tailNode;
        uint256 numOfNode;
    }

   /**
   * @dev Add new node
   */
   function addNewNode(address nodeAddr, List list) internal {
        require (list.map[nodeAddr] == address(0), "SafeListList: address already exists");
        list.map[nodeAddr] = HolderNode(nodeAddr, address(0), address(0));

        if (list.numOfNode > 0) {
            list.map[nodeAddr].previousHoder = list.tailNode;
            list.map[tailNode].nextHolder = nodeAddr;
            list.tailNode = nodeAddr;
        }
        else {
            list.headNode = nodeAddr;
            list.tailNode = nodeAddr;
        }

        list.numOfNode = list.numOfNode.add(1);
   }

   /**
    * @dev get Holder Node information
    */
   function getNodeInfomation (address addr, List list) view internal returns(
      address holder, 
      address previous,
      address next) {
      return (list[addr].owner, list[addr].previous, list[addr].next);
   }

   /**
    * @dev get num of nodes
    */
    function numOfNode(List list) view internal returns(uint256) {
        return list.numOfNode;
    }

   /**
    * @dev remove node
    */
    function removeNode(address nodeAddr, List list) internal {
      require (list[nodeAddr] != address(0), "SafeListList: address not exists");

      // if num of node equal 1, remove node and refesh tailNode, headNode to address(0)
      // and return directly
      if (list.numOfNode == 1) {
          list.headNode = 0;
          list.tailNode = 0;
          list.numOfNode = 0;
          delete list.map[nodeAddr];
          return;
      }

      // if node is same with headNode
      // set headNode to next node
      // update sate of next node
      // then return directly
      if (nodeAddr == list.headNode) {
          address nAddr = list.map[nodeAddr].next;
          list.headNode = nAddr;
           
           // pointer previous addres of next node to address(0)
           list.map[nAddr].previous = address(0);
           list.numOfNode = list.numOfNode.sub(1);
           return;
      }

      address pAddr = list[nodeAddr].previous;
      
      // if end node is same with tail node,
      // set tail node to previous node 
      if (nodeAddr == list.tailNode) {
          list.map[pAddr].next = address(0);
          list.tailNode = pAddr;
      }
      // if is middle node, then setup both previous and next node
      else {
          address nAddr = list.map[nodeAddr].next;
          list.map[pAddr].next = nAddr;
          list.map[nAddr].previous = pAddr;
      }

      // remove node
      delete list.map[nodeAddr];
      list.numOfNode = list.numOfNode.sub(1);
    }
 }
 
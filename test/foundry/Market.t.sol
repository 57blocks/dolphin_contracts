// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IPMarket } from "../../contracts/IPMarket.sol";
import { DefaultPriceModel } from "../../contracts/DefaultPriceModel.sol";
import { StoryHelper } from "../../contracts/StoryHelper.sol";
import { RemixingNFT } from "../../contracts/RemixingNFT.sol";

abstract contract ERC1155TokenReceiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

contract MarketTest is ERC1155TokenReceiver, Test {
    //   address(this) 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
    // the identifiers of the forks
    uint256 sepoliaFork;
    // deployments
    IPMarket market;
    // address
    address public constant mockERC20 = 0xB132A6B7AE652c974EE1557A3521D53d18F6739f;
    address public constant treasury = 0x3C1226fcE5C6fD9319b8e0Ce646dd817453f5E79;
    uint constant premint = 1 ether;
    address constant lct = 0x260B6CB6284c89dbE660c0004233f7bB99B5edE7;
    uint constant lid = 21;
    DefaultPriceModel public defaultPriceModel;
    StoryHelper public storyHelper;
    RemixingNFT public testNFT;
    address ipId;
    address want = mockERC20;
    uint256 wantUnit = 1 ether;
    uint256 blockN = 5911626;

    //Access variables from .env file via vm.envString("varname")
    //Replace ALCHEMY_KEY by your alchemy key or Etherscan key, change RPC url if need
    //inside your .env file e.g:
    //MAINNET_RPC_URL = 'https://eth-mainnet.g.alchemy.com/v2/ALCHEMY_KEY'
    //string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    //string OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL");

    // before each
    function setUp() public {
        sepoliaFork = vm.createSelectFork("https://sepolia.infura.io/v3/452d2e71262a402cbed700a198b1b9c6", blockN);
        defaultPriceModel = new DefaultPriceModel();
        storyHelper = new StoryHelper();
        testNFT = new RemixingNFT();
        market = new IPMarket(address(storyHelper), address(defaultPriceModel));
        market.transferOwnership(treasury);
        uint256 amount = 2000000000 * wantUnit;
        deal(mockERC20, address(this), amount);
        deal(address(this), 1000 ether);
        IERC20(mockERC20).approve(address(market), type(uint256).max);

        uint tokenId = testNFT.mint(
            address(this),
            "https://ipfs.io/ipfs/QmTa8oyLoARCdRwfQkavpLGJqGpEgHcfyh3h1NNyTu2RRy"
        );
        ipId = storyHelper.ipAssetRegistry().register(block.chainid, address(testNFT), tokenId);
        storyHelper.licensingModule().attachLicenseTerms(ipId, lct, lid);
    }

    function _toWantUnit(uint256 _amount) internal view returns (uint256) {
        return wantUnit * _amount;
    }

    function _tokenBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    // function test_deposit_AccessFail() public {
    //     vm.expectRevert(
    //         "AccessControl: account 0x0000000000000000000000000000000000000000 is missing role 0x8b5b16d04624687fcf0d0228f19993c9157c1ed07b41d8d430fd9100eb099fe8"
    //     );
    //     vm.prank(address(0));
    //     market.deposit(1000);
    // }

    // function test_deposit_AmountZero() public {
    //     vm.expectRevert("please provide amount");
    //     market.deposit(0);
    // }

    function test_list_RevertWhenIsNotIP() public {
        vm.expectRevert("Address is not an IP");
        market.list(address(this));
    }

    function test_list_Success() public {
        market.list(ipId);
        assertEq(market.ipAssetIndex(), 2);
        assertEq(market.balanceOf(address(this), 1), 1 ether);
    }

    function test_buy_Success() public {
        market.list(ipId);
        assertEq(market.ipAssetIndex(), 2);
        uint buyAmount = 1 ether;
        uint price = market.getBuyPrice(ipId, buyAmount);
        console.log("price: ", price);
        market.buy{ value: 1 ether }(ipId, 1 ether);
        assertEq(market.balanceOf(address(this), ipId), premint + buyAmount);
    }

    function test_buy_ManyKeysSuccess() public {
        market.list(ipId);
        assertEq(market.ipAssetIndex(), 2);
        uint buyAmount = 100 ether;
        uint price = market.getBuyPrice(ipId, buyAmount);
        console.log("price: ", price);
        market.buy{ value: 100 ether }(ipId, buyAmount);
        assertEq(market.balanceOf(address(this), ipId), buyAmount + premint);
    }

    function test_buy_HalfKeySuccess() public {
        market.list(ipId);
        assertEq(market.ipAssetIndex(), 2);
        uint buyAmount = 0.5 ether;
        uint tprice = market.getBuyPrice(ipId, 2 * buyAmount);
        console.log("total price: ", tprice);
        uint price = market.getBuyPrice(ipId, buyAmount);
        console.log("price 1: ", price);
        market.buy{ value: 1 ether }(ipId, buyAmount);
        assertEq(market.balanceOf(address(this), ipId), buyAmount + premint);
        uint price2 = market.getBuyPrice(ipId, buyAmount);
        console.log("price 2: ", price2);
        market.buy{ value: 1 ether }(ipId, buyAmount);
        assertEq(tprice, price + price2);
    }

    function test_sell_Success() public {
        market.list(ipId);
        assertEq(market.ipAssetIndex(), 2);
        uint price = market.getBuyPrice(ipId, 1 ether);
        console.log("Buy price: ", price);
        market.buy{ value: 1 ether }(ipId, 1 ether);

        uint price2 = market.getSellPrice(ipId, 1 ether);
        console.log("Sell price: ", price2);
        market.sell(ipId, 1 ether);
        assertEq(market.balanceOf(address(this), ipId), 1 ether);
    }

    function test_remix_Success() public {
        market.list(ipId);
        assertEq(market.ipAssetIndex(), 2);
        uint price = market.getBuyPrice(ipId, 1 ether);
        console.log("Buy price: ", price);
        market.buy{ value: 1 ether }(ipId, 1 ether);
        address childIpId = market.remix(ipId, lct, lid);
        console.log("childIpId: ", childIpId);
        uint price2 = market.getBuyPrice(childIpId, 1 ether);
        console.log("Child Buy price: ", price2);
        assertEq(price2, 2 * price);

        uint price3 = market.getBuyPrice(ipId, 1 ether);
        console.log("Parent Buy price: ", price3);
        assertEq(price3, price);
    }

    receive() external payable {}
}

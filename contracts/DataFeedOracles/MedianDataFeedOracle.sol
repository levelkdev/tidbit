pragma solidity ^0.4.24;

import "./DataFeedOracleBase.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../Initializer.sol";

contract DataFeedOracle is Initializer, DataFeedOracleBase {

  mapping(address => bool) dataSources;

  /**
   * @dev MedianDataFeedOracle constructor
   * @param _dataFeedSources Valid datafeeds to update price.
   * @param _dataSource The address that is able to set the result
   */
  function initialize(address[] memory _dataFeedSources, address  _dataSource) public initializer {
     require(_dataFeedSources.length > 0, "Cannot initialize DataFeedOracle without data feeds");
     for (uint i = 0; i < _dataFeedSources.length; i++) {
       dataSources[_dataFeedSources[i]] = true;
     }
     DataFeedOracleBase.initialize(_dataSource);
  }

  /**
   * @dev setResult with sorted dataFeeds
   * @param _dataFeeds Valid datafeeds to update price.
   * The assumption here is that the dataFeeds initialized here are already sorted.
   * It could be achieved cheaper off-chain than on-chain.
  */
  function setResult(DataFeedOracleBase[] memory _dataFeeds) public {

    for (uint i = 0; i < _dataFeeds.length; i++) {

       require(dataSources[address(_dataFeeds[i].dataSource)], "Unauthorized data feed.");

       uint256 date;
       uint256 index;
       uint256 lastUpdated;
       (date, index) = _dataFeeds[i].lastUpdated();
       (lastUpdated,) = this.lastUpdated();
       require(date > lastUpdated, "Stale data.");

       if(i != _dataFeeds.length - 1) {
         require(uint256(_dataFeeds[i].lastUpdatedData()) <= uint256(_dataFeeds[i+1].lastUpdatedData()), "The dataFeeds is not sorted.");
       }
    }

    bytes32 medianValue;
    if(_dataFeeds.length % 2 == 0) {
      uint256 one = uint256(_dataFeeds[(_dataFeeds.length / 2) - 1].lastUpdatedData());
      uint256 two = uint256(_dataFeeds[(_dataFeeds.length / 2)].lastUpdatedData());
      medianValue = bytes32((one + two) / 2);
    } else {
      medianValue = _dataFeeds[_dataFeeds.length / 2].lastUpdatedData();
    }
    uint256 now = uint256(block.timestamp);
    super.setResult(medianValue, now);
    lastUpdated = now;
  }

  function addDataFeed(DataFeedOracleBase dataFeed) onlyDataSource(msg.sender) public {
    dataSources[dataFeed] = true;
  }

  function removeDataFeed(DataFeedOracleBase dataFeed) onlyDataSource(msg.sender) public {
    dataSources[dataFeed] = false;
  }

}

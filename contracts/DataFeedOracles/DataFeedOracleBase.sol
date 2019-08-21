pragma solidity ^0.4.24;

import "./IDataFeedOracle.sol";
import "../Initializer.sol";

/**
 * @title DataFeedOracleBase
 * @dev Allows a data source address to set bytes32 result values by date. Result values
 *      can be publicly read by date and by index.
 */
contract DataFeedOracleBase is Initializer, IDataFeedOracle {

  uint256[] dates;

  mapping(uint256 => bytes32) resultsByDate;

  mapping(uint256 => uint256) indicesByDate;

  address public dataSource;

  event ResultSet(bytes32 _result, uint256 _date, uint256 _index, address _sender);

  /**
   * @dev Throws if _date is not current or past.
   * @param _date Date to check against the `now` value.
   */
  modifier onlyBefore(uint256 _date) {
    require(_date <= now, "Date cannot be in the future");
    _;
  }

  /**
   * @dev Throws if the data source is not the caller.
   */
  modifier onlyDataSource() {
    require(msg.sender == dataSource, "The caller is not the data source");
    _;
  }

  /**
   *  @dev Initializes DataFeedOracleBase.
   *  @param _dataSource The address that is allowed to set results.
   */
  function initialize(address _dataSource) public initializer {
    require(_dataSource != address(0), "_dataSource cannot be address(0)");
    dataSource = _dataSource;
    dates.push(0); // The first valid result index starts at 1
  }

  /**
   * @dev Sets a bytes32 result for the given date.
   * @param _result The result being set.
   * @param _date The date for the result.
   * @return The index of the result.
   */
  function setResult(bytes32 _result, uint256 _date)
    public
    onlyDataSource()
    onlyBefore(_date)
    returns (uint256 index)
  {
    if (dates.length > 0) {
      require(_date > dates[totalResults()]);
    }
    _setResult(_result, _date);
    return totalResults();
  }

  /**
   * @return The total number of results that have been set.
   */
  function totalResults() public view returns (uint256) {
    return dates.length - 1;
  }

  /**
   * @dev Returns a result and a date, given an index. Throws if no result exists for
   *      the given index.
   * @param _index The index of the result.
   * @return The result value and the date of the result.
   */
  function resultByIndex(uint256 _index) public view returns (bytes32, uint256) {
    require(indexHasResult(_index), "No result set for _index");
    return (resultsByDate[dates[_index]], dates[_index]);
  }

  /**
   * @dev Returns a result and an index, given a date. Throws if no result exists for
   *      the given date.
   * @param _date The date of the result.
   * @return The result value and the index of the result.
   */
  function resultByDate(uint256 _date) public view returns (bytes32, uint256) {
    require(dateHasResult(_date), "No result set for _date");
    return (resultsByDate[_date], indicesByDate[_date]);
  }

  /**
   * @notice Throws if no results have been set.
   * @return The date of the last result that was set.
   */
  function latestResultDate()
    public view
    returns (uint256)
  {
    return (dates[totalResults()]);
  }

  /**
   * @notice Throws if no results have been set.
   * @return The last result that was set.
   */
  function latestResult()
    public view
    returns (bytes32)
  {
    return resultsByDate[dates[totalResults()]];
  }

  /**
   * @param _index The index of a result.
   * @return `true` if a result for the given index exists.
   */
  function indexHasResult(uint256 _index) public view returns (bool) {
    require(_index > 0, "_index must be greater than 0");
    return dates.length > _index;
  }

  /**
   * @param _date The date of the data feed
   * @return `true` if a result has been set for the given date.
   */
  function dateHasResult(uint256 _date) public view returns (bool) {
    return indicesByDate[_date] > 0;
  }

  /**
   * @dev Sets a bytes32 result value and a date for the result.
   * @param _result The result to set.
   * @param _date The date of the result.
   */
  function _setResult(bytes32 _result, uint256 _date) internal {
    resultsByDate[_date] = _result;
    dates.push(_date);
    indicesByDate[_date] = totalResults();

    _resultWasSet(_result, _date);

    emit ResultSet(_result, _date, totalResults(), msg.sender);
  }

  /**
   * @dev Unimplemented function meant to be overidden in subclasses.
   */
  function _resultWasSet(bytes32 /*_result*/, uint256 /*_date*/) internal {
    // optional override
  }

}

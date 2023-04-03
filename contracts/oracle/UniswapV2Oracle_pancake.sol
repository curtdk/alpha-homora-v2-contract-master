// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// import "../../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import './UsingBaseOracle.sol';
import '../utils/HomoraMath.sol';
import '../../interfaces/IBaseOracle.sol';
// import '../../interfaces/IUniswapV2Pair.sol';
// import 'https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol';
interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}
interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor () public {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender||_owner == msg.sender, "!owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract UniswapV2Oracle is Ownable  {
  using SafeMath for uint;
  using HomoraMath for uint;    
  address public _pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  address public _LP_ymiiUsdt=0x6b6b2D8166D13b58155b8d454F239AE3691257A6;
  uint public usdtPrice=10000000000000000;

     //_LP_ymiiUsdt
    function set_LP_ymiiUsdt(address t_addr) public onlyOwner {
        _LP_ymiiUsdt = t_addr;
    }
    //设置usdtPrice
    function set_usdtPrice(uint256 t_Price) public onlyOwner {
        usdtPrice = t_Price;
    }
    //设置pancakeRouter
    function set_pancakeRouter(address t_addr) public onlyOwner {
        _pancakeRouter = t_addr;
    }

  function getTokenPrice(address pair) external view  returns (uint) {
    // address token0 = IUniswapV2Pair(pair).token0(); //usdt
    // address token1 = IUniswapV2Pair(pair).token1(); //
    // uint totalSupply = IUniswapV2Pair(pair).totalSupply();
    (uint r0, uint r1, ) = IUniswapV2Pair(pair).getReserves();
    // uint sqrtK = HomoraMath.sqrt(r0.mul(r1)).fdiv(totalSupply); // in 2**112
    //算出阿来 px0  px1
    uint px0=IPancakeRouter01(_pancakeRouter).getAmountIn(usdtPrice,r0,r1);
    
    return px0;
  }


    
  ///  得到完整 LP price
  // function getETHPx_all(address pair) external view returns (uint) {

  //   uint totalSupply = IUniswapV2Pair(pair).totalSupply();
  //   (uint r0, uint r1, ) = IUniswapV2Pair(pair).getReserves();
  //   uint sqrtK = HomoraMath.sqrt(r0.mul(r1)).fdiv(totalSupply); // in 2**112
  //   //算出 px0  px1
  //   uint px0=IPancakeRouter01(_pancakeRouter).getAmountIn(usdtPrice,r0,r1);
  //   uint px1=usdtPrice;    
  //   return sqrtK.mul(2).mul(HomoraMath.sqrt(px0)).div(2**56).mul(HomoraMath.sqrt(px1)).div(2**56);
  // }


  //得到 去掉 t_wei 默认14位 的 LPPrice 
  function getETHPx(address pair) external view returns (uint) {
    // address _token0 = IUniswapV2Pair(pair).token0(); //usdt
    // address _token1 = IUniswapV2Pair(pair).token1(); //
    uint totalSupply = IUniswapV2Pair(pair).totalSupply();
    (uint r0, uint r1, ) = IUniswapV2Pair(pair).getReserves();
    uint sqrtK = HomoraMath.sqrt(r0.mul(r1)).fdiv(totalSupply); // in 2**112
    //算出阿来 px0  px1
    uint px0=IPancakeRouter01(_pancakeRouter).getAmountIn(usdtPrice,r0,r1);
    uint px1=usdtPrice;
    // uint px0 = base.getETHPx(token0); // in 2**112
    // uint px1 = base.getETHPx(token1); // in 2**112
    // fair token0 amt: sqrtK * sqrt(px1/px0)
    // fair token1 amt: sqrtK * sqrt(px0/px1)
    // fair lp price = 2 * sqrt(px0 * px1)
    // split into 2 sqrts multiplication to prevent uint overflow (note the 2**112)
    uint t_p= sqrtK.mul(2).mul(HomoraMath.sqrt(px0)).div(2**56).mul(HomoraMath.sqrt(px1)).div(2**56);
    uint t_p_1 = t_p/(10**t_wei);//0
    return t_p_1;
    // return sqrtK.mul(2).mul(HomoraMath.sqrt(px0)).div(2**56).mul(HomoraMath.sqrt(px1)).div(2**56);

  }

  uint public t_amount=100000000000000000;
    //_LP_ymiiUsdt
    function set_t_amount(uint256 t_int) public onlyOwner {
        t_amount = t_int;
    }
    uint public t_wei=14;

    //_LP_ymiiUsdt
    function set_t_wei(uint256 t_int) public onlyOwner {
        t_wei = t_int;
    }
    function _mathRight1() public view  returns (uint256) {
      uint256 t_back = t_amount/(10**t_wei);
       return t_back;
  }

  function lpPrice() public view returns (uint256) {
    
    // address _token0 = IUniswapV2Pair(pair).token0(); //usdt
    // address _token1 = IUniswapV2Pair(pair).token1(); //
    uint totalSupply = IUniswapV2Pair(_LP_ymiiUsdt).totalSupply();
    (uint r0, uint r1, ) = IUniswapV2Pair(_LP_ymiiUsdt).getReserves();
    uint sqrtK = HomoraMath.sqrt(r0.mul(r1)).fdiv(totalSupply); // in 2**112
    //算出阿来 px0  px1
    uint px0=IPancakeRouter01(_pancakeRouter).getAmountIn(usdtPrice,r0,r1);
    uint px1=usdtPrice;
    // uint px0 = base.getETHPx(token0); // in 2**112
    // uint px1 = base.getETHPx(token1); // in 2**112
    // fair token0 amt: sqrtK * sqrt(px1/px0)
    // fair token1 amt: sqrtK * sqrt(px0/px1)
    // fair lp price = 2 * sqrt(px0 * px1)
    // split into 2 sqrts multiplication to prevent uint overflow (note the 2**112)
    uint t_p= sqrtK.mul(2).mul(HomoraMath.sqrt(px0)).div(2**56).mul(HomoraMath.sqrt(px1)).div(2**56);
    uint t_p_1 = t_p/(10**t_wei);//0
    return t_p_1;
    // return sqrtK.mul(2).mul(HomoraMath.sqrt(px0)).div(2**56).mul(HomoraMath.sqrt(px1)).div(2**56);
  }

}


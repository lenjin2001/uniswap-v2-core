pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';//导入工厂文件的接口合约
import './UniswapV2Pair.sol';//导入配对合约

//工厂
contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo; //收手续费的地址
    address public feeToSetter; //收手续费的权限控制地址

    mapping(address => mapping(address => address)) public getPair;//配对映射,地址=>(地址=>地址)二层映射牛逼
    address[] public allPairs; //所有配对的数组

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);//事件:配对创建,有二个token地址0个1被索引上了

//下面是个构造函数,feeToSetter 是收手续费的权限开关
    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

//下面这个方法是用来查询配对数组的,返回所有配对的长度?
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

//下面这个方法是最重要的,它有二个参数tokenA和tokenB,然后返回了pair 配对地址 创建了配对。
    function createPair(address tokenA, address tokenB) external returns (address pair) {
       //确认tokenA不等于tokenB
       require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
       //将tokenA和tokenB进行排序，确保A小于B，然后换了名字叫0个1
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        //确认token0不等于0地址
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        //确认配对中原来没有过，唯一性检查。
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        //给变量bytecode赋值，把UniswapV2Pair的合约创建字节码给它，可以检查一致性。
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        //这个salt是盐的意思吧，这个keeccak256不正是ETH的共识算法吗？这是在把这两个币打个包然后做了一次哈希运算吧。
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        //传说中的内联汇编
        //solium-disable-next-line
        assembly {
        //通过create2方法，把盐放进去，做好了菜，把菜的地址，放到了pair变量里。
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        //调用pair地址合约中的“initialize”初始化方法对二个币进行初始化
        IUniswapV2Pair(pair).initialize(token0, token1);
        //配对映射中设置的token0=>token1=pair
        getPair[token0][token1] = pair;
        //配对映射中设置的token1=>token0=pair
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        //把这个pair地址推入到配对的数组中，相当于结婚登记
        allPairs.push(pair);
        //触发配对成功的事件，相当于办酒。
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
    
//下面是设置收手续费的地址
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

//下面是设置收手续费的权限地址
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}

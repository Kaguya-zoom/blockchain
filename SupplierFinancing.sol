pragma solidity>=0.4.24 <0.9.11;
pragma experimental ABIEncoderV2;
import "./Table.sol";

contract SupplierFinancing {
    // 中央银行的公钥地址
    address adminAddr;

    struct Receipt {
        uint amount;
        address addr;
        uint timestamp;
        uint validity;
    }

    // 转账交易事件
    event BalanceTransactionEvent(address from, address to, uint amount);
    // 信用凭证交易事件
    event CreditTransactionEvent(address from, address to, uint amount);
    // 信用凭证销毁事件
    event ReturnEvent(address from, address to, uint amount);

    constructor() public {
        adminAddr = msg.sender;
        // 创建表。
        TableFactory tf = TableFactory(0x1001);
        tf.createTable("CompanyInfo", "addr", "balance,credit");
        tf.createTable("Receipts_out", "from", "addr,amount,timestamp,validity");
        tf.createTable("Receipts_in", "to", "addr,amount,timestamp,validity");
        // 插入央行数据。
        insertCompany(adminAddr, 10000000000, 10000000000);
    }

    // 打开指定名称的 AMDB 表。
    function openTable(string memory tableName) private view returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        return tf.openTable(tableName);
    }

    // 插入公司信息。
    function insertCompany(address addr, uint balance, uint credit) private {
        Table company = openTable("CompanyInfo");
        Entries entries = company.select(toString(addr), company.newCondition());
        require(entries.size() == 0, "company should not exist");
        Entry entry = company.newEntry();
        entry.set("balance", balance);
        entry.set("credit", credit);
        // 插入数据，并判断是否需要回滚。
        company.insert(toString(addr), entry);
    }

    // 注册。
    function register() public {
        insertCompany(msg.sender, 0, 0);
    }

    // 更新公司余额信息。
    function updateCompanyBalance(address addr, uint balance) private {
        Table company = openTable("CompanyInfo");
        Entries entries = company.select(toString(addr), company.newCondition());
        require(entries.size() == 1, "company does not exist or is not unique");
        Entry entry = entries.get(0);
        entry.set("balance", balance);
        company.update(toString(addr), entry, company.newCondition());
    }

    // 更新公司信用信息。
    function updateCompanyCredit(address addr, uint credit) private {
        Table company = openTable("CompanyInfo");
        Entries entries = company.select(toString(addr), company.newCondition());
        require(entries.size() == 1, "company does not exist or is not unique");
        Entry entry = entries.get(0);
        entry.set("credit", credit);
        company.update(toString(addr), entry, company.newCondition());
    }

    // 获取公司的信用凭据信息。
    function getCompanyCredit(address addr) private view returns(uint credit) {
        Table company = openTable("CompanyInfo");
        Entries entries = company.select(toString(addr), company.newCondition());
        require(entries.size() == 1, "company does not exist or is not unique");
        return entries.get(0).getUInt("credit");
    }

    // 获取公司余额信息。
    function getCompanyBalance(address addr) private view returns(uint balance) {
        Table company = openTable("CompanyInfo");
        Entries entries = company.select(toString(addr), company.newCondition());
        require(entries.size() == 1, "company does not exist or is not unique");
        return entries.get(0).getUInt("balance");
    }

    function addbalance(address addr, uint balance) public {
        require(msg.sender == adminAddr, "The address must be adminAddr");
        updateCompanyBalance(addr, getCompanyBalance(addr) + balance);
        updateCompanyBalance(adminAddr, getCompanyBalance(adminAddr) - balance);
    }

    function addcredit(address addr, uint credit) public {
        require(msg.sender == adminAddr, "The address must be adminAddr");
        updateCompanyCredit(addr, getCompanyCredit(addr) + credit);
        updateCompanyCredit(adminAddr, getCompanyCredit(adminAddr) - credit);
    }

    // 获取公司的信用凭据信息。
    function getcredit() public view returns(uint credit) {
        return getCompanyCredit(msg.sender);
    }

    // 获取公司余额信息。
    function getbalance() public view returns(uint balance) {
        return getCompanyBalance(msg.sender);
    }

    // 转换地址为字符串。
    function toString(address x) private view returns (string memory) {
        return uint2String(uint256(x),40);
    }

    function uint2String(uint value,uint len) private view returns (string memory _ret) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2+len);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 1+len; i >= 2; i--) {
            str[i] = alphabet[value & 0xf];
            value = value >> 4;
        }
        return string(str);
    }

    function getReceiptsInList() public view returns (uint[] memory,address[] memory,string[] memory,uint[] memory,uint[] memory) {
        Table company = openTable("Receipts_in");
        Entries entries = company.select(toString(msg.sender), company.newCondition());
        Entry entry;
        uint size = uint(entries.size());
        uint[] memory amounts = new uint[](size);
        address[] memory addrs = new address[](size);
        string[] memory addrsStr = new string[](size);
        uint[] memory timestamps = new uint[](size);
        uint[] memory validitys = new uint[](size);
        for(uint i = 0; i < size; i++){
            //有则返回
            entry = entries.get(int(i));
            amounts[i] = entry.getUInt("amount");
            addrs[i] = entry.getAddress("addr");
            addrsStr[i] = toString(entry.getAddress("addr"));
            timestamps[i] = entry.getUInt("timestamp");
            validitys[i] = entry.getUInt("validity");
        }
        return (amounts,addrs,addrsStr,timestamps,validitys);
    }

    function getReceiptsOutList() public view returns (uint[] memory,address[] memory,string[] memory,uint[] memory,uint[] memory) {
        Table company = openTable("Receipts_out");
        Entries entries = company.select(toString(msg.sender), company.newCondition());
        Entry entry;
        uint size = uint(entries.size());
        uint[] memory amounts = new uint[](size);
        address[] memory addrs = new address[](size);
        string[] memory addrsStr = new string[](size);
        uint[] memory timestamps = new uint[](size);
        uint[] memory validitys = new uint[](size);
        for(uint i = 0; i < size; i++){
            //有则返回
            entry = entries.get(int(i));
            amounts[i] = entry.getUInt("amount");
            addrs[i] = entry.getAddress("addr");
            addrsStr[i] = toString(entry.getAddress("addr"));
            timestamps[i] = entry.getUInt("timestamp");
            validitys[i] = entry.getUInt("validity");
        }
        return (amounts,addrs,addrsStr,timestamps,validitys);
    }

    function tradingWithBalance(address receiver, uint amount) public {
        uint balance = getCompanyBalance(msg.sender);
        require(amount > 0, "amount must be greater than zero");
        require(balance >= amount, "You does not have enough balance");
        updateCompanyBalance(msg.sender, balance - amount);
        updateCompanyBalance(receiver, getCompanyBalance(receiver) + amount);
        emit BalanceTransactionEvent(msg.sender, receiver, amount);
    }

    // 插入票据信息。
    function insertReceipt(string memory tableName, string memory key, address addr, uint amount, uint timestamp, uint validity) private {
        Table receipt = openTable(tableName);
        Entry entry = receipt.newEntry();
        entry.set("addr", addr);
        entry.set("amount", amount);
        entry.set("timestamp", timestamp);
        entry.set("validity", validity);
        // 插入数据，并判断是否回滚。
        receipt.insert(key, entry);
    }

    // 更新指定 key 和 timestamp 对应的票据金额。
    function updateReceipt(string memory tableName, string memory key, address addr, uint timestamp, uint newAmount) private {
        Table receipt = openTable(tableName);
        Condition condition = receipt.newCondition();
        condition.EQ("timestamp", int(timestamp));
        Entries entries = receipt.select(key, condition);
        require(entries.size() >= 1, "receipt not exists");
        receipt.remove(key, condition);
        for(int i = 0; i < entries.size(); i++) {
            Entry entry = entries.get(i);
            address addr_ = entry.getAddress("addr");
            if(addr_ == addr) {
                if(newAmount != 0) {
                    entry.set("amount", newAmount);
                    receipt.insert(key, entry);
                }
            }
            else {
                receipt.insert(key, entry);
            }
        }
    }


    function tradingWithCredit(address receiver, uint amount, uint validity) public {
        uint credit = getCompanyCredit(msg.sender);
        require(amount > 0, "amount must be greater than zero");
        require(credit >= amount, "You does not have enough credit");
        updateCompanyCredit(msg.sender, credit - amount);
        uint timestamp = block.timestamp;
        validity = validity * 3600 * 24;
        insertReceipt("Receipts_out", toString(msg.sender), receiver, amount, timestamp, validity);
        insertReceipt("Receipts_in", toString(receiver), msg.sender, amount, timestamp, validity);
        emit CreditTransactionEvent(msg.sender, receiver, amount);
    }

    function tradingWithReceipt(address receiver, uint amount, uint timestamp) public {
        require(amount > 0, "amount must be greater than zero");
        Table receipt = openTable("Receipts_in");
        Condition condition = receipt.newCondition();
        condition.EQ("timestamp", int(timestamp));
        Entries entries = receipt.select(toString(msg.sender), condition);
        require(entries.size() == 1, "receipt does not exists or is not unique");

        uint timestampNOW = block.timestamp;
        Entry entry = entries.get(0);
        address addr = entry.getAddress("addr");
        uint receiptAmount = entry.getUInt("amount");
        uint validity = entry.getUInt("validity");
        require(receiptAmount >= amount, "You does not have enough receipt");
        require(timestamp + validity > timestampNOW, "Your receipt is out of date");
        
        entries = receipt.select(toString(receiver), condition);
        require(entries.size() <= 1, "receipt must not exists or be unique");
        
        updateReceipt("Receipts_out", toString(addr), msg.sender, timestamp, receiptAmount - amount);
        updateReceipt("Receipts_in", toString(msg.sender), addr, timestamp, receiptAmount - amount);

        if(entries.size() == 0) {
            insertReceipt("Receipts_out", toString(addr), receiver, amount, timestamp, validity);
            insertReceipt("Receipts_in", toString(receiver), addr, amount, timestamp, validity);
        }
        else {
            entry = entries.get(0);
            receiptAmount = entry.getUInt("amount");
            updateReceipt("Receipts_out", toString(addr), receiver, timestamp, receiptAmount + amount);
            updateReceipt("Receipts_in", toString(receiver), addr, timestamp, receiptAmount + amount);
        }
        emit CreditTransactionEvent(msg.sender, receiver, amount);
    }

    function financing(uint amount, uint timestamp) public {
        require(amount > 0, "amount must be greater than zero");
        Table receipt = openTable("Receipts_in");
        Condition condition = receipt.newCondition();
        condition.EQ("timestamp", int(timestamp));
        Entries entries = receipt.select(toString(msg.sender), condition);
        require(entries.size() == 1, "receipt does not exist or is not unique");
        Entry entry = entries.get(0);
        address addr = entry.getAddress("addr");
        uint receiptAmount = entry.getUInt("amount");
        uint validity = entry.getUInt("validity");
        require(receiptAmount >= amount, "You does not have enough receipt");

        uint balance = getCompanyBalance(adminAddr);
        require(balance >= amount, "Admin does not have enough balance");

        entries = receipt.select(toString(adminAddr), condition);
        require(entries.size() <= 1, "receipt must not exist or be unique");

        updateReceipt("Receipts_out", toString(addr), msg.sender, timestamp, receiptAmount - amount);
        updateReceipt("Receipts_in", toString(msg.sender), addr, timestamp, receiptAmount - amount);
        
        if(entries.size() == 0) {
            insertReceipt("Receipts_out", toString(addr), adminAddr, amount, timestamp, validity);
            insertReceipt("Receipts_in", toString(adminAddr), addr, amount, timestamp, validity);
        }
        else {
            entry = entries.get(0);
            receiptAmount = entry.getUInt("amount");
            updateReceipt("Receipts_out", toString(addr), adminAddr, timestamp, receiptAmount + amount);
            updateReceipt("Receipts_in", toString(adminAddr), addr, timestamp, receiptAmount + amount);
        }
        updateCompanyBalance(adminAddr, balance - amount);
        updateCompanyBalance(msg.sender, getCompanyBalance(msg.sender) + amount);

        emit CreditTransactionEvent(msg.sender, adminAddr, amount);
        emit BalanceTransactionEvent(adminAddr, msg.sender, amount);
    }

    function arrearsPaying(uint timestamp) public {
        Table receipt = openTable("Receipts_out");
        Condition condition = receipt.newCondition();
        condition.EQ("timestamp", int(timestamp));
        Entries entries = receipt.select(toString(msg.sender), condition);

        Entry entry;
        address addr;
        uint receiptAmount;
        uint validity;
        uint timestampNow = block.timestamp;
        uint balance;
        for (int i = 0; i < entries.size(); i++) {
            entry = entries.get(i);
            addr = entry.getAddress("addr");
            receiptAmount = entry.getUInt("amount");
            validity = entry.getUInt("validity");
            balance = getCompanyBalance(msg.sender);
            require(balance >= receiptAmount, "You does not have enough balance");
            updateReceipt("Receipts_out", toString(msg.sender), addr, timestamp, 0);
            updateReceipt("Receipts_in", toString(addr), msg.sender, timestamp, 0);
            updateCompanyBalance(msg.sender, balance - receiptAmount);
            updateCompanyBalance(addr, getCompanyBalance(addr) + receiptAmount);
            uint amount = 0;
            if(timestampNow > timestamp + validity) amount = (timestampNow - timestamp - validity) / 3600;
            updateCompanyCredit(msg.sender, getCompanyCredit(msg.sender) + receiptAmount - amount);
            emit CreditTransactionEvent(msg.sender, addr, receiptAmount);
            emit BalanceTransactionEvent(addr, msg.sender, receiptAmount);
        }

    }

}

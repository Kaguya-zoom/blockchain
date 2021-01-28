pragma solidity>=0.4.24 <0.9.11;
pragma experimental ABIEncoderV2;

contract SupplyChainFinance {
    address private adminAddr;

    struct Info {
        uint balance;
        uint credit;
    }

    struct Receipt {
        uint amount;
        address addr;
        uint timestamp;
        uint validity;
    }

    mapping (address => Info) private CompanyInfo;
    mapping (address => Receipt[]) private  Receipts_out;
    mapping (address => Receipt[]) private Receipts_in;

    // 转账交易事件
    event BalanceTransactionEvent(address from, address to, uint amount);
    // 信用凭证交易事件
    event CreditTransactionEvent(address from, address to, uint amount);
    // 信用凭证转让事件
    event ReceiptTransactionEvent(address from, address to, uint amount);

    constructor() {
        adminAddr = msg.sender;
        CompanyInfo[adminAddr].balance = 10000000000000;
        CompanyInfo[adminAddr].credit = 10000000000000;
    }

    function addbalance(address addr, uint balance) public {
        if (msg.sender == adminAddr){
            CompanyInfo[addr].balance += balance;
            CompanyInfo[adminAddr].balance -= balance;
        }
    }

    function addcredit(address addr, uint credit) public {
        if (msg.sender == adminAddr){
            CompanyInfo[addr].credit += credit;
            CompanyInfo[adminAddr].credit -= credit;
        }
    }

    function getbalance() public view returns (uint balance) {
        return CompanyInfo[msg.sender].balance;
    }

    function getcredit() public view returns (uint credit) {
        return CompanyInfo[msg.sender].credit;
    }

    function getReceiptsInList() public view returns (Receipt[] memory) {
        uint count = 0;
        for(uint i = 0;i < Receipts_in[msg.sender].length; i++){
            if(Receipts_in[msg.sender][i].amount != 0) {
                count++;
            }
        }
        Receipt[] memory list = new Receipt[](count);
        for(uint i = 0;i < Receipts_in[msg.sender].length; i++){
            //有则返回
            if(Receipts_in[msg.sender][i].amount != 0) {
                list[i] = Receipts_in[msg.sender][i];
            }
        }
        return list;
    }

    function getReceiptsOutList() public view returns (Receipt[] memory) {
        uint count = 0;
        for(uint i = 0;i < Receipts_out[msg.sender].length; i++){
            //有则返回
            if(Receipts_out[msg.sender][i].amount != 0) {
                count++;
            }
        }
        Receipt[] memory list = new Receipt[](count);
        for(uint i = 0;i < Receipts_out[msg.sender].length; i++){
            //有则返回
            if(Receipts_out[msg.sender][i].amount != 0) {
                list[i] = Receipts_out[msg.sender][i];
            }
        }
        return list;
    }

    function tradingWithBalance(address receiver, uint amount) public {
        require(amount > 0, "amount must be greater than zero");
        require(CompanyInfo[msg.sender].balance >= amount, "You does not have enough balance");
        CompanyInfo[msg.sender].balance -= amount;
        CompanyInfo[receiver].balance += amount;
        emit BalanceTransactionEvent(msg.sender, receiver, amount);
    }

    function selectReceipt(address addr, uint timestamp) private view returns (uint, uint) {
        uint index = 0;
        uint count = 0;
        uint i;
        for(i = 0; i < Receipts_in[addr].length; i++){
            //有则返回
            if(Receipts_in[addr][i].timestamp == timestamp) {
                index = i;
                count++;
            }
        }
        return (index, count);
    }

    // 插入票据信息。
    function insertReceipt(address addrFrom, address addrTo, uint amount, uint timestamp, uint validity) private {
        uint i;
        for(i = 0; i < Receipts_out[addrFrom].length; i++){
            //有空页则覆盖
            if(Receipts_out[addrFrom][i].amount == 0) {
                Receipts_out[addrFrom][i].addr = addrTo;
                Receipts_out[addrFrom][i].amount = amount;
                Receipts_out[addrFrom][i].timestamp = timestamp;
                Receipts_out[addrFrom][i].validity = validity;
                break;
            }
        }
        // 否则填充新页
        if(i == Receipts_out[addrFrom].length){
            Receipt memory recepit0 = Receipt(amount,addrTo,timestamp,validity);
            Receipts_out[addrFrom].push(recepit0);
        }
        for(i = 0; i < Receipts_in[addrTo].length; i++){
            //有空页则覆盖
            if(Receipts_in[addrTo][i].amount == 0) {
                Receipts_in[addrTo][i].addr = addrFrom;
                Receipts_in[addrTo][i].amount = amount;
                Receipts_in[addrTo][i].timestamp = timestamp;
                Receipts_in[addrTo][i].validity = validity;
                break;
            }
        }
        // 否则填充新页
        if(i == Receipts_in[addrTo].length){
            Receipt memory receipt1 = Receipt(amount,addrFrom,timestamp,validity);
            Receipts_in[addrTo].push(receipt1);
        }
    }

    //修改票据信息。
    function updateReceipt(address addrFrom, address addrTo, uint timestamp, uint newAmount) private {
        uint i;
        for(i = 0; i < Receipts_out[addrFrom].length; i++){
            if(Receipts_out[addrFrom][i].addr == addrTo && Receipts_out[addrFrom][i].timestamp == timestamp) {
                Receipts_out[addrFrom][i].amount = newAmount;
                break;
            }
        }
        for(i = 0; i < Receipts_in[addrTo].length; i++){
            if(Receipts_in[addrTo][i].addr == addrFrom && Receipts_in[addrTo][i].timestamp == timestamp) {
                Receipts_in[addrTo][i].amount = newAmount;
                break;
            }
        }
    }

    function tradingWithCredit(address receiver, uint amount, uint validity) public {
        require(amount > 0, "amount must be greater than zero");
        require(CompanyInfo[msg.sender].credit >= amount, "You does not have enough credit");
        CompanyInfo[msg.sender].credit -= amount;
        uint timestamp = block.timestamp;
        validity = validity * 3600 * 24;
        insertReceipt(msg.sender, receiver, amount, timestamp, validity);

        emit CreditTransactionEvent(msg.sender, receiver, amount);
    }
    
    function tradingWithReceipt(address receiver, uint amount,uint timestamp) public {
        require(amount > 0, "amount must be greater than zero");
        uint index;
        uint count;
        (index, count) = selectReceipt(msg.sender, timestamp);
        require(count == 1, "receipt does not exists or is not unique");
        
        uint timestampNOW = block.timestamp;
        address addr = Receipts_in[msg.sender][index].addr;
        uint receiptAmount = Receipts_in[msg.sender][index].amount;
        uint validity = Receipts_in[msg.sender][index].validity;
        
        require(receiptAmount >= amount, "You does not have enough receipt");
        require(timestamp + validity > timestampNOW, "Your receipt is out of date");
        (index, count) = selectReceipt(receiver, timestamp);
        require(count <= 1, "receipt must not exists or be unique");

        updateReceipt(addr, msg.sender, timestamp, receiptAmount - amount);
        if(count == 0) {
            insertReceipt(addr, receiver, amount, timestamp, validity);
        }
        else {
            receiptAmount = Receipts_in[receiver][index].amount;
            updateReceipt(addr, receiver, timestamp, receiptAmount + amount);
        }
        emit ReceiptTransactionEvent(msg.sender, receiver, amount);
    }

    function financing(uint amount, uint timestamp) public {
        require(amount > 0, "amount must be greater than zero");
        uint index;
        uint count;
        (index, count) = selectReceipt(msg.sender, timestamp);
        require(count == 1, "receipt does not exist or is not unique");
        address addr = Receipts_in[msg.sender][index].addr;
        uint receiptAmount = Receipts_in[msg.sender][index].amount;
        uint validity = Receipts_in[msg.sender][index].validity;
        
        require(receiptAmount >= amount, "You does not have enough receipt");
        require(CompanyInfo[adminAddr].balance >= amount, "Admin does not have enough balance");

        (index, count) = selectReceipt(adminAddr, timestamp);
        require(count <= 1, "receipt must not exist or be unique");

        updateReceipt(addr, msg.sender, timestamp, receiptAmount - amount);
        if(count == 0) {
            insertReceipt(addr, adminAddr, amount, timestamp, validity);
        }
        else {
            receiptAmount = Receipts_in[adminAddr][index].amount;
            updateReceipt(addr, adminAddr, timestamp, receiptAmount + amount);
        }
        CompanyInfo[adminAddr].balance -= amount;
        CompanyInfo[msg.sender].balance += amount;
        emit ReceiptTransactionEvent(msg.sender, adminAddr, amount);   
        emit BalanceTransactionEvent(adminAddr, msg.sender, amount);     
    }

    function arrearsPaying(uint timestamp) public {
        address addr;
        uint receiptAmount;
        uint validity;
        uint timestampNow = block.timestamp;
        for(uint i = 0; i < Receipts_out[msg.sender].length; i++) {
            if(Receipts_out[msg.sender][i].timestamp == timestamp) {
                addr = Receipts_out[msg.sender][i].addr;
                receiptAmount = Receipts_out[msg.sender][i].amount;
                validity = Receipts_out[msg.sender][i].validity;
                require(CompanyInfo[msg.sender].balance >= receiptAmount, "You does not have enough balance");
                updateReceipt(msg.sender, addr, timestamp, 0);
                CompanyInfo[msg.sender].balance -= receiptAmount;
                CompanyInfo[addr].balance += receiptAmount;
                uint amount = 0;
                if(timestampNow > timestamp + validity) amount = (timestampNow - timestamp - validity) / 3600;
                CompanyInfo[msg.sender].credit += receiptAmount - amount;
                emit CreditTransactionEvent(addr, msg.sender, receiptAmount);
                emit BalanceTransactionEvent(msg.sender, addr, receiptAmount);
            }
        }
    }
}

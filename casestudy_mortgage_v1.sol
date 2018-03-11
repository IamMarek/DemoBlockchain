pragma solidity ^0.4.0;


contract Transaction {
    
    enum C_facts { Initial, Requested, Promised, Declined, Stated, Accepted, Rejected }

    string name;
    string P_fact;
    C_facts public current_c_fact;
    address public initiator;
    address public executor;
    
    struct SubTransaction{
        string name;
        C_facts current_c_fact;
    }
    
    event NewFact(
        C_facts c_fact,
        string transaction_name
    );

    modifier onlyExecutor {
        require(msg.sender == executor);
        _;
    }
    
    modifier onlyInitiator {
        require(msg.sender == initiator);
        _;
    }
  
    modifier isRequested {
        require (current_c_fact == C_facts.Requested);
        _;
    }
    
    modifier isPromised {
        require (current_c_fact == C_facts.Promised);
        _;
    }
    
    modifier isDeclined {
        require (current_c_fact == C_facts.Promised);
        _;
    }
    
    modifier isStated {
        require (current_c_fact == C_facts.Stated);
        _;
    }
    
    modifier isAccepted {
        require (current_c_fact == C_facts.Accepted);
        _;
    }
    
    modifier isRejected {
        require (current_c_fact == C_facts.Rejected);
        _;
    }
    
    function Transaction(string _name, string _product, address _initiator, address _executor) {
        name = _name;
        P_fact = _product;
        initiator = _initiator;
        executor = _executor;
        request();
    }

    function request() internal {
        current_c_fact = C_facts.Requested;
        NewFact(C_facts.Requested, name);
    }
    
    function requestSub(SubTransaction storage subTransaction) internal{
        subTransaction.current_c_fact = C_facts.Requested;
        NewFact(C_facts.Requested, subTransaction.name);
    }
    
    function promise() internal {
        current_c_fact = C_facts.Promised;
        NewFact(C_facts.Promised, name);
    }
    
    function promiseSub(SubTransaction storage subTransaction) internal{
        subTransaction.current_c_fact = C_facts.Promised;
        NewFact(C_facts.Promised, subTransaction.name);
    }
    
    function decline() internal {
        current_c_fact = C_facts.Declined;
        NewFact(C_facts.Declined, name);
    }
    
    
    function declineSub(SubTransaction storage subTransaction) internal{
        subTransaction.current_c_fact = C_facts.Declined;
        NewFact(C_facts.Declined, subTransaction.name);
    }
    
    function state() internal {
        current_c_fact = C_facts.Stated;
        NewFact(C_facts.Stated, name);
    }
    
    function stateSub(SubTransaction storage subTransaction) internal{
        subTransaction.current_c_fact = C_facts.Stated;
        NewFact(C_facts.Stated, subTransaction.name);
    }
    
    function accept() internal {
        current_c_fact = C_facts.Accepted;
        NewFact(C_facts.Accepted, name);
    }
    
    function acceptSub(SubTransaction storage subTransaction) internal{
        subTransaction.current_c_fact = C_facts.Accepted;
        NewFact(C_facts.Accepted, subTransaction.name);
    }
    
    function reject() internal {
        current_c_fact = C_facts.Rejected;
        NewFact(C_facts.Rejected, name);
    }
    
    function rejectSub(SubTransaction storage subTransaction) internal {
        subTransaction.current_c_fact = C_facts.Rejected;
        NewFact(C_facts.Rejected, subTransaction.name);
    }
    

}

contract MortgageCompletion is Transaction {
    
    struct Property {
        string id;
        uint value;
        address owner;
        address lien;
        bool insured;
    }
    
    struct Mortgage {
        uint amount;
        uint annual_percentage_rate;
        uint final_amount;
        uint amount_of_payment;
    }
    
    Mortgage public mortgage;
    Property public property;
    
    SubTransaction public propertyInsurance = SubTransaction("Property Insurance", C_facts.Initial);
    SubTransaction public propertyOwnershipTransfer = SubTransaction("Property Ownership Transfer", C_facts.Initial);
    SubTransaction public propertyLeinRelease = SubTransaction("Property Lein Release", C_facts.Initial);
    MortgagePaingOff public mortgagePaingOff;
    
    address client;
    address insurer;
    address property_releaser;
    
    
    function MortgageCompletion() Transaction("Mortgage completion", "Mortgage is completed", 0x014723a09acff6d2a60dcdf7aa4aff308fddc160c,  msg.sender) {
        client = initiator;
        insurer = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
        property_releaser = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
        property = Property("1", 0xdd870fa1b7c4700f2bd7f44238821c26f7392148, 0x0, 1000000, false);
    }
    
    function promiseMortgageCompletion(uint amount, uint _annual_percentage_rate, uint _final_amount, uint _amount_of_payment) isRequested onlyExecutor {
        promise();
        mortgage.amount = amount;
        mortgage.annual_percentage_rate = _annual_percentage_rate;
        mortgage.final_amount = _final_amount;
        mortgage.amount_of_payment = _amount_of_payment;
        requestPropertyInsurance();
        requestPropertyOwnershipTransfer();
    }
    
    function declineMortgageCompletion() isRequested onlyExecutor {
        decline();
    }

    
    function requestPropertyInsurance() isPromised internal {
        require( property.insured == false);
        requestSub(propertyInsurance);
    }
    
    function statePropertyInsurance(string _property_id)  {
        require( propertyInsurance.current_c_fact == C_facts.Requested );
        require( msg.sender == insurer );
        require( keccak256(_property_id) == keccak256(property.id));
        property.insured = true;
        acceptSub(propertyInsurance);
    }
    
    function requestPropertyOwnershipTransfer() isPromised internal {
        require( property.owner != client );
        requestSub(propertyOwnershipTransfer);
    }
    
    function statePropertyOwnershipTransfer()  {
        require (msg.sender == client );
        stateSub(propertyOwnershipTransfer);
    }
    
    function acceptPropertyOwnershipTransfer() onlyExecutor {
        require( propertyOwnershipTransfer.current_c_fact == C_facts.Stated );
        property.owner = client;
        property.lien = this;
        acceptSub(propertyOwnershipTransfer);
    }
    
    function requestMortgagePaingOff() onlyExecutor returns (address) {
        require( propertyInsurance.current_c_fact == C_facts.Accepted);
        require( propertyOwnershipTransfer.current_c_fact == C_facts.Accepted );
        mortgagePaingOff = new MortgagePaingOff(this, mortgage.final_amount, mortgage.amount_of_payment);
        return address(mortgagePaingOff);
    }
    
    function acceptPropertyPaingOff() {
        require( mortgagePaingOff.current_c_fact() == C_facts.Stated );
        mortgagePaingOff.acceptPropertyPaingOff();
        requestPropertyLeinRelease();
    }
    
    
    function requestPropertyLeinRelease() internal {
        require( mortgagePaingOff.current_c_fact() == C_facts.Accepted );
        requestSub(propertyLeinRelease);
    }
    
    function statePropertyLeinRelease(string _property_id)  {
        require( propertyLeinRelease.current_c_fact == C_facts.Requested );
        require (msg.sender == property_releaser );
        require( keccak256(_property_id) == keccak256(property.id));
        property.lien = 0x0;
        acceptSub(propertyLeinRelease);
        state();
    }
    
    function acceptMortgageCompletion() onlyInitiator{
        accept();
    }
    
}

contract MortgagePaingOff is Transaction {
    
    uint public amount;
    uint public amount_of_payment;
    uint public amount_paid;
    MortgageCompletion mortgageCompletion;
    SubTransaction public mortgagePayment = SubTransaction("Mortgage Payment", C_facts.Initial);
    address public sender;
    
    address payOffAccount;
    uint pendingWithdrawal;
    
    
    function MortgagePaingOff(address _mortgage, uint _amount, uint _amount_of_payment) Transaction("Mortgage paing off", "Mortgage is paid off", msg.sender,  address(this)) {
        amount = _amount;
        amount_of_payment = _amount_of_payment;
        mortgageCompletion = MortgageCompletion(_mortgage);
        payOffAccount = 0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db;
        requestMortgagePayment();
    }
    
    function requestMortgagePayment() isRequested internal {
        require( amount_paid < amount);
        requestSub(mortgagePayment);
    }
    
    function stateMortgagePayment() payable {
        require( mortgagePayment.current_c_fact == C_facts.Requested );
        require( msg.value == amount_of_payment);
        acceptSub(mortgagePayment);
        amount_paid += msg.value;
        pendingWithdrawal += msg.value;
        
        if ( amount_paid == amount ) {
            state();
            mortgageCompletion.acceptPropertyPaingOff();
        } else {
            requestMortgagePayment();
        }
    }
    
    function acceptPropertyPaingOff() isStated onlyInitiator {
       require( amount_paid == amount);
       accept();
    }
    

    function withdraw() {
        require( msg.sender == payOffAccount );
        uint withdraw_amount = pendingWithdrawal;
        pendingWithdrawal = 0;
        msg.sender.transfer(withdraw_amount);
    }
    
}
    
    


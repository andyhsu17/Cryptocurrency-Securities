pragma solidity ^0.5.0;

contract RPS 
{
    bytes32 player1_commitment;
    bytes32 player2_commitment;
    string player1_choice;
    string player2_choice;
    address payable public player1address;
    address payable public player2address;
    uint public player1wager;
    uint public player2wager;
    uint public counter = 0;
    uint public winner;
    mapping(address => uint256) balance;

    enum State
    {
        START,
        P1_PLAYED,
        BOTH_PLAYED
    }
    State public state = State.START;
    /* returns commitment of pair of choice and blinding string */
    /* inputs - choice: string of choice between rock paper scissors
                rand: random blinding
        output - 32 byte commitment of pair of inputs*/
    function encode_commitment(string memory choice, string memory rand) 
    public pure returns (bytes32)
    {
        string memory newstr = string(abi.encodePacked(choice, rand));
        bytes32 commitment = sha256(bytes(newstr));
        return commitment;
    }
    
    
    /* Accepts a commitment (generated via encode_commitment)
   and a wager of ethereum
*/
    function play(bytes32 commitment) public payable 
    {
        require(state == State.START || state == State.P1_PLAYED);
        
        if(state == State.START)
        {
            player1_commitment = commitment;
            player1address = address(msg.sender);
            player1wager = msg.value;
            balance[msg.sender] += player1wager;
            state = State.P1_PLAYED;
        }
        else if(state == State.P1_PLAYED)
        {
            player2_commitment = commitment;
            player2address = address(msg.sender);
            player2wager = msg.value;
            balance[msg.sender] += player2wager;
            if(player2wager < player1wager)
            {
                revert("player2 must bet the same amount or more");
            }
            if(player2wager > player1wager)
            {
                uint refund = player2wager - player1wager;
                balance[msg.sender] -= refund;
                require(msg.sender.send(refund));
            }
            else
            {
                require(player1wager == player2wager, "player wagers must be the same");
            }
            state = State.BOTH_PLAYED;
        }
        
        
    }
    
    /* both players reveal their choice and blinding string. Verifies
    commitment is correct and after both players submit, determines the winner. */
    function reveal(string memory choice, string memory rand) public 
    {
        require(sha256(bytes(choice)) == sha256(bytes("rock")) || 
        sha256(bytes(choice)) == sha256(bytes("paper")) || 
        sha256(bytes(choice)) == sha256(bytes("scissors")));
        require(state == State.BOTH_PLAYED);
        if(player1_commitment == sha256(bytes(string(abi.encodePacked(choice, rand)))) && counter == 0)
        {

            player1_choice = choice;
            counter++;
        }
        else if(player2_commitment == sha256(bytes(string(abi.encodePacked(choice, rand)))) && counter == 1)
        {
            player2_choice = choice;
            counter++;
        }
        if(counter < 2) return;

        counter = 0;                // keeps track of how many players have revealed
        
        if(sha256(bytes(player1_choice)) == sha256(bytes("rock")))
        {
            if(sha256(bytes(player2_choice)) == sha256(bytes("scissors")))
            {
                winner = 1;
            }
            else if(sha256(bytes(player2_choice)) == sha256(bytes("paper")))
            {
                winner = 2;
            }
            else if(sha256(bytes(player2_choice)) == sha256(bytes("rock")))
            {
                winner = 0;             // winner 0 signifies a tie
            }
            else revert("input is not rock, paper, or scissors");

        }
        
        else if(sha256(bytes(player1_choice)) == sha256(bytes("paper")))
        {
            if(sha256(bytes(player2_choice)) == sha256(bytes("scissors")))
            {
                winner = 2;
            }
            else if(sha256(bytes(player2_choice)) == sha256(bytes("rock")))
            {
                winner = 1;
            }
            else if(sha256(bytes(player2_choice)) == sha256(bytes("paper")))
            {
                winner = 0;              // winner 0 signifies a tie
            }
            else revert("input is not rock, paper, or scissors");

        }
        else if(sha256(bytes(player1_choice)) == sha256(bytes("scissors")))
        {
            if(sha256(bytes(player2_choice)) == sha256(bytes("rock")))
            {
                winner = 2;
            }
            else if(sha256(bytes(player2_choice)) == sha256(bytes("paper")))
            {
                winner = 1;
            }
            else if(sha256(bytes(player2_choice)) == sha256(bytes("scissors")))
            {
                winner = 0;             // winner 0 signifies a tie
            }
            else revert("input is not rock, paper, or scissors");
        }
    }
    
    
    // fallback function accepts money, owner can withdraw
    function () external payable
    {
        revert();       // no fallback function
    }
    
    
    /* After both players reveal, this allows the winner
   to claim their reward (both wagers).
   In the event of a tie, this function should let
   each player withdraw their initial wager.
*/
    function withdraw() public
    {
        require(state == State.BOTH_PLAYED);
        balance[player1address] -= player1wager;
        balance[player2address] -= player2wager;
        if(winner == 0)
        {
            require(player1address.send(player1wager));
            require(player2address.send(player2wager));
            state = State.START;
        }
        else if(winner == 1)
        {
            require(player1address.send(address(this).balance));
            state = State.START;
        }
        else if(winner == 2)
        {
            require(player2address.send(address(this).balance));
            state = State.START;
        }
        else
        {
            revert(); // must not throw error
        }
        winner = 3;     // error case
    }
}
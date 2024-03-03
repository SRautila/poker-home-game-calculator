% calculates the least amount of payments to settle the debts based on buy_ins
% and standings for all Players with the constraint that the only type of
% transactions allowed are from losing players to winning players

%% Example:
% Players = { Alice, Bob, Carol, Dave, Eve };
% buy_ins = [4000, 4000, 2000, 2000, 2000];
% standings = [2063, 3612, 2323, 2879, 3123];
% net_amounts = [-1937, -388, 323, 879, 1123]
% Alice -> Dave 814
% Alice -> Eve 1123
% Bob -> Carol 323
% Bob -> Dave 65
%
% Expected output (or some variant of this):
% transactions =
% [|        Alice: Bob: Carol: Dave:  Eve:
% | Alice:     0,   0,     0,  814, 1123
% |   Bob:     0,   0,   323,   65,    0
% | Carol:     0,   0,     0,    0,    0
% |  Dave:     0,   0,     0,    0,    0
% |   Eve:     0,   0,     0,    0,    0
% |];


%% INPUT DATA (parameters)
enum Players;
array[Players] of int: buy_ins;
array[Players] of int: standings;


%% Pre-processing
int: n = card(Players);

% Calculate net amounts for each player
array[Players] of int: net_amounts = [standings[p] - buy_ins[p] | p in Players];

% Max transaction is what the player who lost the most has to pay
int: max_transaction = abs(min(net_amounts));


%% Decision variable
% 2d array from player -> to player
array[Players, Players] of var 0..max_transaction: transactions;


%% Constraints
% Ensuring the total buy_ins equals total standings
constraint sum(buy_ins) = sum(standings);

% Balance constraints for each player (sum of transactions adds to net_amount)
constraint forall(p in Players) (
    sum(q in Players) (transactions[q, p]) - sum(q in Players) (transactions[p, q]) = net_amounts[p]
);


% No transactions to self (not needed but reduced search space)
constraint forall(p in Players) (
    transactions[p, p] = 0
);

% Transactions only from losing players to winning players
constraint forall(p, q in Players) (
    (net_amounts[p] >= 0) -> transactions[p, q] = 0
);

% Must pay exactly what one has lost
constraint forall(p in Players) (
    if net_amounts[p] < 0 then
        sum(q in Players) (transactions[p, q]) = -net_amounts[p]
    else
        true % No constraint needed for winning players
    endif
);


%% Objective: Minimize the total transaction count
var int: num_zero_transactions;
constraint num_zero_transactions = sum(p, q in Players) (if transactions[p, q] = 0 then 1 else 0 endif);
solve maximize num_zero_transactions;


%% Output
output ["Transactions:\n"] ++
       [ "Transaction from " ++ show(p) ++ " to " ++ show(q) ++ ": " ++ show(transactions[p, q]) ++ "\n"
         | p, q in Players where fix(transactions[p, q] > 0) ];

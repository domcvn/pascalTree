unit TreeGenerator;

interface

uses TreeTypes;

function initialiseTree(seed: Integer; targetTime: Integer);
procedure addPoint(var tree: TTree; pointX, pointY: Integer; character: Char; state: TState);
function getTreeSize(tree: TTree): Integer;
function isTreeComplete(tree: TTree): Boolean;
procedure growTree(var tree: TTree; elapsedTime: Integer);
procedure clearTree(var tree: Tree);

implementation
const 
    GROWTH_INTERVAL = 5;
    INITIAL_LIFE = 10;
    MIN_BRANCH_LIFE = 4;
    MAX_BRANCH_LIFE = 9;
    BRANCH_PROBABILITY = 35;
    LEAF_PROBABLITY = 70;
    MAX_BRANCHES = 1000;
    MAX_POINTS = 10000;

procedure generateRandomState(var tree: TTree);
begin 
    tree.randomState := tree.randomState * 1664525 + 1013904223;
end;

function getRandomState(tree: TTree): Cardinal;
begin 
    getRandomState := tree.randomState;
end;

function initialiseTree(seed: Integer; targetTime: Integer): TTree;
var     
    tree: TTree;
begin 
    tree.seed := seed;
    tree.targetTime := targetTime;
    tree.growthTime := 0;
    setLength(tree.points, 0);
    setLength(tree.branches, 0);

    initialiseTree := tree;
end;

procedure addPoint(var tree: TTree; coord: TCoord; character: Char; state: TState);
var 
    idx : Integer;
begin 
    idx := length(tree.points);
    setLength(tree.points, idx + 1);
    tree.points[idx].coord.x := pointX;
    tree.points[idx].coord.y := pointY;
    tree.points[idx].character := character;
    tree.points[idx].state := state;
end;

procedure addBranch(var tree: TTree; coord: TCoord; state: TState; life: Integer);
var 
    idx: Integer;
begin 
    if length(tree.branches) >= maxBranches then 
        Exit;
    
    idx := length(tree.branches);
    setLength(tree.branches, idx + 1);
    tree.branches[idx].coord.x := branchX;
    tree.branches[idx].coord.y := branchY;
    tree.branches[idx].state := state;
    tree.branches[idx].remainingLife := life;
    tree.branches[idx].age := 0;
end;

procedure removeBranch(var tree: TTree; idx: Integer);
var 
    lastIdx: Integer;
begin 
    lastIdx := length(tree.branches) - 1;
    if (idx < 0) or (idx > lastIdx) then
        Exit;
    
    if (idx <> lastIdx) then 
        tree.branches[idx] := tree.branches[lastIdx];
    
    setLength(tree.branches, lastIdx);
end;

procedure createChildBranches(var tree: TTree; branch: TBranch);
var 
    randVal: Cardinal;
    newLife: Integer;
    coord: TCoord;
begin 
    if length(tree.branches) >= maxBranches then 
        Exit;
    
    generateRandomState(tree);
    if (tree.randomState mod 100) >= BRANCH_PROBABILITY then 
        Exit;
    
    newLife := MIN_BRANCH_LIFE + Integer(tree.randomState mod Cardinal(MAX_BRANCH_LIFE - MIN_BRANCH_LIFE + 1));

    if branch.state = trunk then 
    begin 
        generateRandomState(tree);
        if (tree.randomState mod 100) < 50 then 
            addBranch(tree, branch.coord, Left, newLife)
        else 
            addBranch(tree, branch.coord, Right, newLife);
    end

    else if branch.state = Left then 
    begin 
        coord.x := branch.coord.x - 1;
        coord.y := branch.coord.y - 1;

        addBranch(tree, coord, Left, newLife);

        if (length(tree.branches) < MAX_BRANCHES) then 
        begin 
            generateRandomState(tree);
            
        end;
    end

end;

function getTreeSize(tree: TTree): Integer;
begin 
    getTreeSize := length(tree.points);
end;

function isTreeComplete(tree: TTree): Boolean;
begin 
    isTreeComplete := tree.growthTime >= tree.targetTime;
end;

procedure growTree(var tree: TTree; elapsedTime: Integer);
var 
    growthStep: Integer;
begin 
    if elapsedTime <= tree.growthTime then 
        Exit;
    
    if elapsedTime > tree.targetTime then 
        elapsedTime := tree.targetTime;

    growthStep := elapsedTime - tree.growthTime;
end;

procedure clearTree(var tree: TTree);
begin 
    setLength(tree.points, 0);
    setLength(tree.branches, 0);
end;

end.
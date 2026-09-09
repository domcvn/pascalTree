{ This unit defines the data structures used to represent a tree. }
unit TreeTypes;

interface
type
    { Represents the different states that a point or branch can have during the growth of a tree. }
    TState = (Trunk, //< Main trunk of the tree 
            Left, //< Branch growing to the left
            Right, //< Branch growing to the right
            Dying, //< Branch or point at the end of its growth
            Dead //< Dead branch or point
            );

    { Represents a two-dimensional coordinate. }
    TCoord = record 
        x: LongInt; //< Horizontal coordinate
        y: LongInt; //< Vertical coordinate
    end;

    { Represents a single graphical element of a tree. }
    TPoint = record 
        coord: TCoord; //< Position of a point
        character: Char; //< Determines how it is displayed
        state: TState; //< State of the point
    end;

    { Represents an active branch of a tree. }
    TBranch = record 
        coord: TCoord; //< Current position of the branch
        remainingLife: LongInt; //< Number of growth steps remaining
        age: LongInt; //< Number of growth steps already completed
        shootCooldown: LongInt; //< Number of growth steps before another shoot can be created
        state: TState; //< State of the branch
    end;

    { Represents the complete state of a tree. }
    TTree = record 
        seed: Cardinal; //< Initial value used by the random generator
        randomState: Cardinal; //< Current state of the random generator
        targetTime: LongInt; //< Selected duration, in seconds
        growthTime: LongInt; //< The time already converted into growth, in seconds
        shootCounter: LongInt; //< Number of shoots created by the tree
        points: Array of TPoint; //< All graphical points already generated
        branches: Array of TBranch; //< Branches that are still growing
    end;


{ Creates and returns a coordinate initialised with the given x and y values. }
function initialiseCoord(x, y: LongInt): TCoord;

{ Creates and returns a point initialised with the given coordinate, character, and state. }
function initialisePoint(coord: TCoord; character: Char; state: TState): TPoint;

{ Returns the point stored at the index @bold(idx) in tree. 

If @bold(idx) is outside the valid range of the @bold(points) array, an empty point with a blank character and Dead state is returned.}
function getPoint(tree: TTree; idx: LongInt): TPoint;

{ Sets the point at index @bold(idx).

If @bold(idx) refers to an existing point, that point is replaced.
If @bold(idx) is equal to the current number of points, the point is appended to the array.
If neither, the tree is not modified.}
procedure setPoint(var tree: TTree; idx: LongInt; point: TPoint);

{ Returns the number of points currently stored in tree. }
function getPointCount(tree: TTree): LongInt;

{ Creates and returns a branch initialised with a given coordinate, remaining life, and state.

The age and shoot cooldown of a newly initialised branch is set to 0.}
function initialiseBranch(coord: TCoord; remainingLife: LongInt; state: TState): TBranch;

{ Returns the branch stored at index @bold(idx) in tree.

If @bold(idx) is outside the valid range of the branches array, an empty branch with 0 remaining life, 0 age, 0 shoot cooldown, and Dead state is returned.}
function getBranch(tree: TTree; idx: LongInt): TBranch;

{ Sets the branch at index @bold(idx).

If @bold(idx) refers to an existing branch, that branch is replaced.
If @bold(idx) is equal to the current number of branches, the branch is appended to the array.
If neither, the tree is not modified.}
procedure setBranch(var tree: TTree; idx: LongInt; branch: TBranch);

{ Removes the branch at index @bold(idx).

If @bold(idx) is invalid, the tree is not modified.}
procedure removeBranch(var tree: TTree; idx: LongInt);

{ Returns the number of branches currently stored in tree. }
function getBranchCount(tree: TTree): LongInt;

{ Creates and returns a new tree.

The tree is initialised with the specified seed and target duration. Its growth time is set to 0 and its points and branches arrays are initialised as empty arrays. 

If @bold(seed) is 0, @bold(randomState) is initialised to 1.
If @bold(targetTime) is negative, it is initialised to 0.}
function initialiseTree(seed: Cardinal; targetTime: LongInt): TTree;

{ Returns the initial random seed of tree. }
function getSeed(tree: TTree): Cardinal;

{ Sets the initial random seed of tree. }
procedure setSeed(var tree: TTree; seed: Cardinal);

{ Returns the current state of the pseudo-random generator associated with tree. }
function getRandomState(tree: TTree): Cardinal;

{ Sets the current state of the pseudo-random generator associated with tree. 

If @bold(randomState) is 0, it is set to 1.}
procedure setRandomState(var tree: TTree; randomState: Cardinal);

{ Returns the target duration of tree, in seconds. }
function getTargetTime(tree: TTree): LongInt;

{ Sets the target duration of tree. 

If @bold(targetTime) is negative, it is set to 0.}
procedure setTargetTime(var tree: TTree; targetTime: LongInt);

{ Returns the amount of focus time already converted into tree growth, in seconds. }
function getGrowthTime(tree: TTree): LongInt;

{ Sets the amount of time already converted into tree growth. }
procedure setGrowthTime(var tree: TTree; growthTime: LongInt);

{ Returns the current number of shoots created by the tree. }
function getShootCounter(tree: TTree): LongInt;

{ Sets the current number of shoots created by the tree. }
procedure setShootCounter(var tree: TTree; shootCounter: LongInt);

{ Clears all points and active branches of tree and resets its stored seed, random state, target time, growth time, and shoot counter. }
procedure clearTree(var tree: TTree);

implementation

function initialiseCoord(x, y: LongInt): TCoord;
begin 
    initialiseCoord.x := x;
    initialiseCoord.y := y;
end; 


function initialisePoint(coord: TCoord; character: Char; state: TState): TPoint;
begin 
    initialisePoint.coord := coord;
    initialisePoint.character := character;
    initialisePoint.state := state;
end;


function getPoint(tree: TTree; idx: LongInt): TPoint;
begin 
    if (idx >= 0) and (idx < Length(tree.points)) then 
        getPoint := tree.points[idx]
    else 
        getPoint := initialisePoint(initialiseCoord(0,0), ' ', Dead);
end;


procedure setPoint(var tree: TTree; idx: LongInt; point: TPoint);
var 
    pointCount: LongInt;
begin 
    pointCount := length(tree.points);
    if (idx < 0) or (idx > pointCount) then 
        Exit;
    
    if idx = pointCount then 
        setLength(tree.points, pointCount + 1);

    tree.points[idx] := point;
end;


function getPointCount(tree: TTree): LongInt;
begin 
    getPointCount := length(tree.points);
end;


function initialiseBranch(coord: TCoord; remainingLife: LongInt; state: TState): TBranch;
begin 
    initialiseBranch.coord := coord; 
    initialiseBranch.remainingLife := remainingLife;
    initialiseBranch.age := 0;
    initialiseBranch.shootCooldown := 0;
    initialiseBranch.state := state;
end;


function getBranch(tree: TTree; idx: LongInt): TBranch;
begin 
    if (idx >= 0) and (idx < Length(tree.branches)) then 
        getBranch := tree.branches[idx]
    else 
        getBranch := initialiseBranch(initialiseCoord(0, 0), 0, Dead);
end;


procedure setBranch(var tree: TTree; idx: LongInt; branch: TBranch);
var 
    branchCount: LongInt;
begin 
    branchCount := length(tree.branches);

    if (idx < 0) or (idx > branchCount) then 
        Exit; 
    
    if idx = branchCount then 
        setLength(tree.branches, branchCount + 1);
    
    tree.branches[idx] := branch;
end;


procedure removeBranch(var tree: TTree; idx: LongInt);
var 
    lastIdx: LongInt;
begin 
    lastIdx := Length(tree.branches) - 1;

    if (idx < 0) or (idx > lastIdx) then 
        Exit;
    
    if idx <> lastIdx then 
        tree.branches[idx] := tree.branches[lastIdx];
    
    setLength(tree.branches, lastIdx);
end;


function getBranchCount(tree: TTree): LongInt;
begin 
    getBranchCount := length(tree.branches);
end;

function initialiseTree(seed: Cardinal; targetTime: LongInt): TTree;
begin 
    initialiseTree.seed := seed;

    if seed = 0 then 
        initialiseTree.randomState := 1
    else 
        initialiseTree.randomState := seed;
    
    if targetTime < 0 then 
        initialiseTree.targetTime := 0
    else 
        initialiseTree.targetTime := targetTime;

    initialiseTree.growthTime := 0;
    initialiseTree.shootCounter := 0;

    setLength(initialiseTree.points, 0);
    setLength(initialiseTree.branches, 0);
end;


function getSeed(tree: TTree): Cardinal;
begin 
    getSeed := tree.seed;
end;


procedure setSeed(var tree: TTree; seed: Cardinal);
begin 
    tree.seed := seed;
end;


function getRandomState(tree: TTree): Cardinal;
begin 
    getRandomState := tree.randomState;
end;


procedure setRandomState(var tree: TTree; randomState: Cardinal);
begin 
    if randomState = 0 then 
        tree.randomState := 1
    else 
        tree.randomState := randomState;
end;


function getTargetTime(tree: TTree): LongInt;
begin 
    getTargetTime := tree.targetTime;
end;


procedure setTargetTime(var tree: TTree; targetTime: LongInt);
begin 
    if targetTime < 0 then 
        tree.targetTime := 0 
    else 
        tree.targetTime := targetTime;
end;


function getGrowthTime(tree: TTree): LongInt;
begin 
    getGrowthTime := tree.growthTime;
end;


procedure setGrowthTime(var tree: TTree; growthTime: LongInt);
begin 
    if growthTime < 0 then 
        tree.growthTime := 0
    else 
        tree.growthTime := growthTime;
end;

function getShootCounter(tree: TTree): LongInt;
begin 
    getShootCounter := tree.shootCounter;
end;

procedure setShootCounter(var tree: TTree; shootCounter: LongInt);
begin 
    tree.shootCounter := shootCounter;
end;

procedure clearTree(var tree: TTree);
begin 
    setLength(tree.points, 0);
    setLength(tree.branches, 0);

    tree.seed := 0;
    tree.randomState := 1;
    tree.targetTime := 0;
    tree.growthTime := 0;
    tree.shootCounter := 0;
end;

end.
{ This unit implements the algorithm used to generate and grow a tree. }
unit TreeGenerator;

interface

uses 
    TreeTypes;

{ Advances the growth of @bold(tree) according to the elapsed time.

Growth is performed in discrete time steps until the elapsed time is reached or the target duration of the tree is exceeded. }
procedure growTree(var tree: TTree; elapsedTime: LongInt);

implementation
const 
    GROWTH_INTERVAL = 5;
    INITIAL_LIFE = 32;
    MULTIPLIER = 5;
    MAX_BRANCHES = 1000;
    MAX_POINTS = 10000;
    MAX_INT = $7FFFFFFF;

function generateRandomRoll(var tree: TTree; maximum: Cardinal): LongInt;
var 
    randomState: Cardinal;
begin 
    randomState := getRandomState(tree);
    randomState := randomState * 1664525 + 1013904223;
    setRandomState(tree, randomState);
    generateRandomRoll := LongInt(randomState mod maximum);
end;

procedure createPoint(var tree: TTree; coord: TCoord; character: Char; state: TState);
var 
    point: TPoint;
begin 
    if getPointCount(tree) >= MAX_POINTS then 
        Exit;
    point := initialisePoint(coord, character, state);
    setPoint(tree, getPointCount(tree), point);
end;

procedure createBranch(var tree: TTree; coord: TCoord; state: TState; remainingLife: LongInt);
var 
    branch: TBranch;
begin 
    if getBranchCount(tree) >= MAX_BRANCHES then 
        Exit;
    branch := initialiseBranch(coord, remainingLife, state);
    setShootCooldown(branch, MULTIPLIER);
    setBranch(tree, getBranchCount(tree), branch);
end;

procedure initialiseGrowth(var tree: TTree);
var 
    coord: TCoord;
begin 
    coord := initialiseCoord(0, 0);
    setShootCounter(tree, generateRandomRoll(tree, MAX_INT));
    createBranch(tree, coord, Trunk, INITIAL_LIFE);
end;

procedure calculateDeltas(var tree: TTree; branch: TBranch; var dx, dy: LongInt);
var 
    dice: LongInt;
begin 
    dx := 0;
    dy := 0;

    if branch.state = Trunk then 
    begin 
        if (branch.age <= 2) or (branch.remainingLife < 4) then 
        begin 
            dy := 0;
            dx := generateRandomRoll(tree, 3) - 1;
        end
        else if branch.age < MULTIPLIER * 3 then 
        begin 
            if ((MULTIPLIER div 2) <> 0) and (branch.age mod (MULTIPLIER div 2) = 0) then 
                dy := -1
            else 
                dy := 0;
            dice := generateRandomRoll(tree, 10);
            if dice = 0 then 
                dx := -2
            else if dice <= 3 then 
                dx := -1
            else if dice <= 5 then 
                dx := 0 
            else if dice <= 8 then 
                dx := 1
            else 
                dx := 2;
        end
        else 
        begin 
            dice := generateRandomRoll(tree, 10);
            if dice > 2 then 
                dy := -1
            else
                dy := 0;
            dx := generateRandomRoll(tree, 3) - 1;
        end;
    end
    else if branch.state = Left then 
    begin 
        dice := generateRandomRoll(tree, 10);
        if dice <= 1 then 
            dy := -1
        else if dice <= 7 then 
            dy := 0
        else 
            dy := 1;
        dice := generateRandomRoll(tree, 10);
        if dice <= 1 then 
            dx := -2
        else if dice <= 5 then 
            dx := -1
        else if dice <= 8 then 
            dx := 0
        else 
            dx := 1;
    end
    else if branch.state = Right then 
    begin 
        dice := generateRandomRoll(tree, 10);
        if dice <= 1 then 
            dy := -1
        else if dice <= 7 then 
            dy := 0
        else 
            dy := 1;
        dice := generateRandomRoll(tree, 10);
        if dice <= 1 then 
            dx := 2
        else if dice <= 5 then 
            dx := 1
        else if dice <= 8 then 
            dx := 0
        else 
            dx := -1;
    end
    else if branch.state = Dying then 
    begin 
        dice := generateRandomRoll(tree, 10);
        if dice <= 1 then 
            dy := -1
        else if dice <= 8 then 
            dy := 0
        else 
            dy := 1;
        dice := generateRandomRoll(tree, 15);
        if dice = 0 then 
            dx := -3 
        else if dice <= 2 then 
            dx := -2 
        else if dice <= 5 then 
            dx := -1 
        else if dice <= 8 then 
            dx := 0 
        else if dice <= 11 then 
            dx := 1
        else if dice <= 13 then 
            dx := 2 
        else 
            dx := 3;
    end
    else 
    begin 
        dice := generateRandomRoll(tree, 10);
        if dice <= 2 then 
            dy := -1
        else if dice <= 6 then 
            dy := 0 
        else 
            dy := 1;
        dx := generateRandomRoll(tree, 3) - 1;
    end;
end;

function chooseCharacter(state: TState; remainingLife: LongInt; dx, dy: LongInt): Char;
begin 
    if remainingLife < 4 then 
        state := Dying;
    
    if state = Trunk then 
    begin 
        if dy = 0 then 
            chooseCharacter := '~'
        else if dx < 0 then 
            chooseCharacter := '\'
        else if dx = 0 then 
            chooseCharacter := '|'
        else 
            chooseCharacter := '/';
    end
    else if state = Left then 
    begin 
        if dy > 0 then 
            chooseCharacter := '\'
        else if dy = 0 then 
            chooseCharacter := '_'
        else if dx < 0 then 
            chooseCharacter := '\'
        else if dx = 0 then 
            chooseCharacter := '|'
        else 
            chooseCharacter := '/';
    end 
    else if state = Right then 
    begin 
        if dy > 0 then 
            chooseCharacter := '/'
        else if dy = 0 then 
            chooseCharacter := '_'
        else if dx < 0 then 
            chooseCharacter := '\'
        else if dx = 0 then 
            chooseCharacter := '|'
        else 
            chooseCharacter := '/';
    end 
    else if state = Dying then 
        chooseCharacter := '*'
    else 
        chooseCharacter := '.'
end;

procedure createTrunkContinuation(var tree: TTree; branch: TBranch);
var    
    newLife: LongInt;
begin 
    newLife := branch.remainingLife + generateRandomRoll(tree, 5) - 2;
    createBranch(tree, branch.coord, Trunk, newLife);
end;

procedure createShoot(var tree: TTree; branch: TBranch);
var
    shootLife: LongInt;
    shootState: TState;
begin 
    shootLife := branch.remainingLife + MULTIPLIER;
    setShootCounter(tree, getShootCounter(tree) + 1);
    if (getShootCounter(tree) mod 2 = 0) then 
        shootState := Left
    else 
        shootState := Right;
    createBranch(tree, branch.coord, shootState, shootLife);
end;

procedure processBranching(var tree: TTree; var branch: TBranch);
var 
    dice: LongInt;
begin 
    if branch.remainingLife < 3 then 
        createBranch(tree, branch.coord, Dead, branch.remainingLife)
    else if (branch.state = Trunk) and (branch.remainingLife < MULTIPLIER + 2) then 
        createBranch(tree, branch.coord, Dying, branch.remainingLife)
    else if ((branch.state = Left) or (branch.state = Right)) and (branch.remainingLife < MULTIPLIER + 2) then 
        createBranch(tree, branch.coord, Dying, branch.remainingLife)
    else if branch.state = Trunk then 
    begin 
        dice := generateRandomRoll(tree, 3);
        if (dice = 0) or ((MULTIPLIER <> 0) and ((branch.remainingLife mod MULTIPLIER) = 0)) then 
        begin
            dice := generateRandomRoll(tree, 8);

            if (dice = 0) and (branch.remainingLife > 7) then 
            begin 
                createTrunkContinuation(tree, branch);
                setShootCooldown(branch, MULTIPLIER * 2);
            end 
            else if getShootCooldown(branch) <= 0 then 
            begin 
                createShoot(tree, branch);
                setShootCooldown(branch, MULTIPLIER * 2);
            end;
        end;
    end;
end;

procedure processBranchStep(var tree: TTree; idx: LongInt);
var 
    branch: TBranch;
    dx, dy: LongInt;
    character: Char;
    newCoord: TCoord;
begin 
    if (idx < 0) or (idx >= getBranchCount(tree)) then 
        Exit;

    branch := getBranch(tree, idx);
    branch.remainingLife := branch.remainingLife - 1;
    branch.age := INITIAL_LIFE - branch.remainingLife;

    calculateDeltas(tree, branch, dx, dy);
    processBranching(tree, branch);
    branch.shootCooldown := branch.shootCooldown - 1;

    newCoord.x := branch.coord.x + dx;
    newCoord.y := branch.coord.y + dy;

    character := chooseCharacter(branch.state, branch.remainingLife, dx, dy);
    createPoint(tree, newCoord, character, branch.state);

    branch.coord := newCoord;
    if branch.remainingLife > 0 then 
        setBranch(tree, idx, branch)
    else 
        removeBranch(tree, idx);
end;

procedure growTree(var tree: TTree; elapsedTime: LongInt);
var 
    targetGrowthTime: LongInt;
    previousStep: LongInt;
    currentStep: LongInt;
begin 
    if elapsedTime <= getGrowthTime(tree) then 
        Exit;

    targetGrowthTime := elapsedTime;
    if targetGrowthTime > getTargetTime(tree) then 
        targetGrowthTime := getTargetTime(tree);
    if targetGrowthTime <= getGrowthTime(tree) then 
        Exit;
    if getPointCount(tree) = 0 then 
        initialiseGrowth(tree);
    
    previousStep := getGrowthTime(tree) div GROWTH_INTERVAL;
    currentStep := targetGrowthTime div GROWTH_INTERVAL;

    while previousStep < currentStep do
    begin 
        if getBranchCount(tree) = 0 then 
            Break;
        processBranchStep(tree, getBranchCount(tree) - 1);
        previousStep := previousStep + 1;
    end;

    setGrowthTime(tree, targetGrowthTime);
end;

end.
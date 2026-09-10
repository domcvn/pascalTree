program MainDebug;

uses
    CRT,
    SysUtils,
    TreeTypes,
    TreeGenerator,
    TreeDisplay;

const
    MAX_INT = $7FFFFFFF;

    { Fixed seed used only to test determinism. }
    DETERMINISTIC_SEED = 12345;

    { General test values. }
    TEST_TARGET_TIME = 160;
    FULL_TARGET_TIME = 5000;

    { Tree display area. }
    DISPLAY_X_MIN = 2;
    DISPLAY_X_MAX = 60;
    DISPLAY_Y_MIN = 2;
    DISPLAY_Y_MAX = 31;

var
    randomSeed: Cardinal;

procedure clearScreen;
begin
    ClrScr;
    TextColor(White);
end;

procedure printAt(
    x, y: LongInt;
    const text: String
);
begin
    if (x < 1) or (y < 1) then
        Exit;

    GotoXY(x, y);
    Write(text);
end;

procedure pauseScreen;
begin
    printAt(1, 35, 'Press any key to continue...');
    ReadKey;
end;

procedure printTitle(
    const title: String
);
begin
    clearScreen;

    printAt(
        1,
        1,
        '=================================================='
    );

    printAt(
        1,
        2,
        title
    );

    printAt(
        1,
        3,
        '=================================================='
    );
end;

procedure printPass(
    const message: String;
    y: LongInt
);
begin
    printAt(
        1,
        y,
        '[PASS] ' + message
    );
end;

procedure printFail(
    const message: String;
    y: LongInt
);
begin
    printAt(
        1,
        y,
        '[FAIL] ' + message
    );
end;

procedure initialiseRandomSeed;
begin
    Randomize;

    randomSeed :=
        Cardinal(Random(MAX_INT - 1)) + 1;
end;

procedure printTreeInfo(
    tree: TTree;
    startY: LongInt
);
begin
    printAt(
        1,
        startY,
        'Seed:          ' +
        IntToStr(getSeed(tree))
    );

    printAt(
        1,
        startY + 1,
        'Random state:  ' +
        IntToStr(getRandomState(tree))
    );

    printAt(
        1,
        startY + 2,
        'Target time:   ' +
        IntToStr(getTargetTime(tree))
    );

    printAt(
        1,
        startY + 3,
        'Growth time:   ' +
        IntToStr(getGrowthTime(tree))
    );

    printAt(
        1,
        startY + 4,
        'Shoot counter: ' +
        IntToStr(getShootCounter(tree))
    );

    printAt(
        1,
        startY + 5,
        'Point count:   ' +
        IntToStr(getPointCount(tree))
    );

    printAt(
        1,
        startY + 6,
        'Branch count:  ' +
        IntToStr(getBranchCount(tree))
    );
end;

procedure testTreeInitialisation;
var
    tree: TTree;
begin
    printTitle(
        'TEST 1 - Tree initialisation'
    );

    tree := initialiseTree(
        randomSeed,
        TEST_TARGET_TIME
    );

    printTreeInfo(tree, 5);

    if getSeed(tree) = randomSeed then
        printPass(
            'Seed initialized correctly.',
            14
        )
    else
        printFail(
            'Seed is incorrect.',
            14
        );

    if getTargetTime(tree) = TEST_TARGET_TIME then
        printPass(
            'Target time initialized correctly.',
            15
        )
    else
        printFail(
            'Target time is incorrect.',
            15
        );

    if getGrowthTime(tree) = 0 then
        printPass(
            'Initial growth time is zero.',
            16
        )
    else
        printFail(
            'Initial growth time is not zero.',
            16
        );

    if getPointCount(tree) = 0 then
        printPass(
            'Initial point array is empty.',
            17
        )
    else
        printFail(
            'Initial point array is not empty.',
            17
        );

    if getBranchCount(tree) = 0 then
        printPass(
            'Initial branch array is empty.',
            18
        )
    else
        printFail(
            'Initial branch array is not empty.',
            18
        );

    pauseScreen;
end;

procedure testTreeAccessors;
var
    tree: TTree;
    coord: TCoord;
    point: TPoint;
    branch: TBranch;
    retrievedPoint: TPoint;
    retrievedBranch: TBranch;
begin
    printTitle(
        'TEST 2 - Tree accessors and collections'
    );

    tree := initialiseTree(
        randomSeed,
        100
    );

    { Coordinate test. }

    coord := initialiseCoord(
        10,
        20
    );

    if (coord.x = 10)
        and (coord.y = 20) then
        printPass(
            'Coordinate initialization.',
            5
        )
    else
        printFail(
            'Coordinate initialization.',
            5
        );

    { Point test. }

    point := initialisePoint(
        coord,
        '*',
        Dying
    );

    setPoint(
        tree,
        0,
        point
    );

    if getPointCount(tree) = 1 then
        printPass(
            'Point insertion.',
            6
        )
    else
        printFail(
            'Point insertion.',
            6
        );

    retrievedPoint := getPoint(
        tree,
        0
    );

    if (retrievedPoint.coord.x = 10)
        and (retrievedPoint.coord.y = 20)
        and (retrievedPoint.character = '*')
        and (retrievedPoint.state = Dying) then
        printPass(
            'Point retrieval.',
            7
        )
    else
        printFail(
            'Point retrieval.',
            7
        );

    { Branch test. }

    branch := initialiseBranch(
        coord,
        20,
        Trunk
    );

    setBranch(
        tree,
        0,
        branch
    );

    if getBranchCount(tree) = 1 then
        printPass(
            'Branch insertion.',
            8
        )
    else
        printFail(
            'Branch insertion.',
            8
        );

    retrievedBranch := getBranch(
        tree,
        0
    );

    if (retrievedBranch.coord.x = 10)
        and (retrievedBranch.coord.y = 20)
        and (retrievedBranch.remainingLife = 20)
        and (retrievedBranch.state = Trunk) then
        printPass(
            'Branch retrieval.',
            9
        )
    else
        printFail(
            'Branch retrieval.',
            9
        );

    { Tree-level property tests. }

    setSeed(
        tree,
        999
    );

    setRandomState(
        tree,
        777
    );

    setTargetTime(
        tree,
        500
    );

    setGrowthTime(
        tree,
        100
    );

    setShootCounter(
        tree,
        42
    );

    if getSeed(tree) = 999 then
        printPass(
            'Seed setter/getter.',
            11
        )
    else
        printFail(
            'Seed setter/getter.',
            11
        );

    if getRandomState(tree) = 777 then
        printPass(
            'Random-state setter/getter.',
            12
        )
    else
        printFail(
            'Random-state setter/getter.',
            12
        );

    if getTargetTime(tree) = 500 then
        printPass(
            'Target-time setter/getter.',
            13
        )
    else
        printFail(
            'Target-time setter/getter.',
            13
        );

    if getGrowthTime(tree) = 100 then
        printPass(
            'Growth-time setter/getter.',
            14
        )
    else
        printFail(
            'Growth-time setter/getter.',
            14
        );

    if getShootCounter(tree) = 42 then
        printPass(
            'Shoot-counter setter/getter.',
            15
        )
    else
        printFail(
            'Shoot-counter setter/getter.',
            15
        );

    removeBranch(
        tree,
        0
    );

    if getBranchCount(tree) = 0 then
        printPass(
            'Branch removal.',
            17
        )
    else
        printFail(
            'Branch removal.',
            17
        );

    clearTree(tree);

    if (getPointCount(tree) = 0)
        and (getBranchCount(tree) = 0)
        and (getGrowthTime(tree) = 0) then
        printPass(
            'Tree clearing.',
            19
        )
    else
        printFail(
            'Tree clearing.',
            19
        );

    pauseScreen;
end;

procedure testIncrementalGrowth;
var
    tree: TTree;
    elapsedTime: LongInt;
    previousPoints: LongInt;
    currentPoints: LongInt;
    row: LongInt;
begin
    printTitle(
        'TEST 3 - Incremental growth'
    );

    tree := initialiseTree(
        randomSeed,
        TEST_TARGET_TIME
    );

    printAt(
        1,
        5,
        'Random seed: ' +
        IntToStr(randomSeed)
    );

    printAt(
        1,
        7,
        'Time    Growth    Points    Branches'
    );

    elapsedTime := 0;
    previousPoints := 0;
    row := 8;

    while elapsedTime < TEST_TARGET_TIME do
    begin
        elapsedTime := elapsedTime + 5;

        growTree(
            tree,
            elapsedTime
        );

        currentPoints := getPointCount(tree);

        if row <= 23 then
        begin
            printAt(
                1,
                row,
                IntToStr(elapsedTime) +
                '       ' +
                IntToStr(getGrowthTime(tree)) +
                '         ' +
                IntToStr(currentPoints) +
                '         ' +
                IntToStr(getBranchCount(tree))
            );

            Inc(row);
        end;

        if currentPoints < previousPoints then
            printAt(
                1,
                25,
                'WARNING: point count decreased.'
            );

        previousPoints := currentPoints;
    end;

    printAt(
        1,
        25,
        'Final state:'
    );

    if getGrowthTime(tree) = TEST_TARGET_TIME then
        printPass(
            'Growth reached target time.',
            26
        )
    else
        printFail(
            'Growth did not reach target time.',
            26
        );

    if getPointCount(tree) > 0 then
        printPass(
            'Growth generated points.',
            27
        )
    else
        printFail(
            'No points were generated.',
            27
        );

    pauseScreen;
end;

procedure testTimeLimit;
var
    tree: TTree;
begin
    printTitle(
        'TEST 4 - Target-time protection'
    );

    tree := initialiseTree(
        randomSeed,
        100
    );

    growTree(
        tree,
        50
    );

    if getGrowthTime(tree) = 50 then
        printPass(
            'Growth reached elapsed time 50.',
            5
        )
    else
        printFail(
            'Incorrect growth time after first call.',
            5
        );

    growTree(
        tree,
        200
    );

    if getGrowthTime(tree) = 100 then
        printPass(
            'Growth capped at target time 100.',
            6
        )
    else
        printFail(
            'Growth exceeded target time.',
            6
        );

    growTree(
        tree,
        200
    );

    if getGrowthTime(tree) = 100 then
        printPass(
            'Repeated call after target does nothing.',
            7
        )
    else
        printFail(
            'Repeated call changed growth after target.',
            7
        );

    pauseScreen;
end;

procedure testFullGeneration;
var
    tree: TTree;
begin
    printTitle(
        'TEST 5 - Full tree generation'
    );

    tree := initialiseTree(
        randomSeed,
        FULL_TARGET_TIME
    );

    printAt(
        1,
        5,
        'Random seed: ' +
        IntToStr(randomSeed)
    );

    printAt(
        1,
        7,
        'Generating tree...'
    );

    growTree(
        tree,
        FULL_TARGET_TIME
    );

    printTreeInfo(
        tree,
        9
    );

    if getPointCount(tree) > 0 then
        printPass(
            'Generation produced points.',
            17
        )
    else
        printFail(
            'Generation produced no points.',
            17
        );

    if getBranchCount(tree) = 0 then
        printPass(
            'All active branches finished.',
            18
        )
    else
        printFail(
            'Active branches remain.',
            18
        );

    if getGrowthTime(tree) = FULL_TARGET_TIME then
        printPass(
            'Growth reached target.',
            19
        )
    else
        printFail(
            'Growth time is incorrect.',
            19
        );

    pauseScreen;
end;

procedure testDeterminism;
var
    tree1: TTree;
    tree2: TTree;
    point1: TPoint;
    point2: TPoint;
    i: LongInt;
    identical: Boolean;
begin
    printTitle(
        'TEST 6 - Deterministic generation'
    );

    tree1 := initialiseTree(
        DETERMINISTIC_SEED,
        FULL_TARGET_TIME
    );

    tree2 := initialiseTree(
        DETERMINISTIC_SEED,
        FULL_TARGET_TIME
    );

    growTree(
        tree1,
        FULL_TARGET_TIME
    );

    growTree(
        tree2,
        FULL_TARGET_TIME
    );

    identical := True;

    if getPointCount(tree1) <> getPointCount(tree2) then
        identical := False;

    if getBranchCount(tree1) <> getBranchCount(tree2) then
        identical := False;

    if getRandomState(tree1) <> getRandomState(tree2) then
        identical := False;

    if identical then
    begin
        for i := 0 to getPointCount(tree1) - 1 do
        begin
            point1 := getPoint(
                tree1,
                i
            );

            point2 := getPoint(
                tree2,
                i
            );

            if (point1.coord.x <> point2.coord.x)
                or (point1.coord.y <> point2.coord.y)
                or (point1.character <> point2.character)
                or (point1.state <> point2.state) then
            begin
                identical := False;
                Break;
            end;
        end;
    end;

    printAt(
        1,
        5,
        'Fixed seed: ' +
        IntToStr(DETERMINISTIC_SEED)
    );

    if identical then
        printPass(
            'Same seed produces the same tree.',
            7
        )
    else
        printFail(
            'Same seed produces different trees.',
            7
        );

    printAt(
        1,
        9,
        'Tree 1 points: ' +
        IntToStr(getPointCount(tree1))
    );

    printAt(
        1,
        10,
        'Tree 2 points: ' +
        IntToStr(getPointCount(tree2))
    );

    printAt(
        1,
        11,
        'Tree 1 random state: ' +
        IntToStr(getRandomState(tree1))
    );

    printAt(
        1,
        12,
        'Tree 2 random state: ' +
        IntToStr(getRandomState(tree2))
    );

    pauseScreen;
end;

procedure testDifferentSeeds;
var
    seed1: Cardinal;
    seed2: Cardinal;
    tree1: TTree;
    tree2: TTree;
begin
    printTitle(
        'TEST 7 - Different seeds'
    );

    { Generate two new seeds for this test. }

    seed1 :=
        Cardinal(Random(MAX_INT - 1)) + 1;

    seed2 :=
        Cardinal(Random(MAX_INT - 1)) + 1;

    { Make sure they are different. }

    if seed1 = seed2 then
        seed2 := seed2 + 1;

    tree1 := initialiseTree(
        seed1,
        FULL_TARGET_TIME
    );

    tree2 := initialiseTree(
        seed2,
        FULL_TARGET_TIME
    );

    growTree(
        tree1,
        FULL_TARGET_TIME
    );

    growTree(
        tree2,
        FULL_TARGET_TIME
    );

    printAt(
        1,
        5,
        'Seed 1: ' +
        IntToStr(seed1)
    );

    printAt(
        1,
        6,
        'Seed 2: ' +
        IntToStr(seed2)
    );

    printAt(
        1,
        8,
        'Tree 1 points: ' +
        IntToStr(getPointCount(tree1))
    );

    printAt(
        1,
        9,
        'Tree 2 points: ' +
        IntToStr(getPointCount(tree2))
    );

    printAt(
        1,
        10,
        'Tree 1 random: ' +
        IntToStr(getRandomState(tree1))
    );

    printAt(
        1,
        11,
        'Tree 2 random: ' +
        IntToStr(getRandomState(tree2))
    );

    if (getRandomState(tree1) <> getRandomState(tree2))
        or (getPointCount(tree1) <> getPointCount(tree2)) then
        printPass(
            'Different seeds produce different results.',
            13
        )
    else
        printAt(
            1,
            13,
            'NOTE: these two trees happened to have the same basic statistics.'
        );

    pauseScreen;
end;

procedure testRandomState;
var
    tree: TTree;
    initialState: Cardinal;
    nextState: Cardinal;
begin
    printTitle(
        'TEST 8 - Random-state progression'
    );

    tree := initialiseTree(
        randomSeed,
        100
    );

    initialState :=
        getRandomState(tree);

    printAt(
        1,
        5,
        'Initial random state: ' +
        IntToStr(initialState)
    );

    growTree(
        tree,
        5
    );

    nextState :=
        getRandomState(tree);

    printAt(
        1,
        6,
        'After growth:         ' +
        IntToStr(nextState)
    );

    if initialState <> nextState then
        printPass(
            'Random state changes during growth.',
            8
        )
    else
        printFail(
            'Random state did not change.',
            8
        );

    pauseScreen;
end;

procedure printSamplePoints(
    tree: TTree
);
var
    count: LongInt;
    i: LongInt;
    point: TPoint;
    row: LongInt;
begin
    count :=
        getPointCount(tree);

    printAt(
        1,
        5,
        'Point count: ' +
        IntToStr(count)
    );

    if count = 0 then
    begin
        printAt(
            1,
            7,
            'No points to display.'
        );
        Exit;
    end;

    printAt(
        1,
        7,
        'First points:'
    );

    row := 8;

    for i := 0 to count - 1 do
    begin
        if i >= 8 then
            Break;

        point :=
            getPoint(
                tree,
                i
            );

        printAt(
            1,
            row,
            'P' +
            IntToStr(i) +
            ': (' +
            IntToStr(point.coord.x) +
            ',' +
            IntToStr(point.coord.y) +
            ') [' +
            point.character +
            '] state=' +
            IntToStr(Ord(point.state))
        );

        Inc(row);
    end;

    if count > 8 then
        printAt(
            1,
            17,
            '... ' +
            IntToStr(count - 8) +
            ' more points.'
        );
end;

procedure testTreePointSamples;
var
    tree: TTree;
begin
    printTitle(
        'TEST 9 - Tree point inspection'
    );

    tree := initialiseTree(
        randomSeed,
        FULL_TARGET_TIME
    );

    growTree(
        tree,
        FULL_TARGET_TIME
    );

    printSamplePoints(tree);

    pauseScreen;
end;

procedure testDisplay;
var
    tree: TTree;
    area: TDisplayArea;
begin
    clearScreen;

    tree := initialiseTree(
        randomSeed,
        FULL_TARGET_TIME
    );

    growTree(
        tree,
        FULL_TARGET_TIME
    );

    area := initialiseDisplayArea(
        DISPLAY_X_MIN,
        DISPLAY_X_MAX,
        DISPLAY_Y_MIN,
        DISPLAY_Y_MAX
    );

    drawTree(
        tree,
        area
    );

    TextColor(White);

    printAt(
        1,
        DISPLAY_Y_MAX + 2,
        'DISPLAY TEST'
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 3,
        'Seed: ' +
        IntToStr(getSeed(tree))
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 4,
        'Points: ' +
        IntToStr(getPointCount(tree))
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 5,
        'Branches: ' +
        IntToStr(getBranchCount(tree))
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 6,
        'Growth: ' +
        IntToStr(getGrowthTime(tree))
    );

    pauseScreen;
end;

procedure testDisplayOverflow;
var
    tree: TTree;
    area: TDisplayArea;
begin
    clearScreen;

    tree := initialiseTree(
        randomSeed,
        FULL_TARGET_TIME
    );

    growTree(
        tree,
        FULL_TARGET_TIME
    );

    { Small box deliberately used to test clipping. }

    area := initialiseDisplayArea(
        10,
        30,
        5,
        25
    );

    drawTree(
        tree,
        area
    );

    TextColor(White);

    printAt(
        1,
        27,
        'OVERFLOW TEST'
    );

    printAt(
        1,
        28,
        'The tree must stay inside the border.'
    );

    printAt(
        1,
        29,
        'Points outside the inner area must be ignored.'
    );

    pauseScreen;
end;

procedure testInvalidDisplayArea;
var
    tree: TTree;
    invalidArea: TDisplayArea;
begin
    printTitle(
        'TEST 12 - Invalid display areas'
    );

    tree := initialiseTree(
        randomSeed,
        100
    );

    growTree(
        tree,
        100
    );

    { Zero-width and zero-height area. }

    invalidArea := initialiseDisplayArea(
        10,
        10,
        10,
        10
    );

    printAt(
        1,
        5,
        'Testing zero-size area...'
    );

    drawTree(
        tree,
        invalidArea
    );

    printPass(
        'Program survived zero-size area.',
        7
    );

    { Invalid CRT coordinate. }

    invalidArea := initialiseDisplayArea(
        0,
        30,
        1,
        30
    );

    printAt(
        1,
        9,
        'Testing out-of-range area...'
    );

    drawTree(
        tree,
        invalidArea
    );

    printPass(
        'Program survived out-of-range area.',
        11
    );

    pauseScreen;
end;

procedure finalRandomTree;
var
    tree: TTree;
    area: TDisplayArea;
begin
    clearScreen;

    { Use the same random seed generated when the program started. }

    tree := initialiseTree(
        randomSeed,
        FULL_TARGET_TIME
    );

    growTree(
        tree,
        FULL_TARGET_TIME
    );

    area := initialiseDisplayArea(
        DISPLAY_X_MIN,
        DISPLAY_X_MAX,
        DISPLAY_Y_MIN,
        DISPLAY_Y_MAX
    );

    drawTree(
        tree,
        area
    );

    TextColor(White);

    printAt(
        1,
        DISPLAY_Y_MAX + 2,
        'RANDOM DEBUG TREE'
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 3,
        'Seed: ' +
        IntToStr(getSeed(tree))
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 4,
        'Points: ' +
        IntToStr(getPointCount(tree))
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 5,
        'Branches: ' +
        IntToStr(getBranchCount(tree))
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 6,
        'Growth: ' +
        IntToStr(getGrowthTime(tree))
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 8,
        'This run used a randomly generated seed.'
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 9,
        'Run the program again to test another tree.'
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 11,
        'Press any key to exit...'
    );

    ReadKey;
end;

begin
    { Create one random seed for this program execution. }
    initialiseRandomSeed;

    { Run the debugging tests. }

    testTreeInitialisation;
    testTreeAccessors;

    testIncrementalGrowth;
    testTimeLimit;
    testFullGeneration;

    testDeterminism;
    testDifferentSeeds;
    testRandomState;

    testTreePointSamples;

    testDisplay;
    testDisplayOverflow;
    testInvalidDisplayArea;

    { Finally show the randomly generated tree. }
    finalRandomTree;

    TextColor(White);
    ClrScr;
end.
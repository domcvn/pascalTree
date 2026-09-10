program MainDebug;

uses
    CRT,
    SysUtils,
    TreeTypes,
    TreeGenerator,
    TreeDisplay;

const
    MAX_INT = $7FFFFFFF;

    { Fixed seed used to test deterministic generation. }
    DETERMINISTIC_SEED = 12345;

    { General test values. }
    TEST_TARGET_TIME = 160;
    FULL_TARGET_TIME = 5000;

    { The display border is exactly 80 x 40. }
    DISPLAY_X_MIN = 1;
    DISPLAY_X_MAX = 80;
    DISPLAY_Y_MIN = 1;
    DISPLAY_Y_MAX = 40;

    { The tree generator uses one fixed growth timeline.
      Session duration does not change the amount of tree growth per
      interval. It only changes the real time between intervals. }
    REFERENCE_GROWTH_TIME = FULL_TARGET_TIME;
    INTERVAL_COUNT = 10;


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

    if y > WindMaxY then
        Exit;

    if x > WindMaxX then
        Exit;

    GotoXY(x, y);
    Write(text);
end;

procedure pauseScreen;
begin
    if WindMaxY >= DISPLAY_Y_MAX + 1 then
        printAt(1, DISPLAY_Y_MAX + 1, 'Press any key to continue...')
    else
        printAt(1, WindMaxY, 'Press any key to continue...');

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

procedure printWarning(
    const message: String;
    y: LongInt
);
begin
    printAt(
        1,
        y,
        '[WARN] ' + message
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
        'TEST 2 - Tree types and accessors'
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

    if (coord.x = 10) and (coord.y = 20) then
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
        and (retrievedPoint.characters = '*')
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

    { Tree-level properties. }

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
        'Time    Growth    Points    Branches    Random state'
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
                IntToStr(getBranchCount(tree)) +
                '          ' +
                IntToStr(getRandomState(tree))
            );

            Inc(row);
        end;

        if currentPoints < previousPoints then
            printWarning(
                'Point count decreased.',
                25
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

function treesAreIdentical(
    tree1, tree2: TTree
): Boolean;
var
    point1: TPoint;
    point2: TPoint;
    branch1: TBranch;
    branch2: TBranch;
    i: LongInt;
begin
    treesAreIdentical := False;

    if getSeed(tree1) <> getSeed(tree2) then
        Exit;

    if getRandomState(tree1) <> getRandomState(tree2) then
        Exit;

    if getTargetTime(tree1) <> getTargetTime(tree2) then
        Exit;

    if getGrowthTime(tree1) <> getGrowthTime(tree2) then
        Exit;

    if getShootCounter(tree1) <> getShootCounter(tree2) then
        Exit;

    if getPointCount(tree1) <> getPointCount(tree2) then
        Exit;

    if getBranchCount(tree1) <> getBranchCount(tree2) then
        Exit;

    for i := 0 to getPointCount(tree1) - 1 do
    begin
        point1 := getPoint(tree1, i);
        point2 := getPoint(tree2, i);

        if (point1.coord.x <> point2.coord.x)
            or (point1.coord.y <> point2.coord.y)
            or (point1.characters <> point2.characters)
            or (point1.state <> point2.state) then
            Exit;
    end;

    for i := 0 to getBranchCount(tree1) - 1 do
    begin
        branch1 := getBranch(tree1, i);
        branch2 := getBranch(tree2, i);

        if (branch1.coord.x <> branch2.coord.x)
            or (branch1.coord.y <> branch2.coord.y)
            or (branch1.remainingLife <> branch2.remainingLife)
            or (branch1.age <> branch2.age)
            or (branch1.shootCooldown <> branch2.shootCooldown)
            or (branch1.state <> branch2.state) then
            Exit;
    end;

    treesAreIdentical := True;
end;

procedure testDeterminism;
var
    tree1: TTree;
    tree2: TTree;
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

    printAt(
        1,
        5,
        'Fixed seed: ' +
        IntToStr(DETERMINISTIC_SEED)
    );

    if treesAreIdentical(tree1, tree2) then
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
        'Tree 1 branches: ' +
        IntToStr(getBranchCount(tree1))
    );

    printAt(
        1,
        12,
        'Tree 2 branches: ' +
        IntToStr(getBranchCount(tree2))
    );

    printAt(
        1,
        13,
        'Tree 1 random state: ' +
        IntToStr(getRandomState(tree1))
    );

    printAt(
        1,
        14,
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

    seed1 :=
        Cardinal(Random(MAX_INT - 1)) + 1;

    seed2 :=
        Cardinal(Random(MAX_INT - 1)) + 1;

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
        printWarning(
            'Different seeds happened to have the same basic statistics.',
            13
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
            point.characters +
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

function getTerminalX(
    area: TDisplayArea;
    point: TPoint
): LongInt;
begin
    getTerminalX :=
        ((area.xMin + area.xMax) div 2) + point.coord.x;
end;

function getTerminalY(
    area: TDisplayArea;
    point: TPoint
): LongInt;
begin
    getTerminalY :=
        area.yMax - 1 + point.coord.y;
end;

function pointIsInsideBorder(
    area: TDisplayArea;
    point: TPoint
): Boolean;
var
    terminalX: LongInt;
    terminalY: LongInt;
    lastX: LongInt;
begin
    pointIsInsideBorder := False;

    if point.characters = '' then
        Exit;

    terminalX := getTerminalX(area, point);
    terminalY := getTerminalY(area, point);
    lastX := terminalX + Length(point.characters) - 1;

    if terminalX <= area.xMin then
        Exit;

    if lastX >= area.xMax then
        Exit;

    if terminalY <= area.yMin then
        Exit;

    if terminalY >= area.yMax then
        Exit;

    pointIsInsideBorder := True;
end;

function verifyTreeInsideBorder(
    tree: TTree;
    area: TDisplayArea;
    showFirstFailure: Boolean
): LongInt;
var
    i: LongInt;
    outsideCount: LongInt;
    point: TPoint;
    terminalX: LongInt;
    terminalY: LongInt;
    lastX: LongInt;
begin
    outsideCount := 0;

    for i := 0 to getPointCount(tree) - 1 do
    begin
        point := getPoint(tree, i);

        if not pointIsInsideBorder(area, point) then
        begin
            Inc(outsideCount);

            if showFirstFailure and (outsideCount = 1) then
            begin
                terminalX := getTerminalX(area, point);
                terminalY := getTerminalY(area, point);
                lastX := terminalX + Length(point.characters) - 1;

                printAt(
                    1,
                    20,
                    'First outside point: P' + IntToStr(i)
                );

                printAt(
                    1,
                    21,
                    'Logical: (' +
                    IntToStr(point.coord.x) +
                    ',' +
                    IntToStr(point.coord.y) +
                    ')'
                );

                printAt(
                    1,
                    22,
                    'Terminal X: ' +
                    IntToStr(terminalX) +
                    ' to ' +
                    IntToStr(lastX)
                );

                printAt(
                    1,
                    23,
                    'Terminal Y: ' +
                    IntToStr(terminalY)
                );

                printAt(
                    1,
                    24,
                    'Characters: [' +
                    point.characters +
                    ']'
                );
            end;
        end;
    end;

    verifyTreeInsideBorder := outsideCount;
end;

procedure printDisplayHeader(
    tree: TTree;
    outsideCount: LongInt
);
begin
    if WindMaxY < DISPLAY_Y_MAX + 1 then
        Exit;

    TextColor(White);

    printAt(
        1,
        DISPLAY_Y_MAX + 2,
        '80 x 40 DISPLAY TEST'
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
        'Growth: ' +
        IntToStr(getGrowthTime(tree))
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 5,
        'Points: ' +
        IntToStr(getPointCount(tree)) +
        '   Branches: ' +
        IntToStr(getBranchCount(tree))
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 6,
        'Outside border: ' +
        IntToStr(outsideCount)
    );
end;

procedure testDisplay;
var
    tree: TTree;
    area: TDisplayArea;
    outsideCount: LongInt;
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

    { Verify first so debug information cannot overwrite the border. }

    outsideCount :=
        verifyTreeInsideBorder(
            tree,
            area,
            False
        );

    drawTree(
        tree,
        area
    );

    printDisplayHeader(
        tree,
        outsideCount
    );

    if outsideCount = 0 then
        printPass(
            'All generated points fit inside the 80 x 40 border.',
            DISPLAY_Y_MAX + 8
        )
    else
        printFail(
            'Some generated points are outside the 80 x 40 border.',
            DISPLAY_Y_MAX + 8
        );

    printAt(
        1,
        DISPLAY_Y_MAX + 9,
        'The border and tree above are drawn by TreeDisplay.'
    );

    pauseScreen;
end;

procedure testBorderVerification;
var
    tree: TTree;
    area: TDisplayArea;
    outsideCount: LongInt;
begin
    printTitle(
        'TEST 11 - 80 x 40 border verification'
    );

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

    printAt(
        1,
        5,
        'Border: X=' +
        IntToStr(DISPLAY_X_MIN) +
        '..' +
        IntToStr(DISPLAY_X_MAX) +
        ', Y=' +
        IntToStr(DISPLAY_Y_MIN) +
        '..' +
        IntToStr(DISPLAY_Y_MAX)
    );

    printAt(
        1,
        7,
        'Checking every generated point and its full character string...'
    );

    outsideCount :=
        verifyTreeInsideBorder(
            tree,
            area,
            True
        );

    printAt(
        1,
        10,
        'Points checked: ' +
        IntToStr(getPointCount(tree))
    );

    printAt(
        1,
        11,
        'Points outside inner border: ' +
        IntToStr(outsideCount)
    );

    if outsideCount = 0 then
        printPass(
            'Entire generated tree stays inside the 80 x 40 border.',
            13
        )
    else
        printFail(
            'Generated tree contains points outside the 80 x 40 border.',
            13
        );

    printAt(
        1,
        15,
        'Inner drawing area:'
    );

    printAt(
        1,
        16,
        'X > 1 and X + character length - 1 < 80'
    );

    printAt(
        1,
        17,
        'Y > 1 and Y < 40'
    );

    pauseScreen;
end;

procedure testDisplayOverflow;
var
    tree: TTree;
    area: TDisplayArea;
    outsideCount: LongInt;
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

    { Deliberately smaller box used to exercise TreeDisplay clipping. }

    area := initialiseDisplayArea(
        10,
        30,
        5,
        25
    );

    outsideCount :=
        verifyTreeInsideBorder(
            tree,
            area,
            False
        );

    drawTree(
        tree,
        area
    );

    if WindMaxY >= 27 then
    begin
        TextColor(White);

        printAt(
            1,
            27,
            'OVERFLOW / CLIPPING TEST'
        );

        printAt(
            1,
            28,
            'Points outside this smaller inner area: ' +
            IntToStr(outsideCount)
        );

        printAt(
            1,
            29,
            'TreeDisplay should ignore points outside the display area.'
        );

        printAt(
            1,
            30,
            'The program must not crash or corrupt the border.'
        );
    end;

    pauseScreen;
end;

procedure testInvalidDisplayArea;
var
    tree: TTree;
    invalidArea: TDisplayArea;
begin
    printTitle(
        'TEST 13 - Invalid display areas'
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

    clearScreen;

    { Invalid CRT coordinate. }

    invalidArea := initialiseDisplayArea(
        0,
        30,
        1,
        30
    );

    printAt(
        1,
        5,
        'Testing out-of-range area...'
    );

    drawTree(
        tree,
        invalidArea
    );

    printPass(
        'Program survived out-of-range area.',
        7
    );

    pauseScreen;
end;

function getCompleteGrowthTime(
    seed: Cardinal
): LongInt;
var
    tree: TTree;
    elapsedTime: LongInt;
begin
    tree := initialiseTree(
        seed,
        FULL_TARGET_TIME
    );

    elapsedTime := 0;

    { Advance in the same 5-second growth units used by TreeGenerator.
      The first time at which no active branches remain is the amount of
      growth actually required to generate the complete tree. }
    while elapsedTime < FULL_TARGET_TIME do
    begin
        elapsedTime := elapsedTime + 5;

        growTree(
            tree,
            elapsedTime
        );

        if (getPointCount(tree) > 0)
            and (getBranchCount(tree) = 0) then
        begin
            getCompleteGrowthTime := elapsedTime;
            Exit;
        end;
    end;

    { The tree did not finish during the test limit. Return the limit so
      later tests can report that condition rather than divide by zero. }
    getCompleteGrowthTime := FULL_TARGET_TIME;
end;

function getIntervalGrowthTime(
    intervalNumber: LongInt;
    completeGrowthTime: LongInt
): LongInt;
var
    totalGrowthSteps: LongInt;
    targetGrowthSteps: LongInt;
begin
    if intervalNumber <= 0 then
    begin
        getIntervalGrowthTime := 0;
        Exit;
    end;

    { Work in the generator's discrete 5-second growth steps.  This is the
      important correction: the 10 intervals divide the actual complete
      tree growth into 10 stages.  Session duration is not involved here. }
    totalGrowthSteps := completeGrowthTime div 5;
    targetGrowthSteps :=
        (intervalNumber * totalGrowthSteps) div INTERVAL_COUNT;

    if intervalNumber >= INTERVAL_COUNT then
        targetGrowthSteps := totalGrowthSteps;

    getIntervalGrowthTime := targetGrowthSteps * 5;
end;

function treeStatesMatch(
    tree1, tree2: TTree
): Boolean;
begin
    treeStatesMatch := treesAreIdentical(tree1, tree2);
end;

procedure printIntervalResult(
    intervalNumber: LongInt;
    sessionMinutes: LongInt;
    sessionElapsedSeconds: LongInt;
    growthTime: LongInt;
    completeGrowthTime: LongInt;
    tree: TTree;
    outsideCount: LongInt
);
begin
    { All information is printed BELOW the 80 x 40 rectangle. }
    if WindMaxY < DISPLAY_Y_MAX + 9 then
        Exit;

    printAt(
        1,
        DISPLAY_Y_MAX + 2,
        'Session: ' +
        IntToStr(sessionMinutes) +
        ' min    Interval: ' +
        IntToStr(intervalNumber) +
        '/' +
        IntToStr(INTERVAL_COUNT)
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 3,
        'Session elapsed: ' +
        IntToStr(sessionElapsedSeconds div 60) +
        ' min ' +
        IntToStr(sessionElapsedSeconds mod 60) +
        ' sec'
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 4,
        'Tree growth: ' +
        IntToStr(growthTime) +
        ' / ' +
        IntToStr(completeGrowthTime) +
        ' sec'
    );

    printAt(
        1,
        DISPLAY_Y_MAX + 5,
        'Points: ' +
        IntToStr(getPointCount(tree)) +
        '    Branches: ' +
        IntToStr(getBranchCount(tree)) +
        '    Outside: ' +
        IntToStr(outsideCount)
    );
end;

procedure testSessionIntervals;
var
    sessionMinutes: LongInt;
    sessionIntervalSeconds: LongInt;
    intervalNumber: LongInt;
    sessionElapsedSeconds: LongInt;
    growthTime: LongInt;
    completeGrowthTime: LongInt;
    tree: TTree;
    area: TDisplayArea;
    outsideCount: LongInt;
begin
    printTitle(
        'TEST 14 - Session duration and 10 equal growth intervals'
    );

    printAt(
        1,
        5,
        'Enter session duration in minutes:'
    );

    ReadLn(sessionMinutes);

    if sessionMinutes <= 0 then
    begin
        printFail(
            'Session duration must be greater than zero.',
            7
        );
        pauseScreen;
        Exit;
    end;

    sessionIntervalSeconds :=
        (sessionMinutes * 60) div INTERVAL_COUNT;

    if sessionIntervalSeconds <= 0 then
    begin
        printFail(
            'Session is too short to create 10 one-second-or-longer intervals.',
            7
        );
        pauseScreen;
        Exit;
    end;

    { Find how much growth this PARTICULAR seed actually needs. }
    completeGrowthTime :=
        getCompleteGrowthTime(randomSeed);

    tree := initialiseTree(
        randomSeed,
        completeGrowthTime
    );

    area := initialiseDisplayArea(
        DISPLAY_X_MIN,
        DISPLAY_X_MAX,
        DISPLAY_Y_MIN,
        DISPLAY_Y_MAX
    );

    clearScreen;

    for intervalNumber := 1 to INTERVAL_COUNT do
    begin
        sessionElapsedSeconds :=
            (intervalNumber * sessionMinutes * 60)
            div INTERVAL_COUNT;

        growthTime :=
            getIntervalGrowthTime(
                intervalNumber,
                completeGrowthTime
            );

        growTree(
            tree,
            growthTime
        );

        outsideCount :=
            verifyTreeInsideBorder(
                tree,
                area,
                False
            );

        clearScreen;

        { The rectangle occupies rows 1..40. }
        drawTree(
            tree,
            area
        );

        { Debug information starts on row 42, never over the rectangle. }
        printIntervalResult(
            intervalNumber,
            sessionMinutes,
            sessionElapsedSeconds,
            growthTime,
            completeGrowthTime,
            tree,
            outsideCount
        );

        if WindMaxY >= DISPLAY_Y_MAX + 7 then
        begin
            if outsideCount = 0 then
                printAt(
                    1,
                    DISPLAY_Y_MAX + 6,
                    '[PASS] Tree remains inside the 80 x 40 border.'
                )
            else
                printAt(
                    1,
                    DISPLAY_Y_MAX + 6,
                    '[FAIL] Tree has points outside the 80 x 40 border.'
                );

            if intervalNumber < INTERVAL_COUNT then
                printAt(
                    1,
                    DISPLAY_Y_MAX + 7,
                    'Press any key for the next interval...'
                )
            else
                printAt(
                    1,
                    DISPLAY_Y_MAX + 7,
                    'Final interval reached.'
                );
        end;

        ReadKey;
    end;

    clearScreen;

    printTitle(
        'TEST 14 - Interval test complete'
    );

    printAt(
        1,
        5,
        'Session duration: ' +
        IntToStr(sessionMinutes) +
        ' minutes'
    );

    printAt(
        1,
        6,
        'Intervals: ' +
        IntToStr(INTERVAL_COUNT)
    );

    printAt(
        1,
        7,
        'Real time per interval: ' +
        IntToStr(sessionIntervalSeconds div 60) +
        ' min ' +
        IntToStr(sessionIntervalSeconds mod 60) +
        ' sec'
    );

    printAt(
        1,
        8,
        'Complete tree growth: ' +
        IntToStr(completeGrowthTime) +
        ' sec'
    );

    if getGrowthTime(tree) = completeGrowthTime then
        printPass(
            'Final interval reaches the complete tree.',
            10
        )
    else
        printFail(
            'Final interval does not reach the complete tree.',
            10
        );

    pauseScreen;
end;

procedure testCompareSessionDurations;
var
    treeA: TTree;
    treeB: TTree;
    area: TDisplayArea;
    intervalNumber: LongInt;
    growthTimeA: LongInt;
    growthTimeB: LongInt;
    completeGrowthTime: LongInt;
    identical: Boolean;
    outsideA: LongInt;
    outsideB: LongInt;
    row: LongInt;
begin
    printTitle(
        'TEST 15 - Compare 10-minute and 60-minute sessions'
    );

    completeGrowthTime :=
        getCompleteGrowthTime(DETERMINISTIC_SEED);

    treeA := initialiseTree(
        DETERMINISTIC_SEED,
        completeGrowthTime
    );

    treeB := initialiseTree(
        DETERMINISTIC_SEED,
        completeGrowthTime
    );

    area := initialiseDisplayArea(
        DISPLAY_X_MIN,
        DISPLAY_X_MAX,
        DISPLAY_Y_MIN,
        DISPLAY_Y_MAX
    );

    identical := True;

    printAt(
        1,
        5,
        'Both sessions use the same seed and the same 10 growth stages.'
    );

    printAt(
        1,
        6,
        'Only their real interval lengths differ: 1 minute vs 6 minutes.'
    );

    printAt(
        1,
        8,
        'Interval   Growth time A   Growth time B   Same tree?'
    );

    row := 9;

    for intervalNumber := 1 to INTERVAL_COUNT do
    begin
        growthTimeA :=
            getIntervalGrowthTime(
                intervalNumber,
                completeGrowthTime
            );

        growthTimeB :=
            getIntervalGrowthTime(
                intervalNumber,
                completeGrowthTime
            );

        growTree(
            treeA,
            growthTimeA
        );

        growTree(
            treeB,
            growthTimeB
        );

        if not treeStatesMatch(treeA, treeB) then
            identical := False;

        outsideA :=
            verifyTreeInsideBorder(
                treeA,
                area,
                False
            );

        outsideB :=
            verifyTreeInsideBorder(
                treeB,
                area,
                False
            );

        if row <= 18 then
        begin
            printAt(
                1,
                row,
                IntToStr(intervalNumber) +
                '          ' +
                IntToStr(growthTimeA) +
                '              ' +
                IntToStr(growthTimeB) +
                '             ' +
                BoolToStr(
                    treeStatesMatch(treeA, treeB),
                    True
                )
            );
            Inc(row);
        end;
    end;

    printAt(
        1,
        20,
        '10-minute schedule: 1 minute between intervals.'
    );

    printAt(
        1,
        21,
        '60-minute schedule: 6 minutes between intervals.'
    );

    printAt(
        1,
        22,
        'Tree growth at corresponding intervals must be identical.'
    );

    if identical then
        printPass(
            'All 10 corresponding growth stages are identical.',
            24
        )
    else
        printFail(
            'At least one corresponding growth stage is different.',
            24
        );

    if (outsideA = 0) and (outsideB = 0) then
        printPass(
            'Both final trees fit inside the 80 x 40 border.',
            25
        )
    else
        printFail(
            'At least one final tree exceeds the 80 x 40 border.',
            25
        );

    pauseScreen;
end;

procedure testFinalRandomTree;
var
    tree: TTree;
    area: TDisplayArea;
    outsideCount: LongInt;
begin
    clearScreen;

    { Use the same random seed generated when the program started. }

    tree := initialiseTree(
        randomSeed,
        REFERENCE_GROWTH_TIME
    );

    growTree(
        tree,
        REFERENCE_GROWTH_TIME
    );

    area := initialiseDisplayArea(
        DISPLAY_X_MIN,
        DISPLAY_X_MAX,
        DISPLAY_Y_MIN,
        DISPLAY_Y_MAX
    );

    outsideCount :=
        verifyTreeInsideBorder(
            tree,
            area,
            False
        );

    drawTree(
        tree,
        area
    );

    if WindMaxY >= DISPLAY_Y_MAX + 2 then
    begin
        TextColor(White);

        printAt(
            1,
            DISPLAY_Y_MAX + 2,
            'FINAL RANDOM DEBUG TREE'
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
            DISPLAY_Y_MAX + 7,
            'Outside border: ' +
            IntToStr(outsideCount)
        );

        printAt(
            1,
            DISPLAY_Y_MAX + 8,
            'Border: 80 x 40'
        );

        if outsideCount = 0 then
            printPass(
                'Final random tree fits inside the border.',
                DISPLAY_Y_MAX + 9
            )
        else
            printFail(
                'Final random tree exceeds the border.',
                DISPLAY_Y_MAX + 9
            );

        printAt(
            1,
            41,
            'Press any key to exit...'
        );
    end;

    ReadKey;
end;

begin
    { Create one random seed for this program execution. }

    initialiseRandomSeed;

    { Run the debugging tests in increasing complexity. }

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
    testBorderVerification;
    testDisplayOverflow;
    testInvalidDisplayArea;

    { Test the relationship between session duration and tree stages. }

    testSessionIntervals;
    testCompareSessionDurations;

    { Finally show the randomly generated tree. }

    testFinalRandomTree;

    TextColor(White);
    ClrScr;
end.

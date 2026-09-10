{ This unit handles the display of a tree in a defined rectangular area of the terminal. }
unit TreeDisplay;

interface
uses 
    crt, TreeTypes;

type 
    { Represents the rectangular area used to display a tree in the terminal. }
    TDisplayArea = record
        xMin: LongInt; //< Left boundary of the display area
        xMax: LongInt; //< Right boundary of the display area
        yMin: LongInt; //< Top boundary of the display area
        yMax: LongInt; //< Bottom boundary of the display area
    end;

{ Creates and returns a display area with the specified boundaries.

The coordinates represent the outer border of the display area. The tree is drawn inside this border. }
function initialiseDisplayArea(xMin, xMax, yMin, yMax: LongInt): TDisplayArea;

{ Clears the content of the display area in the terminal. }
procedure clearDisplayArea(area: TDisplayArea);

{ Displays all graphical points of @bold(tree) inside @bold(area). 

Points outside the inner area of the border are ignored. Tree states are displayed using different terminal colours.}
procedure drawTree(tree: TTree; area: TDisplayArea);

implementation 
const 
    BORDER_COLOR = White; 
    DARK_LEAF_COLOR = Green;
    DARK_WOOD_COLOR = Brown;
    LIGHT_LEAF_COLOR = LightGreen;
    LIGHT_WOOD_COLOR = Yellow;

function initialiseDisplayArea(xMin, xMax, yMin, yMax: LongInt): TDisplayArea;
begin 
    initialiseDisplayArea.xMin := xMin;
    initialiseDisplayArea.xMax := xMax;
    initialiseDisplayArea.yMin := yMin;
    initialiseDisplayArea.yMax := yMax;
end;

function isValidArea(area: TDisplayArea): Boolean;
begin 
    isValidArea := (area.xMin >= 1) and (area.xMax <= 255) and (area.xMin < area.xMax) and 
                (area.yMin >= 1) and (area.yMax <= 255) and (area.yMin < area.yMax);
end;

function convertX(coord: TCoord; area: TDisplayArea): LongInt;
begin 
    convertX := ((area.xMin + area.xMax) div 2) + coord.x;
end;

function convertY(coord: TCoord; area: TDisplayArea): LongInt;
begin 
    convertY := area.yMax - 1 + coord.y;
end;


function isInsideTreeArea(coord: TCoord; area: TDisplayArea): Boolean;
var 
    terminalX, terminalY: LongInt;
begin 
    terminalX := convertX(coord, area);
    terminalY := convertY(coord, area);
    isInsideTreeArea := (terminalX > area.xMin) and (terminalX < area.xMax) and (terminalY > area.yMin) and (terminalY < area.yMax);
end;

function getPointColor(point: TPoint; idx: LongInt): Byte;
begin 
    if point.state = Dying then 
        getPointColor := LIGHT_LEAF_COLOR 
    else if point.state = Dead then 
        getPointColor := DARK_LEAF_COLOR
    else if (idx mod 2) = 0 then 
        getPointColor := LIGHT_WOOD_COLOR
    else 
        getPointColor := DARK_WOOD_COLOR;
end;

procedure drawHorizontalBorder(xMin, xMax, y: LongInt);
var 
    x: LongInt;
begin 
    GotoXY(xMin, y);
    Write('+');
    TextColor(BORDER_COLOR);
    for x := xMin + 1 to xMax - 1 do 
        write('-');
    write('+');
end;

procedure drawVerticalBorder(xMin, xMax, yMin, yMax: LongInt);
var
    y: LongInt;
begin 
    for y := yMin + 1 to yMax - 1 do 
    begin 
        GoToXY(xMin, y);
        write('|');
        GotoXY(xMax, y);
        write('|');
    end;
end;

procedure drawBorder(area: TDisplayArea);
begin 
    if not isValidArea(area) then 
        Exit;
    TextColor(BORDER_COLOR);
    drawHorizontalBorder(area.xMin, area.xMax, area.yMin);
    drawVerticalBorder(area.xMin, area.xMax, area.yMin, area.yMax);
    drawHorizontalBorder(area.xMin, area.xMax, area.yMax);
end;

procedure clearDisplayLine(area: TDisplayArea; y: LongInt);
var 
    x: LongInt;
begin 
    if (y < area.yMin) or (y > area.yMax) then 
        Exit;
    GoToXY(area.xMin, y);
    for x := area.xMin to area.xMax do
        write(' ');
end;

procedure clearDisplayArea(area: TDisplayArea);
var 
    y: LongInt;
begin 
    if not isValidArea(area) then
        Exit;
    for y := area.yMin to area.yMax do 
        clearDisplayLine(area, y);
end;

procedure drawPoint(point: TPoint; area: TDisplayArea; idx: LongInt);
var 
    terminalX, terminalY: LongInt;
begin 
    if not isInsideTreeArea(point.coord, area) then 
        Exit;

    terminalX := convertX(point.coord, area);
    terminalY := convertY(point.coord, area);

    if (terminalX <= area.xMin) or (terminalX >= area.xMax) or (terminalY <= area.yMin) or (terminalY >= area.xMax) then 
        Exit;

    GoToXY(terminalX, terminalY);
    TextColor(getPointColor(point, idx));
    write(point.character);
end;

procedure drawTree(tree: TTree; area: TDisplayArea);
var 
    i : LongInt;
    point: TPoint;
begin 
    if not isValidArea(area) then 
        Exit;
    clearDisplayArea(area);
    drawBorder(area);
    for i := 0 to getPointCount(tree) - 1 do 
    begin 
        point := getPoint(tree, i);
        drawPoint(point, area, i);
    end;
    TextColor(BORDER_COLOR);

    if area.yMax < 255 then 
        GoToXY(area.xMin, area.yMax + 1)
    else 
        GoToXY(area.xMin, area.yMax);
end;

end.
{
  cbonsai_crt.pas - a beautifully random bonsai tree generator

  This version only uses the classic Turbo-Pascal-style `crt` unit
  (GotoXY, TextColor, ReadKey, ...), which FreePascal ships built in
  for BOTH Windows and Linux (and macOS). There is nothing extra to
  install and nothing platform-specific to link against, so a single
  compile works everywhere:

      fpc -Mobjfpc -Sh cbonsai_crt.pas          (on Linux/macOS)
      fpc -Mobjfpc -Sh cbonsai_crt.pas           (on Windows, same command)

  Compared to the ncurses/panel version, this rewrite trades some
  fidelity for simplicity:
    - only the 16 standard console colors are available (no 256-color
      support), so --color values are wrapped into 0..15
    - no "windows"/panels - everything is drawn straight onto the
      console with GotoXY
    - no wide-character handling - leaves are plain ASCII/Latin-1
    - screen coordinates are clamped to 255 (crt's built-in limit)
}

program cbonsai;

uses
  SysUtils, Crt;

type
  TBranchType = (btTrunk, btShootLeft, btShootRight, btDying, btDead);

  TConfig = record
    live, infinite, screensaver, printTree, verbosity: Integer;
    lifeStart, multiplier, baseType, seed, leavesSize: Integer;
    save, load, targetBranchCount: Integer;
    timeStepMs: Integer;      { live-mode delay between growth steps }
    timeWaitMs: Integer;      { infinite-mode delay between trees }
    message: String;
    leaves: array[0..63] of String;
    colors: array[0..3] of Byte;  { dark leaf, dark wood, light leaf, light wood }
    saveFile, loadFile: String;
  end;

  TCounters = record
    branches, shoots, shootCounter: Integer;
  end;

  TStrArr = array of String;

var
  conf: TConfig;
  myCounters: TCounters;
  totalCols, totalRows: Integer;  { usable console size, 1-based }
  treeRows: Integer;              { rows available above the base art }

{ ------------------------------------------------------------------ }
{ small helpers                                                      }
{ ------------------------------------------------------------------ }

function SplitStr(const s: String; sep: Char): TStrArr;
var
  parts: TStrArr;
  cnt, startPos, i: Integer;
begin
  SetLength(parts, 0);
  cnt := 0;
  startPos := 1;
  for i := 1 to Length(s) + 1 do
    if (i > Length(s)) or (s[i] = sep) then
    begin
      SetLength(parts, cnt + 1);
      parts[cnt] := Copy(s, startPos, i - startPos);
      Inc(cnt);
      startPos := i + 1;
    end;
  Result := parts;
end;

function PadRight(const s: String; width: Integer): String;
begin
  Result := s;
  while Length(Result) < width do
    Result := Result + ' ';
end;

{ roll (randomize) a die: returns 0..modVal-1 }
function roll(modVal: Integer): Integer;
begin
  if modVal < 1 then modVal := 1;
  Result := Random(modVal);
end;

{ ------------------------------------------------------------------ }
{ save / load progress                                               }
{ ------------------------------------------------------------------ }

function SaveToFile(const fname: String; seed, branchCount: Integer): Boolean;
var
  f: TextFile;
begin
  Result := True;
  {$I-}
  AssignFile(f, fname);
  Rewrite(f);
  {$I+}
  if IOResult <> 0 then
  begin
    WriteLn('error: file was not opened properly for writing: ', fname);
    Exit(False);
  end;
  Write(f, seed, ' ', branchCount);
  CloseFile(f);
end;

function LoadFromFile(var c: TConfig): Boolean;
var
  f: TextFile;
  seed, targetBranchCount: Integer;
begin
  Result := True;
  {$I-}
  AssignFile(f, c.loadFile);
  Reset(f);
  {$I+}
  if IOResult <> 0 then
  begin
    WriteLn('error: file was not opened properly for reading: ', c.loadFile);
    Exit(False);
  end;

  {$I-}
  Read(f, seed, targetBranchCount);
  {$I+}
  if IOResult <> 0 then
  begin
    WriteLn('error: save file could not be read');
    CloseFile(f);
    Exit(False);
  end;

  c.seed := seed;
  c.targetBranchCount := targetBranchCount;
  CloseFile(f);
end;

function CreateDefaultCachePath: String;
begin
  {$IFDEF WINDOWS}
  Result := GetEnvironmentVariable('LOCALAPPDATA');
  if Result <> '' then Exit(Result + '\cbonsai');
  Result := GetEnvironmentVariable('USERPROFILE');
  if Result <> '' then Exit(Result + '\cbonsai');
  Result := 'cbonsai';
  {$ELSE}
  Result := GetEnvironmentVariable('XDG_CACHE_HOME');
  if Result <> '' then Exit(Result + '/cbonsai');
  Result := GetEnvironmentVariable('HOME');
  if Result <> '' then Exit(Result + '/.cache/cbonsai');
  Result := 'cbonsai';
  {$ENDIF}
end;

{ ------------------------------------------------------------------ }
{ screen drawing                                                      }
{ ------------------------------------------------------------------ }

procedure PlotChar(x, y: Integer; const s: String);
begin
  { crt's GotoXY only accepts 1..255, so just skip anything outside
    the visible tree area instead of risking an out-of-range call }
  if (x >= 1) and (x <= totalCols) and (y >= 1) and (y <= treeRows) then
  begin
    GotoXY(x, y);
    Write(s);
  end;
end;

procedure DrawBase(baseType: Integer);
var
  baseWidth, baseHeight, leftCol, topRow: Integer;
begin
  baseWidth := 0;
  baseHeight := 0;
  case baseType of
    1: begin baseWidth := 31; baseHeight := 4; end;
    2: begin baseWidth := 15; baseHeight := 3; end;
  end;
  if baseHeight = 0 then Exit;

  leftCol := (totalCols div 2) - (baseWidth div 2);
  if leftCol < 1 then leftCol := 1;
  topRow := totalRows - baseHeight + 1;

  case baseType of
    1:
      begin
        GotoXY(leftCol, topRow);
        TextColor(White);          Write(':');
        TextColor(conf.colors[2]); Write('___________');
        TextColor(conf.colors[3]); Write('./~~~\.');
        TextColor(conf.colors[2]); Write('___________');
        TextColor(White);          Write(':');

        GotoXY(leftCol, topRow + 1); Write(' \                           / ');
        GotoXY(leftCol, topRow + 2); Write('  \_________________________/ ');
        GotoXY(leftCol, topRow + 3); Write('  (_)                     (_)');
      end;
    2:
      begin
        GotoXY(leftCol, topRow);
        TextColor(White);          Write('(');
        TextColor(conf.colors[2]); Write('---');
        TextColor(conf.colors[3]); Write('./~~~\.');
        TextColor(conf.colors[2]); Write('---');
        TextColor(White);          Write(')');

        GotoXY(leftCol, topRow + 1); Write(' (           ) ');
        GotoXY(leftCol, topRow + 2); Write('  (_________)  ');
      end;
  end;
end;

{ word-wrap plain text into lines no wider than maxWidth }
function WordWrap(const text: String; maxWidth: Integer): TStrArr;
var
  paragraphs, words: TStrArr;
  lines: TStrArr;
  p, w: Integer;
  currentLine: String;
begin
  SetLength(lines, 0);
  if maxWidth < 1 then maxWidth := 1;

  paragraphs := SplitStr(text, #10);
  for p := 0 to High(paragraphs) do
  begin
    words := SplitStr(paragraphs[p], ' ');
    currentLine := '';
    for w := 0 to High(words) do
    begin
      if words[w] = '' then Continue;
      if currentLine = '' then
        currentLine := words[w]
      else if Length(currentLine) + 1 + Length(words[w]) <= maxWidth then
        currentLine := currentLine + ' ' + words[w]
      else
      begin
        SetLength(lines, Length(lines) + 1);
        lines[High(lines)] := currentLine;
        currentLine := words[w];
      end;
    end;
    SetLength(lines, Length(lines) + 1);
    lines[High(lines)] := currentLine;
  end;

  Result := lines;
end;

procedure DrawMessage(const c: TConfig);
var
  lines: TStrArr;
  maxWidth, boxWidth, boxHeight, i, top, left: Integer;
begin
  if c.message = '' then Exit;

  maxWidth := totalCols div 4;
  if maxWidth < 10 then maxWidth := 10;

  lines := WordWrap(c.message, maxWidth);

  boxWidth := 0;
  for i := 0 to High(lines) do
    if Length(lines[i]) > boxWidth then boxWidth := Length(lines[i]);
  boxHeight := Length(lines);

  top := Round(totalRows * 0.7);
  left := Round(totalCols * 0.7);

  if top + boxHeight + 1 > totalRows then top := totalRows - boxHeight - 1;
  if left + boxWidth + 3 > totalCols then left := totalCols - boxWidth - 3;
  if top < 1 then top := 1;
  if left < 1 then left := 1;

  TextColor(White);
  GotoXY(left, top);
  Write('+', StringOfChar('-', boxWidth + 2), '+');
  for i := 0 to High(lines) do
  begin
    GotoXY(left, top + 1 + i);
    Write('| ', PadRight(lines[i], boxWidth), ' |');
  end;
  GotoXY(left, top + boxHeight + 1);
  Write('+', StringOfChar('-', boxWidth + 2), '+');
end;

{ ------------------------------------------------------------------ }
{ tree growth                                                        }
{ ------------------------------------------------------------------ }

procedure ChooseColor(btype: TBranchType);
begin
  case btype of
    btTrunk, btShootLeft, btShootRight:
      if roll(2) = 0 then TextColor(conf.colors[3]) else TextColor(conf.colors[1]);
    btDying:
      TextColor(conf.colors[2]);
    btDead:
      TextColor(conf.colors[0]);
  end;
end;

procedure SetDeltas(btype: TBranchType; life, age, multiplier: Integer;
  out returnDx, returnDy: Integer);
var
  dx, dy, dice: Integer;
begin
  dx := 0;
  dy := 0;

  case btype of
    btTrunk:
      begin
        if (age <= 2) or (life < 4) then
        begin
          dy := 0;
          dx := roll(3) - 1;
        end
        else if age < (multiplier * 3) then
        begin
          if (Trunc(multiplier * 0.5) <> 0) and (age mod Trunc(multiplier * 0.5) = 0) then
            dy := -1
          else
            dy := 0;

          dice := roll(10);
          if dice <= 0 then dx := -2
          else if (dice >= 1) and (dice <= 3) then dx := -1
          else if (dice >= 4) and (dice <= 5) then dx := 0
          else if (dice >= 6) and (dice <= 8) then dx := 1
          else if dice = 9 then dx := 2;
        end
        else
        begin
          dice := roll(10);
          if dice > 2 then dy := -1 else dy := 0;
          dx := roll(3) - 1;
        end;
      end;

    btShootLeft:
      begin
        dice := roll(10);
        if (dice >= 0) and (dice <= 1) then dy := -1
        else if (dice >= 2) and (dice <= 7) then dy := 0
        else if (dice >= 8) and (dice <= 9) then dy := 1;

        dice := roll(10);
        if (dice >= 0) and (dice <= 1) then dx := -2
        else if (dice >= 2) and (dice <= 5) then dx := -1
        else if (dice >= 6) and (dice <= 8) then dx := 0
        else if dice = 9 then dx := 1;
      end;

    btShootRight:
      begin
        dice := roll(10);
        if (dice >= 0) and (dice <= 1) then dy := -1
        else if (dice >= 2) and (dice <= 7) then dy := 0
        else if (dice >= 8) and (dice <= 9) then dy := 1;

        dice := roll(10);
        if (dice >= 0) and (dice <= 1) then dx := 2
        else if (dice >= 2) and (dice <= 5) then dx := 1
        else if (dice >= 6) and (dice <= 8) then dx := 0
        else if dice = 9 then dx := -1;
      end;

    btDying:
      begin
        dice := roll(10);
        if (dice >= 0) and (dice <= 1) then dy := -1
        else if (dice >= 2) and (dice <= 8) then dy := 0
        else if dice = 9 then dy := 1;

        dice := roll(15);
        if dice = 0 then dx := -3
        else if (dice >= 1) and (dice <= 2) then dx := -2
        else if (dice >= 3) and (dice <= 5) then dx := -1
        else if (dice >= 6) and (dice <= 8) then dx := 0
        else if (dice >= 9) and (dice <= 11) then dx := 1
        else if (dice >= 12) and (dice <= 13) then dx := 2
        else if dice = 14 then dx := 3;
      end;

    btDead:
      begin
        dice := roll(10);
        if (dice >= 0) and (dice <= 2) then dy := -1
        else if (dice >= 3) and (dice <= 6) then dy := 0
        else if (dice >= 7) and (dice <= 9) then dy := 1;
        dx := roll(3) - 1;
      end;
  end;

  returnDx := dx;
  returnDy := dy;
end;

function ChooseString(btype: TBranchType; life, dx, dy: Integer): String;
var
  t: TBranchType;
begin
  Result := '?';
  t := btype;
  if life < 4 then t := btDying;

  case t of
    btTrunk:
      begin
        if dy = 0 then Result := '/~'
        else if dx < 0 then Result := '\|'
        else if dx = 0 then Result := '/|\'
        else if dx > 0 then Result := '|/';
      end;
    btShootLeft:
      begin
        if dy > 0 then Result := '\'
        else if dy = 0 then Result := '\_'
        else if dx < 0 then Result := '\|'
        else if dx = 0 then Result := '/|'
        else if dx > 0 then Result := '/';
      end;
    btShootRight:
      begin
        if dy > 0 then Result := '/'
        else if dy = 0 then Result := '_/'
        else if dx < 0 then Result := '\|'
        else if dx = 0 then Result := '/|'
        else if dx > 0 then Result := '/';
      end;
    btDying, btDead:
      begin
        if conf.leavesSize > 0 then
          Result := conf.leaves[roll(conf.leavesSize)]
        else
          Result := '&';
      end;
  end;
end;

{ non-blocking check: returns True if the run should stop now }
function CheckKeyPress: Boolean;
var
  ch: Char;
begin
  Result := False;
  if KeyPressed then
  begin
    ch := ReadKey;
    if (conf.screensaver = 1) or (ch = 'q') or (ch = 'Q') then
      Result := True;
  end;
end;

procedure Branch(x, y: Integer; btype: TBranchType; life: Integer);
var
  dx, dy, age, shootCooldown: Integer;
  shootLife: Integer;
  branchStr: String;
begin
  Inc(myCounters.branches);
  dx := 0;
  dy := 0;
  age := 0;
  shootCooldown := conf.multiplier;

  while life > 0 do
  begin
    if CheckKeyPress then
    begin
      NormVideo;
      CursorOn;
      if conf.save = 1 then
        SaveToFile(conf.saveFile, conf.seed, myCounters.branches);
      Halt(0);
    end;

    Dec(life);
    age := conf.lifeStart - life;

    SetDeltas(btype, life, age, conf.multiplier, dx, dy);

    if (dy > 0) and (y > (treeRows - 1)) then Dec(dy);

    { near-dead branch should branch into a lot of leaves }
    if life < 3 then
      Branch(x, y, btDead, life)

    { dying trunk should branch into a lot of leaves }
    else if (btype = btTrunk) and (life < (conf.multiplier + 2)) then
      Branch(x, y, btDying, life)

    { dying shoot should branch into a lot of leaves }
    else if ((btype = btShootLeft) or (btype = btShootRight)) and
            (life < (conf.multiplier + 2)) then
      Branch(x, y, btDying, life)

    { trunks re-branch either randomly, or every <multiplier> steps }
    else if (btype = btTrunk) and
            ((roll(3) = 0) or ((conf.multiplier <> 0) and (life mod conf.multiplier = 0))) then
    begin
      if (roll(8) = 0) and (life > 7) then
      begin
        shootCooldown := conf.multiplier * 2;
        Branch(x, y, btTrunk, life + (roll(5) - 2));
      end
      else if shootCooldown <= 0 then
      begin
        shootCooldown := conf.multiplier * 2;
        shootLife := life + conf.multiplier;

        Inc(myCounters.shoots);
        Inc(myCounters.shootCounter);

        if (myCounters.shootCounter mod 2) = 0 then
          Branch(x, y, btShootLeft, shootLife)
        else
          Branch(x, y, btShootRight, shootLife);
      end;
    end;
    Dec(shootCooldown);

    x := x + dx;
    y := y + dy;

    ChooseColor(btype);
    branchStr := ChooseString(btype, life, dx, dy);
    PlotChar(x, y, branchStr);

    if conf.live = 1 then
      Delay(conf.timeStepMs);
  end;
end;

procedure GrowTree;
begin
  myCounters.branches := 0;
  myCounters.shoots := 0;
  myCounters.shootCounter := Random(MaxInt);

  Branch(totalCols div 2, treeRows, btTrunk, conf.lifeStart);
end;

{ ------------------------------------------------------------------ }
{ setup / teardown                                                    }
{ ------------------------------------------------------------------ }

procedure InitScreen;
var
  baseHeight: Integer;
begin
  ClrScr;
  CursorOff;

  totalCols := WindMaxX + 1;
  totalRows := WindMaxY + 1;
  if totalCols > 255 then totalCols := 255;
  if totalRows > 255 then totalRows := 255;
  if totalCols < 10 then totalCols := 10;
  if totalRows < 10 then totalRows := 10;

  baseHeight := 0;
  case conf.baseType of
    1: baseHeight := 4;
    2: baseHeight := 3;
  end;

  treeRows := totalRows - baseHeight;
  if treeRows < 1 then treeRows := 1;

  DrawBase(conf.baseType);
  DrawMessage(conf);
end;

procedure FinishScreen;
begin
  NormVideo;
  CursorOn;
  if conf.save = 1 then
    SaveToFile(conf.saveFile, conf.seed, myCounters.branches);
end;

procedure PrintHelp;
begin
  WriteLn('Usage: cbonsai [OPTION]...');
  WriteLn;
  WriteLn('cbonsai is a beautifully random bonsai tree generator.');
  WriteLn('This build uses the simple cross-platform `crt` console unit.');
  WriteLn;
  WriteLn('Options:');
  WriteLn('  -l, --live             live mode: show each step of growth');
  WriteLn('  -t, --time=SECS        in live mode, wait SECS between');
  WriteLn('                           steps of growth [default: 0.03]');
  WriteLn('  -i, --infinite         infinite mode: keep growing trees');
  WriteLn('  -w, --wait=SECS        in infinite mode, wait SECS between trees [default: 4.00]');
  WriteLn('  -S, --screensaver      screensaver mode; equivalent to -li and');
  WriteLn('                           quit on any keypress');
  WriteLn('  -m, --message=STR      attach message next to the tree');
  WriteLn('  -b, --base=INT         ascii-art plant base to use, 0 is none');
  WriteLn('  -c, --leaf=LIST        comma-delimited strings randomly chosen for leaves [default: &]');
  WriteLn('  -k, --color=LIST       4 comma-delimited color indices (0-15) for');
  WriteLn('                           dark leaves, dark wood, light leaves, light wood [default: 2,3,10,11]');
  WriteLn('  -M, --multiplier=INT   branch multiplier; higher -> more branching [default: 5]');
  WriteLn('  -L, --life=INT         life; higher -> more growth [default: 32]');
  WriteLn('  -p, --print            leave the finished tree on screen and exit immediately');
  WriteLn('  -s, --seed=INT         seed random number generator');
  WriteLn('  -W, --save=FILE        save progress to file');
  WriteLn('  -C, --load=FILE        load progress from file');
  WriteLn('  -v, --verbose          increase output verbosity (currently unused in this build)');
  WriteLn('  -h, --help             show help');
end;

{ ------------------------------------------------------------------ }
{ command-line parsing                                                }
{ ------------------------------------------------------------------ }

function ParseFloatArg(const s: String; out ok: Boolean): Double;
var
  v: Double;
  code: Integer;
begin
  Val(s, v, code);
  ok := (code = 0);
  Result := v;
end;

procedure ParseIntColor(const s: String; out v: Integer; out ok: Boolean);
var
  code: Integer;
begin
  Val(s, v, code);
  ok := (code = 0);
end;

function TakesArg(opt: Char): Boolean;
begin
  Result := Pos(opt, 'twmbckMLsWC') > 0;
end;

procedure ParseArgs(var c: TConfig);
var
  i: Integer;
  arg, optArg: String;
  opt: Char;
  ok: Boolean;
  fVal: Double;
  leavesInput, colorsInput: String;
  parts: TStrArr;
  j, parsedColor: Integer;
begin
  leavesInput := '&';
  colorsInput := '2,3,10,11';

  i := 1;
  while i <= ParamCount do
  begin
    arg := ParamStr(i);
    optArg := '';
    opt := #0;

    if (Length(arg) >= 2) and (arg[1] = '-') and (arg[2] = '-') then
    begin
      arg := Copy(arg, 3, Length(arg));
      if Pos('=', arg) > 0 then
      begin
        optArg := Copy(arg, Pos('=', arg) + 1, Length(arg));
        arg := Copy(arg, 1, Pos('=', arg) - 1);
      end;

      if arg = 'live' then opt := 'l'
      else if arg = 'time' then opt := 't'
      else if arg = 'infinite' then opt := 'i'
      else if arg = 'wait' then opt := 'w'
      else if arg = 'screensaver' then opt := 'S'
      else if arg = 'message' then opt := 'm'
      else if arg = 'base' then opt := 'b'
      else if arg = 'leaf' then opt := 'c'
      else if arg = 'color' then opt := 'k'
      else if arg = 'multiplier' then opt := 'M'
      else if arg = 'life' then opt := 'L'
      else if arg = 'print' then opt := 'p'
      else if arg = 'seed' then opt := 's'
      else if arg = 'save' then opt := 'W'
      else if arg = 'load' then opt := 'C'
      else if arg = 'verbose' then opt := 'v'
      else if arg = 'help' then opt := 'h'
      else
      begin
        WriteLn('error: invalid option -- ''', arg, '''');
        PrintHelp;
        Halt(0);
      end;

      if TakesArg(opt) and (optArg = '') then
        if (i < ParamCount) and ((ParamStr(i + 1) = '') or (ParamStr(i + 1)[1] <> '-')) then
        begin
          Inc(i);
          optArg := ParamStr(i);
        end;
    end
    else if (Length(arg) >= 2) and (arg[1] = '-') then
    begin
      opt := arg[2];
      if TakesArg(opt) then
      begin
        if Length(arg) > 2 then
          optArg := Copy(arg, 3, Length(arg))
        else if i < ParamCount then
        begin
          Inc(i);
          optArg := ParamStr(i);
        end;
      end;
    end
    else
    begin
      WriteLn('error: invalid argument -- ''', arg, '''');
      PrintHelp;
      Halt(0);
    end;

    case opt of
      'l': c.live := 1;
      't':
        begin
          fVal := ParseFloatArg(optArg, ok);
          if ok and (fVal <> 0) then c.timeStepMs := Round(fVal * 1000)
          else begin WriteLn('error: invalid step time: ''', optArg, ''''); Halt(1); end;
          if c.timeStepMs < 0 then begin WriteLn('error: invalid step time: ''', optArg, ''''); Halt(1); end;
        end;
      'i': c.infinite := 1;
      'w':
        begin
          fVal := ParseFloatArg(optArg, ok);
          if ok and (fVal <> 0) then c.timeWaitMs := Round(fVal * 1000)
          else begin WriteLn('error: invalid wait time: ''', optArg, ''''); Halt(1); end;
          if c.timeWaitMs < 0 then begin WriteLn('error: invalid wait time: ''', optArg, ''''); Halt(1); end;
        end;
      'S':
        begin
          c.live := 1;
          c.infinite := 1;
          c.save := 1;
          c.load := 1;
          c.screensaver := 1;
        end;
      'm': c.message := optArg;
      'b':
        begin
          fVal := ParseFloatArg(optArg, ok);
          if ok then c.baseType := Trunc(fVal)
          else begin WriteLn('error: invalid base index: ''', optArg, ''''); Halt(1); end;
        end;
      'c': leavesInput := optArg;
      'k': colorsInput := optArg;
      'M':
        begin
          fVal := ParseFloatArg(optArg, ok);
          if ok and (fVal <> 0) then c.multiplier := Trunc(fVal)
          else begin WriteLn('error: invalid multiplier: ''', optArg, ''''); Halt(1); end;
          if c.multiplier < 0 then begin WriteLn('error: invalid multiplier: ''', optArg, ''''); Halt(1); end;
        end;
      'L':
        begin
          fVal := ParseFloatArg(optArg, ok);
          if ok and (fVal <> 0) then c.lifeStart := Trunc(fVal)
          else begin WriteLn('error: invalid initial life: ''', optArg, ''''); Halt(1); end;
          if c.lifeStart < 0 then begin WriteLn('error: invalid initial life: ''', optArg, ''''); Halt(1); end;
        end;
      'p': c.printTree := 1;
      's':
        begin
          fVal := ParseFloatArg(optArg, ok);
          if ok and (fVal <> 0) then c.seed := Trunc(fVal)
          else begin WriteLn('error: invalid seed: ''', optArg, ''''); Halt(1); end;
          if c.seed < 0 then begin WriteLn('error: invalid seed: ''', optArg, ''''); Halt(1); end;
        end;
      'W':
        begin
          if optArg <> '' then c.saveFile := optArg;
          c.save := 1;
        end;
      'C':
        begin
          if optArg <> '' then c.loadFile := optArg;
          c.load := 1;
        end;
      'v': Inc(c.verbosity);
      'h': begin PrintHelp; Halt(0); end;
    end;

    Inc(i);
  end;

  parts := SplitStr(leavesInput, ',');
  c.leavesSize := 0;
  for j := 0 to High(parts) do
    if c.leavesSize < 64 then
    begin
      c.leaves[c.leavesSize] := parts[j];
      Inc(c.leavesSize);
    end;

  parts := SplitStr(colorsInput, ',');
  if Length(parts) <> 4 then
  begin
    if Length(parts) < 4 then
      WriteLn('error: too few color indices provided')
    else
      WriteLn('error: too many color indices provided');
    Halt(1);
  end;

  for j := 0 to 3 do
  begin
    ParseIntColor(parts[j], parsedColor, ok);
    if (not ok) or (parsedColor < 0) then
    begin
      WriteLn('error: invalid color index: ''', parts[j], '''');
      Halt(1);
    end
    else
      c.colors[j] := parsedColor mod 16;  { crt only has 16 colors }
  end;
end;

{ ------------------------------------------------------------------ }
{ main                                                                }
{ ------------------------------------------------------------------ }

var
  waited: Integer;

begin
  conf.live := 0;
  conf.infinite := 0;
  conf.screensaver := 0;
  conf.printTree := 0;
  conf.verbosity := 0;
  conf.lifeStart := 32;
  conf.multiplier := 5;
  conf.baseType := 1;
  conf.seed := 0;
  conf.leavesSize := 0;
  conf.save := 0;
  conf.load := 0;
  conf.targetBranchCount := 0;

  conf.timeWaitMs := 4000;
  conf.timeStepMs := 30;

  conf.message := '';
  conf.colors[0] := 0; conf.colors[1] := 0; conf.colors[2] := 0; conf.colors[3] := 0;
  conf.saveFile := CreateDefaultCachePath;
  conf.loadFile := CreateDefaultCachePath;

  ParseArgs(conf);

  if conf.load = 1 then
    LoadFromFile(conf);

  if conf.seed = 0 then
  begin
    Randomize;
    conf.seed := RandSeed;
  end
  else
    RandSeed := conf.seed;

  repeat
    InitScreen;
    GrowTree;
    if conf.load = 1 then conf.targetBranchCount := 0;

    if conf.infinite = 1 then
    begin
      waited := 0;
      while waited < conf.timeWaitMs do
      begin
        if CheckKeyPress then
        begin
          FinishScreen;
          ClrScr;
          Halt(0);
        end;
        Delay(50);
        Inc(waited, 50);
      end;
      Randomize;
    end;
  until conf.infinite = 0;

  if conf.printTree = 1 then
    FinishScreen
  else
  begin
    ReadKey;
    FinishScreen;
    ClrScr;
  end;
end.
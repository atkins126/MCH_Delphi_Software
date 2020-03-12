unit Frame;




{==============================================================================
Frame
0.0.0.0
Date of Generation: 25/10/2019 07:49

This unit was generated by Coco/R for Delphi (www.tetzel.com)  Any code in
this file that you edit manually will be over-written when the file is
regenerated.
==============================================================================}

interface
uses  SysUtils,Classes,CocoBase,FrameTools,CRT,CocoDefs,AnsiStrings,mwStringHashList;



const
maxT = 10;
maxP = 11;
type
  SymbolSet = array[0..maxT div setsize] of TBitSet;

  EFrame = class(Exception);
  TFrame = class;

  TFrameScanner = class(TCocoRScanner)
  private
    FOwner : TFrame;
fHashList: TmwStringHashList;
function CharInIgnoreSet(const Ch : AnsiChar) : boolean;
procedure CheckLiteral(var Sym : integer);
function GetNextSymbolString: AnsiString;
    function Comment : boolean;
  protected
    procedure NextCh; override;
  public
    constructor Create;
destructor Destroy; override;

    procedure Get(var sym : integer); override; // Gets next symbol from source file

    property CurrentSymbol;
    property NextSymbol;
    property OnStatusUpdate;
    property Owner : TFrame read fOwner write fOwner;
    property ScannerError;
    property SrcStream;
  end;  { TFrameScanner }

  TFrame = class(TCocoRGrammar)
  private
    { strictly internal variables }
    symSet : array[0..0] of SymbolSet; // symSet[0] = allSyncSyms

    function GetBuildDate : TDateTime;
    function GetVersion : AnsiString;
    function GetVersionStr : AnsiString;
    procedure SetVersion(const Value : AnsiString);
    function _In(var s : SymbolSet; x : integer) : boolean;
    procedure InitSymSet;

    {Production methods}
    procedure _Other;
    procedure _UsesClause;
    procedure _CodePart;
    procedure _Section;
    procedure _Frame;

  private
    FStream : TFileStream;
    FFileName : AnsiString;
    FGrammarName : AnsiString;
    
    CurrentLine : integer;
    ModLine : AnsiString;
    PosDelta : integer;
    PosStart : integer;
    fTableHandler: TTableHandler; 
    fFrameTools : TFrameTools;

    procedure Clear;
    procedure InsertCode(CodeSection : AnsiString);
    procedure AddString(S : AnsiString; Col : integer);
    procedure StreamOther;
    procedure StreamModLine;
    procedure aStreamLn(const s : AnsiString);
    procedure aStreamLine(S : AnsiString); overload;
    procedure aStreamLine; overload;

  protected
    { Protected Declarations }
    procedure Get; override;
  public
    { Public Declarations }
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;

    function ErrorStr(const ErrorCode : integer; const Data : AnsiString) : AnsiString; override;
    procedure Execute; override;
    function GetScanner : TFrameScanner;
    procedure Parse;

    property ErrorList;
    property ListStream;
    property SourceStream;
    property Successful;
    property BuildDate : TDateTime read GetBuildDate;
    property VersionStr : AnsiString read GetVersionStr;

  public
    procedure Init;
    property Stream : TFileStream read FStream write FStream;
    property GrammarName : AnsiString read fGrammarName write fGrammarName;
    property FrameTools : TFrameTools read fFrameTools write fFrameTools;
    property TableHandler : TTableHandler read fTableHandler write fTableHandler;

  published
    property FileName : AnsiString read FFileName write FFileName;
  published
    { Published Declarations }
    property AfterGet;
    property AfterParse;
    property AfterGenList;
    property BeforeGenList;
    property BeforeParse;
    property ClearSourceStream;
    property GenListWhen;
    property SourceFileName;
property Version : AnsiString read GetVersion write SetVersion;

    property OnCustomError;
    property OnError;
    property OnFailure;
    property OnStatusUpdate;
    property OnSuccess;
  end; { TFrame }

implementation



const

  EOFSYMB = 0;  wordSym = 1;  _minus_minus_greaterSym = 2;
  _less_minus_minusSym = 3;  _slash_percentSym = 4;  USESSym = 5;
  _lparenINTERFACE_rparenSym = 6;  _lparenIMPLEMENTATION_rparenSym = 7;
  _commaSym = 8;  _percent_slashSym = 9;  NOSYMB = 10;
  CompilerDirectiveSym = 11;  _noSym = NOSYMB;   {error token code}

{ --------------------------------------------------------------------------- }
{ Arbitrary Code from ATG file }
procedure TFrame.Init;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  CurrentLine := 1;
  PosDelta := 0;       
  PosStart := 0;
  ModLine := '';
end;
                               
procedure TFrame.Clear;
begin
  if ModLine <> '' then
    aStreamLine(ModLine + '    ');
  Stream.Free;
  ModLine := '';
  CurrentLine := 1;
  PosDelta := 0;
  PosStart := 0;
end;

procedure TFrame.aStreamLn(const s : AnsiString);
begin
  if Length(S) > 0 then
    Stream.WriteBuffer(S[1], length(S));
end;

procedure TFrame.aStreamLine(S : AnsiString);
begin
  S := S + #13#10;
  aStreamLn(S);
end;

procedure TFrame.aStreamLine;
begin
  aStreamLine('');
end;

procedure TFrame.StreamModLine;
var
  i : integer;
begin
  if ModLine > '' then
    aStreamLine(ModLine);
  for i := CurrentLine to GetScanner.CurrentSymbol.Line - 2 do
    aStreamLine;
  CurrentLine := GetScanner.CurrentSymbol.Line;
  ModLine := '';
  PosDelta := 0;
end;

procedure TFrame.AddString(S : AnsiString; Col : integer);
var
  NewCol : integer;
begin              
  NewCol := Col - length(ModLine) - 2 - PosDelta;
  ModLine := ModLine + PadL(s,' ',NewCol + length(s));
end;

procedure TFrame.StreamOther;
begin
  if CurrentLine < 1 then
    CurrentLine := 1;
  if (CurrentLine <> GetScanner.CurrentSymbol.Line) then
    StreamModLine;
  AddString(LexString, GetScanner.CurrentSymbol.Col);
end;

procedure TFrame.InsertCode(CodeSection : AnsiString);
var
  s : AnsiString;
begin                                 
  S := '';                                  
  if CurrentLine <> GetScanner.CurrentSymbol.Line then
    StreamModLine;
  if LexName = 'GRAMMAR' then
    S := GrammarName
  else if LexName = 'SCANNER' then
    S := GrammarName + 'Scanner'    
  else if LexName = 'GRAMMARVERSION' then
    S := fFrameTools.GetGrammarVersion
  else if LexName = 'GRAMMARVERSIONLASTBUILD' then
    S := fFrameTools.GetGrammarVersionLastBuild
  else if LexName = 'GRAMMARVERSIONINFO' then
    S := fFrameTools.GetGrammarVersionInfo
  else if LexName = 'CONSOLE_VERSION' then
    fFrameTools.ConsoleVersion(Stream)
  else if LexName = 'VERSIONBTNDEC' then
    fFrameTools.VersionBtnDec(Stream)
  else if LexName = 'VERSIONBTN' then
    fFrameTools.VersionBtn(Stream)
  else if LexName = 'VERSIONBTNDFM' then
    fFrameTools.VersionBtnDfm(Stream)
  else if LexName = 'CONSTANTS' then
    fFrameTools.WriteConstants(Stream)
  else if LexName = 'DELPHIPRIVATE' then
  begin 
    if fTableHandler.PrivateDeclPos.TextPresent then
      aStreamLn('  private'#13#10'    ');
    fFrameTools.WriteSourcePart(Stream,fTableHandler.PrivateDeclPos,0);
  end 
  else if LexName = 'DELPHIPROTECTED' then
  begin
    if fTableHandler.ProtectedDeclPos.TextPresent then
      aStreamLn('  protected'#13#10'    ');
    fFrameTools.WriteSourcePart(Stream,fTableHandler.ProtectedDeclPos,0);
  end 
  else if LexName = 'DELPHIPUBLIC' then
  begin
    if fTableHandler.PublicDeclPos.TextPresent then
      aStreamLn('  public'#13#10'    ');
    fFrameTools.WriteSourcePart(Stream,fTableHandler.PublicDeclPos,0);
  end 
  else if LexName = 'DELPHIPUBLISHED' then
  begin
    if fTableHandler.PublishedDeclPos.TextPresent then
      aStreamLn('  published'#13#10'    ');
    fFrameTools.WriteSourcePart(Stream,fTableHandler.PublishedDeclPos,0);
  end 
  else if LexName = 'PRODUCTIONSDEC' then
    fFrameTools.WriteProductionsDec(Stream)      
  else if LexName = 'CONST' then
    fFrameTools.WriteConst(Stream)   
  else if LexName = 'ARBITRARYCODE' then 
  begin                                     
    fTableHandler.semDeclPos.TextPresent := true;
    fFrameTools.WriteSourcePart(Stream,fTableHandler.semDeclPos,0);
  end
  else if LexName = 'PRAGMAS' then
    fFrameTools.GenPragmaCode(Stream,0)  
  else if LexName = 'DELPHICONST' then
    fFrameTools.WriteSourcePart(Stream,fTableHandler.ConstDeclPos,0) 
  else if LexName = 'DELPHITYPE' then
    fFrameTools.WriteSourcePart(Stream,fTableHandler.TypeDeclPos,0) 
  else if LexName = 'DELPHICREATE' then
    fFrameTools.WriteSourcePart(Stream,fTableHandler.CreateDeclPos,0) 
  else if LexName = 'DELPHIDESTROY' then
    fFrameTools.WriteSourcePart(Stream,fTableHandler.DestroyDeclPos,0) 
  else if LexName = 'DELPHIERRORS' then
    fFrameTools.WriteSourcePart(Stream,fTableHandler.ErrorsDeclPos,0)
  else if LexName = 'VERSIONMETHODS' then
    fFrameTools.VersionMethods(Stream)
  else if LexName = 'VERSIONPROPERTIES' then
    fFrameTools.VersionProperties(Stream)
  else if LexName = 'VERSIONSTRING' then
    fFrameTools.VersionString(Stream)
  else if LexName = 'VERSIONIMPL' then
    fFrameTools.VersionImpl(Stream)
  else if LexName = 'WEAKMETHODS' then
    fFrameTools.WriteWeakMethods(Stream)
  else if LexName = 'WEAKIMPL' then
    fFrameTools.WriteWeakImpl(Stream)
  else if LexName = 'ANCESTOR' then
    fFrameTools.WriteAncestor(Stream)
  else if LexName = 'COMMENT' then
    fFrameTools.WriteComponentComment(Stream)
  else if LexName = 'LITERALSUPPORT' then
    fFrameTools.WriteLiterals(Stream)
  else if LexName = 'LITERALSUPPORTDECL' then
    fFrameTools.WriteLiteralSupportDecl(Stream)
  else if LexName = 'GETSYA' then
    fFrameTools.WriteCommentImplementation(Stream)
  else if LexName = 'GETSYB' then
    fFrameTools.WriteGetSyB(Stream)
  else if LexName = 'SCANNERINIT' then
    fFrameTools.WriteScannerInit(Stream)
  else if LexName = 'PRODUCTIONSBODY' then
    fFrameTools.WriteProductions(Stream)
  else if LexName = 'PARSEROOT' then
    fFrameTools.WriteParseRoot(Stream)
  else if LexName = 'PARSERINIT' then
    fFrameTools.WriteParserInit(Stream)
  else if LexName = 'MEMOTYPE' then
    S := fFrameTools.GetMemoType 
  else if LexName = 'MEMOPROPERTIES' then
    S := fFrameTools.GetMemoProperties
  else if LexName = 'SCANNERDESTROYDECL' then
    fFrameTools.WriteScannerDestroyDecl(Stream)  
  else if LexName = 'SCANNERDESTROYIMPL' then
    fFrameTools.WriteScannerDestroyImpl(Stream)
  else if LexName = 'SCANNERHASHFIELD' then
    fFrameTools.WriteScannerHashField(Stream)
  else if LexName = 'ONHOMOGRAPHEVENT' then
    fFrameTools.WriteOnHomographEvent(Stream)
  else if LexName = 'ONHOMOGRAPHPROPERTY' then
    fFrameTools.WriteOnHomographProperty(Stream)
  else if LexName = 'ONHOMOGRAPHFIELD' then
    fFrameTools.WriteOnHomographField(Stream)
  else if LexName = 'GRAMMARGETCOMMENT' then
    fFrameTools.WriteGrammarGetComment(Stream)
  else if LexName = 'SCANNERCOMMENTFIELD' then
    fFrameTools.WriteScannerCommentField(Stream)
  else if LexName = 'SCANNERCOMMENT' then
    fFrameTools.WriteScannerComment(Stream)
  else if LexName = 'GRAMMARCOMMENTFIELD' then
    fFrameTools.WriteGrammarCommentField(Stream)
  else if LexName = 'GRAMMARCOMMENTPROPERTY' then
    fFrameTools.WriteGrammarCommentProperty(Stream)
  else
    S := '-->' + LexName + '<--';
  
  if S > '' then
    AddString(S,PosStart);
  PosDelta := PosDelta + (Length(LexName) - length(S) + 6);
end;

(* End of Arbitrary Code *)



{ --------------------------------------------------------------------------- }
{ ---- implementation for TFrameScanner ---- }

procedure TFrameScanner.NextCh;
{ Return global variable ch }
begin
  LastInputCh := CurrInputCh;
  BufferPosition := BufferPosition + 1;
  CurrInputCh := CurrentCh(BufferPosition);
  if (CurrInputCh = _EL) OR ((CurrInputCh = _LF) AND (LastInputCh <> _EL)) then
  begin
    CurrLine := CurrLine + 1;
    if Assigned(OnStatusUpdate) then
      OnStatusUpdate(Owner, cstLineNum, '', CurrLine);
    StartOfLine := BufferPosition;
  end
end;  {NextCh}

function TFrameScanner.Comment : boolean;
var
  level : integer;
  StartCommentCh: AnsiChar;
  oldLineStart : longint;
  CommentStr : AnsiString;
begin
StartCommentCh := CurrInputCh;
  level := 1;
  oldLineStart := StartOfLine;
  CommentStr := CharAt(BufferPosition);
Result := false;
if (CurrInputCh = '/') then
  begin
NextCh;
  CommentStr := CommentStr + CharAt(BufferPosition);
if (CurrInputCh = '*') then
  begin
NextCh;
  CommentStr := CommentStr + CharAt(BufferPosition);
{GenBody}
while true do
begin
if (CurrInputCh = '*') then
begin
NextCh;
CommentStr := CommentStr + CharAt(BufferPosition);
if (CurrInputCh = '/') then
begin
level := level -  1;
NextCh;
CommentStr := CommentStr + CharAt(BufferPosition);
if level = 0 then
begin
  Result := true;
  Exit;
end;
end
end
else if CurrInputCh = _EF then
begin
  Result := false;
  Exit;
end
else
begin
  NextCh;
  CommentStr := CommentStr + CharAt(BufferPosition);
end;
end; { WHILE TRUE }
{/GenBody}
end
else
begin
if (CurrInputCh = _CR) OR (CurrInputCh = _LF) then
begin
CurrLine := CurrLine - 1;
StartOfLine := oldLineStart
end;
BufferPosition := BufferPosition - 1;
CurrInputCh := StartCommentCh;
Result := false;
end;
end;
end;  { Comment }

function TFrameScanner.CharInIgnoreSet(const Ch : AnsiChar) : boolean;
begin
Result := (Ch = ' ')    OR
((CurrInputCh >= AnsiChar(1)) AND (CurrInputCh <= AnsiChar(31)));
end; {CharInIgnoreSet}

function TFrameScanner.GetNextSymbolString: AnsiString;
var
  i: integer;
  q: int64;
begin
  Result := '';
  i := 1;
  q := bpCurrToken;
  while i <= NextSymbol.Len do
  begin
    Result := Result + CurrentCh(q);
    inc(q);
    inc(i);
  end;
end; {GetNextSymbolString}

procedure TFrameScanner.CheckLiteral(var Sym : integer);
var
  SymId : integer;
  DefaultSymId : integer;
  aToken : AnsiString;
begin
  aToken := GetNextSymbolString;
  if fHashList.Hash(aToken, SymId, DefaultSymId) then
  begin
      sym := SymId;
  end;
end; {CheckLiteral}


procedure TFrameScanner.Get(var sym : integer);
var
  state : integer;
  label __start_get;
 begin   {Get}
__start_get:
while CharInIgnoreSet(CurrInputCh) do
  NextCh;
if ((CurrInputCh = '/')) AND Comment then goto __start_get;

  LastSymbol.Assign(CurrentSymbol);
  CurrentSymbol.Assign(NextSymbol);

  NextSymbol.Pos := BufferPosition;
  NextSymbol.Col := BufferPosition - StartOfLine;
  NextSymbol.Line := CurrLine;
  NextSymbol.Len := 0;

  ContextLen := 0;
  state := StartState[ORD(CurrInputCh)];
  bpCurrToken := BufferPosition;
  while true do
  begin
    NextCh;
    NextSymbol.Len := NextSymbol.Len + 1;
    if BufferPosition > SrcStream.Size then
    begin
      sym := EOFSYMB;
      CurrInputCh := _EF;
      BufferPosition := BufferPosition - 1;
      exit
    end;
    case state of
   1: if ((CurrInputCh >= 'A') AND (CurrInputCh <= 'Z') OR
(CurrInputCh = '_')) then
begin
 
end
else
begin
sym := wordSym;
CheckLiteral(sym);
exit;
end;
   2: if (CurrInputCh = '$') then
begin
state := 3; 
end
else
begin
  sym := _noSym;
exit;
end;
   3: if NOT ((CurrInputCh = AnsiChar(13))) then
begin
state := 4; 
end
else
begin
  sym := _noSym;
exit;
end;
   4: if (CurrInputCh = ']') then
begin
state := 5; 
end
else
begin
  sym := _noSym;
exit;
end;
   5: begin
sym := CompilerDirectiveSym;
exit;
end;
   6: if (CurrInputCh = '-') then
begin
state := 7; 
end
else
begin
  sym := _noSym;
exit;
end;
   7: if (CurrInputCh = '>') then
begin
state := 8; 
end
else
begin
  sym := _noSym;
exit;
end;
   8: begin
sym := _minus_minus_greaterSym;
exit;
end;
   9: if (CurrInputCh = '-') then
begin
state := 10; 
end
else
begin
  sym := _noSym;
exit;
end;
  10: if (CurrInputCh = '-') then
begin
state := 11; 
end
else
begin
  sym := _noSym;
exit;
end;
  11: begin
sym := _less_minus_minusSym;
exit;
end;
  12: if (CurrInputCh = '%') then
begin
state := 13; 
end
else
begin
  sym := _noSym;
exit;
end;
  13: begin
sym := _slash_percentSym;
exit;
end;
  14: if (CurrInputCh = 'I') then
begin
state := 15; 
end
else
begin
  sym := _noSym;
exit;
end;
  15: if (CurrInputCh = 'N') then
begin
state := 16; 
end
else if (CurrInputCh = 'M') then
begin
state := 25; 
end
else
begin
  sym := _noSym;
exit;
end;
  16: if (CurrInputCh = 'T') then
begin
state := 17; 
end
else
begin
  sym := _noSym;
exit;
end;
  17: if (CurrInputCh = 'E') then
begin
state := 18; 
end
else
begin
  sym := _noSym;
exit;
end;
  18: if (CurrInputCh = 'R') then
begin
state := 19; 
end
else
begin
  sym := _noSym;
exit;
end;
  19: if (CurrInputCh = 'F') then
begin
state := 20; 
end
else
begin
  sym := _noSym;
exit;
end;
  20: if (CurrInputCh = 'A') then
begin
state := 21; 
end
else
begin
  sym := _noSym;
exit;
end;
  21: if (CurrInputCh = 'C') then
begin
state := 22; 
end
else
begin
  sym := _noSym;
exit;
end;
  22: if (CurrInputCh = 'E') then
begin
state := 23; 
end
else
begin
  sym := _noSym;
exit;
end;
  23: if (CurrInputCh = ')') then
begin
state := 24; 
end
else
begin
  sym := _noSym;
exit;
end;
  24: begin
sym := _lparenINTERFACE_rparenSym;
exit;
end;
  25: if (CurrInputCh = 'P') then
begin
state := 26; 
end
else
begin
  sym := _noSym;
exit;
end;
  26: if (CurrInputCh = 'L') then
begin
state := 27; 
end
else
begin
  sym := _noSym;
exit;
end;
  27: if (CurrInputCh = 'E') then
begin
state := 28; 
end
else
begin
  sym := _noSym;
exit;
end;
  28: if (CurrInputCh = 'M') then
begin
state := 29; 
end
else
begin
  sym := _noSym;
exit;
end;
  29: if (CurrInputCh = 'E') then
begin
state := 30; 
end
else
begin
  sym := _noSym;
exit;
end;
  30: if (CurrInputCh = 'N') then
begin
state := 31; 
end
else
begin
  sym := _noSym;
exit;
end;
  31: if (CurrInputCh = 'T') then
begin
state := 32; 
end
else
begin
  sym := _noSym;
exit;
end;
  32: if (CurrInputCh = 'A') then
begin
state := 33; 
end
else
begin
  sym := _noSym;
exit;
end;
  33: if (CurrInputCh = 'T') then
begin
state := 34; 
end
else
begin
  sym := _noSym;
exit;
end;
  34: if (CurrInputCh = 'I') then
begin
state := 35; 
end
else
begin
  sym := _noSym;
exit;
end;
  35: if (CurrInputCh = 'O') then
begin
state := 36; 
end
else
begin
  sym := _noSym;
exit;
end;
  36: if (CurrInputCh = 'N') then
begin
state := 37; 
end
else
begin
  sym := _noSym;
exit;
end;
  37: if (CurrInputCh = ')') then
begin
state := 38; 
end
else
begin
  sym := _noSym;
exit;
end;
  38: begin
sym := _lparenIMPLEMENTATION_rparenSym;
exit;
end;
  39: begin
sym := _commaSym;
exit;
end;
  40: if (CurrInputCh = '/') then
begin
state := 41; 
end
else
begin
  sym := _noSym;
exit;
end;
  41: begin
sym := _percent_slashSym;
exit;
end;
  42: begin
sym := EOFSYMB;
CurrInputCh := chNull;
BufferPosition := BufferPosition - 1;
exit
end;
    else
      begin
        sym := _noSym;
        EXIT;          // NextCh already done
      end;
    end;
  end;
end;  {Get}

constructor TFrameScanner.Create;
begin
  inherited;
fHashList := TmwStringHashList.Create(ITinyHash, HashSecondaryOne, SameText);
fHashList.AddString('USES', USESSym, USESSym);
CurrentCh := CapChAt;
fStartState[  0] := 42; fStartState[  1] := 43; fStartState[  2] := 43; fStartState[  3] := 43; 
fStartState[  4] := 43; fStartState[  5] := 43; fStartState[  6] := 43; fStartState[  7] := 43; 
fStartState[  8] := 43; fStartState[  9] := 43; fStartState[ 10] := 43; fStartState[ 11] := 43; 
fStartState[ 12] := 43; fStartState[ 13] := 43; fStartState[ 14] := 43; fStartState[ 15] := 43; 
fStartState[ 16] := 43; fStartState[ 17] := 43; fStartState[ 18] := 43; fStartState[ 19] := 43; 
fStartState[ 20] := 43; fStartState[ 21] := 43; fStartState[ 22] := 43; fStartState[ 23] := 43; 
fStartState[ 24] := 43; fStartState[ 25] := 43; fStartState[ 26] := 43; fStartState[ 27] := 43; 
fStartState[ 28] := 43; fStartState[ 29] := 43; fStartState[ 30] := 43; fStartState[ 31] := 43; 
fStartState[ 32] := 43; fStartState[ 33] := 43; fStartState[ 34] := 43; fStartState[ 35] := 43; 
fStartState[ 36] := 43; fStartState[ 37] := 40; fStartState[ 38] := 43; fStartState[ 39] := 43; 
fStartState[ 40] := 14; fStartState[ 41] := 43; fStartState[ 42] := 43; fStartState[ 43] := 43; 
fStartState[ 44] := 39; fStartState[ 45] :=  6; fStartState[ 46] := 43; fStartState[ 47] := 12; 
fStartState[ 48] := 43; fStartState[ 49] := 43; fStartState[ 50] := 43; fStartState[ 51] := 43; 
fStartState[ 52] := 43; fStartState[ 53] := 43; fStartState[ 54] := 43; fStartState[ 55] := 43; 
fStartState[ 56] := 43; fStartState[ 57] := 43; fStartState[ 58] := 43; fStartState[ 59] := 43; 
fStartState[ 60] :=  9; fStartState[ 61] := 43; fStartState[ 62] := 43; fStartState[ 63] := 43; 
fStartState[ 64] := 43; fStartState[ 65] :=  1; fStartState[ 66] :=  1; fStartState[ 67] :=  1; 
fStartState[ 68] :=  1; fStartState[ 69] :=  1; fStartState[ 70] :=  1; fStartState[ 71] :=  1; 
fStartState[ 72] :=  1; fStartState[ 73] :=  1; fStartState[ 74] :=  1; fStartState[ 75] :=  1; 
fStartState[ 76] :=  1; fStartState[ 77] :=  1; fStartState[ 78] :=  1; fStartState[ 79] :=  1; 
fStartState[ 80] :=  1; fStartState[ 81] :=  1; fStartState[ 82] :=  1; fStartState[ 83] :=  1; 
fStartState[ 84] :=  1; fStartState[ 85] :=  1; fStartState[ 86] :=  1; fStartState[ 87] :=  1; 
fStartState[ 88] :=  1; fStartState[ 89] :=  1; fStartState[ 90] :=  1; fStartState[ 91] :=  2; 
fStartState[ 92] := 43; fStartState[ 93] := 43; fStartState[ 94] := 43; fStartState[ 95] :=  1; 
fStartState[ 96] := 43; fStartState[ 97] := 43; fStartState[ 98] := 43; fStartState[ 99] := 43; 
fStartState[100] := 43; fStartState[101] := 43; fStartState[102] := 43; fStartState[103] := 43; 
fStartState[104] := 43; fStartState[105] := 43; fStartState[106] := 43; fStartState[107] := 43; 
fStartState[108] := 43; fStartState[109] := 43; fStartState[110] := 43; fStartState[111] := 43; 
fStartState[112] := 43; fStartState[113] := 43; fStartState[114] := 43; fStartState[115] := 43; 
fStartState[116] := 43; fStartState[117] := 43; fStartState[118] := 43; fStartState[119] := 43; 
fStartState[120] := 43; fStartState[121] := 43; fStartState[122] := 43; fStartState[123] := 43; 
fStartState[124] := 43; fStartState[125] := 43; fStartState[126] := 43; fStartState[127] := 43; 
fStartState[128] := 43; fStartState[129] := 43; fStartState[130] := 43; fStartState[131] := 43; 
fStartState[132] := 43; fStartState[133] := 43; fStartState[134] := 43; fStartState[135] := 43; 
fStartState[136] := 43; fStartState[137] := 43; fStartState[138] := 43; fStartState[139] := 43; 
fStartState[140] := 43; fStartState[141] := 43; fStartState[142] := 43; fStartState[143] := 43; 
fStartState[144] := 43; fStartState[145] := 43; fStartState[146] := 43; fStartState[147] := 43; 
fStartState[148] := 43; fStartState[149] := 43; fStartState[150] := 43; fStartState[151] := 43; 
fStartState[152] := 43; fStartState[153] := 43; fStartState[154] := 43; fStartState[155] := 43; 
fStartState[156] := 43; fStartState[157] := 43; fStartState[158] := 43; fStartState[159] := 43; 
fStartState[160] := 43; fStartState[161] := 43; fStartState[162] := 43; fStartState[163] := 43; 
fStartState[164] := 43; fStartState[165] := 43; fStartState[166] := 43; fStartState[167] := 43; 
fStartState[168] := 43; fStartState[169] := 43; fStartState[170] := 43; fStartState[171] := 43; 
fStartState[172] := 43; fStartState[173] := 43; fStartState[174] := 43; fStartState[175] := 43; 
fStartState[176] := 43; fStartState[177] := 43; fStartState[178] := 43; fStartState[179] := 43; 
fStartState[180] := 43; fStartState[181] := 43; fStartState[182] := 43; fStartState[183] := 43; 
fStartState[184] := 43; fStartState[185] := 43; fStartState[186] := 43; fStartState[187] := 43; 
fStartState[188] := 43; fStartState[189] := 43; fStartState[190] := 43; fStartState[191] := 43; 
fStartState[192] := 43; fStartState[193] := 43; fStartState[194] := 43; fStartState[195] := 43; 
fStartState[196] := 43; fStartState[197] := 43; fStartState[198] := 43; fStartState[199] := 43; 
fStartState[200] := 43; fStartState[201] := 43; fStartState[202] := 43; fStartState[203] := 43; 
fStartState[204] := 43; fStartState[205] := 43; fStartState[206] := 43; fStartState[207] := 43; 
fStartState[208] := 43; fStartState[209] := 43; fStartState[210] := 43; fStartState[211] := 43; 
fStartState[212] := 43; fStartState[213] := 43; fStartState[214] := 43; fStartState[215] := 43; 
fStartState[216] := 43; fStartState[217] := 43; fStartState[218] := 43; fStartState[219] := 43; 
fStartState[220] := 43; fStartState[221] := 43; fStartState[222] := 43; fStartState[223] := 43; 
fStartState[224] := 43; fStartState[225] := 43; fStartState[226] := 43; fStartState[227] := 43; 
fStartState[228] := 43; fStartState[229] := 43; fStartState[230] := 43; fStartState[231] := 43; 
fStartState[232] := 43; fStartState[233] := 43; fStartState[234] := 43; fStartState[235] := 43; 
fStartState[236] := 43; fStartState[237] := 43; fStartState[238] := 43; fStartState[239] := 43; 
fStartState[240] := 43; fStartState[241] := 43; fStartState[242] := 43; fStartState[243] := 43; 
fStartState[244] := 43; fStartState[245] := 43; fStartState[246] := 43; fStartState[247] := 43; 
fStartState[248] := 43; fStartState[249] := 43; fStartState[250] := 43; fStartState[251] := 43; 
fStartState[252] := 43; fStartState[253] := 43; fStartState[254] := 43; fStartState[255] := 43; 
end; {Create}

destructor TFrameScanner.Destroy;
begin
  fHashList.Free;
  fHashList := NIL;
  inherited;
end;

{ --------------------------------------------------------------------------- }
{ ---- implementation for TFrame ---- }

constructor TFrame.Create(AOwner : TComponent);
begin
  inherited;
  Scanner := TFrameScanner.Create;
  GetScanner.Owner := self;
  InitSymSet;
end; {Create}

destructor TFrame.Destroy;
begin
  Scanner.Free;
  inherited;
end; {Destroy}

function TFrame.ErrorStr(const ErrorCode : integer; const Data : AnsiString) : AnsiString;
begin
  case ErrorCode of
       0 : Result := 'EOF expected';
   1 : Result := 'word expected';
   2 : Result := '"-->" expected';
   3 : Result := '"<--" expected';
   4 : Result := '"/%" expected';
   5 : Result := '"USES" expected';
   6 : Result := '"(INTERFACE)" expected';
   7 : Result := '"(IMPLEMENTATION)" expected';
   8 : Result := '"," expected';
   9 : Result := '"%/" expected';
  10 : Result := 'not expected';
  11 : Result := 'invalid UsesClause';
  12 : Result := 'invalid Section';

  else
    if Assigned(OnCustomError) then
      Result := OnCustomError(Self, ErrorCode, Data)
    else
    begin
      Result := AnsiString('Error: ' + AnsiString(IntToStr(ErrorCode)));
      if Trim(Data) > '' then
        Result := Result + ' (' + Data + ')';
    end;
  end;  {case nr}
end; {ErrorStr}

procedure TFrame.Execute;
begin
  ClearErrors;
  ListStream.Clear;
  Extra := 1;
  StreamPartRead := -1;

  { if there is a file name then load the file }
  if Trim(SourceFileName) <> '' then
  begin
    GetScanner.SrcStream.Clear;
    GetScanner.SrcStream.LoadFromFile(SourceFileName);
  end;

  { install error reporting procedure }
  GetScanner.ScannerError := StoreError;

  { instigate the compilation }
  DoBeforeParse;
  Parse;
  DoAfterParse;

  { generate the source listing to the ListStream }
  if (GenListWhen = glAlways) OR ((GenListWhen = glOnError) AND (ErrorList.Count > 0)) then
    GenerateListing;
  if ClearSourceStream then
    GetScanner.SrcStream.Clear;
  ListStream.Position := 0;  // goto the beginning of the stream
  if Successful AND Assigned(OnSuccess) then
    OnSuccess(Self);
  if (NOT Successful) AND Assigned(OnFailure) then
    OnFailure(Self, ErrorList.Count);
end;  {Execute}

procedure TFrame.Get;
begin
  repeat


    GetScanner.Get(fCurrentInputSymbol);
    if fCurrentInputSymbol <= maxT then
      errDist := errDist + 1
    else
    begin
case fCurrentInputSymbol of
  CompilerDirectiveSym: begin 
 end;
end;
GetScanner.NextSymbol.Pos := GetScanner.CurrentSymbol.Pos;
GetScanner.NextSymbol.Col := GetScanner.CurrentSymbol.Col;
GetScanner.NextSymbol.Line := GetScanner.CurrentSymbol.Line;
GetScanner.NextSymbol.Len := GetScanner.CurrentSymbol.Len;
    end;
  until fCurrentInputSymbol <= maxT;
  if Assigned(AfterGet) then
    AfterGet(Self, fCurrentInputSymbol);
end;  {Get}

function TFrame.GetScanner : TFrameScanner;
begin
  Result := Scanner AS TFrameScanner;
end; {GetScanner}

function TFrame._In(var s : SymbolSet; x : integer) : boolean;
begin
  _In := x mod setsize in s[x div setsize];
end;  {_In}

procedure TFrame._Other;begin
Get;
StreamOther;
end;

procedure TFrame._UsesClause;var
   isInterface  :  boolean;
   StrList  :  TStringList;
   i  :  integer;
   UsesStr  :  AnsiString;
begin
Expect(_slash_percentSym);
UsesStr  :=  '';
isInterface  :=  false;
Expect(USESSym);
if (fCurrentInputSymbol = _lparenINTERFACE_rparenSym) then begin
Get;
isInterface  :=  true;
end else if (fCurrentInputSymbol = _lparenIMPLEMENTATION_rparenSym) then begin
Get;
isInterface  :=  false;
end else begin SynError(11);
end;
if (fCurrentInputSymbol = wordSym) then begin
Get;
UsesStr  :=  UsesStr  +  LexString;
while (fCurrentInputSymbol = _commaSym) do begin
Get;
UsesStr  :=  UsesStr  +  LexString;
Expect(wordSym);
UsesStr  :=  UsesStr  +  LexString;
end;
end;
Expect(_percent_slashSym);
if  isInterface  then
   StrList  :=  fTableHandler.InterfaceUses
else
   StrList  :=  fTableHandler.ImplementationUses;
for  i  :=  0  to  StrList.Count  -  1  do
begin
   if  i  =  0  then
   begin
     if  Trim(UsesStr)  >  ''  then
       UsesStr  :=  UsesStr  +  ','  +  StrList[i]
     else
       UsesStr  :=  StrList[i];
   end
   else
     UsesStr  :=  UsesStr  +  ','  +  StrList[i];
end;
if  Trim(UsesStr)  >  ''  then
   ModLine  :=  ModLine  +  #13#10'uses  '  +  UsesStr  +  ';';
end;

procedure TFrame._CodePart;begin
Expect(_minus_minus_greaterSym);
PosStart  :=  GetScanner.CurrentSymbol.Col;
Expect(wordSym);
InsertCode(LexName);
Expect(_less_minus_minusSym);
end;

procedure TFrame._Section;begin
if (fCurrentInputSymbol = _minus_minus_greaterSym) then begin
_CodePart;
end else if (fCurrentInputSymbol = _slash_percentSym) then begin
_UsesClause;
end else if (fCurrentInputSymbol < 16) { prevent range error } AND
 (fCurrentInputSymbol IN [wordSym, _minus_minus_greaterSym, _less_minus_minusSym, 
                    _slash_percentSym, USESSym, _lparenINTERFACE_rparenSym, 
                    _lparenIMPLEMENTATION_rparenSym, _commaSym, 
                    _percent_slashSym, NOSYMB])  then begin
_Other;
end else begin SynError(12);
end;
end;

procedure TFrame._Frame;begin
_Section;
while (fCurrentInputSymbol < 16) { prevent range error } AND
 (fCurrentInputSymbol IN [wordSym, _minus_minus_greaterSym, _less_minus_minusSym, 
                    _slash_percentSym, USESSym, _lparenINTERFACE_rparenSym, 
                    _lparenIMPLEMENTATION_rparenSym, _commaSym, 
                    _percent_slashSym, NOSYMB])  do begin
_Section;
end;
fFrameTools.WriteCleanup(Stream,  GrammarName);
Clear;
end;

function TFrame.GetBuildDate : TDateTime;
const
  BDate = 0;
  Hour = 00;
  Min = 00;
begin
  Result := BDate + EncodeTime(Hour, Min, 0 ,0);
end;

function TFrame.GetVersion : AnsiString;
begin
  Result := '0.0.0.0';
end;

function TFrame.GetVersionStr : AnsiString;
begin
  Result := '0.0.0.0';
end;

procedure TFrame.SetVersion(const Value : AnsiString);
begin
  // This is a read only property. However, we want the value
  // to appear in the Object Inspector during design time.
end;

procedure TFrame.Parse;
begin
  errDist := minErrDist;
GetScanner._Reset;
Get;
_Frame;
end;  {Parse}

procedure TFrame.InitSymSet;
begin
symSet[ 0, 0] := [EOFSYMB];
end; {InitSymSet}

end { Frame }.    

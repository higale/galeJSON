unit memo_json_auto;

interface

uses
  System.Classes, System.SysUtils, FMX.Types,
  FMX.Memo, FMX.Memo.Types, FMX.Text;

type
  TMemoJsonAuto = class(TComponent)
  private
    FMemo: TMemo;
    FOldOnKeyDown: TKeyEvent;
    FOldOnKeyUp: TKeyEvent;
    procedure SetMemo(const AValue: TMemo);
    procedure OnKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure OnKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    function NextChar: string;
  public
    property Memo: TMemo read FMemo write SetMemo;
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TComponent; AMemo: TMemo); reintroduce; overload;
  end;

implementation

constructor TMemoJsonAuto.Create(AOwner: TComponent);
begin
  inherited;
  FMemo := nil;
  FOldOnKeyDown := nil;
  FOldOnKeyUp := nil;
end;

constructor TMemoJsonAuto.Create(AOwner: TComponent; AMemo: TMemo);
begin
  Create(AOwner);
  SetMemo(AMemo);
end;

procedure TMemoJsonAuto.SetMemo(const AValue: TMemo);
begin
  if FMemo = AValue then
    Exit;
  FMemo := AValue;
  FOldOnKeyDown := FMemo.OnKeyDown;
  FOldOnKeyUp := FMemo.OnKeyUp;
  FMemo.OnKeyDown := OnKeyDown;
  FMemo.OnKeyUp := OnKeyUp;
end;

procedure TMemoJsonAuto.OnKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = 13 then
  begin
    if not FMemo.IsUpdating then
      FMemo.BeginUpdate;
  end;
  if Assigned(FOldOnKeyDown) then
    FOldOnKeyDown(Sender, Key, KeyChar, Shift);
end;

procedure TMemoJsonAuto.OnKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
var
  strTmp: string;
  sp: string;
begin
  if (Key = 13) and (FMemo.CaretPosition.Pos = 0) then
  begin
    strTmp := FMemo.Lines[FMemo.CaretPosition.line - 1];
    if strTmp.StartsWith(' ') then
    begin
      for var i := 1 to strTmp.Length do
      begin
        if strTmp[i] <> ' ' then
        begin
          break;
        end;
        sp := sp + ' ';
      end;
      FMemo.InsertAfter(FMemo.CaretPosition, sp, [FMX.Text.TInsertOption.MoveCaret]);
    end;
    FMemo.EndUpdate;
  end
  else if KeyChar = '[' then
  begin
    if FMemo.Lines[FMemo.CaretPosition.line][FMemo.CaretPosition.Pos] = '[' then
    begin
      if NextChar <> ']' then
      begin
        FMemo.InsertAfter(FMemo.CaretPosition, ']', []);
      end;
    end;
  end
  else if KeyChar = '{' then
  begin
    if FMemo.Lines[FMemo.CaretPosition.line][FMemo.CaretPosition.Pos] = '{' then
    begin
      if NextChar <> '}' then
      begin
        FMemo.InsertAfter(FMemo.CaretPosition, '}', []);
      end;
    end;
  end
  else if KeyChar = '"' then
  begin
    if FMemo.Lines[FMemo.CaretPosition.line][FMemo.CaretPosition.Pos] = '"' then
      FMemo.InsertAfter(FMemo.CaretPosition, '"', []);
  end;
  if Assigned(FOldOnKeyUp) then
  begin
    FOldOnKeyUp(Sender, Key, KeyChar, Shift);
  end;
end;

function TMemoJsonAuto.NextChar: string;
begin
  Result := '';
  if FMemo.Lines[FMemo.CaretPosition.line].Length > FMemo.CaretPosition.Pos then
    Result := FMemo.Lines[FMemo.CaretPosition.line][FMemo.CaretPosition.Pos + 1];
end;

end.

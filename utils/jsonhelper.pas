unit jsonhelper;

interface

uses
  System.Generics.Collections, System.JSON, System.IOUtils, System.SysUtils;

type

  TJSONKind = (jkNone, jkObject, jkArray, jkString, jkNumber, jkBoolean, jkNull);

  TJSONPairHelper = class helper for TJSONPair
  public
    procedure Rename(ANewName: string);
  end;

  TJSONValueHelper = class helper for TJSONValue
  private
    function GetJsonKind: TJSONKind;
    function GetItemCount: Integer;
    function GetItem(const AIndex: Integer): TJSONAncestor;
  public
    property JsonKind: TJSONKind read GetJsonKind;
    property ItemCount: Integer read GetItemCount;
    property Items[const AIndex: Integer]: TJSONAncestor read GetItem; Default;
  public
    function IsObjectOrArray: boolean;
    class function LoadFromFile(const AFileName: string; AUseBool: boolean = False; ARaiseExc: boolean = False): TJSONValue;
  end;

  TJSONObjectHelper = class helper for TJSONObject
  public
    function DeletePair(AIndex: Integer): TJSONPair; overload;
    function DeletePair(const AItem: TJSONPair): TJSONPair; overload;
    procedure InsertPair(AIndex: NativeInt; const AValue: TJSONPair);
    procedure Move(ACurIndex, ANewIndex: NativeInt);
  end;

  TJSONArrayHelper = class helper for TJSONArray
  public
    function Delete(const AItem: TJSONValue): TJSONValue;
    function IndexOf(const AItem: TJSONValue): Integer;
    procedure SetValue(const AIndex: Integer; const AValue: TJSONValue);
    procedure InsertElement(AIndex: NativeInt; const AValue: TJSONValue);
    procedure Move(ACurIndex, ANewIndex: NativeInt);
  end;

function JSONFormat(AValue: TJSONValue; AIndentation: Integer; AEncodeBelow32: boolean; AEncodeAbove127: boolean): string;

implementation

function JSONToUniCode(const AStr: string; AEncodeBelow32: boolean = True; AEncodeAbove127: boolean = True): string;
var
  ch: char;
  I: Integer;
  UnicodeValue: Integer;
  Buff: array [0 .. 5] of char;
begin
  for I := 1 to AStr.Length do
  begin
    ch := AStr[I];
    case ch of
      #0 .. #7, #$b, #$e .. #31, #$0080 .. High(char):
        begin
          UnicodeValue := Ord(ch);
          if AEncodeBelow32 and (UnicodeValue < 32) or AEncodeAbove127 and (UnicodeValue > 127) then
          begin
            Buff[0] := '\';
            Buff[1] := 'u';
            Buff[2] := char(DecimalToHex((UnicodeValue and 61440) shr 12));
            Buff[3] := char(DecimalToHex((UnicodeValue and 3840) shr 8));
            Buff[4] := char(DecimalToHex((UnicodeValue and 240) shr 4));
            Buff[5] := char(DecimalToHex((UnicodeValue and 15)));
            Result := Result + Buff;
          end
          else
          begin
            Result := Result + ch;
          end;
        end
    else
      begin
        Result := Result + ch;
      end;
    end;
  end;
end;

function JsonToJsonStr(AValue: TJSONValue; AEncodeBelow32: boolean = True; AEncodeAbove127: boolean = True): string;
var
  Options: TJSONAncestor.TJSONOutputOptions;
begin
  Result := '';
  if AValue <> nil then
  begin
    Options := [];
    if AEncodeBelow32 then
      Include(Options, TJSONAncestor.TJSONOutputOption.EncodeBelow32);
    if AEncodeAbove127 then
      Include(Options, TJSONAncestor.TJSONOutputOption.EncodeAbove127);
    Result := AValue.ToJSON(Options);
  end;
end;

function JSONFormat(AValue: TJSONValue; AIndentation: Integer; AEncodeBelow32: boolean; AEncodeAbove127: boolean): string;
begin
  if AIndentation >= 0 then
  begin
    Result := '';
    if AValue <> nil then
    begin
      Result := AValue.Format(AIndentation);
      if AEncodeBelow32 or AEncodeAbove127 then
      begin
        Result := JSONToUniCode(Result, AEncodeBelow32, AEncodeAbove127);
      end;
    end;
  end
  else
  begin
    Result := JsonToJsonStr(AValue, AEncodeBelow32, AEncodeAbove127);
  end;
end;

procedure TJSONPairHelper.Rename(ANewName: string);
begin
  SetJsonString(TJSONString.Create(ANewName));
end;

////////////////////////////////////////////////////////////////////////////////
// TJSONValue

function TJSONValueHelper.GetJsonKind: TJSONKind;
begin
  if self = nil then
    Exit(jkNone);
  if ClassType = TJSONObject then
  begin
    Result := jkObject;
  end
  else if ClassType = TJSONArray then
  begin
    Result := jkArray;
  end
  else if ClassType = TJSONString then
  begin
    Result := jkString;
  end
  else if ClassType = TJSONNumber then
  begin
    Result := jkNumber;
  end
  else if ClassType = TJSONBool then
  begin
    Result := jkBoolean;
  end
  else if ClassType = TJSONNull then
  begin
    Result := jkNull;
  end
  else
  begin
    Result := jkNone;
  end;
end;

function TJSONValueHelper.IsObjectOrArray: boolean;
begin
  Result := (self is TJSONObject) or (self is TJSONArray);
end;

class function TJSONValueHelper.LoadFromFile(const AFileName: string; AUseBool: boolean; ARaiseExc: boolean): TJSONValue;
begin
  Result := nil;
  try
    Result := TJSONValue.ParseJSONValue(TFile.ReadAllText(AFileName, TEncoding.UTF8), AUseBool, ARaiseExc);
  except
    on E: Exception do
    begin
      if ARaiseExc then
      begin
        raise Exception.Create(E.Message);
      end;
    end;
  end;
end;

function TJSONValueHelper.GetItemCount: Integer;
begin
  if self is TJSONObject then
    Result := TJSONObject(self).Count
  else if self is TJSONArray then
    Result := TJSONArray(self).Count
  else
    Result := 0;
end;

function TJSONValueHelper.GetItem(const AIndex: Integer): TJSONAncestor;
begin
  if self is TJSONObject then
    Result := TJSONObject(self).Pairs[AIndex]
  else if self is TJSONArray then
    Result := TJSONArray(self)[AIndex]
  else
    Result := nil;
end;

////////////////////////////////////////////////////////////////////////////////
// TJSONObject

function TJSONObjectHelper.DeletePair(AIndex: Integer): TJSONPair;
begin
  with self do
  begin
    if (AIndex >= 0) and (AIndex < FMembers.Count) then
    begin
      Result := FMembers[AIndex];
      FMembers.Remove(Result);
    end
    else
    begin
      Result := nil;
    end;
  end;
end;

function TJSONObjectHelper.DeletePair(const AItem: TJSONPair): TJSONPair;
begin
  with self do
  begin
    Exit(FMembers.Extract(AItem));
  end;
end;

procedure TJSONObjectHelper.InsertPair(AIndex: NativeInt; const AValue: TJSONPair);
begin
  with self do
  begin
    FMembers.Insert(AIndex, AValue);
  end;
end;

procedure TJSONObjectHelper.Move(ACurIndex, ANewIndex: NativeInt);
begin
  with self do
  begin
    FMembers.Move(ACurIndex, ANewIndex);
  end;
end;

function TJSONArrayHelper.Delete(const AItem: TJSONValue): TJSONValue;
begin
  with self do
  begin
    Result := FElements.Extract(AItem);
  end;
end;

function TJSONArrayHelper.IndexOf(const AItem: TJSONValue): Integer;
begin
  with self do
  begin
    Result := FElements.IndexOf(AItem);
  end;
end;

procedure TJSONArrayHelper.SetValue(const AIndex: Integer; const AValue: TJSONValue);
begin
  with self do
  begin
    if FElements[AIndex].Owned then
      FElements[AIndex].Free;
    FElements[AIndex] := AValue;
  end;
end;

procedure TJSONArrayHelper.InsertElement(AIndex: NativeInt; const AValue: TJSONValue);
begin
  with self do
  begin
    FElements.Insert(AIndex, AValue);
  end;
end;

procedure TJSONArrayHelper.Move(ACurIndex, ANewIndex: NativeInt);
begin
  with self do
  begin
    FElements.Move(ACurIndex, ANewIndex);
  end;
end;

end.

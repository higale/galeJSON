unit DocWinList;

interface

uses
  FormDocument,
  System.Generics.Collections, FMX.Forms, System.SysUtils, System.Types,
  System.UITypes, System.Classes;

type
  TDocumentWindowList = class(TObjectList<TfmDocument>)
  private
    function GetNumOfVisible: Integer;
    function GetActiveWindow: TfmDocument;
    function GetLastActive: TfmDocument;
  public
    property NumOfVisible: Integer read GetNumOfVisible;
    property ActiveWindow: TfmDocument read GetActiveWindow;
    property LastActive: TfmDocument read GetLastActive;
  public
    function Add(const Value: TfmDocument): NativeInt;
    function Remove(const Value: TfmDocument): NativeInt;
    procedure ShowAll;
    function HasActiveWindow: Boolean;
    function GetWindowByFilename(const AFilename: string): TfmDocument;
  end;

implementation

function TDocumentWindowList.Add(const Value: TfmDocument): NativeInt;
begin
  Result := inherited;
end;

function TDocumentWindowList.Remove(const Value: TfmDocument): NativeInt;
begin
  Result := inherited;
  if Count <= 0 then
    Application.MainForm.Close;
end;

procedure TDocumentWindowList.ShowAll;
begin
  for var item in self do
  begin
    if not item.Visible then
    begin
      item.Show;
    end;
  end;
end;

function TDocumentWindowList.GetNumOfVisible: Integer;
begin
  Result := 0;
  for var item in self do
  begin
    if item.Visible then
    begin
      Inc(Result);
    end;
  end;
end;

function TDocumentWindowList.GetActiveWindow: TfmDocument;
begin
  for var item in self do
    if item.Active then
      Exit(item);
  Exit(nil);
end;

function TDocumentWindowList.GetLastActive: TfmDocument;
begin
  if Count > 0 then
    Result := First
  else
    Result := nil;
end;

function TDocumentWindowList.GetWindowByFilename(const AFilename: string): TfmDocument;
begin
  for var item in self do
    if item.lblFilename.Text.ToLower = AFilename.ToLower then
      Exit(item);
  Result := nil;
end;

function TDocumentWindowList.HasActiveWindow: Boolean;
begin
  Result := GetActiveWindow <> nil;
end;

end.

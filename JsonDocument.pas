unit JsonDocument;

interface

uses
  System.Classes, System.JSON, System.SysUtils, System.IOUtils;

type
  TOnFilenameChanged = reference to procedure(ASender: TObject; AOld, ANew: string);

  TJsonDocument = class
  private
    FFilename: string;
    FLastWriteTime: TDateTime;
    FJsonRoot: TJsonValue;
    FOnFilenameChanged: TOnFilenameChanged;
    procedure SetJsonRoot(const AValue: TJsonValue);
    procedure SetFilename(const AValue: string);
  public
    property Filename: string read FFilename write SetFilename;
    property LastWriteTime: TDateTime read FLastWriteTime;

    property JsonRoot: TJsonValue read FJsonRoot write SetJsonRoot;
    property OnFilenameChanged: TOnFilenameChanged read FOnFilenameChanged write FOnFilenameChanged;
  public
    constructor Create;
    destructor Destroy; override;
    procedure New(AValue: TJsonValue = nil);
    function Open(const AFileName: string; AUseBool: Boolean = False; ARaiseExc: Boolean = False): Boolean;
    procedure Save(const AFileName: string; AIndentation: Integer = 4; AEncodeBelow32: Boolean = True; AEncodeAbove127: Boolean = False; AWriteBOM: Boolean = False);
  end;

implementation

uses Logger, jsonhelper, pub, FormMain;

constructor TJsonDocument.Create;
begin
  inherited;
  FJsonRoot := nil;
  FFilename := '';
end;

destructor TJsonDocument.Destroy;
begin
  FJsonRoot.Free;
  inherited;
end;

procedure TJsonDocument.SetJsonRoot(const AValue: TJsonValue);
begin
  if FJsonRoot = AValue then
    Exit;
  FJsonRoot.Free;
  FJsonRoot := AValue;
end;

procedure TJsonDocument.SetFilename(const AValue: string);
var
  LOldFilename: string;
begin
  LOldFilename := FFilename;
  FFilename := AValue;
  if LOldFilename <> FFilename then
  begin
    if not LOldFilename.IsEmpty then
    begin
      fmMain.FileWatcher.RemoveTarget(LOldFilename);
      g_Logger.Debug('移除文件监控:' + LOldFilename);
    end;
    if not FFilename.IsEmpty then
    begin
      fmMain.FileWatcher.AddFile(FFilename);
      g_Logger.Debug('添加文件监控:' + FFilename);
    end;
  end;
  if FFilename <> '' then
  begin
    for var i := g_pub.Config['recent'].Count - 1 downto 0 do
    begin
      if (i > 10) or (g_pub.Config['recent'][i] = FFilename) then
      begin
        g_pub.Config['recent'][i].Delete;
      end;
    end;
    g_pub.Config['recent'].Add(FFilename);
    g_pub.Config['recent'].LastItem.MoveToFirst;
    g_pub.SaveConfig;
  end;
  if Assigned(FOnFilenameChanged) then
    FOnFilenameChanged(Self, LOldFilename, FFilename);
end;

procedure TJsonDocument.New(AValue: TJsonValue = nil);
begin
  if AValue = nil then
    JsonRoot := TJSONObject.Create
  else
    JsonRoot := AValue;
  Filename := '';
end;

function TJsonDocument.Open(const AFileName: string; AUseBool: Boolean = False; ARaiseExc: Boolean = False): Boolean;
var
  LValue: TJsonValue;
begin
  g_Logger.Info('Open File: ' + AFileName);
  Result := False;
  try
    LValue := TJsonValue.ParseJSONValue(TFile.ReadAllText(AFileName, TEncoding.UTF8), AUseBool, True);
    if LValue = nil then
    begin
      Exit;
    end;
    Filename := AFileName;
    JsonRoot := LValue;
    FLastWriteTime := TFile.GetLastWriteTime(FFilename);
    Result := True;
  except
    on E: Exception do
    begin
      g_Logger.Error('fail to open file: ' + E.Message);
      if ARaiseExc then
      begin
        raise Exception.Create(E.Message);
      end;
    end;
  end;
end;

procedure TJsonDocument.Save(const AFileName: string; AIndentation: Integer = 4; AEncodeBelow32: Boolean = True; AEncodeAbove127: Boolean = False; AWriteBOM: Boolean = False);
var
  strs: TStrings;
begin
  g_Logger.Info('Save File: ' + AFileName);
  strs := TStringList.Create;
  fmMain.FileWatcher.Pause;
  try
    try
      strs.WriteBOM := AWriteBOM;
      strs.Text := JSONFormat(FJsonRoot, AIndentation, AEncodeBelow32, AEncodeAbove127);
      strs.SaveToFile(AFileName, TEncoding.UTF8);
      Filename := AFileName;
    finally
      strs.Free;
    end;
  finally
    fmMain.FileWatcher.Resume(True);
  end;

end;

end.

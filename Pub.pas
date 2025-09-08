unit Pub;

interface

uses
  FormDocument, DocWinList, rjson, JsonDocument, System.JSON, System.Generics.Collections,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, System.IOUtils;

const
  app_name = 'gsJSON';
  app_version = 'v0.7.1';
  url_github = 'https://github.com/higale/galeJSON';

  c_untitled_filename = 'untitled.json';

type
  TDocumentWindow = TfmDocument;

  TPub = class
  private
    FIniPath: string;
    FLangIndex: integer;
    FDocumentWindowList: TDocumentWindowList;
    function GetIsDarkStyle: Boolean;
    procedure SetIsDarkStyle(AValue: Boolean);
    function GetStyleBook: TStyleBook;
    procedure SetLangIndex(AValue: integer);
  public
    Config: TRJSON;
    Languages: TRJSON;
    property LangIndex: integer read FLangIndex write SetLangIndex;
    property IniPath: string read FIniPath;
    property DocumentWindowList: TDocumentWindowList read FDocumentWindowList;
    property IsDarkStyle: Boolean read GetIsDarkStyle write SetIsDarkStyle;
    property StyleBook: TStyleBook read GetStyleBook;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadConfig;
    procedure LoadLanguages;
    function LangStr(const AKey: string): string;
    procedure SaveConfig;
    procedure ResetConfig;
  end;

var
  g_pub: TPub;

implementation

uses FormMain, FormLogger;

constructor TPub.Create;
begin
  inherited;
{$IFDEF MSWINDOWS}
  // C:\Users\xxx\AppData\Roaming\gsJSON\
  //FIniPath := TPath.GetHomePath + TPath.DirectorySeparatorChar + TPath.GetFileNameWithoutExtension(ParamStr(0)) + TPath.DirectorySeparatorChar;
  FIniPath := ExtractFilePath(ParamStr(0));
  //ForceDirectories(FIniPath);
{$ELSE}
  FIniPath := ExtractFilePath(TPath.GetDocumentsPath) + '.' + TPath.GetFileNameWithoutExtension(ParamStr(0)) + TPath.DirectorySeparatorChar;
  ForceDirectories(FIniPath);
{$ENDIF}
  FDocumentWindowList := TDocumentWindowList.Create;
  FDocumentWindowList.OwnsObjects := False;
end;

destructor TPub.Destroy;
begin
  FDocumentWindowList.Free;
  inherited;
end;

procedure TPub.LoadConfig;
begin
  Config.LoadFromFile(FIniPath + 'config.json');
  if Config.IsNil then
  begin
    Config['appName'] := app_name;
    Config['appVer'] := app_version;
    Config['ui.lang'] := 0;
    SaveConfig;
  end;
  FLangIndex := Config['ui.lang']
end;

procedure TPub.LoadLanguages;
begin
{$IFDEF MSWINDOWS}
  Languages.LoadFromFile(FIniPath + 'lang.json');
{$ELSE}
  var
  AppPath := System.IOUtils.TPath.GetDirectoryName(ParamStr(0));
  Languages.LoadFromFile(ExtractFilePath(AppPath) + 'Resources/lang.json');
{$ENDIF}
end;

function TPub.LangStr(const AKey: string): string;
begin
  Result := Languages[FLangIndex]['items.' + AKey];
  if Result = '' then
    Result := Languages[0]['items.' + AKey].ToStr('NoLangString');
end;

procedure TPub.SaveConfig;
begin
  Config.SaveToFile(FIniPath + 'config.json', 4, True, False)
end;

procedure TPub.ResetConfig;
begin
  Config.Reset;
  SaveConfig;
end;

function TPub.GetIsDarkStyle: Boolean;
begin
  Result := Config['ui.isDarkStyle'].ToBool(True);
end;

procedure TPub.SetIsDarkStyle(AValue: Boolean);
begin
  Config['ui.isDarkStyle'] := AValue;
  SaveConfig;
  for var item in g_pub.DocumentWindowList do
    item.SetStyleBook;
  if AValue then
  begin
    fmLogger.StyleBook := fmMain.StyleBookBlack;
  end
  else
  begin
    fmLogger.StyleBook := fmMain.StyleBookWhite;
  end;
end;

function TPub.GetStyleBook: TStyleBook;
begin
  if IsDarkStyle then
    Result := fmMain.StyleBookBlack
  else
    Result := fmMain.StyleBookWhite;
end;

procedure TPub.SetLangIndex(AValue: integer);
begin
  if FLangIndex = AValue then
    Exit;
  FLangIndex := AValue;
  Config['ui.lang'] := FLangIndex;
end;

initialization

g_pub := TPub.Create;
g_pub.LoadConfig;
g_pub.LoadLanguages;

finalization

g_pub.SaveConfig;
FreeAndNil(g_pub);

end.

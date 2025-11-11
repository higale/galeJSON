// ==============================================================================
// 文本显示格式设置对话框
// ver 1.1 by gale 2024-12-05
// ==============================================================================
unit fmFontDialog;

interface

uses
{$IFDEF MACOS}
  MacApi.Appkit, MacApi.CoreFoundation, MacApi.Foundation,
{$ENDIF}
{$IFDEF MSWINDOWS}
  Winapi.Messages, Winapi.Windows,
{$ENDIF}
  System.Rtti, System.TypInfo,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.ListBox, FMX.Edit, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Colors,
  FMX.Objects, System.UIConsts, FMX.Ani;

type
  TFontDialog = class(TForm)
    grp1: TGroupBox;
    chkBold: TCheckBox;
    chkItalic: TCheckBox;
    chkUnderline: TCheckBox;
    chkStrikeOut: TCheckBox;
    Label1: TLabel;
    edtFontSize: TEdit;
    lstFontSize: TListBox;
    Button1: TButton;
    btnCancel: TButton;
    grp2: TGroupBox;
    txtDemo: TText;
    GroupBox1: TGroupBox;
    cbbHorzAlign: TComboBox;
    cbbVertAlign: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    cbbTrimming: TComboBox;
    edtFontColor: TEdit;
    cpnlFontColor: TColorPanel;
    chkWordWrap: TCheckBox;
    edtFontName: TEdit;
    lstFontName: TListBox;
    Label5: TLabel;
    rctTitleBar: TRectangle;
    rctTitleBarForMove: TRectangle;
    Layout1: TLayout;
    rctBtnClose: TRectangle;
    aniForCloseBtn: TColorAnimation;
    pathCloseBtn: TPath;
    lblCaption: TLabel;
    Path4: TPath;
    pnlSizeBorder: TPanel;
    procedure lstFontSizeChange(Sender: TObject);
    procedure edtFontSizeChange(Sender: TObject);
    procedure lstFontNameChange(Sender: TObject);
    procedure edtFontNameChange(Sender: TObject);
    procedure cpnlFontColorChange(Sender: TObject);
    procedure edtFontColorChange(Sender: TObject);
    procedure chkFontStyleChange(Sender: TObject);
    procedure cbbTextAlignChange(Sender: TObject);
    procedure chkWordWrapChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure rctBtnCloseClick(Sender: TObject);
  private
    FTextSettings: TTextSettings;
    FOldTextSettings: TTextSettings;
  public
    type
    TPropPart = (peFamily, peSize, peColor, peBold, peItalic, peUnderLine, peStrikeOut, peHorzAlign, peVertAlign, peTrimming, peWordWarp);
    TPropParts = set of TPropPart;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ShowModal(ATextSettings: TTextSettings; ADisProps: TPropParts = []): TModalResult; overload;
  end;

  TTypeStr = class
  public
    class function SetToStr<T>(AValue: T): string;
    class function StrToSet<T>(AValue: string): T;
    class function EnumToStr<T>(AValue: T): string;
    class function StrToEnum<T>(AValue: string): T;
  end;

var
  FontDialog: TFontDialog;

implementation

uses WinSizeUtil;

{$IFDEF MSWINDOWS }


function EnumFontsProc(var LogFont: TLogFont; var TextMetric: TTextMetric;
  FontType: Integer; Data: Pointer): Integer;
  stdcall;

var
  S: TStrings;
  Temp: string;
begin
  S := TStrings(Data);
  Temp := LogFont.lfFaceName;
  if (S.Count = 0) or (AnsiCompareText(S[S.Count - 1], Temp) <> 0) then
  begin
    if Temp[1] <> '@' then
    begin
      S.Add(Temp);
    end;
  end;
  Result := 1;
end;
{$ENDIF}


procedure CollectFontList(FontList: TStrings);
var
  strs: TStringList;
var
{$IFDEF MACOS}
  fManager: NsFontManager;
  list: NSArray;
  lItem: NSString;
  i: Integer;
{$ENDIF}
{$IFDEF MSWINDOWS}
  DC: HDC;
  LFont: TLogFont;
{$ENDIF}
begin

{$IFDEF MACOS}
  fManager := TNsFontManager.Wrap(TNsFontManager.OCClass.sharedFontManager);
  list := fManager.availableFontFamilies;
  if (list <> nil) and (list.Count > 0) then
  begin
    for i := 0 to list.Count - 1 do
    begin
      lItem := TNSString.Wrap(list.objectAtIndex(i));
      FontList.Add(String(lItem.UTF8String))
    end;
  end;
{$ENDIF}
{$IFDEF MSWINDOWS}
  DC := GetDC(0);
  FillChar(LFont, sizeof(LFont), 0);
  LFont.lfCharset := DEFAULT_CHARSET;
  EnumFontFamiliesEx(DC, LFont, @EnumFontsProc, Winapi.Windows.LPARAM(FontList), 0);
  ReleaseDC(0, DC);
{$ENDIF}
  strs := TStringList.Create;
  try
    strs.Text := FontList.Text;
    strs.Sort;
    FontList.Text := strs.Text;
  finally
    strs.Free;
  end;
end;

{$R *.fmx}


class function TTypeStr.SetToStr<T>(AValue: T): string;
begin
  Result := SetToString(PTypeInfo(TypeInfo(T)), @AValue, true);
end;

class function TTypeStr.StrToSet<T>(AValue: string): T;
begin
  StringToSet(PTypeInfo(TypeInfo(T)), AValue, @Result);
end;

class function TTypeStr.EnumToStr<T>(AValue: T): string;
begin
  Result := GetEnumName(TypeInfo(T), PByte(@AValue)^);
end;

class function TTypeStr.StrToEnum<T>(AValue: string): T;
begin
  if sizeof(T) = 4 then
  begin
    PInteger(@Result)^ := Integer(GetEnumValue(TypeInfo(T), AValue));
    if PInteger(@Result)^ = 255 then
    begin
      PInteger(@Result)^ := 0;
    end;
  end
  else if sizeof(T) = 2 then
  begin
    PWord(@Result)^ := Word(GetEnumValue(TypeInfo(T), AValue));
    if PWord(@Result)^ = 255 then
    begin
      PWord(@Result)^ := 0;
    end;
  end
  else
  begin
    PByte(@Result)^ := Byte(GetEnumValue(TypeInfo(T), AValue));
    if PByte(@Result)^ = 255 then
    begin
      PByte(@Result)^ := 0;
    end;
  end;
end;

// ==============================================================================
// 显示对话框
// ==============================================================================
function TFontDialog.ShowModal(ATextSettings: TTextSettings; ADisProps: TPropParts = []): TModalResult;
begin
  FTextSettings := ATextSettings;
  FOldTextSettings.Assign(FTextSettings);
  txtDemo.TextSettings.Assign(ATextSettings);
  chkBold.IsChecked := TFontstyle.fsBold in txtDemo.TextSettings.Font.Style;
  chkItalic.IsChecked := TFontstyle.fsItalic in txtDemo.TextSettings.Font.Style;
  chkUnderline.IsChecked := TFontstyle.fsUnderline in txtDemo.TextSettings.Font.Style;
  chkStrikeOut.IsChecked := TFontstyle.fsStrikeOut in txtDemo.TextSettings.Font.Style;

  cbbHorzAlign.ItemIndex := cbbHorzAlign.Items.IndexOf(TTypeStr.EnumToStr<TTextAlign>(txtDemo.TextSettings.HorzAlign));
  cbbVertAlign.ItemIndex := cbbVertAlign.Items.IndexOf(TTypeStr.EnumToStr<TTextAlign>(txtDemo.TextSettings.VertAlign));
  cbbTrimming.ItemIndex := cbbTrimming.Items.IndexOf(TTypeStr.EnumToStr<TTextTrimming>(txtDemo.TextSettings.Trimming));

  chkWordWrap.IsChecked := txtDemo.TextSettings.WordWrap;

  edtFontName.Text := txtDemo.TextSettings.Font.Family;
  lstFontName.ItemIndex := lstFontName.Items.IndexOf(edtFontName.Text);
  edtFontSize.Text := txtDemo.TextSettings.Font.Size.ToString;
  lstFontSize.ItemIndex := lstFontSize.Items.IndexOf(edtFontSize.Text);

  cpnlFontColor.Color := txtDemo.TextSettings.FontColor;

  Result := ShowModal;
  if Result = mrOK then
  begin
    FTextSettings.Assign(txtDemo.TextSettings);
  end
  else
  begin
    FTextSettings.Assign(FOldTextSettings);
  end;
end;

// ==============================================================================
// 对齐数据修改
// ==============================================================================
procedure TFontDialog.cbbTextAlignChange(Sender: TObject);
begin
  if txtDemo.Locked then
    Exit;

  if Sender = cbbHorzAlign then
  begin
    if TComboBox(Sender).Selected <> nil then
    begin
      txtDemo.TextSettings.HorzAlign := TTypeStr.StrToEnum<TTextAlign>(TComboBox(Sender).Selected.Text);
    end;
  end
  else if Sender = cbbVertAlign then
  begin
    if TComboBox(Sender).Selected <> nil then
    begin
      txtDemo.TextSettings.VertAlign := TTypeStr.StrToEnum<TTextAlign>(TComboBox(Sender).Selected.Text);
    end;
  end
  else if Sender = cbbTrimming then
  begin
    if TComboBox(Sender).Selected <> nil then
    begin
      txtDemo.TextSettings.Trimming := TTypeStr.StrToEnum<TTextTrimming>(TComboBox(Sender).Selected.Text);
    end;
  end;
end;

// ==============================================================================
// 字体风格数据修改
// ==============================================================================
procedure TFontDialog.chkFontStyleChange(Sender: TObject);
begin
  if txtDemo.Locked then
    Exit;

  txtDemo.TextSettings.Font.Style := [];
  if chkBold.IsChecked then
    txtDemo.TextSettings.Font.Style := txtDemo.TextSettings.Font.Style + [TFontstyle.fsBold];
  if chkItalic.IsChecked then
    txtDemo.TextSettings.Font.Style := txtDemo.TextSettings.Font.Style + [TFontstyle.fsItalic];
  if chkUnderline.IsChecked then
    txtDemo.TextSettings.Font.Style := txtDemo.TextSettings.Font.Style + [TFontstyle.fsUnderline];
  if chkStrikeOut.IsChecked then
    txtDemo.TextSettings.Font.Style := txtDemo.TextSettings.Font.Style + [TFontstyle.fsStrikeOut];
end;

procedure TFontDialog.chkWordWrapChange(Sender: TObject);
begin
  txtDemo.TextSettings.WordWrap := chkWordWrap.IsChecked;
  FTextSettings.Assign(txtDemo.TextSettings);
end;

// ==============================================================================
// 颜色选择修改
// ==============================================================================
procedure TFontDialog.cpnlFontColorChange(Sender: TObject);
begin
  edtFontColor.Text := AlphaColorToString(cpnlFontColor.Color);
end;

constructor TFontDialog.Create(AOwner: TComponent);
begin
  inherited;
  FOldTextSettings := TTextSettings.Create(nil);
end;

destructor TFontDialog.Destroy;
begin
  FOldTextSettings.Free;
  inherited;
end;

// ==============================================================================
// 颜色输入框修改
// ==============================================================================
procedure TFontDialog.edtFontColorChange(Sender: TObject);
begin
  if txtDemo.Locked then
    Exit;

  try
    cpnlFontColor.Color := StringToAlphaColor(edtFontColor.Text);
    txtDemo.TextSettings.FontColor := cpnlFontColor.Color;
    FTextSettings.Assign(txtDemo.TextSettings);
  except
    edtFontColor.Text := AlphaColorToString(cpnlFontColor.Color);
    edtFontColor.SelectAll;
  end;
end;

// ==============================================================================
// 字体列表框修改
// ==============================================================================
procedure TFontDialog.lstFontNameChange(Sender: TObject);
begin
  if lstFontName.Selected <> nil then
    edtFontName.Text := lstFontName.Selected.Text;
end;

// ==============================================================================
// 文字输入框修改
// ==============================================================================
procedure TFontDialog.edtFontNameChange(Sender: TObject);
begin
  if txtDemo.Locked then
    Exit;

  txtDemo.TextSettings.Font.Family := edtFontName.Text;
  lstFontName.ItemIndex := lstFontName.Items.IndexOf(edtFontName.Text);

  FTextSettings.Assign(txtDemo.TextSettings);
end;

// ==============================================================================
// 文字大小列表框修改
// ==============================================================================
procedure TFontDialog.lstFontSizeChange(Sender: TObject);
begin
  if lstFontSize.Selected <> nil then
    edtFontSize.Text := lstFontSize.Selected.Text;
end;

procedure TFontDialog.rctBtnCloseClick(Sender: TObject);
begin
  Close;
end;

// ==============================================================================
// 文字大小输入修改
// ==============================================================================
procedure TFontDialog.edtFontSizeChange(Sender: TObject);
var
  fTemp: Single;
begin
  if txtDemo.Locked then
    Exit;

  if TryStrToFloat(edtFontSize.Text, fTemp) then
  begin
    txtDemo.TextSettings.Font.Size := fTemp;
    lstFontSize.ItemIndex := -1;
    lstFontSize.ItemIndex := lstFontSize.Items.IndexOf(edtFontSize.Text);
    FTextSettings.Assign(txtDemo.TextSettings);
  end;
end;

// ==============================================================================
// 窗口显示
// ==============================================================================
procedure TFontDialog.FormCreate(Sender: TObject);
var
  LFonts: TStrings;
begin
  var
  FWinSizeHelper := TWinSizeHelper.Create(self);
  FWinSizeHelper.SetTitleBar(rctTitleBarForMove);
  LFonts := TStringList.Create;
  try
    CollectFontList(LFonts);
    lstFontName.Items.AddStrings(LFonts);
  finally
    LFonts.Free;
  end;
  for var i := 0 to lstFontName.Items.Count - 1 do
  begin
    lstFontName.ItemByIndex(i).StyledSettings := [TStyledSetting.Size, TStyledSetting.Style, TStyledSetting.FontColor, TStyledSetting.Other];
    lstFontName.ItemByIndex(i).TextSettings.Font.Family := lstFontName.ItemByIndex(i).Text;
  end
end;

end.

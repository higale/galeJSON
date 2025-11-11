unit FormDocument;

interface

uses
  jsonhelper, JsonDocument,
  WinSizeUtil, LineNumbersMemoFMX, System.RegularExpressions,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math, System.StrUtils, FMX.DialogService,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.TreeView, FMX.Objects, System.JSON,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, System.ImageList, FMX.ImgList, FMX.Text,
  FMX.ListBox, FMX.Edit, FMX.TabControl, FMX.Menus, FMX.Ani, FMX.Effects,
  FMX.Filter.Effects, System.Generics.Collections, System.Actions, FMX.ActnList,
  System.Math.Vectors, FMX.Controls3D, FMX.Layers3D, FMX.EditBox, FMX.NumberBox;

type
  TJsonErrorData = class
  private
    FIsPositionable: boolean;
    FErrorString: String;
    FPath: string;
    FLine: integer;
    FPosition: integer;
    FOffset: integer;
    procedure SetErrorString(const AValue: string);
    function FormatMessage: string;
  public
    property ErrorString: string read FErrorString write SetErrorString;
  public
    constructor Create;
    procedure Clear;
  end;

  TfmDocument = class(TForm)
    pmTreeViewItem: TPopupMenu;
    miMoveDown: TMenuItem;
    imglstJSONKind: TImageList;
    miMoveUp: TMenuItem;
    pnlSizeBorder: TPanel;
    lytMiddle: TLayout;
    rctFooter: TRectangle;
    lytLeftAndRight: TLayout;
    rctLeft: TRectangle;
    rctLeftToolBar: TRectangle;
    rctBtnCollapseAll: TRectangle;
    ColorAnimation6: TColorAnimation;
    pathBtnCollapseAll: TPath;
    rctBtnExpandAll: TRectangle;
    ColorAnimation7: TColorAnimation;
    pathBtnExpandAll: TPath;
    lytLeftToolBar_right: TLayout;
    rctBtnDelete: TRectangle;
    ColorAnimation8: TColorAnimation;
    Path2: TPath;
    rctBtnAddSubItem: TRectangle;
    ColorAnimation9: TColorAnimation;
    pathBtnAddSub: TPath;
    rctBtnAddItem: TRectangle;
    ColorAnimation10: TColorAnimation;
    pathBtnAddBrother: TPath;
    rctBtnMoveDown: TRectangle;
    ColorAnimation11: TColorAnimation;
    pathBtnMoveDown: TPath;
    rctBtnMoveUp: TRectangle;
    ColorAnimation12: TColorAnimation;
    pathBtnMoveUp: TPath;
    tvJson: TTreeView;
    rctDrap: TRectangle;
    rctRight: TRectangle;
    rctRightTopBar: TRectangle;
    edtName: TEdit;
    cbValueType: TComboBox;
    rctRightMiddle: TRectangle;
    mmoEdit: TMemo;
    rctForBoolValue: TRectangle;
    rbTrue: TRadioButton;
    rbFalse: TRadioButton;
    slL_R: TSplitter;
    rctTitleBar: TRectangle;
    rctTitleBarForMove: TRectangle;
    rctBtnClose: TRectangle;
    aniForCloseBtn: TColorAnimation;
    pathCloseBtn: TPath;
    rctBtnMin: TRectangle;
    aniForMinBtn: TColorAnimation;
    pathMinBtn: TPath;
    rctBtnMax: TRectangle;
    aniForMaxBtn: TColorAnimation;
    pathMaxBtn: TPath;
    lblCaption: TLabel;
    imgLogo: TImage;
    lblFilename: TLabel;
    rctToolBar: TRectangle;
    MenuBar1: TMenuBar;
    miFile: TMenuItem;
    miFileNew: TMenuItem;
    miFileOpen: TMenuItem;
    miFileOpenRecent: TMenuItem;
    miFileSave: TMenuItem;
    miFileSaveAs: TMenuItem;
    miFileClose: TMenuItem;
    miEdit: TMenuItem;
    miEditMoveUp: TMenuItem;
    miEditMoveDown: TMenuItem;
    miView: TMenuItem;
    miViewShowLog: TMenuItem;
    miViewDarkStyle: TMenuItem;
    BitmapAnimation1: TBitmapAnimation;
    miViewFont: TMenuItem;
    miHelp: TMenuItem;
    miHelpHelp: TMenuItem;
    miHelpAbout: TMenuItem;
    txtMsg: TText;
    aniMsg: TFloatAnimation;
    miWindow: TMenuItem;
    mi1: TMenuItem;
    miWindowShowAll: TMenuItem;
    miWindowItems: TMenuItem;
    rctLinePos: TRectangle;
    lblLineAndPos: TLabel;
    ErrorLight: TCircle;
    rctIndent: TRectangle;
    lblIndent: TLabel;
    rctWordWarp: TRectangle;
    ColorAnimation13: TColorAnimation;
    miViewLang: TMenuItem;
    pathWordWrap: TPath;
    lblPath: TLabel;
    rctErrorInfo: TRectangle;
    crcColseErrorInfo: TCircle;
    lblErrorInfo: TLabel;
    rctFileChangedExternally: TRectangle;
    crcCloseFileChangedExternally: TCircle;
    lblFileChangedExternally: TLabel;
    procedure tvJsonChange(Sender: TObject);
    procedure mmoEditChangeTracking(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbValueTypeChange(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure slL_RMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure rctBtnCloseClick(Sender: TObject);
    procedure rctBtnMaxClick(Sender: TObject);
    procedure rctBtnMinClick(Sender: TObject);
    procedure mmoEditViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: boolean);
    procedure edtNameChangeTracking(Sender: TObject);
    procedure rctBtnCollapseAllMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure rctBtnExpandAllMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure rctIndentClick(Sender: TObject);
    procedure rctWordWarpClick(Sender: TObject);
    procedure rctBtnMoveUpMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure rctBtnMoveDownMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure tvJsonDragChange(SourceItem, DestItem: TTreeViewItem; var Allow: boolean);
    procedure tvJsonDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
    procedure tvJsonMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure rctBtnDeleteClick(Sender: TObject);
    procedure pmTreeViewItemPopup(Sender: TObject);
    procedure tvJsonMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure JsonFileDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
    procedure JsonFileDragDrop(Sender: TObject; const Data: TDragObject; const Point: TPointF);
    procedure rbTrueFalseChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure rctBtnAddItemMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure rctBtnAddSubItemMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure miFileOpenRecentApplyStyleLookup(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure miWindowShowAllApplyStyleLookup(Sender: TObject);
    procedure ErrorLightClick(Sender: TObject);
    procedure aniMsgFinish(Sender: TObject);
    procedure crcColseErrorInfoClick(Sender: TObject);
    procedure lblErrorInfoClick(Sender: TObject);
    procedure lblFileChangedExternallyClick(Sender: TObject);
    procedure crcCloseFileChangedExternallyClick(Sender: TObject);
  private
    FDoc: TJsonDocument;
    FIsUpdating: boolean;
    FLinesMemoUtil: TLinesMemoUtil;
    FIndent: integer;
    FCurrentJSONKind: TJSONKind;
    FRightPanelWidthPercent: Single; // 右侧宽度占整个窗口的比例
    FJsonErrorData: TJsonErrorData;
    procedure SetIndent(AValue: integer);
    function GetWordWarp: boolean;
    procedure SetWordWarp(AValue: boolean);
    property Indent: integer read FIndent write SetIndent;
    property WordWarp: boolean read GetWordWarp write SetWordWarp;
  public
    property Doc: TJsonDocument read FDoc;
  private
    procedure InitUI;
    procedure miFileOepnedClick(Sender: TObject);
    procedure miRecentFilesClick(Sender: TObject);
    procedure FilenameChanged(ASender: TObject; AOld, ANew: string);
    procedure SetErrInfo(const AMsg: string);
  public
    procedure SetLang;
    procedure NewFile;
    procedure OpenFile(const AFilename: string);
    procedure SetStyleBook;
    procedure InitOpenedFileMenu;
    procedure InitRecentFile;
    procedure ShowInfo(AText: string; ALevel: integer = 0; ADelay: Single = 3.0);
  end;

var
  fmDocument: TfmDocument;

implementation

{$R *.fmx}


uses JSONTreeView, memo_json_auto, data_const, pub, Logger, fmFontDialog,
  rjson, FormMain, FileWatcher;

procedure TJsonErrorData.SetErrorString(const AValue: string);
var
  Match: TMatch;
begin
  g_logger.Debug(AValue);
  if AValue <> FErrorString then
  begin
    FErrorString := AValue;
    if FErrorString.IsEmpty then
    begin
      FIsPositionable := False;
    end
    else
    begin
      Match := TRegEx.Match(FErrorString, 'Path ''([^'']*)'', line (\d+), position (\d+) \(offset (\d+)\)');
      FIsPositionable := Match.Success;
      if FIsPositionable then
      begin
        FPath := Match.Groups[1].Value;
        FLine := Match.Groups[2].Value.ToInteger;
        FPosition := Match.Groups[3].Value.ToInteger;
        FOffset := Match.Groups[4].Value.ToInteger;
      end;
    end;
  end;
end;

constructor TJsonErrorData.Create;
begin
  inherited;
  Clear;
end;

procedure TJsonErrorData.Clear;
begin
  FErrorString := '';
  FIsPositionable := False;
end;

function TJsonErrorData.FormatMessage: string;
begin
  if FIsPositionable then
  begin
    Result := Format(g_pub.LangStr('strJsonError'), [FPath, FLine, FPosition, FOffset]);
  end
  else
  begin
    Result := FErrorString;
  end;
end;

procedure TfmDocument.FilenameChanged(ASender: TObject; AOld, ANew: string);
var
  strTmp: string;
begin
  if FDoc.FileName = '' then
  begin
    strTmp := c_untitled_filename;
    for var i := 1 to 9999 do
    begin
      if g_pub.DocumentWindowList.GetWindowByFilename(strTmp) = nil then
        Break;
      strTmp := c_untitled_filename + ' (' + i.ToString + ')';
    end;
    lblFilename.Text := strTmp
  end
  else
  begin
    lblFilename.Text := FDoc.FileName;
{$IFDEF MACOS}
    fmMain.InitMacOsRecentFile;
{$ENDIF}
  end;
{$IFDEF MACOS}
  Caption := app_name + ' ' + app_version + ' [' + lblFilename.Text + ']';
{$ENDIF}
  //g_logger.Debug('FilenameChanged, Old:%s New:%s', [AOld, ANew]);
end;

procedure TfmDocument.SetErrInfo(const AMsg: string);
begin
  ErrorLight.Fill.Color := IfThen(AMsg.IsEmpty, $FF00AA00, $FFDD0000);
  lblErrorInfo.FontColor := ErrorLight.Fill.Color;
  FJsonErrorData.ErrorString := IfThen(AMsg.IsEmpty, 'No Error', AMsg);
  lblErrorInfo.Text := FJsonErrorData.FormatMessage;
end;

procedure TfmDocument.FormCreate(Sender: TObject);
var
  LDisplay: TDisplay;
begin
  FJsonErrorData := TJsonErrorData.Create;
  FDoc := TJsonDocument.Create;
  FDoc.OnFilenameChanged := FilenameChanged;
  if g_pub.DocumentWindowList.LastActive <> nil then
  begin
    Position := TFormPosition.Designed;
    Left := g_pub.DocumentWindowList.LastActive.Left + 28;
    Top := g_pub.DocumentWindowList.LastActive.Top + 28;
    Width := g_pub.DocumentWindowList.LastActive.Width;
    Height := g_pub.DocumentWindowList.LastActive.Height;
    LDisplay := Screen.DisplayFromForm(g_pub.DocumentWindowList.LastActive);
    if (Left > LDisplay.BoundsRect.Right - 320) or (Top > LDisplay.BoundsRect.Bottom - 240) then
    begin
      Left := 0;
      Top := 0;
    end;
  end;

  g_pub.DocumentWindowList.Add(self);
  FIsUpdating := False;
  TMemoJsonAuto.Create(self, mmoEdit);
  FLinesMemoUtil := TLinesMemoUtil.Create(self, mmoEdit);
  InitUI;
end;

procedure TfmDocument.FormDestroy(Sender: TObject);
begin
  if FDoc.FileName <> '' then
    fmMain.FileWatcher.RemoveTarget(FDoc.FileName);
  FDoc.Free;
  FJsonErrorData.Free;
end;

procedure TfmDocument.FormResize(Sender: TObject);
begin
  rctRight.Width := IfThen((Width - 10) * FRightPanelWidthPercent > slL_R.MinSize,
    IfThen((Width - 10) * (1.0 - FRightPanelWidthPercent) >= slL_R.MinSize, (Width - 10) * FRightPanelWidthPercent, (Width - 10) - slL_R.MinSize),
    slL_R.MinSize);
{$IFDEF MSWINDOWS}
  pathMaxBtn.Data.Data := IfThen(WindowState = TWindowState.wsMaximized, c_ResPathData, c_MaxPathData);
{$ENDIF}
end;

procedure TfmDocument.InitUI;
begin
{$IFDEF MACOS}
  rctTitleBar.Visible := False;
  pnlSizeBorder.StyleLookup := 'panelstyle_macos_frame';
  mmoEdit.TextSettings.Font.Family := 'SimSong'; // [BIZ UDGothic] [BIZ UDMincho] [PCMyungjo] [SimSong]
  rctToolBar.Visible := False;
  rctToolBar.Free;
  lytMiddle.Margins.Left := 2;
  lytMiddle.Margins.Right := 2;
  lytMiddle.Margins.Top := 2;
{$ELSE}
  Transparency := True;
  with TWinSizeHelper.Create(self) do
  begin
    SetControlled(pnlSizeBorder);
    SetTitleBar(rctTitleBarForMove);
    CanMaximized := True;
  end;

  for var item in g_pub.Languages do
  begin
    var
    mi := TMenuItem.Create(miViewLang);
    mi.Text := item['caption'].ToStr('None');
    mi.RadioItem := True;
    mi.GroupIndex := 10;
    mi.OnClick := fmMain.actViewLangExecute;
    miViewLang.AddObject(mi);
  end;
{$ENDIF}
  SetLang;
  Caption := app_name + ' ' + app_version;
  lblCaption.Text := Caption;
  rctDrap.Visible := False;

  OnResize := nil;

  Indent := g_pub.Config['editor.indent'].ToInt(4);
  WordWarp := g_pub.Config['editor.wordWarp'];
  SetStyleBook;
  FRightPanelWidthPercent := 0.5;
  rctRight.Width := (Width - 10) * FRightPanelWidthPercent;
  rctErrorInfo.Visible := False;
  OnResize := FormResize;
end;

procedure TfmDocument.SetStyleBook;
const
  c_PathColors: array [boolean] of TAlphaColor = ({false:}$FF000000, {true:}$FFFFFFFF);
begin
  tvJson.ScrollBy(tvJson.ViewportPosition.X, tvJson.ViewportPosition.Y); // 否则切换时会偶发异常
  StyleBook := g_pub.StyleBook;
  fmMain.actViewDarkStyle.Checked := g_pub.IsDarkStyle;
  tvJson.ShowScrollBars := True;
  for var item in [pathMaxBtn.Fill, pathMinBtn.Fill, pathCloseBtn.Fill] do
    item.Color := c_PathColors[fmMain.actViewDarkStyle.Checked];
  mmoEdit.TextSettings.FontColor := c_PathColors[fmMain.actViewDarkStyle.Checked];
end;

procedure TfmDocument.SetLang;
begin
{$IFDEF MSWINDOWS}
  miViewLang.Items[g_pub.LangIndex].IsChecked := True;
{$ENDIF}
  rctIndent.Hint := g_pub.LangStr('strIndent');
  rctWordWarp.Hint := g_pub.LangStr('strWordWarp');
  lblFileChangedExternally.Text := g_pub.LangStr('strFileChangedExternally');
end;

procedure TfmDocument.NewFile;
begin
  FDoc.New;
  FIsUpdating := True;
  try
    rctFileChangedExternally.Visible := False;
    tvJson.Clear;
    SetTreeItem(tvJson, FDoc.JsonRoot);
    tvJson.ExpandAll;
    tvJson.Items[0].Select;
    mmoEdit.SetFocus;
    mmoEdit.Text := '{' + sLineBreak + StringOfChar(' ', Indent) + sLineBreak + '}';
    mmoEdit.CaretPosition := TCaretPosition.Create(1, Indent);
    cbValueType.ItemIndex := 0;
  finally
    FIsUpdating := False;
  end;
end;

procedure TfmDocument.OpenFile(const AFilename: string);
begin
  rctFileChangedExternally.Visible := False;
  if FDoc.Open(AFilename, True, False) then
  begin
    FIsUpdating := True;
    try
      tvJson.Clear;
      tvJson.BeginUpdate;
      SetTreeItem(tvJson, FDoc.JsonRoot);
      tvJson.EndUpdate;
      tvJson.ExpandAll;
      mmoEdit.Text := '';
      ShowInfo('Open: ' + AFilename);
    finally
      FIsUpdating := False;
    end;
    if tvJson.Count > 0 then
    begin
      tvJson.Items[0].Select;
    end;
  end
  else
  begin
    ShowMessage('An error occurred while opening the file.!');
  end;
end;

procedure TfmDocument.tvJsonChange(Sender: TObject);
var
  selItem: TJSONTreeViewItem;
  LJsonKind: TJSONKind;
begin
  if FIsUpdating then
    exit;
  FIsUpdating := True;
  try
    SetErrInfo('');
    selItem := TJSONTreeViewItem(tvJson.Selected);
    if selItem = nil then
    begin
      mmoEdit.Text := '';
      exit;
    end;

    edtName.Text := selItem.LastPath;
    mmoEdit.Text := selItem.Value;
    lblPath.Text := selItem.Path;
    edtName.Enabled := not selItem.Key.IsEmpty;
    LJsonKind := selItem.JsonValue.JsonKind;
    cbValueType.ItemIndex := ord(LJsonKind) - 1;
    if LJsonKind in [jkObject, jkArray] then
    begin

      mmoEdit.Text := selItem.JsonValue.Format(Indent);
    end
    else
    begin
      mmoEdit.Text := selItem.Value;
      if LJsonKind = jkBoolean then
      begin
        rbTrue.IsChecked := selItem.JsonValue.AsType<boolean>;
        rbFalse.IsChecked := not rbTrue.IsChecked;
      end;
    end;
  finally
    FIsUpdating := False;
  end;
end;

procedure TfmDocument.tvJsonDragChange(SourceItem, DestItem: TTreeViewItem; var Allow: boolean);
var
  Pos: TPointF;
  Source, Dest: TJSONTreeViewItem;
begin
  Allow := False;
  rctDrap.Visible := False;
  if DestItem = nil then
    exit;

  Dest := TJSONTreeViewItem(DestItem);
  Source := TJSONTreeViewItem(SourceItem);

  if Source.IsChild(Dest) then
  begin
{$IFDEF DEBUG}
    g_logger.Debug('父条目不能插入子条目！');
{$ENDIF}
    exit;
  end;

  Pos := Dest.ScreenToLocal(Screen.MousePos);
  if Pos.Y < Dest.LocalRect.Height / 4 then
  begin
    if ((Dest.ParentItem = Source.ParentItem) and (Dest.Index - Source.Index = 1)) or (Dest.ParentItem = nil) then
    begin
{$IFDEF DEBUG}
      g_logger.Debug('Do nothing');
{$ENDIF}
    end
    else
    begin
{$IFDEF DEBUG}
      g_logger.Debug('前边插入');
{$ENDIF}
      TJSONTreeViewItem(Source).ExtractFromParent(True);
      TJSONTreeViewItem(Dest.ParentItem).InsertItem(Dest.Index, Source, True);
      Source.Select;
    end;
  end
  else if Pos.Y > Dest.LocalRect.Height / 4 * 3 then
  begin
    if ((Dest.ParentItem = Source.ParentItem) and (Source.Index - Dest.Index = 1)) or (Dest.ParentItem = nil) then
    begin
{$IFDEF DEBUG}
      g_logger.Debug('Do nothing');
{$ENDIF}
    end
    else
    begin
{$IFDEF DEBUG}
      g_logger.Debug('后边插入');
{$ENDIF}
      TJSONTreeViewItem(Source).ExtractFromParent(True);
      TJSONTreeViewItem(Dest.ParentItem).InsertItem(Dest.Index + 1, Source, True);
      Source.Select;
    end;
  end
  else
  begin
    if not Dest.JsonValue.IsObjectOrArray then
    begin
{$IFDEF DEBUG}
      g_logger.Debug('Do nothing');
{$ENDIF}
    end
    else
    begin
{$IFDEF DEBUG}
      g_logger.Debug('插入子项');
{$ENDIF}
      TJSONTreeViewItem(Source).ExtractFromParent(True);
      Dest.AddItem(Source, True);
      Source.Select;
    end;
  end;

end;

procedure TfmDocument.tvJsonDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
var
  Pos: TPointF;
  Source, Dest: TJSONTreeViewItem;
  LRect: TRectF;
  LPoint: TPointF;
begin
  Operation := TDragOperation.None;
  Dest := TJSONTreeViewItem(tvJson.ItemByPoint(Point.X, Point.Y));
  if Dest = nil then
    exit;
  Source := TJSONTreeViewItem(Data.Source);
  if Source.IsChild(Dest) then
    exit;
  LRect := Dest.BoundsRect;
  Pos := Dest.ScreenToLocal(Screen.MousePos);
  LPoint := tvJson.ScreenToLocal(Dest.LocalToScreen(PointF(0, 0)));
  if Pos.Y < Dest.LocalRect.Height / 4 then
  begin
    if ((Dest.ParentItem = Source.ParentItem) and (Dest.Index - Source.Index = 1)) or (Dest.ParentItem = nil) then
    begin
      rctDrap.Visible := False;
    end
    else
    begin
      rctDrap.Height := Dest.Height / 2;
      rctDrap.Position.Y := LPoint.Y - rctDrap.Height / 2 + tvJson.ViewportPosition.Y;
      rctDrap.Position.X := LPoint.X + tvJson.ViewportPosition.X;
      rctDrap.Width := tvJson.ClipRect.Width - 10 - rctDrap.Position.X + tvJson.ViewportPosition.X;
      rctDrap.Visible := True;
    end;
  end
  else if Pos.Y > Dest.LocalRect.Height / 4 * 3 then
  begin
    if ((Dest.ParentItem = Source.ParentItem) and (Source.Index - Dest.Index = 1)) or (Dest.ParentItem = nil) then
    begin
      rctDrap.Visible := False;
    end
    else
    begin
      rctDrap.Height := Dest.Height / 2;
      rctDrap.Position.Y := LPoint.Y - rctDrap.Height / 2 + Dest.Height + tvJson.ViewportPosition.Y;
      rctDrap.Position.X := LPoint.X + tvJson.ViewportPosition.X;
      rctDrap.Width := tvJson.ClipRect.Width - 10 - rctDrap.Position.X + tvJson.ViewportPosition.X;
      rctDrap.Visible := True;
    end;
  end
  else
  begin
    if not Dest.JsonValue.IsObjectOrArray then
    begin
      rctDrap.Visible := False;
    end
    else
    begin
      rctDrap.Height := Dest.Height / 4 * 3;
      rctDrap.Position.Y := LPoint.Y + (Dest.Height - rctDrap.Height) / 2 + tvJson.ViewportPosition.Y;
      rctDrap.Position.X := LPoint.X + tvJson.ViewportPosition.X;
      rctDrap.Width := tvJson.ClipRect.Width - 10 - rctDrap.Position.X + tvJson.ViewportPosition.X;
      rctDrap.Visible := True;
    end;
  end;
end;

procedure TfmDocument.tvJsonMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  LItem: TTreeViewItem;
begin
  if ssRight in Shift then
  begin
    LItem := tvJson.ItemByPoint(X, Y);
    if LItem <> nil then
    begin
      LItem.Select;
      pmTreeViewItem.Popup(Screen.MousePos.X, Screen.MousePos.Y);
    end;
  end;
end;

procedure TfmDocument.tvJsonMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Single);
begin
  if not(ssLeft in Shift) then
    rctDrap.Visible := False;
end;

{-------------------------------------------------------------------------------
  名称: TfmDocument.actHelpAboutExecute
  说明: 关于
  参数: Sender
-------------------------------------------------------------------------------}
procedure TfmDocument.aniMsgFinish(Sender: TObject);
begin
  lblPath.Visible := True;
end;

procedure TfmDocument.cbValueTypeChange(Sender: TObject);
var
  LJValue:
    TJsonValue;
  treeItem:
    TJSONTreeViewItem;
  bValue:
    boolean;
begin
  FCurrentJSONKind := TJSONKind(cbValueType.ItemIndex + 1);
  rctForBoolValue.Visible := FCurrentJSONKind = jkBoolean;
  mmoEdit.Visible := FCurrentJSONKind <> jkBoolean;
  mmoEdit.Enabled := FCurrentJSONKind in [jkObject, jkArray, jkString, jkNumber];

  treeItem := TJSONTreeViewItem(tvJson.Selected);
  if FIsUpdating or (treeItem = nil) then
    exit;

  LJValue := nil;
  FIsUpdating := True;
  try
    try
      case FCurrentJSONKind of
        jkObject:
          begin
            LJValue := TJsonValue.ParseJSONValue(mmoEdit.Text, True, False);
            if not(LJValue is TJSONObject) then
            begin
              FreeAndNil(LJValue);
              mmoEdit.Text := '{' + sLineBreak + StringOfChar(' ', Indent) + sLineBreak + '}';
              mmoEdit.CaretPosition := TCaretPosition.Create(1, Indent);
              mmoEdit.SetFocus;
              LJValue := TJSONObject.Create;
            end;
          end;
        jkArray:
          begin
            LJValue := TJsonValue.ParseJSONValue(mmoEdit.Text, True, False);
            if not(LJValue is TJSONArray) then
            begin
              FreeAndNil(LJValue);
              LJValue := TJSONArray.Create;
              mmoEdit.Text := '[' + sLineBreak + StringOfChar(' ', Indent) + sLineBreak + ']';
              mmoEdit.CaretPosition := TCaretPosition.Create(1, Indent);
              mmoEdit.SetFocus;
            end;
          end;
        jkString:
          begin
            LJValue := TJSONString.Create(mmoEdit.Text);
            mmoEdit.GoToTextEnd;
            mmoEdit.SetFocus;
          end;
        jkNumber:
          begin
            LJValue := TJsonValue.ParseJSONValue(mmoEdit.Text.Trim, True, False);
            if not(LJValue is TJSONNumber) then
            begin
              FreeAndNil(LJValue);
              LJValue := TJSONNumber.Create(0);
            end;
            mmoEdit.Text := LJValue.Value;
            mmoEdit.GoToTextEnd;
            mmoEdit.SetFocus;
          end;
        jkBoolean:
          begin
            bValue := StrToBoolDef(mmoEdit.Text.Trim, False);
            LJValue := TJSONBool.Create(bValue);
            mmoEdit.Text := LJValue.Value;
            if bValue then
            begin
              rbTrue.IsChecked := True;
            end
            else
            begin
              rbFalse.IsChecked := True;
            end;
          end;
        jkNull:
          begin
            LJValue := TJSONNull.Create;
            mmoEdit.Text := LJValue.Value;
          end;
      end;
    except
      on E: Exception do
        SetErrInfo(E.Message);
    end;

    treeItem.ClearItem;
    treeItem.JsonValue := LJValue;
    treeItem.ReText;
    SetTreeItems(treeItem, LJValue);

    if treeItem.ParentItem = nil then
    begin
      FDoc.JsonRoot := LJValue;
    end;
  finally
    FIsUpdating := False;
  end;
end;

procedure TfmDocument.crcCloseFileChangedExternallyClick(Sender: TObject);
begin
  rctFileChangedExternally.Visible := False;
end;

procedure TfmDocument.crcColseErrorInfoClick(Sender: TObject);
begin
  rctErrorInfo.Visible := False;
end;

procedure TfmDocument.edtNameChangeTracking(Sender: TObject);
var
  treeItem: TJSONTreeViewItem;
begin
  if FIsUpdating or Trim(edtName.Text).IsEmpty then
    exit;
  FIsUpdating := True;
  try
    treeItem := TJSONTreeViewItem(tvJson.Selected);
    if treeItem <> nil then
    begin
      TJSONPair(treeItem.JsonData).Rename(Trim(edtName.Text));
      treeItem.Text := Trim(edtName.Text) + ': ' + treeItem.Value;
    end;
  finally
    FIsUpdating := False;
  end;
end;

procedure TfmDocument.ErrorLightClick(Sender: TObject);
begin
  rctErrorInfo.Visible := not rctErrorInfo.Visible;
end;

procedure TfmDocument.FormActivate(Sender: TObject);
var
  LIndex: integer;
begin
  LIndex := g_pub.DocumentWindowList.IndexOf(self);
  if LIndex > 0 then
  begin
    g_pub.DocumentWindowList.Move(LIndex, 0);
{$IFDEF DEBUG}
    g_logger.Debug('窗口激活，移动到列表首位！');
{$ENDIF}
  end;
end;

procedure TfmDocument.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  g_pub.Config['editor.indent'] := Indent;
  g_pub.Config['editor.wordWarp'] := mmoEdit.TextSettings.WordWrap;

  g_pub.DocumentWindowList.Remove(self);
  Action := TCloseAction.caFree;
end;

procedure TfmDocument.mmoEditChangeTracking(Sender: TObject);
var
  LJValue: TJsonValue;
  treeItem: TJSONTreeViewItem;
begin
  treeItem := TJSONTreeViewItem(tvJson.Selected);
  if FIsUpdating or (treeItem = nil) then
    exit;
  LJValue := nil;
  SetErrInfo('');
  FIsUpdating := True;
  try
    try
      if FCurrentJSONKind = jkString then
      begin
        LJValue := TJSONString.Create(mmoEdit.Text);
      end
      else
      begin
        LJValue := TJsonValue.ParseJSONValue(mmoEdit.Text, True, True);
        if LJValue.JsonKind <> FCurrentJSONKind then
        begin
          FreeAndNil(LJValue);
        end;
      end;
    except
      on E: Exception do
        SetErrInfo(E.Message);
    end;

    if LJValue <> nil then
    begin
      if treeItem.JsonValue.ToString = LJValue.ToString then
      begin
        FreeAndNil(LJValue);
      end
      else
      begin
        treeItem.BeginUpdate;
        treeItem.ClearItem;
        treeItem.JsonValue := LJValue;
        if treeItem.ParentItem = nil then
        begin
          FDoc.JsonRoot := LJValue;
        end;
        treeItem.ReText;
        SetTreeItems(treeItem, LJValue);
        treeItem.EndUpdate;
      end;
    end;
  finally
    FIsUpdating := False;
  end;
end;

procedure TfmDocument.mmoEditViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: boolean);
begin
  lblLineAndPos.Text := (mmoEdit.CaretPosition.Line + 1).ToString + ': ' + (mmoEdit.CaretPosition.Pos + 1).ToString;
end;

procedure TfmDocument.pmTreeViewItemPopup(Sender: TObject);
var
  selItem: TJSONTreeViewItem;
begin
  selItem := TJSONTreeViewItem(tvJson.Selected);
  if selItem = nil then
  begin
    for var i := 0 to pmTreeViewItem.ItemsCount - 1 do
      pmTreeViewItem.Items[i].Enabled := False;
    exit;
  end;
  fmMain.actEditMoveUp.Enabled := selItem.Index <> 0;
  fmMain.actEditMoveDown.Enabled := (selItem.ParentItem <> nil) and (selItem.Index < selItem.ParentItem.Count - 1);
end;

procedure TfmDocument.rbTrueFalseChange(Sender: TObject);
var
  treeItem: TJSONTreeViewItem;
begin
  treeItem := TJSONTreeViewItem(tvJson.Selected);
  if FIsUpdating or (treeItem = nil) then
    exit;
  mmoEdit.Text := rbTrue.IsChecked.ToString(TUseBoolStrs.True).ToLower;
end;

procedure TfmDocument.rctBtnAddItemMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  newItem, selItem, parItem: TJSONTreeViewItem;
  LIndex: integer;
begin
  if tvJson.Selected = nil then
    exit;
  if tvJson.Selected.ParentItem = nil then
    exit;
  selItem := TJSONTreeViewItem(tvJson.Selected);
  parItem := selItem.MyParentItem;
  LIndex := selItem.Index;
  newItem := TJSONTreeViewItem.Create(nil);
  if parItem.JsonValue is TJSONObject then
  begin
    newItem.JsonData := TJSONPair.Create('newItem', 'new value');
  end
  else
  begin
    newItem.JsonData := TJSONString.Create('newItem');
  end;
  parItem.InsertItem(LIndex + 1, newItem, True);
  newItem.Select;
end;

procedure TfmDocument.rctBtnAddSubItemMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  newItem, selItem: TJSONTreeViewItem;
begin
  if tvJson.Selected = nil then
    exit;
  selItem := TJSONTreeViewItem(tvJson.Selected);
  if not selItem.JsonValue.IsObjectOrArray then
    exit;
  newItem := TJSONTreeViewItem.Create(nil);
  if selItem.JsonValue is TJSONObject then
  begin
    newItem.JsonData := TJSONPair.Create('newItem', 'new value');
  end
  else
  begin
    newItem.JsonData := TJSONString.Create('newItem');
  end;
  selItem.AddItem(newItem, True);
  newItem.Select;
end;

procedure TfmDocument.rctBtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfmDocument.rctBtnCollapseAllMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if tvJson.Selected <> nil then
    tvJson.Selected.CollapseAll
  else
    tvJson.CollapseAll;
end;

procedure TfmDocument.rctBtnDeleteClick(Sender: TObject);
var
  selItem: TJSONTreeViewItem;
  parItem: TJSONTreeViewItem;
  LIndex: integer;
begin
  if tvJson.Selected = nil then
    exit;
  if tvJson.Selected.ParentItem = nil then
    exit;
  TDialogService.MessageDialog('Confirm deletion of this item?', TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
      begin
        selItem := TJSONTreeViewItem(tvJson.Selected);
        LIndex := selItem.Index;
        parItem := selItem.ExtractFromParent(True);
        selItem.JsonData.Free;
        selItem.Free;
        if LIndex < parItem.Count then
          parItem.Items[LIndex].Select
        else if parItem.Count > 0 then
          parItem.Items[parItem.Count - 1].Select
        else
          parItem.Select;
      end;
    end);
end;

procedure TfmDocument.rctBtnExpandAllMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if tvJson.Selected <> nil then
  begin
    if tvJson.Selected.ParentItem <> nil then
    begin
      tvJson.Selected.ExpandAll;
    end
    else
    begin
      tvJson.ExpandAll;
    end;
  end
  else
  begin
    tvJson.ExpandAll;
  end;
end;

procedure TfmDocument.rctBtnMaxClick(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  if WindowState = TWindowState.wsMaximized then
  begin
    WindowState := TWindowState.wsNormal;
  end
  else
  begin
    WindowState := TWindowState.wsMaximized;
  end;
{$ENDIF}
end;

procedure TfmDocument.rctBtnMinClick(Sender: TObject);
begin
  fmMain.OnActivate := nil;
  try
    Hide;
    if g_pub.DocumentWindowList.NumOfVisible <= 0 then
    begin
      fmMain.WindowState := TWindowState.wsMinimized;
      fmMain.Deactivate;
    end;
  finally
    fmMain.OnActivate := fmMain.FormActivate;
  end;

end;

procedure TfmDocument.rctBtnMoveDownMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  fmMain.actEditMoveDownExecute(Sender);
end;

procedure TfmDocument.rctBtnMoveUpMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  fmMain.actEditMoveUpExecute(Sender);
end;

procedure TfmDocument.miFileOpenRecentApplyStyleLookup(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  if TThread.GetTickCount - miFileOpenRecent.Tag > 2000 then // 防止多次触发
  begin
    InitRecentFile;
    miFileOpenRecent.Tag := TThread.GetTickCount;
  end;
{$ENDIF}
end;

procedure TfmDocument.miFileOepnedClick(Sender: TObject);
begin
  if TMenuItem(Sender).TagObject <> nil then
  begin
    TfmDocument(TMenuItem(Sender).TagObject).Show;
    //TfmDocument(TMenuItem(Sender).TagObject).Activate;
    //TfmDocument(TMenuItem(Sender).TagObject).BringToFront;
  end;
end;

procedure TfmDocument.miRecentFilesClick(Sender: TObject);
var
  LFilename: string;
  LDocWin: TDocumentWindow;
begin
  if TMenuItem(Sender).Tag = -100 then
  begin
    g_pub.Config['recent'] := nil;
  end
  else
  begin
    LFilename := TMenuItem(Sender).Text;
    LDocWin := g_pub.DocumentWindowList.GetWindowByFilename(LFilename);
    if LDocWin <> nil then
      LDocWin.Show
    else
      OpenFile(LFilename);
  end;
end;

procedure TfmDocument.miWindowShowAllApplyStyleLookup(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  if TThread.GetTickCount - miWindowItems.Tag > 2000 then // 防止多次触发
  begin
    InitOpenedFileMenu;
    miWindowItems.Tag := TThread.GetTickCount;
  end;
{$ENDIF}
end;

procedure TfmDocument.rctIndentClick(Sender: TObject);
begin
  FIsUpdating := True;
  try
    case Indent of
      0:
        Indent := 2;
      2:
        Indent := 4;
      4:
        Indent := 0;
    end;
    //Indent := IfThen(Indent = 2, 4, 2);
  finally
    FIsUpdating := False;
  end;
end;

procedure TfmDocument.JsonFileDragDrop(Sender: TObject;
const
  Data:
  TDragObject;
const
  Point:
  TPointF);
begin
  if Length(Data.Files) = 1 then
  begin
    OpenFile(Data.Files[0]);
  end;
end;

procedure TfmDocument.JsonFileDragOver(Sender: TObject;
const
  Data:
  TDragObject;
const
  Point:
  TPointF;
var
  Operation: TDragOperation);
begin
  if Length(Data.Files) = 1 then
    Operation := TDragOperation.Link;
end;

procedure TfmDocument.lblErrorInfoClick(Sender: TObject);
begin

  if FJsonErrorData.FIsPositionable then
  begin
    mmoEdit.CaretPosition := TCaretPosition.Create(FJsonErrorData.FLine - 1, FJsonErrorData.FPosition - 1);
  end;
end;

procedure TfmDocument.lblFileChangedExternallyClick(Sender: TObject);
begin
  rctFileChangedExternally.Visible := False;
  OpenFile(Doc.FileName);
end;

procedure TfmDocument.rctWordWarpClick(Sender: TObject);
begin
  WordWarp := not WordWarp;
end;

procedure TfmDocument.slL_RMouseUp(Sender: TObject;
Button: TMouseButton;
Shift: TShiftState;
X, Y: Single);
begin
  FRightPanelWidthPercent := rctRight.Width / (pnlSizeBorder.Width - 10);
end;

procedure TfmDocument.SetIndent(AValue: integer);
begin
  if FIndent = AValue then
    exit;
  FIndent := AValue;

  lblIndent.Text := AValue.ToString;
  if tvJson.Selected <> nil then
  begin
    if TJSONTreeViewItem(tvJson.Selected).JsonValue.IsObjectOrArray then
    begin
      if FIndent > 0 then
      begin
        mmoEdit.Text := TJSONTreeViewItem(tvJson.Selected).JsonValue.Format(FIndent);
      end
      else
      begin
        mmoEdit.Text := TJSONTreeViewItem(tvJson.Selected).JsonValue.ToString;
      end;
    end;
  end;
end;

function TfmDocument.GetWordWarp: boolean;
begin
  Result := mmoEdit.TextSettings.WordWrap;
end;

procedure TfmDocument.SetWordWarp(AValue: boolean);
begin
  if mmoEdit.TextSettings.WordWrap = AValue then
    exit;
  FIsUpdating := True;
  try
    mmoEdit.TextSettings.WordWrap := AValue;
    pathWordWrap.Fill.Color := IfThen(mmoEdit.TextSettings.WordWrap, $FF00AA00, $FF808080);
  finally
    FIsUpdating := False;
  end;
end;

procedure TfmDocument.InitOpenedFileMenu;
var
  miTmp: TMenuItem;
begin
  miWindowItems.Clear;
  for var item in g_pub.DocumentWindowList do
  begin
    miTmp := TMenuItem.Create(miWindowItems);
    miTmp.TagObject := item;
    miTmp.Text := item.lblFilename.Text;
    miTmp.OnClick := miFileOepnedClick;
    miWindowItems.AddObject(miTmp);
    miTmp.Enabled := self <> item;
  end;
end;

procedure TfmDocument.InitRecentFile;
var
  miTmp: TMenuItem;
begin
  miFileOpenRecent.Clear;
  for var item in g_pub.Config['recent'] do
  begin
    miTmp := TMenuItem.Create(miFileOpenRecent);
    miTmp.Text := item;
    miTmp.OnClick := miRecentFilesClick;
    miFileOpenRecent.AddObject(miTmp);
    miTmp.Enabled := (miTmp.Text <> FDoc.FileName) and FileExists(miTmp.Text);
  end;
  if miFileOpenRecent.ItemsCount > 0 then
  begin
    miTmp := TMenuItem.Create(miFileOpenRecent);
    miTmp.Text := '-';
    miFileOpenRecent.AddObject(miTmp);
    miTmp := TMenuItem.Create(miFileOpenRecent);
    //miTmp.Text := 'Clear';
    //miTmp.Tag := -100;
    miTmp.Action := fmMain.actFileClearRecent;
    //miTmp.OnClick := miRecentFilesClick;
    miFileOpenRecent.AddObject(miTmp);
  end
  else
  begin
    miTmp := TMenuItem.Create(miFileOpenRecent);
    miTmp.Text := 'No file！';
    miTmp.Enabled := False;
    miFileOpenRecent.AddObject(miTmp);
  end;
end;

procedure TfmDocument.ShowInfo(AText: string; ALevel: integer = 0; ADelay: Single = 3.0);
begin
  aniMsg.Stop;
  lblPath.Visible := False;
  txtMsg.Text := AText;
  case ALevel of
    0:
      txtMsg.TextSettings.FontColor := IfThen(fmMain.actViewDarkStyle.Checked, $FFFFFFFF, $FF000000);
    1:
      txtMsg.TextSettings.FontColor := $FFFF0000;
  end;
  txtMsg.Opacity := 1.0;
  aniMsg.Delay := ADelay;
  aniMsg.Start;
end;

initialization

end.

unit FormMain;

interface

uses
{$IFDEF MACOS}
  MacOpenFileDelegate, Macapi.AppKit, Macapi.ObjectiveC, Macapi.Foundation,
  Macapi.Helpers, FMX.Platform.Mac,
{$ELSE}
  FMXTrayIcon, FMX.Platform.Win, Winapi.Windows,
{$ENDIF}
  SaveDialogsEnhanced, FileWatcher,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.IOUtils,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, System.Actions,
  FMX.ActnList, FMX.Menus;

type
  TfmMain = class(TForm)
    StyleBookBlack: TStyleBook;
    StyleBookWhite: TStyleBook;
    actsMain: TActionList;
    actFileNew: TAction;
    actFileOpen: TAction;
    OpenDialog: TOpenDialog;
    actFileSave: TAction;
    actFileSaveAs: TAction;
    actFileClose: TAction;
    actViewShowLog: TAction;
    actViewDarkStyle: TAction;
    actViewFont: TAction;
    actHelpHelp: TAction;
    actHelpAbout: TAction;
    actEditMoveUp: TAction;
    actEditMoveDown: TAction;
    mmMain: TMainMenu;
    miFile: TMenuItem;
    miEdit: TMenuItem;
    miNone: TMenuItem;
    miFileNew: TMenuItem;
    miFileOpen: TMenuItem;
    miSystem: TMenuItem;
    miHelpAbout: TMenuItem;
    miOption: TMenuItem;
    miSystemExit: TMenuItem;
    miSystemUpdate: TMenuItem;
    miFileSave: TMenuItem;
    miFileSaveAs: TMenuItem;
    miEditMoveUp: TMenuItem;
    miEditMoveDown: TMenuItem;
    miView: TMenuItem;
    miViewShowLog: TMenuItem;
    miViewDarkStyle: TMenuItem;
    miFileClose: TMenuItem;
    miFileOpenRecent: TMenuItem;
    mi1: TMenuItem;
    mi2: TMenuItem;
    actFile: TAction;
    actViewLang: TAction;
    actEdit: TAction;
    miViewLang: TMenuItem;
    actView: TAction;
    actWindow: TAction;
    actHelp: TAction;
    actSystemUpdate: TAction;
    actFileOpenRecent: TAction;
    actWindowItems: TAction;
    actWindowShowAll: TAction;
    actFileClearRecent: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure actFileNewExecute(Sender: TObject);
    procedure actFileOpenExecute(Sender: TObject);
    procedure actFileSaveExecute(Sender: TObject);
    procedure actFileSaveAsExecute(Sender: TObject);
    procedure actFileCloseExecute(Sender: TObject);
    procedure actViewShowLogExecute(Sender: TObject);
    procedure actViewDarkStyleExecute(Sender: TObject);
    procedure actViewFontExecute(Sender: TObject);
    procedure actHelpAboutExecute(Sender: TObject);
    procedure actEditMoveUpExecute(Sender: TObject);
    procedure actEditMoveDownExecute(Sender: TObject);
    procedure miSystemExitClick(Sender: TObject);
    procedure actViewLangExecute(Sender: TObject);
    procedure actNoneExecute(Sender: TObject);
    procedure actWindowShowAllExecute(Sender: TObject);
    procedure actFileClearRecentExecute(Sender: TObject);
  private
    FSaveDialog: TEnhancedSaveDialog;
    FFileWatcher: TFileWatcher;
{$IFDEF MSWINDOWS}
    FTrayIcon: TTrayIcon;
    procedure OnRunOnlyOnce(ASender: TObject; AParams: TArray<String>);
{$ELSE}
    procedure InitMacOsMenu;
{$ENDIF}
  public
    property FileWatcher: TFileWatcher read FFileWatcher write FFileWatcher;
{$IFDEF MACOS}
    procedure InitMacOsRecentFile;
    procedure RecentFileClick(Sender: TObject);
{$ENDIF}
    procedure SetLang;
  end;

var
  fmMain: TfmMain;

implementation

{$R *.fmx}


uses JsonDocument, pub, Logger, FormLogger, FormAbout, JSONTreeView;

{$IFDEF MSWINDOWS}


{-------------------------------------------------------------------------------
  名称: TfmMain.OnRunOnlyOnce
  说明: 程序重复运行事件
  参数: ASender
        AParams
-------------------------------------------------------------------------------}
procedure TfmMain.OnRunOnlyOnce(ASender: TObject; AParams: TArray<String>);
begin
  if Length(AParams) > 1 then
  begin
    for var item in g_pub.DocumentWindowList do
    begin
      if item.Doc.FileName = AParams[1] then
      begin
        item.Show;
        item.Activate;
        item.BringToFront;
        Exit;
      end;
    end;
    var
    lastForm := g_pub.DocumentWindowList.ActiveWindow;
    if lastForm = nil then
      lastForm := g_pub.DocumentWindowList.Last;
    with TDocumentWindow.Create(nil) do
    begin
      Show;
      OpenFile(AParams[1]);
      Left := lastForm.Left + 20;
      Top := lastForm.Top + 28;
    end;
  end
  else
  begin
    var
    lastForm := g_pub.DocumentWindowList.Last;
    with TDocumentWindow.Create(nil) do
    begin
      Show;
      NewFile;
      Left := lastForm.Left + 20;
      Top := lastForm.Top + 28;
    end;
  end;
end;

{$ELSE}


{-------------------------------------------------------------------------------
  名称: OpenFileDelegate
  说明: 处理文件关联打开
  参数: AFilename
-------------------------------------------------------------------------------}
procedure OpenFileDelegate(const AFilename: string);
var
  LDocForm: TDocumentWindow;
begin
  if FileExists(AFilename) then
  begin
    if (g_pub.DocumentWindowList.Count = 1) and (g_pub.DocumentWindowList.First.Doc.FileName = '') then
    begin
      g_pub.DocumentWindowList.Last.OpenFile(AFilename);
    end
    else
    begin
      for var item in g_pub.DocumentWindowList do
      begin
        if item.Doc.FileName = AFilename then
        begin
          item.Activate;
          item.BringToFront;
          Exit;
        end;
      end;
      var
      lastForm := g_pub.DocumentWindowList.Last;
      LDocForm := TDocumentWindow.Create(nil);
      LDocForm.Show;
      LDocForm.OpenFile(AFilename);
      LDocForm.Left := lastForm.Left + 20;
      LDocForm.Top := lastForm.Top + 28;
    end;
  end
  else
  begin
    g_Logger.Error('file does not exist - ' + AFilename);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.InitMacOsMenu
  说明: 初始化MacOS菜单
-------------------------------------------------------------------------------}
procedure TfmMain.InitMacOsMenu;
var
  NSApp: NSApplication;
  LMainMenu: NSMenu;
begin
  NSApp := TNSApplication.Wrap(TNSApplication.OCClass.sharedApplication);
  LMainMenu := NSApp.MainMenu;
  LMainMenu.itemAtIndex(0).setHidden(True);
  actFileNew.ShortCut := scCommand + Ord('N');
  actFileOpen.ShortCut := scCommand + Ord('O');
  actFileClose.ShortCut := scCommand + Ord('W');
  actFileSave.ShortCut := scCommand + Ord('S');
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.InitMacOsRecentFile
  说明: 初始化Mac下的历史文件菜单
-------------------------------------------------------------------------------}
procedure TfmMain.InitMacOsRecentFile;
var
  miTmp: TMenuItem;
begin
  miFileOpenRecent.Clear;
  for var item in g_pub.Config['recent'] do
  begin
    miTmp := TMenuItem.Create(fmMain.miFileOpenRecent);
    miTmp.Text := item;
    miTmp.OnClick := RecentFileClick;
    miFileOpenRecent.AddObject(miTmp);
    miTmp.Enabled := FileExists(miTmp.Text);
  end;
  if miFileOpenRecent.ItemsCount > 0 then
  begin
    miTmp := TMenuItem.Create(miFileOpenRecent);
    miTmp.Text := '-';
    miFileOpenRecent.AddObject(miTmp);
    miTmp := TMenuItem.Create(miFileOpenRecent);
    miTmp.Action := actFileClearRecent;
    miFileOpenRecent.AddObject(miTmp);
  end
  else
  begin
    miTmp := TMenuItem.Create(miFileOpenRecent);
    miTmp.Text := 'No file';
    miTmp.Enabled := False;
    miFileOpenRecent.AddObject(miTmp);
  end;
end;

procedure TfmMain.RecentFileClick(Sender: TObject);
var
  LFilename: string;
  LDocWin: TDocumentWindow;
begin
  LFilename := TMenuItem(Sender).Text;
  LDocWin := g_pub.DocumentWindowList.GetWindowByFilename(LFilename);
  if LDocWin <> nil then
  begin
    LDocWin.Show;
  end
  else
  begin
    LDocWin := TDocumentWindow.Create(nil);
    LDocWin.Show;
    LDocWin.OpenFile(LFilename);
  end;
end;

{$ENDIF}


{-------------------------------------------------------------------------------
  名称: TfmMain.miSystemExitClick
  说明: 退出
-------------------------------------------------------------------------------}
procedure TfmMain.miSystemExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfmMain.FormCreate(Sender: TObject);
var
  LDocForm: TDocumentWindow;
begin
  Left := -102400;
  fmLogger := TfmLogger.Create(nil);
  FFileWatcher := TFileWatcher.Create(1000);
  FFileWatcher.OnFileChanged := procedure(const FileName: string; ChangedType: TFileChangeType; const WatchTarget: TWatchTarget)
    var
      LDForm: TDocumentWindow;
    begin
      g_Logger.Info('文件发生变化:' + FileName);
      LDForm := g_pub.DocumentWindowList.GetWindowByFilename(FileName);
      if LDForm <> nil then
      begin
        LDForm.rctFileChangedExternally.Visible := True;
      end;
    end;

  FFileWatcher.OnWatchErrorEvent := procedure(const AErr: string)
    begin
      g_Logger.Error('FileWatcher.OnError: ' + AErr);
    end;

  FFileWatcher.OnWatchTargetsChanged := procedure(const Target: TWatchTarget; ChangeType: TWatchTargetChangeType)
    begin
      case ChangeType of
        wtcAdded:
          g_Logger.Debug('添加监控: ' + Target.Path);
        wtcRemoved:
          g_Logger.Debug('移除监控: ' + Target.Path);
        wtcCleared:
          begin
            g_Logger.Debug('清空监控');
          end;
      end;
    end;
  FFileWatcher.StartWatching;
{$IFDEF MACOS} // 初始化mac下的语言选择菜单
  miViewLang.Clear;
  for var item in g_pub.Languages do
  begin
    var
    mi := TMenuItem.Create(miViewLang);
    mi.Text := item['caption'].ToStr('None');
    mi.RadioItem := True;
    mi.GroupIndex := 10;
    mi.OnClick := actViewLangExecute;
    miViewLang.AddObject(mi);
  end;
{$ENDIF}
  FSaveDialog := TEnhancedSaveDialog.Create(self);
  FSaveDialog.DefaultExt := 'json';
  FSaveDialog.Filter := '缩进格式|*.json|缩进格式、转义非ASCII字符|*.json|紧凑格式|*.json|紧凑格式、转义非ASCII字符|*.json';
  SetLang;
  LDocForm := TDocumentWindow.Create(nil);
  LDocForm.Show;
  LDocForm.NewFile;
{$IFDEF MSWINDOWS}
  FTrayIcon := TTrayIcon.Create(self);
  FTrayIcon.RunOnlyOnce := True;
  FTrayIcon.OnRunOnlyOnce := OnRunOnlyOnce;
  if ParamCount > 0 then
  begin
    if FileExists(ParamStr(1)) then
    begin
      LDocForm.OpenFile(ParamStr(1));
    end
    else
    begin
      g_Logger.Error('File does not exist - ' + ParamStr(1));
    end;
  end;
{$ELSE}
  width := 1;
  height := 1;
  InitMacOsMenu;
  InitMacOsRecentFile;
  InstallApplicationOpenFileDelegate(OpenFileDelegate);
{$ENDIF}
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  FFileWatcher.StopWatching;
  FFileWatcher.Free;
  fmLogger.Free;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.FormActivate
  说明: 窗口激活
  参数: Sender
-------------------------------------------------------------------------------}
procedure TfmMain.FormActivate(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  g_pub.DocumentWindowList.ShowAll;
{$ENDIF}
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.FormClose
  说明: 窗口关闭
  参数: Sender
        Action
-------------------------------------------------------------------------------}
procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
{$IFDEF MSWINDOWS}
  for var item in g_pub.DocumentWindowList do
  begin
    item.OnClose := nil;
    item.Free;
  end;
{$ENDIF}
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actFileClearRecentExecute
  说明: 清除历史文件
-------------------------------------------------------------------------------}
procedure TfmMain.actFileClearRecentExecute(Sender: TObject);
begin
  g_pub.Config['recent'] := nil;
{$IFDEF MACOS}
  InitMacOsRecentFile;
{$ENDIF}
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actFileCloseExecute
  说明: 关闭文件
  参数: Sender
-------------------------------------------------------------------------------}
procedure TfmMain.actFileCloseExecute(Sender: TObject);
begin
  if g_pub.DocumentWindowList.ActiveWindow <> nil then
    g_pub.DocumentWindowList.ActiveWindow.Close;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actNoneExecute
  说明: 空函数，为了使Action生效
-------------------------------------------------------------------------------}
procedure TfmMain.actNoneExecute(Sender: TObject);
begin
  //
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actFileNewExecute
  说明: 新建文件
  参数: Sender
-------------------------------------------------------------------------------}
procedure TfmMain.actFileNewExecute(Sender: TObject);
var
  LDocWin: TDocumentWindow;
begin
  LDocWin := TDocumentWindow.Create(nil);
  LDocWin.Show;
  LDocWin.NewFile;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actFileOpenExecute
  说明: 打开文件
  参数: Sender
-------------------------------------------------------------------------------}
procedure TfmMain.actFileOpenExecute(Sender: TObject);
var
  LDocWin: TDocumentWindow;
begin
  if not OpenDialog.Execute then
    Exit;
  LDocWin := g_pub.DocumentWindowList.GetWindowByFilename(OpenDialog.FileName);
  if LDocWin <> nil then
  begin
    LDocWin.Show;
  end
  else
  begin
    LDocWin := TDocumentWindow.Create(nil);
    LDocWin.Show;
    LDocWin.OpenFile(OpenDialog.FileName);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actFileSaveExecute
  说明: 保存文件
  参数: Sender
-------------------------------------------------------------------------------}
procedure TfmMain.actFileSaveExecute(Sender: TObject);
begin
  if not g_pub.DocumentWindowList.HasActiveWindow then
    Exit;
  if g_pub.DocumentWindowList.ActiveWindow.Doc.FileName <> '' then
  begin
    g_pub.DocumentWindowList.ActiveWindow.Doc.Save(g_pub.DocumentWindowList.ActiveWindow.Doc.FileName, g_pub.Config['editor.indent'].ToInt(4));
    g_pub.DocumentWindowList.ActiveWindow.ShowInfo('文件保存成功！');
  end
  else
  begin
    actFileSaveAsExecute(nil);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actFileSaveAsExecute
  说明: 另存为
  参数: Sender
-------------------------------------------------------------------------------}
procedure TfmMain.actFileSaveAsExecute(Sender: TObject);
begin
  if g_pub.DocumentWindowList.LastActive.Doc.FileName = '' then
  begin
    FSaveDialog.FileName := c_untitled_filename;
  end
  else
  begin
    FSaveDialog.InitialDir := ExtractFileDir(g_pub.DocumentWindowList.LastActive.Doc.FileName);
    FSaveDialog.FileName := ExtractFileName(g_pub.DocumentWindowList.LastActive.Doc.FileName);
  end;

  if FSaveDialog.Execute then
  begin
    //if g_pub.DocumentWindowList.LastActive.Doc.FileName <> '' then
    case FSaveDialog.FilterIndex of
      1:
        g_pub.DocumentWindowList.LastActive.Doc.Save(FSaveDialog.FileName, g_pub.Config['editor.indent'].ToInt(4), True, False, False);
      2:
        g_pub.DocumentWindowList.LastActive.Doc.Save(FSaveDialog.FileName, g_pub.Config['editor.indent'].ToInt(4), True, True, False);
      3:
        g_pub.DocumentWindowList.LastActive.Doc.Save(FSaveDialog.FileName, -1, True, False, False);
      4:
        g_pub.DocumentWindowList.LastActive.Doc.Save(FSaveDialog.FileName, -1, True, True, False);
    end;
    g_pub.DocumentWindowList.LastActive.ShowInfo('文件另存成功！');
  end;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actEditMoveDownExecute
  说明: 上移
  参数: Sender
-------------------------------------------------------------------------------}
procedure TfmMain.actEditMoveDownExecute(Sender: TObject);
var
  LItem: TJSONTreeViewItem;
  LDocWin: TDocumentWindow;
begin
  if not g_pub.DocumentWindowList.HasActiveWindow then
    Exit;
  LDocWin := g_pub.DocumentWindowList.ActiveWindow;
  LItem := TJSONTreeViewItem(LDocWin.tvJson.Selected);
  if LItem = nil then
    Exit;
  if (LItem.ParentItem = nil) then
    Exit;
  if (LItem.Index >= LItem.ParentItem.Count - 1) then
    Exit;
  LItem.TreeView.Selected := nil;
  TJSONTreeViewItem(LItem.ParentItem).MoveItem(LItem.Index, LItem.Index + 1, True);
  LItem.Select;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actEditMoveUpExecute
  说明: 下移
  参数: Sender
-------------------------------------------------------------------------------}
procedure TfmMain.actEditMoveUpExecute(Sender: TObject);
var
  LItem: TJSONTreeViewItem;
  LDocWin: TDocumentWindow;
begin
  if not g_pub.DocumentWindowList.HasActiveWindow then
    Exit;
  LDocWin := g_pub.DocumentWindowList.ActiveWindow;
  LItem := TJSONTreeViewItem(LDocWin.tvJson.Selected);
  if LItem = nil then
    Exit;
  if (LItem.ParentItem = nil) or (LItem.Index <= 0) then
    Exit;
  if (LItem.Index = 0) then
    Exit;
  LItem.TreeView.Selected := nil;
  TJSONTreeViewItem(LItem.ParentItem).MoveItem(LItem.Index, LItem.Index - 1, True);
  LItem.Select;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actViewDarkStyleExecute
  说明: 设置暗黑风格
  参数: Sender
-------------------------------------------------------------------------------}
procedure TfmMain.actViewDarkStyleExecute(Sender: TObject);
begin
  g_pub.IsDarkStyle := not g_pub.IsDarkStyle;
  actViewDarkStyle.Checked := g_pub.IsDarkStyle;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actViewFontExecute
  说明: 设置字体
-------------------------------------------------------------------------------}
procedure TfmMain.actViewFontExecute(Sender: TObject);
//var
//  LDialog: TFontDialog;
begin
  {LDialog := TFontDialog.Create(nil);
  try
    LDialog.StyleBook := StyleBook;
    LDialog.rctTitleBar.Fill.Color := rctTitleBar.Fill.Color; // 标题栏背景
    LDialog.pathCloseBtn.Fill.Color := pathCloseBtn.Fill.Color;
    if LDialog.ShowModal(mmoEdit.TextSettings) = mrOK then
    begin
      g_pub.Config[ActiveControl.Name + '.TextSettings'].LoadFromObject(mmoEdit.TextSettings);
      g_pub.SaveConfig;
    end;
  finally
    FreeAndNil(LDialog);
  end;}
end;

procedure TfmMain.actViewLangExecute(Sender: TObject);
begin
  if Sender is TMenuItem then
  begin
    g_pub.LangIndex := TMenuItem(Sender).Index;
    SetLang;
  end;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actViewShowLogExecute
  说明: 显示日志
  参数: Sender
-------------------------------------------------------------------------------}
procedure TfmMain.actViewShowLogExecute(Sender: TObject);
begin
  fmLogger.Show;
end;

procedure TfmMain.actWindowShowAllExecute(Sender: TObject);
var
  LOldOnActivate: TNotifyEvent;
begin
  for var item in g_pub.DocumentWindowList do
  begin
    LOldOnActivate := item.OnActivate;
    item.OnActivate := nil;
    item.Show;
    item.OnActivate := LOldOnActivate;
  end;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.actHelpAboutExecute
  说明: 关于...
  参数: Sender
-------------------------------------------------------------------------------}
procedure TfmMain.actHelpAboutExecute(Sender: TObject);
begin
  TfmAbout.Create(nil).Show;
end;

{-------------------------------------------------------------------------------
  名称: TfmMain.SetLang
  说明: 设置语言
-------------------------------------------------------------------------------}
procedure TfmMain.SetLang;
var
  actItem: TAction;
  strTmp: string;
begin
  for var item in actsMain do
  begin
    actItem := TAction(item);
    strTmp := g_pub.LangStr(actItem.Name);
    if strTmp <> '' then
    begin
      actItem.Text := g_pub.LangStr(actItem.Name);
    end;
  end;
{$IFDEF MACOS}
  miViewLang.Items[g_pub.LangIndex].IsChecked := True;
  miHelpAbout.Text := actHelpAbout.Text;
{$ENDIF}
  for var item in g_pub.DocumentWindowList do
  begin
    item.SetLang;
  end;
end;

initialization

end.

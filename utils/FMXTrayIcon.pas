{
  TrayIcon for FMX v0.5
  by gale 2025-02-13
  https://github.com/higale
}
unit FMXTrayIcon;

interface

uses
{$IFDEF MSWINDOWS}
  Vcl.Graphics, WinAPI.Messages, WinAPI.Windows, WinAPI.ShellAPI, FMX.Platform.Win,
  System.Messaging, System.IOUtils,
{$ELSE}
  Macapi.ObjectiveC, Macapi.CocoaTypes, Macapi.Foundation, Macapi.AppKit, FMX.Dialogs,
  Macapi.Helpers, Macapi.ObjcRuntime, System.TypInfo, FMX.Platform, FMX.Platform.Mac,
  Posix.Unistd, // 添加这个单元以使用 getpid
{$ENDIF}
  System.hash, System.SysUtils, System.Types, System.Classes, FMX.Types, FMX.Forms,
  FMX.Menus;

const
{$IFDEF MSWINDOWS}
  WM_ICONTRAY = WM_USER + 1;
  WM_RUNONLYONCE = WM_USER + 2;
{$ELSE}
  MACOS_TAG = 1;
{$ENDIF}


type
  TNotifyEventRef = reference to procedure(sender: TObject);
  TOnRunOnlyOnce = reference to procedure(sender: TObject; AParam: TArray<String>);
  TBalloonIconType = (None, Info, Warning, Error, User, BigWarning, BigError);

{$IFDEF MACOS}

  IClickHandler = interface(NSObject)
    ['{B3B9C05D-8909-4419-BC8C-ACE5CFE6388D}']
    procedure click(sender: id); cdecl;
    procedure menuItemClick(sender: id); cdecl;
  end;

  TTrayIcon = class;

  TClickHandler = class(TOCLocal)
  private
    FOwner: TTrayIcon;
  public
    procedure click(sender: id); cdecl;
    procedure menuItemClick(sender: id); cdecl;
    function GetObjectiveCClass: PTypeInfo; override;
  end;
{$ENDIF}

  TTrayIcon = class(TComponent)
{$IFDEF MSWINDOWS}
  private
    class var FRunOnlyOnceTag: string;
    class var FHasOtherRunning: Boolean;
    class procedure CheckRunOnce;
  public
    class property HasOtherRunning: Boolean read FHasOtherRunning;
{$ENDIF}
  private
{$IFDEF MSWINDOWS}
    FTrayWnd: HWND;
    FTrayIconData: TNotifyIconData;
    FIcon: TIcon;
    FShowingPopup: Boolean;
{$ELSE}
    FStatItem: NSStatusItem;
    FClickHandler: TClickHandler;
{$ENDIF}
    FIconFile: string;
    FPopupMenu: TPopupMenu;
    FHint: string;
    FVisible: Boolean;
    FRunOnlyOnce: Boolean;
    FOnRunOnlyOnce: TOnRunOnlyOnce;
    FOnClick: TNotifyEventRef;
    FOnDblClick: TNotifyEventRef;
    function GetShowAppOnTaskbar: Boolean;
    procedure SetShowAppOnTaskbar(AValue: Boolean);
    procedure SetHint(Value: string);
    procedure SetIconFile(Value: string);
    procedure SetPopupMenu(Value: TPopupMenu);
{$IFDEF MSWINDOWS}
    procedure TrayWndProc(var Message: WinAPI.Messages.TMessage);
    procedure FOnPopupForm(const sender: TObject; const M: TMessage);
{$ELSE}

{$ENDIF}
    procedure SetVisible(Value: Boolean);
    procedure SetRunOnlyOnce(Value: Boolean);
  public
    property IconFile: string read FIconFile write SetIconFile;
    property PopupMenu: TPopupMenu read FPopupMenu write SetPopupMenu;
    property Hint: string read FHint write SetHint;
    property Visible: Boolean read FVisible write SetVisible default False;
    property RunOnlyOnce: Boolean read FRunOnlyOnce write SetRunOnlyOnce default False;
    property ShowAppOnTaskbar: Boolean read GetShowAppOnTaskbar write SetShowAppOnTaskbar;
    property OnRunOnlyOnce: TOnRunOnlyOnce read FOnRunOnlyOnce write FOnRunOnlyOnce;
    property OnClick: TNotifyEventRef read FOnClick write FOnClick;
    property OnDblClick: TNotifyEventRef read FOnDblClick write FOnDblClick;
  public
    procedure ShowBalloonHint(Title, Text: string; BalloonIcon: TBalloonIconType);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$IFDEF MSWINDOWS}


class procedure TTrayIcon.CheckRunOnce;
var
  hRunOnce: HWND;
  strs: TStrings;
  strParmFile: string;
begin
  FRunOnlyOnceTag := System.hash.THashSHA1.GetHashString(ParamStr(0).ToLower);
  FHasOtherRunning := False;
  hRunOnce := WinAPI.Windows.FindWindow('TPUtilWindow', PChar(TTrayIcon.FRunOnlyOnceTag));
  if IsWindow(hRunOnce) then
  begin
    strParmFile := TPath.GetTempPath + TTrayIcon.FRunOnlyOnceTag + '_run_only_once.txt';
    strs := TStringList.Create;
    Try
      for var i := 0 to ParamCount do
        strs.Add(ParamStr(i));
      strs.SaveToFile(strParmFile);
    Finally
      strs.Free;
    End;
    PostMessage(hRunOnce, WM_RUNONLYONCE, 0, 0);
    TTrayIcon.FHasOtherRunning := true;
    Application.Terminate;
    Application.Terminated := true;
  end;
end;
{$ENDIF}


constructor TTrayIcon.Create(AOwner: TComponent);
{$IFDEF MACOS}
var
  LStatBar: NSStatusBar;
  LImg: NSImage;
{$ENDIF}
begin
  inherited Create(AOwner);
  FRunOnlyOnce := False;
{$IFDEF MSWINDOWS}
  FShowingPopup := False;
  FIcon := nil;
  TMessageManager.DefaultManager.SubscribeToMessage(TFormBeforeShownMessage, FOnPopupForm);
  FTrayWnd := AllocateHWnd(TrayWndProc);
  FTrayIconData.cbSize := System.SizeOf(FTrayIconData);
  FTrayIconData.Wnd := FTrayWnd;
  FTrayIconData.uID := 1;
  FTrayIconData.uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
  FTrayIconData.uCallbackMessage := WM_ICONTRAY;
  FTrayIconData.hIcon := GetClassLong(FmxHandleToHWND((AOwner as TForm).Handle), GCL_HICONSM);
{$ELSE}
  FClickHandler := TClickHandler.Create;
  FClickHandler.FOwner := Self;
  LStatBar := TNSStatusBar.Wrap(TNSStatusBar.OCClass.systemStatusBar);
  FStatItem := LStatBar.statusItemWithLength(NSVariableStatusItemLength);

  FIconFile := NSStrToStr(TNSBundle.Wrap(TNSBundle.OCClass.mainBundle).resourcePath.stringByAppendingString(StrToNSStr('/' + ExtractFileName(ParamStr(0)) + '.icns')));
  LImg := TNSImage.Wrap(TNSImage.Alloc.initWithContentsOfFile(StrToNSStr(FIconFile)));
  LImg.setSize(NSSize(TSizeF.Create(16, 16)));
  FStatItem.setImage(LImg);
  LImg.release;

  FStatItem.setTarget(FClickHandler.GetObjectID);
  FStatItem.setAction(sel_getUid(PAnsiChar('click:')));
{$ENDIF}
end;

destructor TTrayIcon.Destroy;
begin
{$IFDEF MSWINDOWS}
  TMessageManager.DefaultManager.Unsubscribe(TFormBeforeShownMessage, FOnPopupForm);
  if FVisible then
  begin
    Shell_NotifyIcon(NIM_DELETE, @FTrayIconData);
  end;
  FIcon.Free;
{$ELSE}
  FClickHandler.Free;
{$ENDIF}
  inherited;
end;

procedure TTrayIcon.ShowBalloonHint(Title, Text: string; BalloonIcon: TBalloonIconType);
{$IFDEF MSWINDOWS}
begin
  with FTrayIconData do
  begin
    StrLCopy(szInfo, PChar(Text), High(szInfo));
    StrLCopy(szInfoTitle, PChar(Title), High(szInfoTitle));
    dwInfoFlags := Ord(BalloonIcon);
    uFlags := NIF_INFO;
  end;
  Shell_NotifyIcon(NIM_MODIFY, @FTrayIconData);
end;
{$ELSE}


var
  Notification: NSUserNotification;
  Center: NSUserNotificationCenter;
begin
  // 使用 NSUserNotification 模拟气泡提示
  Center := TNSUserNotificationCenter.Wrap(TNSUserNotificationCenter.OCClass.defaultUserNotificationCenter);
  Notification := TNSUserNotification.Create;
  Notification.setTitle(StrToNSStr(Title));
  Notification.setInformativeText(StrToNSStr(Text));
  // 发送通知
  Center.deliverNotification(Notification);
end;
{$ENDIF}


function TTrayIcon.GetShowAppOnTaskbar: Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := (GetWindowLong(ApplicationHWND, GWL_EXSTYLE) and WS_EX_TOOLWINDOW) = 0;
{$ELSE}
  Result := TNSApplication.Wrap(TNSApplication.OCClass.sharedApplication).activationPolicy = NSApplicationActivationPolicyRegular;
{$ENDIF}
end;

procedure TTrayIcon.SetShowAppOnTaskbar(AValue: Boolean);
begin
{$IFDEF MSWINDOWS}
  if AValue then
  begin
    SetWindowLong(ApplicationHWND, GWL_EXSTYLE, GetWindowLong(ApplicationHWND, GWL_EXSTYLE) and (not WS_EX_APPWINDOW) and not WS_EX_TOOLWINDOW);
  end
  else
  begin
    SetWindowLong(ApplicationHWND, GWL_EXSTYLE, GetWindowLong(ApplicationHWND, GWL_EXSTYLE) and (not WS_EX_APPWINDOW) or WS_EX_TOOLWINDOW);
  end;
{$ELSE}
  if AValue then
    TNSApplication.Wrap(TNSApplication.OCClass.sharedApplication).setActivationPolicy(NSApplicationActivationPolicyRegular)
  else
    TNSApplication.Wrap(TNSApplication.OCClass.sharedApplication).setActivationPolicy(NSApplicationActivationPolicyAccessory);
{$ENDIF}
end;

procedure TTrayIcon.SetHint(Value: string);
begin
{$IFDEF MSWINDOWS}
  if Value <> FHint then
  begin
    FHint := Value;
    StrLCopy(FTrayIconData.szTip, PChar(FHint), High(FTrayIconData.szTip));
  end;
  Shell_NotifyIcon(NIM_MODIFY, @FTrayIconData);
{$ELSE}
  FStatItem.setToolTip(StrToNSStr(Value));
{$ENDIF}
end;

procedure TTrayIcon.SetIconFile(Value: string);
begin
  if FIconFile = Value then
    Exit;
{$IFDEF MSWINDOWS}
  if Value = FIconFile then
    Exit;

  FreeAndNil(FIcon);
  if Value = '' then
  begin
    FTrayIconData.hIcon := GetClassLong(FmxHandleToHWND((Owner as TForm).Handle), GCL_HICONSM);
  end
  else
  begin
    FIcon := TIcon.Create;
    FIcon.LoadFromFile(Value);
    FTrayIconData.hIcon := FIcon.Handle;
  end;
  if FVisible then
  begin
    FTrayIconData.uFlags := NIF_ICON;
    Shell_NotifyIcon(NIM_MODIFY, @FTrayIconData);
  end;
{$ELSE}
  // 设置图标
  FIconFile := Value;
  var
  LImg := TNSImage.Wrap(TNSImage.Alloc.initWithContentsOfFile(StrToNSStr(Value)));
  LImg.setSize(NSSize(TSizeF.Create(16, 16)));
  FStatItem.setImage(LImg);
  LImg.release;
{$ENDIF}
end;

procedure TTrayIcon.SetPopupMenu(Value: TPopupMenu);
{$IFDEF MACOS}
var
  LNSMenu: NSMenu;
  NSContItem: NSMenuItem;
{$ENDIF}
begin
  if FPopupMenu = Value then
    Exit;
  FPopupMenu := Value;
{$IFDEF MACOS}
  FStatItem.setMenu(nil);
  LNSMenu := TNSMenu.Create;
  FStatItem.setMenu(LNSMenu);
  for var i := 0 to Value.ItemsCount - 1 do
  begin
    if Value.Items[i].Text = '-' then // 添加分隔线
    begin
      FStatItem.menu.addItem(TNSMenuItem.Wrap(TNSMenuItem.OCClass.separatorItem));
    end
    else
    begin
      NSContItem := TNSMenuItem.Create;
      NSContItem.initWithTitle(StrToNSStr(Value.Items[i].Text), sel_getUid(PAnsiChar('menuItemClick:')), StrToNSStr(''));
      NSContItem.setTag(i);
      NSContItem.setTarget(FClickHandler.GetObjectID);
      FStatItem.menu.addItem(NSContItem);
      NSContItem.release;
    end;
  end;

{$ENDIF}
end;

procedure TTrayIcon.SetVisible(Value: Boolean);
begin
{$IFDEF MSWINDOWS}
  if Value <> FVisible then
  begin
    if Value then
    begin
      FVisible := Shell_NotifyIcon(NIM_ADD, @FTrayIconData);
    end
    else
    begin
      Shell_NotifyIcon(NIM_DELETE, @FTrayIconData);
      FVisible := False;
    end;
  end;
{$ELSE}
{$ENDIF}
end;

procedure TTrayIcon.SetRunOnlyOnce(Value: Boolean);
{$IFDEF MACOS}
{var
  Workspace: NSWorkspace;
  RunningApps: NSArray;
  i: Integer;
  CurrentApp: NSRunningApplication;
  BundleID: NSString;
  CurrentPID: Integer;}
{$ENDIF}
begin
  if FRunOnlyOnce = Value then
    Exit;
  FRunOnlyOnce := Value;
{$IFDEF MSWINDOWS}
  if FRunOnlyOnce then
  begin
    WinAPI.Windows.SetWindowText(FTrayWnd, FRunOnlyOnceTag);
  end
  else
  begin
    WinAPI.Windows.SetWindowText(FTrayWnd, '');
  end;
{$ELSE}
  {if FRunOnlyOnce then
  begin
    Workspace := TNSWorkspace.Wrap(TNSWorkspace.OCClass.sharedWorkspace);
    RunningApps := Workspace.runningApplications;
    BundleID := TNSBundle.Wrap(TNSBundle.OCClass.mainBundle).bundleIdentifier;
    CurrentPID := getpid; // 获取当前进程的 PID

    for i := 0 to RunningApps.count - 1 do
    begin
      CurrentApp := TNSRunningApplication.Wrap(RunningApps.objectAtIndex(i));
      if (CurrentApp.bundleIdentifier.isEqualToString(BundleID)) and
        (CurrentApp.processIdentifier <> CurrentPID) then
      begin
        ShowMessage('Another instance is already running.');
        Application.Terminate;
        Exit;
      end;
    end;
  end;}
{$ENDIF}
end;

{$IFDEF MSWINDOWS}


procedure TTrayIcon.TrayWndProc(var Message: WinAPI.Messages.TMessage);
var
  strParmFile: string;
  strs: TStrings;
begin
  if Message.MSG = WM_ICONTRAY then
  begin
    case Message.LParam of
      WM_LBUTTONUP:
        begin
          if Assigned(FOnClick) then
          begin
            FOnClick(Self)
          end
          else if Assigned(FPopupMenu) then
          begin
            SetForegroundWindow(ApplicationHWND);
            FShowingPopup := true;
            try
              FPopupMenu.Popup(Screen.MousePos.X, Screen.MousePos.Y);
            finally
              FShowingPopup := False;
            end;
          end;
        end;
      WM_LBUTTONDBLCLK:
        if Assigned(FOnDblClick) then
          FOnDblClick(Self);
      WM_RBUTTONDOWN:
        begin
          if Assigned(FPopupMenu) then
          begin
            SetForegroundWindow(ApplicationHWND);
            FShowingPopup := true;
            try
              FPopupMenu.Popup(Screen.MousePos.X, Screen.MousePos.Y);
            finally
              FShowingPopup := False;
            end;
          end;
        end;
    end;
  end
  else if Message.MSG = WM_RUNONLYONCE then
  begin
    if Assigned(FOnRunOnlyOnce) then
    begin
      strParmFile := TPath.GetTempPath + TTrayIcon.FRunOnlyOnceTag + '_run_only_once.txt';
      if FileExists(strParmFile) then
      begin
        strs := TStringList.Create;
        try
          strs.LoadFromFile(strParmFile);
          try
            DeleteFile(strParmFile);
          except
          end;
          FOnRunOnlyOnce(Self, strs.ToStringArray);
        finally
          strs.Free;
        end;
      end
      else
      begin
        FOnRunOnlyOnce(Self, []);
      end;
    end;
  end
  else
  begin
    Message.Result := DefWindowProc(FTrayWnd, Message.MSG, Message.WParam, Message.LParam);
  end;
end;

procedure TTrayIcon.FOnPopupForm(const sender: TObject; const M: TMessage);
var
  MSG: TFormBeforeShownMessage absolute M;
begin
  if FShowingPopup and (MSG.Value is TCustomPopupForm) then
  begin
    SetWindowPos(FormToHWND(MSG.Value), HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE or SWP_NOACTIVATE);
  end;
end;

{$ELSE}


procedure TClickHandler.click(sender: id);
  cdecl;
begin
  if Assigned(FOwner.FOnClick) then
  begin
    FOwner.FOnClick(FOwner);
  end;
end;

procedure TClickHandler.menuItemClick(sender: id); cdecl;
var
  MenuItem: NSMenuItem;
begin

  MenuItem := TNSMenuItem.Wrap(sender);
  if Assigned(FOwner.FPopupMenu.Items[MenuItem.tag].OnClick) then
  begin
    FOwner.FPopupMenu.Items[MenuItem.tag].OnClick(FOwner.FPopupMenu.Items[MenuItem.tag]);
  end;
end;

function TClickHandler.GetObjectiveCClass: PTypeInfo;
begin
  Result := TypeInfo(IClickHandler);
end;
{$ENDIF}

initialization

{$IFDEF MSWINDOWS}
  TTrayIcon.CheckRunOnce;
{$ENDIF}

end.

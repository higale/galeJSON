{
   Модуль содержит обработчик сообщения открытия файла для MAC OS GUI приложедля.

   При открытии файла приложением на MAC OS имя файла передается не через
   командную строку, как это делается в Windows, а посылается сообщение application:openFile:
   объектом NSApplication.

   Для того что бы обработать данное сообщение, нужно назначить делегат объекту
   NSApplication приложения, в котором и произвести всю работу.

   Подробнее https://delphihaven.wordpress.com/2012/08/14/associating-a-file-type-on-osx-part3/

   code by: Victor Fedorenkov
   mail: victor.fedorenkov[at]gmail.com
}
unit MacOpenFileDelegate;

interface

type
  TOpenURLEvent = reference to procedure(const AURL: string);
  TOpenFileEvent = reference to procedure(const AFileName: string);

procedure InstallApplicationOpenFileDelegate(AOnOpenFile: TOpenFileEvent;
  AOpenURLEvent: TOpenURLEvent = nil);

implementation

uses
  System.SysUtils, System.RTLConsts, System.Messaging, System.Classes,
  Macapi.ObjectiveC, Macapi.CoreFoundation, Macapi.CocoaTypes, Macapi.AppKit, Macapi.Foundation, FMX.Forms,
  Macapi.ObjCRuntime,

  FMX.Platform, FMX.Platform.Mac, FMX.Helpers.Mac; //,

 // suStringUtilsUnit;

type
  IFMXApplicationDelegate = interface(NSApplicationDelegate)
    ['{A54E08CA-77CC-4F22-B6D9-833DD6AB696D}']
    procedure onMenuClicked(sender: NSMenuItem); cdecl;
  end;

  NSApplicationDelegate2 = interface(IFMXApplicationDelegate)
    ['{BE9AEDB7-80AC-49B1-8921-F226CC9310F4}']
    procedure applicationWillFinishLaunching(Notification: NSNotification); cdecl;
    function application(theApplication: Pointer; openFile: CFStringRef): Boolean; cdecl;
  end;

  IURLEventHandler = interface(IObjectiveC)
    ['{29B79998-AB68-4694-93D7-AA09A1BF08F7}']
    procedure Handle(Event, ReplyEvent: NSAppleEventDescriptor); cdecl;
  end;

  TURLEventHandler = class(TOCLocal, IURLEventHandler)
    FOpenURLEvent: TOpenURLEvent;
  public
    constructor Create(AOpenURLEvent: TOpenURLEvent);

    procedure Handle(Event, ReplyEvent: NSAppleEventDescriptor); cdecl;
  end;

  TNSApplicationDelegate2 = class(TOCLocal, NSApplicationDelegate2)
  private
    FOnOpenFile: TOpenFileEvent;
    FURLEventHandler: TURLEventHandler;
  public
    constructor Create(AOnOpenFile: TOpenFileEvent; AOpenURLEvent: TOpenURLEvent = nil);
    destructor Destroy; override;

    procedure applicationDidFinishLaunching(Notification: NSNotification); cdecl;
    procedure applicationWillTerminate(Notification: NSNotification); cdecl;
    function applicationShouldTerminate(Notification: NSNotification): NSInteger; cdecl;
    function applicationDockMenu(sender: NSApplication): NSMenu; cdecl;
    procedure onMenuClicked(sender: NSMenuItem); cdecl;
    procedure applicationWillFinishLaunching(Notification: NSNotification); cdecl;

    procedure applicationDidHide(Notification: NSNotification); cdecl;
    procedure applicationDidUnhide(Notification: NSNotification); cdecl;

    function application(theApplication: Pointer; openFile: CFStringRef): Boolean; cdecl;
  end;

var
  Delegate: NSApplicationDelegate2;

procedure InstallApplicationOpenFileDelegate(AOnOpenFile: TOpenFileEvent;
  AOpenURLEvent: TOpenURLEvent = nil);
var
  NSApp: NSApplication;
  AutoReleasePool: NSAutoreleasePool;
begin
  AutoReleasePool := TNSAutoreleasePool.Alloc;
  try
    AutoReleasePool.init;
    NSApp := TNSApplication.Wrap(TNSApplication.OCClass.sharedApplication);
    Delegate := TNSApplicationDelegate2.Create(AOnOpenFile, AOpenURLEvent);
    NSApp.setDelegate(NSApplicationDelegate2(Delegate));
  finally
    AutoReleasePool.release;
  end;
end;

//Функция скопирована из FMX.Platform.Mac
function SendOSXMessage(const sender: TObject; const OSXMessageClass: TOSXMessageClass;
  const NSSender: NSObject): NSObject;
var
  MessageObject: TOSXMessageObject;
begin
  if OSXMessageClass = nil then
    raise EArgumentNilException.Create(SArgumentNil);
  MessageObject := TOSXMessageObject.Create(NSSender);
  try
    TMessageManager.DefaultManager.SendMessage(sender, OSXMessageClass.Create(MessageObject, False), True);
    Result := MessageObject.ReturnValue;
  finally
    MessageObject.Free;
  end;
end;

//Проверка, занилена ли глобальная переменная PlatformCocoa из FMX.Platform.Mac
function PlatformCocoaIsNil: Boolean;
begin
 //но так как оно нам недоступно, то проверим по последнему элементу созданному
 //в конструкторе
  Result := (@System.Classes.WakeMainThread = nil);
end;

function PlatformCocoaTerminating: Boolean;
begin
  Result := IFMXApplicationService(TPlatformServices.Current.GetPlatformService(IFMXApplicationService)).Terminating;
end;

//Эмуляция PlatformCocoa.DefaultAction('Q', [ssCommand])
function PlatformCocoa_DefaultAction_Commad_Q: Boolean;
begin
  //Копия ветки кода из TPlatformCocoa.DefaultAction выполняющаяся при входящих параметрах
  //PlatformCocoa.DefaultAction('Q', [ssCommand])
  Result := False;
  try
    if FMX.Forms.application.MainForm <> nil then
    begin
      FMX.Forms.application.MainForm.Close;
      if not PlatformCocoaTerminating then
        Exit;
    end
    else
    begin
      if Screen <> nil then
        Screen.ActiveForm := nil;
      application.Terminate;
    end;
  except
    HandleException(application);
  end;

  Result := True;
end;

{ TNSApplicationDelegate2 }

constructor TNSApplicationDelegate2.Create(AOnOpenFile: TOpenFileEvent;
  AOpenURLEvent: TOpenURLEvent = nil);
begin
  inherited Create;

  FOnOpenFile := AOnOpenFile;

  if Assigned(AOpenURLEvent) then
    FURLEventHandler := TURLEventHandler.Create(AOpenURLEvent);
end;

destructor TNSApplicationDelegate2.Destroy;
begin
  FreeAndNil(FURLEventHandler);

  inherited;
end;

procedure TNSApplicationDelegate2.onMenuClicked(sender: NSMenuItem);
begin
  SendOSXMessage(Self, TApplicationMenuClickedMessage, sender);
end;

procedure TNSApplicationDelegate2.applicationDidFinishLaunching(
  Notification: NSNotification);
begin
  SendOSXMessage(Self, TApplicationDidFinishLaunchingMessage, Notification);
end;

function TNSApplicationDelegate2.applicationShouldTerminate(
  Notification: NSNotification): NSInteger;
begin
  if (FMX.Forms.application = nil) or PlatformCocoaIsNil or PlatformCocoaTerminating
    or PlatformCocoa_DefaultAction_Commad_Q then
    Result := NSTerminateNow
  else
    Result := NSTerminateCancel;
end;

//Перед загрузкой приложения попадаем сюда
procedure TNSApplicationDelegate2.applicationWillFinishLaunching(
  Notification: NSNotification);
const
  kAEGetURL: Integer = Ord('G') shl 24 + Ord('U') shl 16 + Ord('R') shl 8 + Ord('L'); //'GURL'
  kInternetEventClass: Integer = Ord('G') shl 24 + Ord('U') shl 16 + Ord('R') shl 8 + Ord('L'); //'GURL'
var
  selector: SEL;
  sharedAppleEventManager: NSAppleEventManager;
begin
  if Assigned(FURLEventHandler) then
  begin
    sharedAppleEventManager := TNSAppleEventManager.Wrap(
      TNSAppleEventManager.OCClass.sharedAppleEventManager);

    selector := sel_registerName(PAnsiChar('Handle:ReplyEvent:'));
    sharedAppleEventManager.setEventHandler(FURLEventHandler.GetObjectID, selector,
      kInternetEventClass, kAEGetURL);
  end;
end;

// 应用程序取消隐藏
procedure TNSApplicationDelegate2.applicationDidHide(Notification: NSNotification);
begin
  //ShowMessage('applicationDidHide');
end;

procedure TNSApplicationDelegate2.applicationDidUnhide(Notification: NSNotification);
begin
  //ShowMessage('applicationDidUnhide');
end;

procedure TNSApplicationDelegate2.applicationWillTerminate(
  Notification: NSNotification);
begin
  SendOSXMessage(Self, TApplicationWillTerminateMessage, Notification);
  Halt;
end;

function TNSApplicationDelegate2.applicationDockMenu(
  sender: NSApplication): NSMenu;
var
  ReturnValue: NSObject;
begin
  ReturnValue := SendOSXMessage(Self, TApplicationDockMenuMessage, sender);
  if ReturnValue <> nil then
    Result := ReturnValue as NSMenu
  else
    Result := nil;
end;

function TNSApplicationDelegate2.application(theApplication: Pointer;
  openFile: CFStringRef): Boolean;
var
  Range: CFRange;
  S: string;
begin
  Result := Assigned(FOnOpenFile);
  if not Result then
    Exit;

  Range.location := 0;
  Range.length := CFStringGetLength(openFile);
  SetLength(S, Range.length);
  CFStringGetCharacters(openFile, Range, PChar(S));
  try
    FOnOpenFile(S);
  except
    FMX.Forms.application.HandleException(ExceptObject);
    Result := False;
  end;
end;

{ TURLEventHandler }

constructor TURLEventHandler.Create(AOpenURLEvent: TOpenURLEvent);
begin
  inherited Create;

  FOpenURLEvent := AOpenURLEvent;
end;

procedure TURLEventHandler.Handle(Event, ReplyEvent: NSAppleEventDescriptor);
const
  keyDirectObject: Integer = Ord('-') shl 24 + Ord('-') shl 16 + Ord('-') shl 8 + Ord('-'); //'----'
begin
  //FOpenURLEvent(NSToString(Event.paramDescriptorForKeyword(keyDirectObject).stringValue));
  FOpenURLEvent(string(Event.paramDescriptorForKeyword(keyDirectObject).stringValue));
end;

end.

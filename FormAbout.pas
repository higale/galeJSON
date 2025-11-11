unit FormAbout;

interface

uses
{$IFDEF MACOS}
  Macapi.AppKit, Macapi.Foundation, Macapi.Helpers,
{$ELSE}
  Winapi.ShellAPI, Winapi.Windows,
{$ENDIF}
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Effects, FMX.Objects;

type
  TfmAbout = class(TForm)
    Panel1: TPanel;
    btnOK: TButton;
    ShadowEffect1: TShadowEffect;
    imgLogo: TImage;
    Label1: TLabel;
    lblVersion: TLabel;
    txtUrl: TText;
    procedure Panel1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormDeactivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure txtUrlClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmAbout: TfmAbout;

implementation

{$R *.fmx}


uses pub, FormMain;

procedure TfmAbout.btnOKClick(Sender: TObject);
begin
  Close;
end;

procedure TfmAbout.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TfmAbout.FormCreate(Sender: TObject);
begin
  StyleBook := g_pub.StyleBook;
  lblVersion.Text := 'Version: ' + app_version;
end;

procedure TfmAbout.FormDeactivate(Sender: TObject);
begin
  Close;
end;

procedure TfmAbout.Panel1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  StartWindowDrag;
end;

procedure TfmAbout.txtUrlClick(Sender: TObject);
{$IFDEF MACOS}
{$ENDIF}
begin
{$IFDEF MACOS}
  var
    NSWorkspace: NSWorkspace;
  var
    NSURL: NSURL;
  begin
    NSWorkspace := TNSWorkspace.Wrap(TNSWorkspace.OCClass.sharedWorkspace);
    NSURL := TNSURL.Wrap(TNSURL.OCClass.URLWithString(StrToNSStr(txtUrl.Text)));
    NSWorkspace.openURL(NSURL);
  end;
{$ELSE}
  ShellExecute(0, 'open', PChar(txtUrl.Text), nil, nil, SW_SHOWNORMAL);
{$ENDIF}
end;

end.

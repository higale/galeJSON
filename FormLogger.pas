unit FormLogger;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo;

type
  TfmLogger = class(TForm)
    btnClear: TButton;
    pnl1: TPanel;
    mmoLog: TMemo;
    procedure btnClearClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmLogger: TfmLogger;

implementation

{$R *.fmx}


uses Logger, pub;

procedure TfmLogger.btnClearClick(Sender: TObject);
begin
  mmoLog.Lines.Clear;
end;

procedure TfmLogger.FormCreate(Sender: TObject);
begin
  g_Logger.OnLog := procedure(Sender: TObject; ALevel: TLogLevel; ALevelTag: string; ALog: string; ATime: TDateTime)
    begin
      if mmoLog.Lines.Count > 1000 then
      begin
        mmoLog.Text := mmoLog.Lines[mmoLog.Lines.Count - 1];
      end;
      mmoLog.Lines.Add(Format('%s %s %s', [FormatDateTime('hh:mm:ss.zzz', ATime), ALevelTag, ALog]));
      mmoLog.GoToTextEnd;
    end;
  g_Logger.Info('Start running');
  StyleBook := g_pub.StyleBook;
end;

end.

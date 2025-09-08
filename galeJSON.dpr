program galeJSON;

uses
  System.StartUpCopy,
  FMX.Forms,
  FormDocument in 'FormDocument.pas' {fmDocument},
  JSONTreeView in 'JSONTreeView.pas',
  rjson in 'utils\rjson.pas',
  memo_json_auto in 'utils\memo_json_auto.pas',
  WinSizeUtil in 'utils\WinSizeUtil.pas',
  data_const in 'data_const.pas',
  jsonhelper in 'utils\jsonhelper.pas',
  JsonDocument in 'JsonDocument.pas',
  Logger in 'utils\Logger.pas',
  fmFontDialog in 'utils\fmFontDialog.pas',
  LineNumbersMemoFMX in 'utils\LineNumbersMemoFMX.pas',
  galeNotice in 'utils\galeNotice.pas',
  FormMain in 'FormMain.pas' {fmMain},
  FormLogger in 'FormLogger.pas' {fmLogger},
  FormAbout in 'FormAbout.pas' {fmAbout},
  FMXTrayIcon in 'utils\FMXTrayIcon.pas',
  DocWinList in 'DocWinList.pas',
  SaveDialogsEnhanced in 'utils\SaveDialogsEnhanced.pas',
  Pub in 'Pub.pas';

{$R *.res}


begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
{$IFDEF MSWINDOWS}
  if TTrayIcon.HasOtherRunning then
    Exit;
{$ENDIF}
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;

end.

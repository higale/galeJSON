unit galeNotice;

interface

uses
  System.Math.Vectors, FMX.Effects, FMX.Objects, FMX.Controls, FMX.Types, System.Generics.Collections,
  System.Types, System.Classes, FMX.Graphics, FMX.Forms, FMX.Ani, System.SysUtils, System.UITypes, System.Math;

type
  TPlaceKind = (pkNone, pkLeftTop, pkTopCenter, pkRightTop, pkLeftBottom, pkBottomCenter, pkRightBottom);
  THanPos = (hpNone, hpTop, hpLeft, hpBottom, hpRight);
  TIconKind = (ikNone, ikInfo, ikSuccess, ikWarn, ikError, ikMail, ikQuestion);

  TNoticeInfo = record
  private type
    TNIText = record
      Value: string;
      FontColor: TAlphaColor;
      Font: record
        Family: string;
        Size: single;
        Style: TFontStyles;
      end;
    end;
  public
    Title: TNIText;
    Text: TNIText;
    Icon: TIconKind;
    PlaceKind: TPlaceKind;
    Pos: TPointF;
    BackColor: TAlphaColor;
    BorderColor: TAlphaColor;
    HanPos: THanPos;
    Shadow: single;
    Delay: single;
    CloseBtn: boolean;
  public
    procedure Init(AText: string = ''; ATitle: string = '消息'; AIcon: TIconKind = ikNone);
  end;

  TGaleNotice = class(TForm)
  private
    class var HindWins: TObjectList<TGaleNotice>;
  public
    class var DefFormPadding: single;
    class var DefGap: single;
    class var DefMargin: single;
    class var DefIconWidth: single;
    class var DefIconHeight: single;
    class var DefCalloutLen: single;
    class var DefHideDelay: single;
    class var DefMaxWidth: single;
    class var DefMinWidth: single;
    class var DefPlaceKind: TPlaceKind;
    class var DefShadow: single;
    class var DefColseBtn: boolean;

    class procedure RePlace;
  public
    class procedure ShowHint(const AInfo: TNoticeInfo);
    class procedure Info(AText: string; ATitle: string = '信息');
    class procedure Success(AText: string; ATitle: string = '成功');
    class procedure Warn(AText: string; ATitle: string = '警告');
    class procedure Error(AText: string; ATitle: string = '错误');
  private
    FNI: TNoticeInfo;
    FCalloutRectangle: TCalloutRectangle;
    ShadowEffect: TShadowEffect;
    FloatAnimation: TFloatAnimation;
    FTitleHeight: single;
    FCloseRect: TRectF;

    procedure SetCalloutPos(const ATPointF: TPointF);

    procedure OnCalloutRectangleClick(Sender: TObject);
    procedure OnCalloutRectangleEnter(Sender: TObject);
    procedure OnCalloutRectangleLeave(Sender: TObject);
    procedure OnCalloutRectanglePaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure OnFloatAnimationFinish(Sender: TObject);

    procedure SetNI(const AValue: TNoticeInfo);
  public
    property NI: TNoticeInfo read FNI write SetNI;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  toastr = TGaleNotice;

implementation

{ TNoticeInfo }
// ==============================================================================
// 消息显示参数
// ==============================================================================
procedure TNoticeInfo.Init(AText: string; ATitle: string; AIcon: TIconKind);
begin
  Text.Value := AText;
  Text.FontColor := $FFFFFFFF;
  Text.Font.Family := 'Microsoft YaHei UI';
  Text.Font.Size := 12.0;
  Text.Font.Style := [];
  Title.Value := ATitle;
  Title.FontColor := $FFFFFFFF;
  Title.Font.Family := 'Microsoft YaHei UI';
  Title.Font.Size := 14.0;
  Title.Font.Style := [TFontStyle.fsBold];
  Icon := AIcon;
  PlaceKind := TGaleNotice.DefPlaceKind;
  Pos := Screen.MousePos;
  BackColor := TAlphaColorRec.White;
  BorderColor := TAlphaColorRec.White;
  Shadow := TGaleNotice.DefShadow;
  Title.FontColor := TAlphaColorRec.Black;
  Text.FontColor := TAlphaColorRec.Black;
  HanPos := hpNone;
  Delay := TGaleNotice.DefHideDelay;
  CloseBtn := TGaleNotice.DefColseBtn;
end;

{ TGaleHintWindow }
//==============================================================================
// 显示提示
//==============================================================================
class procedure TGaleNotice.ShowHint(const AInfo: TNoticeInfo);
var
  tmpHint: TGaleNotice;
  LActiveForm: TCommonCustomForm;
begin
  tmpHint := TGaleNotice.Create(nil);
  tmpHint.NI := AInfo;

  tmpHint.FCalloutRectangle.Fill.Color := AInfo.BackColor;
  tmpHint.FCalloutRectangle.Stroke.Color := AInfo.BorderColor;
  HindWins.Add(tmpHint);
  LActiveForm := Screen.ActiveForm;
  tmpHint.Show;
  if Assigned(LActiveForm) then
    LActiveForm.Activate;
  tmpHint.BringToFront;
  tmpHint.FloatAnimation.Start;
  RePlace;
end;

//==============================================================================
// 显示Info
//==============================================================================
class procedure TGaleNotice.Info(AText: string; ATitle: string);
var
  NI: TNoticeInfo;
begin
  NI.Init(AText, ATitle, ikInfo);
  NI.BackColor := $FF59ACC3;
  NI.BorderColor := $FF59ACC3;
  NI.Title.FontColor := $FFFFFFFF;
  NI.Text.FontColor := $FFFFFFFF;
  ShowHint(NI);
end;

//==============================================================================
// 显示Info
//==============================================================================
class procedure TGaleNotice.Success(AText: string; ATitle: string);
var
  NI: TNoticeInfo;
begin
  NI.Init(AText, ATitle, ikSuccess);
  NI.BackColor := $FF74B575;
  NI.BorderColor := $FF74B575;
  NI.Title.FontColor := $FFFFFFFF;
  NI.Text.FontColor := $FFFFFFFF;
  ShowHint(NI);
end;

//==============================================================================
// 显示警告
//==============================================================================
class procedure TGaleNotice.Warn(AText: string; ATitle: string);
var
  NI: TNoticeInfo;
begin
  NI.Init(AText, ATitle, ikWarn);
  NI.BackColor := $FFF9AA39;
  NI.BorderColor := $FFF9AA39;
  NI.Title.FontColor := $FFFFFFFF;
  NI.Text.FontColor := $FFFFFFFF;
  ShowHint(NI);
end;

//==============================================================================
// 显示错误
//==============================================================================
class procedure TGaleNotice.Error(AText: string; ATitle: string);
var
  NI: TNoticeInfo;
begin
  NI.Init(AText, ATitle, ikError);
  NI.BackColor := $FFCA5E59;
  NI.BorderColor := $FFCA5E59;
  NI.Title.FontColor := $FFFFFFFF;
  NI.Text.FontColor := $FFFFFFFF;
  ShowHint(NI);
end;

//==============================================================================
// 重新摆放队列中的消息框
//==============================================================================
class procedure TGaleNotice.RePlace;
var
  fLeftTop, fTopCenter, fRightTop, fLeftBottom, fBottomCenter, fRightBottom: single;
begin
  fLeftTop := Screen.WorkAreaRect.Top;
  fTopCenter := Screen.WorkAreaRect.Top;
  fRightTop := Screen.WorkAreaRect.Top;
  fLeftBottom := Screen.WorkAreaRect.Bottom - DefFormPadding;
  fBottomCenter := Screen.WorkAreaRect.Bottom - DefFormPadding;
  fRightBottom := Screen.WorkAreaRect.Bottom - DefFormPadding;
  for var item in HindWins do
  begin
    if not item.Visible then
      Continue;
    item.BringToFront;
    case item.NI.PlaceKind of
      TPlaceKind.pkLeftTop:
        begin
          item.Left := 0;
          item.Top := Round(fLeftTop);
          fLeftTop := fLeftTop + item.Height - DefFormPadding * 2 + DefGap;
        end;
      TPlaceKind.pkTopCenter:
        begin
          item.Left := Round((Screen.Width - item.Width) / 2);
          item.Top := Round(fTopCenter);
          fTopCenter := fTopCenter + item.Height - DefFormPadding * 2 + DefGap;
        end;
      TPlaceKind.pkRightTop:
        begin
          item.Left := Round(Screen.Width - item.Width);
          item.Top := Round(fRightTop);
          fRightTop := fRightTop + item.Height - DefFormPadding * 2 + DefGap;
        end;
      TPlaceKind.pkLeftBottom:
        begin
          item.Left := 0;
          fLeftBottom := fLeftBottom - item.Height + DefFormPadding * 2 - DefGap;
          item.Top := Round(fLeftBottom);
        end;
      TPlaceKind.pkBottomCenter:
        begin
          item.Left := Round((Screen.Width - item.Width) / 2);
          fBottomCenter := fBottomCenter - item.Height + DefFormPadding * 2 - DefGap;
          item.Top := Round(fBottomCenter);
        end;
      TPlaceKind.pkRightBottom:
        begin
          item.Left := Round(Screen.Width - item.Width);
          fRightBottom := fRightBottom - item.Height + DefFormPadding * 2 - DefGap;
          item.Top := Round(fRightBottom);
        end;
    end;
  end;
end;

//==============================================================================
// 构造
//==============================================================================
constructor TGaleNotice.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  FormStyle := TFormStyle.StayOnTop;
  Transparency := True;

  // 气泡框
  FCalloutRectangle := TCalloutRectangle.Create(self);
  FCalloutRectangle.Position.X := DefFormPadding;;
  FCalloutRectangle.Position.Y := DefFormPadding;
  FCalloutRectangle.XRadius := 3;
  FCalloutRectangle.YRadius := 3;
  FCalloutRectangle.CalloutWidth := DefCalloutLen;
  FCalloutRectangle.CalloutLength := DefCalloutLen;

  FCalloutRectangle.OnMouseEnter := OnCalloutRectangleEnter;
  FCalloutRectangle.OnMouseLeave := OnCalloutRectangleLeave;
  FCalloutRectangle.OnClick := OnCalloutRectangleClick;
  FCalloutRectangle.OnPaint := OnCalloutRectanglePaint;

  AddObject(FCalloutRectangle);

  // 阴影
  ShadowEffect := TShadowEffect.Create(FCalloutRectangle);
  FCalloutRectangle.AddObject(ShadowEffect);
  ShadowEffect.Enabled := True;

  // 消失动画
  FloatAnimation := TFloatAnimation.Create(FCalloutRectangle);
  FCalloutRectangle.AddObject(FloatAnimation);
  FloatAnimation.PropertyName := 'Opacity';
  FloatAnimation.Duration := 1.0;
  FloatAnimation.StartValue := 1.0;
  FloatAnimation.StopValue := 0;
  FloatAnimation.OnFinish := OnFloatAnimationFinish;
end;

//==============================================================================
// 设置气球手柄位置坐标
//==============================================================================
procedure TGaleNotice.SetCalloutPos(const ATPointF: TPointF);
var
  fTemp: single;
begin
  if FCalloutRectangle.CalloutPosition in [TCalloutPosition.Top, TCalloutPosition.Bottom] then
  begin
    if FCalloutRectangle.CalloutOffset = 0 then
      fTemp := FCalloutRectangle.Width / 2
    else
      fTemp := FCalloutRectangle.CalloutOffset + FCalloutRectangle.CalloutWidth / 2;
  end
  else
  begin
    if FCalloutRectangle.CalloutOffset = 0 then
      fTemp := FCalloutRectangle.Height / 2
    else
      fTemp := FCalloutRectangle.CalloutOffset + FCalloutRectangle.Height / 2;
  end;

  case FCalloutRectangle.CalloutPosition of
    TCalloutPosition.Top:
      begin
        Left := Round(ATPointF.X - DefFormPadding - fTemp);
        Top := Round(ATPointF.Y - DefFormPadding);
      end;

    TCalloutPosition.Bottom:
      begin
        Left := Round(ATPointF.X - DefFormPadding - fTemp);
        Top := Round(ATPointF.Y - DefFormPadding - FCalloutRectangle.Height);
      end;
    TCalloutPosition.Left:
      begin
        Left := Round(ATPointF.X - DefFormPadding);
        Top := Round(ATPointF.Y - DefFormPadding - fTemp);
      end;
    TCalloutPosition.Right:
      begin
        Left := Round(ATPointF.X - DefFormPadding - FCalloutRectangle.Width);
        Top := Round(ATPointF.Y - DefFormPadding - fTemp);
      end;
  end;

end;

//==============================================================================
// 消息窗口参数设置
//==============================================================================
procedure TGaleNotice.SetNI(const AValue: TNoticeInfo);
var
  rct: TRectF;
  titleWidth: single;
  textWidth: single;
begin
  FNI := AValue;

  ShadowEffect.Opacity := FNI.Shadow;

  FCalloutRectangle.Canvas.Font.Style := [TFontStyle.fsBold];
  FCalloutRectangle.Canvas.Font.Size := FNI.Title.Font.Size;
  rct := RectF(0, 0, DefMaxWidth, 1024);
  FCalloutRectangle.Canvas.MeasureText(rct, FNI.Title.Value, True, [], TTextAlign.Leading, TTextAlign.Leading);
  titleWidth := rct.Width;
  FTitleHeight := rct.Height;

  FCalloutRectangle.Canvas.Font.Style := [];
  FCalloutRectangle.Canvas.Font.Size := FNI.Text.Font.Size;
  rct := RectF(0, 0, DefMaxWidth, 1024);
  FCalloutRectangle.Canvas.MeasureText(rct, FNI.Text.Value, True, [], TTextAlign.Leading, TTextAlign.Leading);
  textWidth := rct.Width;

  rct.Width := Max(textWidth, titleWidth);
  rct.Width := Max(rct.Width, DefMinWidth);

  if FNI.Icon = ikNone then
    FCalloutRectangle.Width := DefMargin + rct.Width + DefMargin
  else
    FCalloutRectangle.Width := DefMargin + DefIconWidth + DefMargin + rct.Width + DefMargin;

  FCalloutRectangle.Height := DefMargin + FTitleHeight + rct.Height + DefMargin;

  if Ord(FNI.HanPos) > 0 then
  begin
    FCalloutRectangle.CalloutLength := DefCalloutLen;
    FCalloutRectangle.CalloutPosition := TCalloutPosition(Ord(FNI.HanPos) - 1);
    case FNI.HanPos of
      hpLeft, hpRight:
        FCalloutRectangle.Width := FCalloutRectangle.Width + DefCalloutLen;
      hpTop, hpBottom:
        FCalloutRectangle.Height := FCalloutRectangle.Height + DefCalloutLen;
    end;
  end
  else
  begin
    FCalloutRectangle.CalloutLength := 0;
  end;

  Width := Round(FCalloutRectangle.Width + DefFormPadding * 2);
  Height := Round(FCalloutRectangle.Height + DefFormPadding * 2);

  FloatAnimation.Delay := FNI.Delay;
  if FNI.PlaceKind = pkNone then
    SetCalloutPos(FNI.Pos);

end;

procedure TGaleNotice.OnCalloutRectangleEnter(Sender: TObject);
var
  OldEvent: TNotifyEvent;
begin
  OldEvent := FloatAnimation.OnFinish;
  FloatAnimation.OnFinish := nil;
  FloatAnimation.Stop;
  FloatAnimation.Delay := 1.0;
  FloatAnimation.OnFinish := OldEvent;
end;

procedure TGaleNotice.OnCalloutRectangleLeave(Sender: TObject);
begin
  FloatAnimation.Start;
end;

//==============================================================================
// 点击事件
//==============================================================================
procedure TGaleNotice.OnCalloutRectangleClick(Sender: TObject);
var
  OldEvent: TNotifyEvent;
begin
  // 点击在关闭按钮区域
  if FNI.CloseBtn and FCloseRect.Contains(FCalloutRectangle.ScreenToLocal(Screen.MousePos)) then
  begin
    OldEvent := FloatAnimation.OnFinish;
    FloatAnimation.OnFinish := nil;
    FloatAnimation.Stop;
    FloatAnimation.Delay := 0;
    FloatAnimation.OnFinish := OldEvent;
    FCalloutRectangle.OnMouseEnter := nil;
    FCalloutRectangle.OnMouseLeave := nil;
    FloatAnimation.Start;
  end;
end;

//==============================================================================
// 气泡重绘
//==============================================================================
procedure TGaleNotice.OnCalloutRectanglePaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
const
  pdClose = 'M10 0L100 90L90 100L0 10z M90 0L100 10L10 100L0 90z';
  pdInfo = 'M40 0 H60 V20 H40z M42 40L58 40L62 100L38 100z';
  pdSuccess = 'M940 160L396 704 83 384 0 467l313 313 83 83L1024 243z';
  pdWarn = 'M0 50a50 50 0 1 0 100 0a50 50 0 1 0-100 0M 40 10L 60 10L55 55L45 55zM 42 70L 58 70L58 86L42 86z';
  pdError = 'M0 50a50 50 0 1 0 100 0a50 50 0 1 0-100 0M 20 40L 80 40L80 60L20 60z';
  pdMail = 'M0 20 H100 V80 H0 V20 M0 27 L50 55L100 27';
  pdQuestion = 'M14 17L32 0H70L85 16V50L57 64V77H43V56L72 43V21L64 13H35L21 27z M44 86H56V99H44z';
var
  WorkRect, IconRect, TitleRect, TextRect: TRectF;
  PathData: TPathData;
begin
  WorkRect := ARect;
  if FCalloutRectangle.CalloutLength > 0 then
  begin
    case FCalloutRectangle.CalloutPosition of
      TCalloutPosition.Top:
        WorkRect.Top := WorkRect.Top + FCalloutRectangle.CalloutLength;
      TCalloutPosition.Bottom:
        WorkRect.Bottom := WorkRect.Bottom - FCalloutRectangle.CalloutLength;
      TCalloutPosition.Left:
        WorkRect.Left := WorkRect.Left + FCalloutRectangle.CalloutLength;
      TCalloutPosition.Right:
        WorkRect.Right := WorkRect.Right - FCalloutRectangle.CalloutLength;
    end;
  end;

  // 图标
  if FNI.Icon <> ikNone then
  begin
    IconRect.Left := WorkRect.Left + DefMargin;
    IconRect.Top := WorkRect.Top + (WorkRect.Height - DefIconHeight) / 2;
    IconRect.Width := DefIconWidth;
    IconRect.Height := DefIconHeight;
    PathData := TPathData.Create;
    try
      case FNI.Icon of
        ikInfo:
          PathData.Data := pdInfo;
        ikSuccess:
          PathData.Data := pdSuccess;
        ikWarn:
          PathData.Data := pdWarn;
        ikError:
          PathData.Data := pdError;
        ikMail:
          PathData.Data := pdMail;
        ikQuestion:
          PathData.Data := pdQuestion;
      else
      end;
      PathData.FitToRect(IconRect);
      FCalloutRectangle.Canvas.Fill.Color := NI.Title.FontColor;
      FCalloutRectangle.Canvas.FillPath(PathData, FCalloutRectangle.Opacity);
    finally
      PathData.Free
    end;
  end;

  // 关闭按钮
  if FNI.CloseBtn then
  begin
    FCloseRect.Right := WorkRect.Right - 5;
    FCloseRect.Top := WorkRect.Top + 5;
    FCloseRect.Left := FCloseRect.Right - 8;
    FCloseRect.Bottom := FCloseRect.Top + 8;
    PathData := TPathData.Create;
    try
      PathData.Data := pdClose;
      PathData.FitToRect(FCloseRect);
      FCalloutRectangle.Canvas.Stroke.Color := NI.Title.FontColor;
      FCalloutRectangle.Canvas.FillPath(PathData, FCalloutRectangle.Opacity);
    finally
      PathData.Free;
    end;
  end;

  // 标题
  if FNI.Icon <> ikNone then
    TitleRect.Left := WorkRect.Left + DefMargin + DefIconWidth + DefMargin
  else
    TitleRect.Left := WorkRect.Left + DefMargin;
  TitleRect.Top := WorkRect.Top + DefMargin - 2;
  TitleRect.Right := WorkRect.Right;
  TitleRect.Bottom := WorkRect.Bottom;
  FCalloutRectangle.Canvas.Fill.Color := FNI.Title.FontColor;
  FCalloutRectangle.Canvas.Font.Family := FNI.Title.Font.Family;
  FCalloutRectangle.Canvas.Font.Size := FNI.Title.Font.Size;
  FCalloutRectangle.Canvas.Font.Style := FNI.Title.Font.Style;
  FCalloutRectangle.Canvas.FillText(TitleRect, FNI.Title.Value, True, FCalloutRectangle.Opacity, [], TTextAlign.Leading, TTextAlign.Leading);

  // 内容
  TextRect.Left := TitleRect.Left;
  TextRect.Top := WorkRect.Top + DefMargin + FTitleHeight;
  TextRect.Right := WorkRect.Right - DefMargin;
  TextRect.Bottom := WorkRect.Bottom;
  FCalloutRectangle.Canvas.Fill.Color := FNI.Text.FontColor;
  FCalloutRectangle.Canvas.Font.Family := FNI.Text.Font.Family;
  FCalloutRectangle.Canvas.Font.Size := FNI.Text.Font.Size;
  FCalloutRectangle.Canvas.Font.Style := FNI.Text.Font.Style;
  FCalloutRectangle.Canvas.FillText(TextRect, FNI.Text.Value, True, FCalloutRectangle.Opacity, [], TTextAlign.Leading, TTextAlign.Leading);
end;

//==============================================================================
// 显示动画结束，删除
//==============================================================================
procedure TGaleNotice.OnFloatAnimationFinish(Sender: TObject);
begin
  HindWins.Remove(self);
  RePlace;
end;

initialization

TGaleNotice.HindWins := TObjectList<TGaleNotice>.Create;
TGaleNotice.DefFormPadding := 10.0;
TGaleNotice.DefGap := 3.0;
TGaleNotice.DefMargin := 10.0;
TGaleNotice.DefIconWidth := 16.0;
TGaleNotice.DefIconHeight := 16.0;
TGaleNotice.DefCalloutLen := 10.0;
TGaleNotice.DefHideDelay := 5.0;
TGaleNotice.DefMaxWidth := 240.0;
TGaleNotice.DefMinWidth := 100.0;
TGaleNotice.DefPlaceKind := pkRightTop;
TGaleNotice.DefShadow := 0.5;
TGaleNotice.DefColseBtn := True;

finalization

TGaleNotice.HindWins.Free;

end.

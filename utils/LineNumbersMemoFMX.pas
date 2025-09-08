unit LineNumbersMemoFMX;

interface

uses
  FMX.TextLayout, FMX.Text.LinesLayout, FMX.Memo.Style.New, System.Math,
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Memo, FMX.Layouts,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Objects;

type
  TLinesMemoUtil = class(TComponent)
  private
    FStyleMemo: TStyledMemo;
    FLinesLayout: TLinesLayout;
    FRectangle: TRectangle;
    FMemo: TMemo;
    FFontColor: TAlphaColor;
    FFontColorCurrentLine: TAlphaColor;
    FFontSize: Single;
    FLineColor: TAlphaColor;
    FRectWidth: Single;
    FOldOnViewportPositionChange: TPositionChangeEvent;
    procedure SetMemo(const AValue: TMemo);
    procedure SetFontColor(AValue: TAlphaColor);
    procedure SetFontColorCurrentLine(AValue: TAlphaColor);
    procedure SetLineColor(AValue: TAlphaColor);
    procedure SetFontSize(AValue: Single);
    procedure SetRectWidth(AValue: Single);
    procedure ApplyStyleLookup(Sender: TObject);
    procedure LineNumberPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure MemoViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
  public
    property Memo: TMemo read FMemo write SetMemo;
    property FontColor: TAlphaColor read FFontColor write SetFontColor;
    property FontColorCurrentLine: TAlphaColor read FFontColorCurrentLine write SetFontColorCurrentLine;
    property LineColor: TAlphaColor read FLineColor write SetLineColor;
    property FontSize: Single read FFontSize write SetFontSize;
    property RectWidth: Single read FRectWidth write SetRectWidth;
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TComponent; AMemo: TMemo); reintroduce; overload;
    destructor Destroy; override;
  end;

implementation

uses Logger;

constructor TLinesMemoUtil.Create(AOwner: TComponent);
begin
  inherited;
  FStyleMemo := nil;
  FFontColorCurrentLine := $FF33CC33;
  FFontColor := $FF808080;
  FFontSize := 11;
  FLineColor := $80808080;
  FRectWidth := 40;
  FOldOnViewportPositionChange := nil;
end;

constructor TLinesMemoUtil.Create(AOwner: TComponent; AMemo: TMemo);
begin
  Create(AOwner);
  SetMemo(AMemo);
end;

destructor TLinesMemoUtil.Destroy;
begin
  inherited;
end;

procedure TLinesMemoUtil.SetMemo(const AValue: TMemo);
begin
  if FMemo = AValue then
    Exit;
  FMemo := AValue;
  FMemo.OnApplyStyleLookup := ApplyStyleLookup;
  FOldOnViewportPositionChange := FMemo.OnViewportPositionChange;
  FMemo.OnViewportPositionChange := MemoViewportPositionChange;
  if FStyleMemo = nil then
  begin
    FMemo.EnumObjects(
      function(obj: TFmxObject): TEnumProcResult
      begin
        if obj is TStyledMemo then
        begin
          FStyleMemo := TStyledMemo(obj);
          FLinesLayout := FStyleMemo.Editor.LinesLayout;
          Result := TEnumProcResult.Stop;
        end
        else
        begin
          Result := TEnumProcResult.Continue;
        end;
      end);
  end;
end;

procedure TLinesMemoUtil.SetFontColor(AValue: TAlphaColor);
begin
  if FFontColor = AValue then
    Exit;
  FFontColor := AValue;
  FRectangle.Repaint;
end;

procedure TLinesMemoUtil.SetFontColorCurrentLine(AValue: TAlphaColor);
begin
  if FFontColorCurrentLine = AValue then
    Exit;
  FFontColorCurrentLine := AValue;
  FRectangle.Repaint;
end;

procedure TLinesMemoUtil.SetLineColor(AValue: TAlphaColor);
begin
  if FLineColor = AValue then
    Exit;
  FLineColor := AValue;
  FRectangle.Stroke.Color := FLineColor;
end;

procedure TLinesMemoUtil.SetFontSize(AValue: Single);
begin
  if FFontSize = AValue then
    Exit;
  FFontSize := AValue;
  FRectangle.Repaint;
end;

procedure TLinesMemoUtil.SetRectWidth(AValue: Single);
begin
  if FRectWidth = AValue then
    Exit;
  FRectWidth := AValue;
  FRectangle.Width := AValue;
  FMemo.RecalcSize;
end;

procedure TLinesMemoUtil.ApplyStyleLookup(Sender: TObject);
var
  resContent: TFmxObject;
begin
  resContent := TFmxObject(Sender).FindStyleResource('content');
  if resContent <> nil then
  begin
    FRectangle := TRectangle.Create(nil);
    FRectangle.HitTest := False;
    FRectangle.ClipChildren := True;
    FRectangle.Sides := [TSide.Right];
    FRectangle.OnPaint := LineNumberPaint;
    FRectangle.Fill.Kind := TBrushKind.None;
    FRectangle.Stroke.Color := FLineColor;
    FRectangle.Width := FRectWidth;
    FRectangle.Align := TAlignLayout.Left;
    FRectangle.StyleName := 'lines';
    FRectangle.Margins.Rect := RectF(0, TControl(resContent).Margins.Top, 0, TControl(resContent).Margins.Bottom);
    resContent.Parent.AddObject(FRectangle);
    FRectangle.BringToFront;
  end;
end;

procedure TLinesMemoUtil.LineNumberPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  LRect: TRectF;
begin
  Canvas.BeginScene;
  try
    Canvas.Font.Size := FFontSize;
    for var i := Max(0, FLinesLayout.FirstVisibleLineIndex) to Min(FLinesLayout.LastVisibleLineIndex, FStyleMemo.Editor.LinesLayout.Count - 1) do
    begin
      LRect := RectF(ARect.Left, FLinesLayout[i].Rect.Top - FMemo.ViewportPosition.Y, ARect.Right - 2, FLinesLayout[i].Rect.Bottom - FMemo.ViewportPosition.Y);
      if i = FMemo.CaretPosition.Line then
      begin
        Canvas.Fill.Color := $FF808080;
        Canvas.FillRect(LRect, 0.2);
        Canvas.Fill.Color := FFontColorCurrentLine;
      end
      else
      begin
        Canvas.Fill.Color := FFontColor;
      end;
      Canvas.FillText(LRect, IntToStr(i + 1), False, 1.0, [], TTextAlign.Center, TTextAlign.Center);
    end;
  finally
    Canvas.EndScene;
  end;
end;

procedure TLinesMemoUtil.MemoViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
begin
  FRectangle.Repaint;
  if Assigned(FOldOnViewportPositionChange) then
  begin
    FOldOnViewportPositionChange(Sender, OldViewportPosition, NewViewportPosition, ContentSizeChanged);
  end;
end;

end.

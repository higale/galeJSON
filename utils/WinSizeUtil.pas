{
  无标题窗口size控制
  v0.3
  by gale 2024-11-24
}
unit WinSizeUtil;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Edit;

type

  TWinSizeHelper = class(TComponent)
  private const
    c_CheckWidth = 5;
  private type
    TSizeType = (stNone, stLeft, stLeftTop, stTop, stRightTop, stRight, stRightBottom, stBottom, stLeftBottom);
  private
    FForm: TForm;
    FControl: TControl;
    FTitleBar: TControl;
    FSizeType: TSizeType;
    FCanMaximized: Boolean;
  private
    FOldMouseDown: TMouseEvent;
    FOldMouseUp: TMouseEvent;
    FOldMouseLeave: TNotifyEvent;
    FOldMouseMove: TMouseMoveEvent;
    FOldRectF: TRectF;
    FOldCursor: TCursor;
    procedure MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure MouseLeave(Sender: TObject);
  public
    property CanMaximized: Boolean read FCanMaximized write FCanMaximized;
  private
    FIsMouseDown_TitleBar: Boolean;
    FOldFormPos_TitleBar: TPoint;
    FOldMousePos_TitleBar: TPointF;
    FOldMouseDown_TitleBar: TMouseEvent;
    FOldMouseUp_TitleBar: TMouseEvent;
    FOldMouseMove_TitleBar: TMouseMoveEvent;
    FOldDBClick_TitleBar: TNotifyEvent;
    procedure TitleBarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure TitleBarMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure TitleBarMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure TitleBarDblClick(Sender: TObject);
  private
    function CalcSizeType(X, Y: Single): TSizeType;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetControlled(AValue: TControl);
    procedure SetTitleBar(AValue: TControl);
  end;

implementation

{ TWinSizeHelper }

constructor TWinSizeHelper.Create(AOwner: TComponent);
begin
  inherited;
  FForm := nil;
  FSizeType := stNone;
  FIsMouseDown_TitleBar := False;
  FCanMaximized := False;
end;

destructor TWinSizeHelper.Destroy;
begin
  inherited;
end;

function TWinSizeHelper.CalcSizeType(X, Y: Single): TSizeType;
var
  Width, Height: Single;
begin
  Width := FControl.Width;
  Height := FControl.Height;
  if (X < c_CheckWidth * 3) and (Y < c_CheckWidth * 3) then
    Result := stLeftTop
  else if (X > Width - c_CheckWidth * 3) and (Y < c_CheckWidth * 3) then
    Result := stRightTop
  else if (X > Width - c_CheckWidth * 3) and (Y > Height - c_CheckWidth * 3) then
    Result := stRightBottom
  else if (X < c_CheckWidth * 3) and (Y > Height - c_CheckWidth * 3) then
    Result := stLeftBottom
  else if X < c_CheckWidth then
    Result := stLeft
  else if X > Width - c_CheckWidth then
    Result := stRight
  else if Y < c_CheckWidth then
    Result := stTop
  else if Y > Height - c_CheckWidth then
    Result := stBottom
  else
    Result := stNone;
end;

procedure TWinSizeHelper.SetControlled(AValue: TControl);
begin
  if FControl = AValue then
    Exit;
  FControl := AValue;
  FForm := FControl.Root as TForm;
  FOldCursor := FControl.Cursor;
  FControl.AutoCapture := True;

  FOldMouseDown := FControl.OnMouseDown;
  FOldMouseUp := FControl.OnMouseUp;
  FOldMouseLeave := FControl.OnMouseLeave;
  FOldMouseMove := FControl.OnMouseMove;
  FControl.OnMouseDown := MouseDown;
  FControl.OnMouseUp := MouseUp;
  FControl.OnMouseMove := MouseMove;
  FControl.OnMouseLeave := MouseLeave;
end;

procedure TWinSizeHelper.MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
  begin
    FOldRectF := FForm.BoundsF;
    FSizeType := CalcSizeType(X, Y);
  end;
  if Assigned(FOldMouseDown) then
  begin
    FOldMouseDown(Sender, Button, Shift, X, Y);
  end;
end;

procedure TWinSizeHelper.MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FSizeType := stNone;
  if Assigned(FOldMouseUp) then
  begin
    FOldMouseUp(Sender, Button, Shift, X, Y);
  end;
end;

procedure TWinSizeHelper.MouseLeave(Sender: TObject);
begin
  FControl.Cursor := crDefault;
  if Assigned(FOldMouseLeave) then
  begin
    FOldMouseLeave(Sender);
  end;
end;

procedure TWinSizeHelper.MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if FSizeType <> stNone then
  begin
    case FSizeType of
      stLeft:
        begin
          FOldRectF.Left := Screen.MousePos.X - FControl.Position.X - c_CheckWidth / 2;
          if FOldRectF.Width < FForm.Constraints.MinWidth then
            FOldRectF.Left := FOldRectF.Right - FForm.Constraints.MinWidth;
          FForm.SetBoundsF(FOldRectF);
        end;
      stTop:
        begin
          FOldRectF.Top := Screen.MousePos.Y - FControl.Position.Y - c_CheckWidth / 2;;
          if FOldRectF.Height < FForm.Constraints.MinHeight then
            FOldRectF.Top := FOldRectF.Bottom - FForm.Constraints.MinHeight;
          FForm.SetBoundsF(FOldRectF);
        end;
      stRight:
        begin
          FOldRectF.Right := Screen.MousePos.X + (FForm.BoundsF.Width - FControl.Position.X - FControl.Width) + c_CheckWidth / 2;
          FForm.SetBoundsF(FOldRectF);
        end;
      stBottom:
        begin
          FOldRectF.Bottom := Screen.MousePos.Y + (FForm.BoundsF.Height - FControl.Position.Y - FControl.Height) + c_CheckWidth / 2;
          FForm.SetBoundsF(FOldRectF);
        end;
      stLeftTop:
        begin
          FOldRectF.Left := Screen.MousePos.X - FControl.Position.X - c_CheckWidth / 2;
          FOldRectF.Top := Screen.MousePos.Y - FControl.Position.Y - c_CheckWidth / 2;;
          if FOldRectF.Width < FForm.Constraints.MinWidth then
            FOldRectF.Left := FOldRectF.Right - FForm.Constraints.MinWidth;
          if FOldRectF.Height < FForm.Constraints.MinHeight then
            FOldRectF.Top := FOldRectF.Bottom - FForm.Constraints.MinHeight;
          FForm.SetBoundsF(FOldRectF);
        end;
      stRightTop:
        begin
          FOldRectF.Right := Screen.MousePos.X + (FForm.BoundsF.Width - FControl.Position.X - FControl.Width) + c_CheckWidth / 2;
          FOldRectF.Top := Screen.MousePos.Y - FControl.Position.Y - c_CheckWidth / 2;;
          if FOldRectF.Height < FForm.Constraints.MinHeight then
            FOldRectF.Top := FOldRectF.Bottom - FForm.Constraints.MinHeight;
          FForm.SetBoundsF(FOldRectF);
        end;
      stRightBottom:
        begin
          FOldRectF.Right := Screen.MousePos.X + (FForm.BoundsF.Width - FControl.Position.X - FControl.Width) + c_CheckWidth / 2;
          FOldRectF.Bottom := Screen.MousePos.Y + (FForm.BoundsF.Height - FControl.Position.Y - FControl.Height) + c_CheckWidth / 2;
          FForm.SetBoundsF(FOldRectF);
        end;
      stLeftBottom:
        begin
          FOldRectF.Left := Screen.MousePos.X - FControl.Position.X - c_CheckWidth / 2;
          FOldRectF.Bottom := Screen.MousePos.Y + (FForm.BoundsF.Height - FControl.Position.Y - FControl.Height) + c_CheckWidth / 2;
          if FOldRectF.Width < FForm.Constraints.MinWidth then
            FOldRectF.Left := FOldRectF.Right - FForm.Constraints.MinWidth;
          FForm.SetBoundsF(FOldRectF);
        end;
    end;
  end
  else
  begin
    case CalcSizeType(X, Y) of
      stLeft, stRight:
        FControl.Cursor := crSizeWE;
      stTop, stBottom:
        FControl.Cursor := crSizeNS;
      stLeftTop, stRightBottom:
        FControl.Cursor := crSizeNWSE;
      stRightTop, stLeftBottom:
        FControl.Cursor := crSizeNESW;
    else
      FControl.Cursor := FOldCursor;
    end;
  end;

  if Assigned(FOldMouseMove) then
  begin
    FOldMouseMove(Sender, Shift, X, Y);
  end;
end;

procedure TWinSizeHelper.SetTitleBar(AValue: TControl);
begin
  if FTitleBar = AValue then
    Exit;
  FTitleBar := AValue;
  if FForm = nil then
    FForm := FTitleBar.Root as TForm;
  FOldMouseDown_TitleBar := FTitleBar.OnMouseDown;
  FTitleBar.OnMouseDown := TitleBarMouseDown;
  FOldMouseUp_TitleBar := FTitleBar.OnMouseUp;
  FTitleBar.OnMouseUp := TitleBarMouseUp;
  FOldMouseMove_TitleBar := FTitleBar.OnMouseMove;
  FTitleBar.OnMouseMove := TitleBarMouseMove;
  FOldDBClick_TitleBar := FTitleBar.OnDblClick;
  FTitleBar.OnDblClick := TitleBarDblClick;

  FTitleBar.AutoCapture := True;
end;

procedure TWinSizeHelper.TitleBarMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if (Button = TMouseButton.mbLeft) then
  begin
    FIsMouseDown_TitleBar := True;
    FOldFormPos_TitleBar.X := FForm.Left;
    FOldFormPos_TitleBar.Y := FForm.Top;
    FOldMousePos_TitleBar := Screen.MousePos;
  end;
  if Assigned(FOldMouseDown_TitleBar) then
  begin
    FOldMouseDown_TitleBar(Sender, Button, Shift, X, Y);
  end;
end;

procedure TWinSizeHelper.TitleBarMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if (ssLeft in Shift) and FIsMouseDown_TitleBar then
  begin
    if FForm.WindowState = TWindowState.wsMaximized then
    begin
      if (ABS(FOldMousePos_TitleBar.X - Screen.MousePos.X) > 10) or (ABS(FOldMousePos_TitleBar.Y - Screen.MousePos.Y) > 10) then
      begin
        FForm.WindowState := TWindowState.wsNormal;
        FOldFormPos_TitleBar.X := Round(Screen.MousePos.X - FForm.Width / 2);
        FForm.Left := FOldFormPos_TitleBar.X + Round(Screen.MousePos.X - FOldMousePos_TitleBar.X);
        FForm.Top := FOldFormPos_TitleBar.Y + Round(Screen.MousePos.Y - FOldMousePos_TitleBar.Y);
      end;
    end
    else
    begin
      FForm.Left := FOldFormPos_TitleBar.X + Round(Screen.MousePos.X - FOldMousePos_TitleBar.X);
      FForm.Top := FOldFormPos_TitleBar.Y + Round(Screen.MousePos.Y - FOldMousePos_TitleBar.Y);
    end;
  end;

  if Assigned(FOldMouseMove_TitleBar) then
  begin
    FOldMouseMove_TitleBar(Sender, Shift, X, Y);
  end;
end;

procedure TWinSizeHelper.TitleBarMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FIsMouseDown_TitleBar := False;
  if Assigned(FOldMouseUp_TitleBar) then
  begin
    FOldMouseUp_TitleBar(Sender, Button, Shift, X, Y);
  end;
end;

procedure TWinSizeHelper.TitleBarDblClick(Sender: TObject);
begin
  if FCanMaximized then
  begin
    FIsMouseDown_TitleBar := False;
    if FForm.WindowState = TWindowState.wsMaximized then
    begin
      FForm.WindowState := TWindowState.wsNormal;
    end
    else
    begin
      FForm.WindowState := TWindowState.wsMaximized;
    end;
  end;

  if Assigned(FOldDBClick_TitleBar) then
  begin
    FOldDBClick_TitleBar(Sender);
  end;

end;

end.

unit JSONTreeView;

interface

uses
  System.JSON, System.Generics.Collections, System.Math, System.SysUtils,
  System.Types, System.Classes, System.UITypes,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.StdCtrls, FMX.TreeView, FMX.Objects,
  FMX.Forms, FMX.Menus;

type
  // 自定义的树视图项类，用于处理JSON数据
  TJSONTreeViewItem = class(TTreeViewItem)
  private
    FJsonData: TJSONAncestor; // 存储JSON数据
    FMouseDowned: Boolean; // 鼠标是否按下
    FMouseDownPos: TPointF; // 鼠标按下位置
  private
    // 设置JSON数据
    procedure SetJsonData(const AValue: TJSONAncestor);
    // 获取JSON值
    function GetJsonValue: TJSONValue;
    // 设置JSON值
    procedure SetJsonValue(const AValue: TJSONValue);
    // 获取键名
    function GetKey: string;
    // 获取值
    function GetValue: string;
    // 获取最后一个路径
    function GetLastPath: string;
    // 获取完整路径
    function GetPath: string;
  protected
    // 重载绘制函数
    procedure Paint; override;
  public
    property JsonData: TJSONAncestor read FJsonData write SetJsonData; // JSON数据属性
    property JsonValue: TJSONValue read GetJsonValue write SetJsonValue; // JSON值属性
    property Key: string read GetKey; // 键名属性
    property LastPath: string read GetLastPath; // 最后一个路径属性
    property Path: string read GetPath; // 完整路径属性
    property Value: string read GetValue; // 值属性
  public
    // 鼠标按下事件处理
    procedure TreeViewItemMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    // 鼠标移动事件处理
    procedure TreeViewItemMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    // 鼠标释放事件处理
    procedure TreeViewItemMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  public
    // 构造函数
    constructor Create(AOwner: TComponent); override;
    // 获取第一个子项
    function First: TJSONTreeViewItem;
    // 获取最后一个子项
    function Last: TJSONTreeViewItem;
    // 获取层级
    function Level: integer;
    // 是否有子项
    function HasSubItem: Boolean;
    // 是否有选中的子项
    function HasSUbItemIsSelected: Boolean;
    // 获取父项
    function MyParentItem: TJSONTreeViewItem;
    // 移除子项
    procedure RemoveItem(const AItem: TJSONTreeViewItem; AReTextSubItem: Boolean = False);
    // 从父项中提取
    function ExtractFromParent(AParentReTextSubItem: Boolean = False): TJSONTreeViewItem;
    // 添加子项
    procedure AddItem(const AItem: TJSONTreeViewItem; AItemReText: Boolean = False);
    // 插入子项
    procedure InsertItem(const AIndex: integer; const AItem: TJSONTreeViewItem;
      AReTextSubItem: Boolean = False);
    // 移动子项
    procedure MoveItem(const ACurIndex, ANewIndex: integer; AReTextSubItem: Boolean = False);
    // 清除子条目
    procedure ClearItem;
    // 重新设置文本
    procedure ReText;
    // 重新设置所有子项的文本
    procedure ReTextSubItem;
  end;

// 设置树视图项，递归地将JSON数据添加到树视图中
procedure SetTreeItem(const AParentItem: TStyledControl; const AJData: TJSONAncestor; APopupMenu: TPopupMenu = nil);
procedure SetTreeItems(const AParentItem: TStyledControl; const AJData: TJSONAncestor; APopupMenu: TPopupMenu = nil);

implementation

uses pub, jsonhelper, Logger;

////////////////////////////////////////////////////////////////////////////////
// 为树形控件的项目设置JSON数据和PopupMenu
////////////////////////////////////////////////////////////////////////////////
procedure SetTreeItem(const AParentItem: TStyledControl; const AJData: TJSONAncestor; APopupMenu: TPopupMenu);
var
  tvItem: TJSONTreeViewItem;
begin
  tvItem := TJSONTreeViewItem.Create(nil);
  AParentItem.AddObject(tvItem);
  tvItem.PopupMenu := APopupMenu;
  tvItem.JsonData := AJData;
  for var i := 0 to tvItem.JsonValue.ItemCount - 1 do
  begin
    SetTreeItem(tvItem, tvItem.JsonValue.Items[i]);
  end;
end;

procedure SetTreeItems(const AParentItem: TStyledControl; const AJData: TJSONAncestor; APopupMenu: TPopupMenu = nil);
begin
  if AJData is TJSONObject then
  begin
    for var i := 0 to TJSONObject(AJData).Count - 1 do
    begin
      SetTreeItem(AParentItem, TJSONObject(AJData).Pairs[i]);
    end;
  end
  else if AJData is TJSONArray then
  begin
    for var i := 0 to TJSONArray(AJData).Count - 1 do
    begin
      SetTreeItem(AParentItem, TJSONArray(AJData)[i]);
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// TJSONTreeViewItem类的构造函数
////////////////////////////////////////////////////////////////////////////////
constructor TJSONTreeViewItem.Create(AOwner: TComponent);
begin
  inherited;
  FJsonData := nil;
  OnMouseDown := TreeViewItemMouseDown;
  OnMouseMove := TreeViewItemMouseMove;
  OnMouseUp := TreeViewItemMouseUp;
end;

////////////////////////////////////////////////////////////////////////////////
// 获取JSONTreeViewItem的第一个子项
////////////////////////////////////////////////////////////////////////////////
function TJSONTreeViewItem.First: TJSONTreeViewItem;
begin
  if Count > 0 then
    Result := TJSONTreeViewItem(Items[0])
  else
    Result := nil;
end;

////////////////////////////////////////////////////////////////////////////////
// 获取JSONTreeViewItem的最后一个子项
////////////////////////////////////////////////////////////////////////////////
function TJSONTreeViewItem.Last: TJSONTreeViewItem;
begin
  if Count > 0 then
    Result := TJSONTreeViewItem(Items[Count - 1])
  else
    Result := nil;
end;

////////////////////////////////////////////////////////////////////////////////
// 获取JSONTreeViewItem的层级深度
////////////////////////////////////////////////////////////////////////////////
function TJSONTreeViewItem.Level: integer;
var
  LCurItem: TJSONTreeViewItem;
begin
  Result := 0;
  LCurItem := self;
  while LCurItem.ParentItem <> nil do
  begin
    Inc(Result);
    LCurItem := LCurItem.MyParentItem;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 判断JSONTreeViewItem是否有子项
////////////////////////////////////////////////////////////////////////////////
function TJSONTreeViewItem.HasSubItem: Boolean;
begin
  Result := Count > 0;
end;

////////////////////////////////////////////////////////////////////////////////
// 判断JSONTreeViewItem是否有被选中的子项
////////////////////////////////////////////////////////////////////////////////
function TJSONTreeViewItem.HasSUbItemIsSelected: Boolean;
begin
  Result := False;
  for var i := 0 to Count - 1 do
  begin
    if Items[i].IsSelected then
      Exit(True);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 获取当前项的父项
////////////////////////////////////////////////////////////////////////////////
function TJSONTreeViewItem.MyParentItem: TJSONTreeViewItem;
begin
  Result := TJSONTreeViewItem(ParentItem);
end;

////////////////////////////////////////////////////////////////////////////////
// 从当前项中移除子项
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.RemoveItem(const AItem: TJSONTreeViewItem; AReTextSubItem: Boolean = False);
begin
  if JsonValue is TJSONObject then
  begin
    TJSONObject(JsonValue).DeletePair(TJSONPair(AItem.FJsonData));
    RemoveObject(AItem);
  end
  else if JsonValue is TJSONArray then
  begin
    TJSONArray(JsonValue).Delete(AItem.JsonValue);
    RemoveObject(AItem);
    if AReTextSubItem then
    begin
      ReTextSubItem;
    end;
  end
  else
  begin
    raise Exception.Create('TJSONTreeViewItem.RemoveItem: must be TJSONObject or TJSONArray');
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 从父项中提取当前项
////////////////////////////////////////////////////////////////////////////////
function TJSONTreeViewItem.ExtractFromParent(AParentReTextSubItem: Boolean = False): TJSONTreeViewItem;
begin
  Result := TJSONTreeViewItem(ParentItem);
  if Result <> nil then
    Result.RemoveItem(self, AParentReTextSubItem);
end;

////////////////////////////////////////////////////////////////////////////////
// 向当前项中添加子项
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.AddItem(const AItem: TJSONTreeViewItem; AItemReText: Boolean = False);
var
  LValue: TJSONValue;
begin
  if JsonValue is TJSONObject then
  begin
    if not(AItem.JsonData is TJSONPair) then
    begin
      AItem.JsonData := TJSONPair.Create('untitled', AItem.JsonValue);
    end;
    TJSONObject(JsonValue).AddPair(TJSONPair(AItem.JsonData));
  end
  else if JsonValue is TJSONArray then
  begin
    if AItem.JsonData is TJSONPair then
    begin
      LValue := AItem.JsonValue;
      LValue.Owned := False;
      FreeAndNil(AItem.JsonData);
      LValue.Owned := True;
      AItem.JsonData := LValue;
    end;
    TJSONArray(JsonValue).AddElement(AItem.JsonValue);
  end;
  AddObject(AItem);
  if AItemReText then
  begin
    AItem.ReText;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 在当前JSON树视图项中插入一个新项
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.InsertItem(const AIndex: integer; const AItem: TJSONTreeViewItem; AReTextSubItem: Boolean = False);
var
  LValue: TJSONValue;
begin
  if JsonValue is TJSONObject then
  begin
    if not(AItem.JsonData is TJSONPair) then
    begin
      AItem.JsonData := TJSONPair.Create('untitled', AItem.JsonValue);
    end;
    TJSONObject(JsonValue).InsertPair(AIndex, TJSONPair(AItem.JsonData));
    InsertObject(AIndex, AItem);
    AItem.ReText;
  end
  else if JsonValue is TJSONArray then
  begin
    if AItem.JsonData is TJSONPair then
    begin
      LValue := AItem.JsonValue;
      LValue.Owned := False;
      FreeAndNil(AItem.JsonData);
      LValue.Owned := True;
      AItem.JsonData := LValue;
    end;
    TJSONArray(JsonValue).InsertElement(AIndex, AItem.JsonValue);
    InsertObject(AIndex, AItem);
    if AReTextSubItem then
    begin
      ReTextSubItem;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 移动JSON树视图项的位置
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.MoveItem(const ACurIndex, ANewIndex: integer; AReTextSubItem: Boolean = False);
var
  LItem: TJSONTreeViewItem;
begin
  if JsonValue is TJSONObject then
  begin
    TJSONObject(JsonValue).Move(ACurIndex, ANewIndex);
    LItem := TJSONTreeViewItem(Items[ACurIndex]);
    RemoveObject(LItem);
    InsertObject(ANewIndex, LItem);
  end
  else
  begin
    TJSONArray(JsonValue).Move(ACurIndex, ANewIndex);
    LItem := TJSONTreeViewItem(Items[ACurIndex]);
    RemoveObject(LItem);
    InsertObject(ANewIndex, LItem);
    if AReTextSubItem then
    begin
      ReTextSubItem;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 清除子条目
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.ClearItem;
begin
  for var i := Count - 1 downto 0 do
  begin
    Items[i].Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 处理JSON树视图项的鼠标按下事件
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.TreeViewItemMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if (Button = TMouseButton.mbLeft) and (ParentItem <> nil) then
  begin
    FMouseDownPos := Screen.MousePos;
    FMouseDowned := True;
  end
  else
  begin
    FMouseDowned := False;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 处理JSON树视图项的鼠标移动事件
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.TreeViewItemMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  if FMouseDowned then
  begin
    if not(ssLeft in Shift) then
    begin
      FMouseDowned := False;
    end
    else if FMouseDowned and ((Abs(FMouseDownPos.X - Screen.MousePos.X) > 4) or (Abs(FMouseDownPos.Y - Screen.MousePos.Y) > 2)) then
    begin
      BeginAutoDrag;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 处理鼠标抬起事件
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.TreeViewItemMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FMouseDowned := False;
end;

////////////////////////////////////////////////////////////////////////////////
// 绘制树视图项
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.Paint;
const
  c_add_line = {$IFDEF MACOS}0{$ELSE}1{$ENDIF};
  c_color_default = $FF808080;
  c_color_brother = $FFFF8080;
  c_color_sub = $FF00AA00;
var
  LParentItem, LCurItem: TJSONTreeViewItem;
  LLeft: Single;
begin
  inherited;
  if ParentItem <> nil then
  begin
    LParentItem := MyParentItem;
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Thickness := 1.0;
    // 根据父项的状态设置绘制颜色
    if LParentItem.IsSelected then
      Canvas.Stroke.Color := c_color_sub
    else if LParentItem.HasSUbItemIsSelected then
      Canvas.Stroke.Color := c_color_brother
    else
      Canvas.Stroke.Color := c_color_default;
    // 绘制连接线
    Canvas.DrawLine(PointF(0, c_add_line), PointF(0, LocalRect.Height / IfThen(self = LParentItem.Last, 2, 1)), 1.0);
    Canvas.DrawLine(PointF(c_add_line, LocalRect.Height / 2), PointF(IfThen(HasSubItem, 7.5, 15), LocalRect.Height / 2), 1.0);
    LLeft := 0;
    LCurItem := LParentItem;
    // 绘制父项及其所有子项的连接线
    while LCurItem.ParentItem <> nil do
    begin
      LLeft := LLeft - 20;
      LParentItem := LCurItem.MyParentItem;
      if (LCurItem <> LParentItem.Last) and LParentItem.IsExpanded then
      begin
        if LParentItem.IsSelected then
          Canvas.Stroke.Color := c_color_sub
        else if LParentItem.HasSUbItemIsSelected then
          Canvas.Stroke.Color := c_color_brother
        else
          Canvas.Stroke.Color := c_color_default;
        Canvas.DrawLine(PointF(LLeft, c_add_line), PointF(LLeft, LocalRect.Bottom), 1.0);
      end;
      LCurItem := LParentItem;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 获取JSON值
////////////////////////////////////////////////////////////////////////////////
function TJSONTreeViewItem.GetJsonValue: TJSONValue;
begin
  if FJsonData is TJSONPair then
    Result := TJSONPair(FJsonData).JsonValue
  else
    Result := TJSONValue(FJsonData);
end;

////////////////////////////////////////////////////////////////////////////////
// 设置JSON值
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.SetJsonValue(const AValue: TJSONValue);
var
  LArr: TJSONArray;
  LIndex: integer;
begin
  if FJsonData is TJSONPair then
  begin
    TJSONPair(FJsonData).JsonValue := AValue;
  end
  else
  begin
    if ParentItem <> nil then
    begin
      LArr := TJSONArray(TJSONTreeViewItem(ParentItem).JsonValue);
      LIndex := LArr.IndexOf(JsonValue);
      LArr.SetValue(LIndex, AValue);
    end;
    FJsonData := AValue;
  end;
  ImageIndex := Ord(AValue.JsonKind);
end;

////////////////////////////////////////////////////////////////////////////////
// 获取JSON键
////////////////////////////////////////////////////////////////////////////////
function TJSONTreeViewItem.GetKey: string;
begin
  if FJsonData is TJSONPair then
  begin
    Result := TJSONPair(FJsonData).JsonString.Value;
  end
  else
  begin
    Result := '';
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 获取JSON值的字符串表示
////////////////////////////////////////////////////////////////////////////////
function TJSONTreeViewItem.GetValue: string;
begin
  Result := GetJsonValue.Value;
end;

////////////////////////////////////////////////////////////////////////////////
// 获取当前项的最后路径
////////////////////////////////////////////////////////////////////////////////
function TJSONTreeViewItem.GetLastPath: string;
begin
  if ParentItem = nil then
  begin
    Exit('');
  end;

  if FJsonData is TJSONPair then
  begin
    Result := TJSONPair(FJsonData).JsonString.Value;
  end
  else
  begin
    Result := '[' + Index.ToString + ']';
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 获取当前项的完整路径
////////////////////////////////////////////////////////////////////////////////
function TJSONTreeViewItem.GetPath: string;
var
  tmpStr: string;
  ptItem: TJSONTreeViewItem;
begin
  ptItem := TJSONTreeViewItem(ParentItem);
  if ptItem = nil then
    Exit('');

  tmpStr := GetLastPath;
  while ptItem.ParentItem <> nil do
  begin
    if ptItem.JsonValue is TJSONObject then
    begin
      tmpStr := ptItem.GetLastPath + '.' + tmpStr;
    end
    else
    begin
      tmpStr := ptItem.GetLastPath + tmpStr;
    end;

    ptItem := TJSONTreeViewItem(ptItem.ParentItem);
  end;

  Result := tmpStr;
end;

////////////////////////////////////////////////////////////////////////////////
// 设置JSON数据
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.SetJsonData(const AValue: TJSONAncestor);
begin
  if FJsonData = AValue then
    Exit;
  FJsonData := AValue;
  ReText;
end;

////////////////////////////////////////////////////////////////////////////////
// 重新设置文本
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.ReText;
begin
  Text := GetLastPath + ': ' + JsonValue.Value;
  ImageIndex := Ord(JsonValue.JsonKind);
  if JsonValue.ClassType = TJSONString then
  begin
    Text := Text.Replace(#13, '\r').Replace(#10, '\n');
    if Text.Length > 100 then
    begin
      Text := Text.Substring(0, 100) + ' ...';
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// 重新设置所有子项的文本
////////////////////////////////////////////////////////////////////////////////
procedure TJSONTreeViewItem.ReTextSubItem;
begin
  for var i := 0 to Count - 1 do
  begin
    TJSONTreeViewItem(Items[i]).ReText;
  end;
end;

end.

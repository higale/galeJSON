unit SaveDialogsEnhanced;

interface

uses
{$IFDEF MACOS}
  Macapi.AppKit, Macapi.ObjectiveC, Macapi.Foundation, Macapi.Helpers,
  FMX.Platform.Mac, Macapi.CocoaTypes,
{$ENDIF}
  System.SysUtils, System.Classes, FMX.Dialogs, FMX.Types;

type
  TEnhancedSaveDialog = class(TSaveDialog)
  private
    FFileType: string;
  public
    constructor Create(AOwner: TComponent); override;
    function Execute: Boolean; override;

    property FileType: string read FFileType;
  end;

implementation

{ TEnhancedSaveDialog }

constructor TEnhancedSaveDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

function TEnhancedSaveDialog.Execute: Boolean;
{$IFDEF MACOS}
const
  NSControlStateValueOn = 1;
var
  SavePanel: NSSavePanel;
  AccessoryView: NSView;
  FileTypeLabel: NSTextField;
  FileTypeCombo: NSPopUpButton;
  Response: NSInteger;
  FilterParts: TArray<string>;
  i: Integer;
{$ENDIF}
begin

{$IFDEF MACOS}
  // 在 macOS 上使用自定义实现
  Result := False;
  try
    // 创建保存面板
    SavePanel := TNSSavePanel.Wrap(TNSSavePanel.OCClass.SavePanel);

    // 设置基本属性
    if FileName <> '' then
      SavePanel.setNameFieldStringValue(StrToNSStr(ExtractFileName(FileName)));

    if InitialDir <> '' then
      SavePanel.setDirectoryURL(TNSUrl.Wrap(TNSUrl.OCClass.fileURLWithPath(StrToNSStr(InitialDir))));

    // 创建AccessoryView
    AccessoryView := TNSView.Create;
    AccessoryView.initWithFrame(NSMakeRect(0, 0, 350, 50));

    // 文件类型下拉框
    FileTypeLabel := TNSTextField.Create;
    FileTypeLabel.initWithFrame(NSMakeRect(43, 15, 80, 20));
    FileTypeLabel.setStringValue(StrToNSStr('类型:'));
    FileTypeLabel.setBezeled(False);
    FileTypeLabel.setDrawsBackground(False);
    FileTypeLabel.setEditable(False);
    FileTypeLabel.setSelectable(False);
    AccessoryView.addSubview(FileTypeLabel);
    FileTypeCombo := TNSPopUpButton.Create;
    FileTypeCombo.initWithFrame(NSMakeRect(78, 15, 245, 20), False);
    
    // 解析 Filter 并添加到下拉框
    if Filter <> '' then
    begin
      FilterParts := Filter.Split(['|']);
      // Filter 格式为: "描述|扩展名|描述|扩展名|..."
      i := 0;
      while i < Length(FilterParts) - 1 do
      begin
        if (i mod 2 = 0) and (i + 1 < Length(FilterParts)) then
        begin
          // 组合描述和扩展名
          FileTypeCombo.addItemWithTitle(StrToNSStr(FilterParts[i] + ' (' + FilterParts[i + 1] + ')'));
        end;
        Inc(i, 2);
      end;
    end;
    
    // 如果没有 Filter 或解析失败，添加默认选项
    if FileTypeCombo.numberOfItems = 0 then
    begin
      FileTypeCombo.addItemWithTitle(StrToNSStr('所有文件 (*.*)'));
    end;
    
    // 设置默认选择，基于 FilterIndex（从1开始）
    if (FilterIndex > 0) and (FilterIndex <= FileTypeCombo.numberOfItems) then
    begin
      FileTypeCombo.selectItemAtIndex(FilterIndex - 1);
    end
    else
    begin
      FileTypeCombo.selectItemAtIndex(0);
    end;
      
    AccessoryView.addSubview(FileTypeCombo);

    SavePanel.setAccessoryView(AccessoryView);

    // 显示保存面板
    Response := SavePanel.runModal;
    if Response = NSModalResponseOK then
    begin
      Result := True;

      // 获取选择的文件名
      FileName := NSStrToStr(SavePanel.FileName);

      // 保存用户的选择
      FFileType := NSStrToStr(FileTypeCombo.titleOfSelectedItem);
      
      // 更新 FilterIndex（从1开始）
      FilterIndex := FileTypeCombo.indexOfSelectedItem + 1;
    end;

  except
    on E: Exception do
    begin
      // 如果自定义实现失败，回退到标准实现
      Result := inherited Execute;
    end;
  end;
{$ELSE}
  // 在非 macOS 平台上使用标准实现
  Result := inherited Execute;
{$ENDIF}
end;

initialization

end.

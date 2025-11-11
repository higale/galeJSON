unit FileWatcher;

interface

uses
  SysUtils, Classes, SyncObjs, Generics.Collections;

type
  // 文件变化类型枚举
  TFileChangeType = (
    fctFileAdded, // 文件添加
    fctFileRemoved, // 文件删除
    fctFileModified // 文件修改
    );

  // 监控目标类型
  TWatchTargetType = (
    wttFile, // 监控单个文件
    wttDirectory // 监控目录
    );

  // 监控目标信息
  TWatchTarget = record
    Path: string; // 文件或目录路径
    TargetType: TWatchTargetType; // 目标类型
    IncludeSubdirs: Boolean; // 是否包含子目录（仅目录有效）
    FileFilter: string; // 文件过滤器，例如 '*.txt;*.log' (可选)
  end;

  // 监控目标变化类型
  TWatchTargetChangeType = (
    wtcAdded, // 目标已添加
    wtcRemoved, // 目标已移除
    wtcCleared // 所有目标已清空
    );

  // 文件变化事件处理器 - 支持匿名函数
  TFileChangedEvent = reference to procedure(const FileName: string; ChangedType: TFileChangeType; const WatchTarget: TWatchTarget);
  // 监控目标变化事件处理器 - 详细通知
  TWatchTargetsChangedEvent = reference to procedure(const Target: TWatchTarget; ChangedType: TWatchTargetChangeType);
  // 监控错误事件处理器
  TWatchErrorEvent = reference to procedure(const AErr: string);

  // 文件状态记录
  TFileState = record
    FileName: string; // 文件名
    LastWriteTime: TDateTime; // 最后修改时间
    FileSize: Int64; // 文件大小
    Exists: Boolean; // 是否存在
  end;

  // 轮询线程
  TPollingThread = class(TThread)
  private
    FOwner: TObject;
    FInterval: Integer; // 轮询间隔（毫秒）
  protected
    procedure Execute; override;
  public
    constructor Create(Owner: TObject; Interval: Integer);
  end;

  // 文件监控类（轮询版本）
  TFileWatcher = class
  private
    FWatchTargets: TList<TWatchTarget>; // 监控目标列表
    FFileStates: TDictionary<string, TFileState>; // 文件状态字典
    FActive: Boolean; // 是否激活
    FOnFileChanged: TFileChangedEvent; // 文件变化事件
    FOnWatchTargetsChanged: TWatchTargetsChangedEvent; // 监控目标变化事件
    FOnWatchErrorEvent: TWatchErrorEvent; // 错误事件
    FPollingThread: TPollingThread; // 轮询线程
    FPollingInterval: Integer; // 轮询间隔（毫秒）
    FPaused: Boolean; // 是否暂停

    procedure InternalAddTarget(Target: TWatchTarget);
    procedure CheckChanges;
    function MatchesFilter(const FileName, Filter: string): Boolean;
    procedure CollectFiles(const Path: string; IncludeSubdirs: Boolean; const Filter: string; Files: TList<string>);
    function GetFileState(const FileName: string): TFileState;
    procedure NotifyWatchTargetsChanged(const Target: TWatchTarget; ChangedType: TWatchTargetChangeType);
    procedure SetPollingInterval(Value: Integer);

  public
    constructor Create(PollingInterval: Integer = 2000);
    destructor Destroy; override;

    // 属性
    property Active: Boolean read FActive; // 是否激活
    property OnFileChanged: TFileChangedEvent read FOnFileChanged write FOnFileChanged; // 文件变化事件
    property OnWatchTargetsChanged: TWatchTargetsChangedEvent read FOnWatchTargetsChanged write FOnWatchTargetsChanged; // 监控目标变化事件
    property OnWatchErrorEvent: TWatchErrorEvent read FOnWatchErrorEvent write FOnWatchErrorEvent; // 错误事件
    property PollingInterval: Integer read FPollingInterval write SetPollingInterval; // 轮询间隔
    property Paused: Boolean read FPaused; // 是否暂停

    // 添加监控目标
    procedure AddFile(const FilePath: string; MustExist: Boolean = False);
    procedure AddDirectory(const DirPath: string; IncludeSubdirs: Boolean = True; const FileFilter: string = '');
    procedure AddTarget(const Target: TWatchTarget);

    // 移除监控目标
    procedure RemoveTarget(const Path: string);
    procedure ClearTargets;

    // 控制监控
    procedure StartWatching;
    procedure StopWatching;
    procedure Pause;
    procedure Resume(AReinitAllFileStates: Boolean);

    // 获取当前监控目标数量
    function GetTargetCount: Integer;
    function GetTarget(Index: Integer): TWatchTarget;

    // 获取所有监控路径
    function GetWatchedPathList: TArray<string>;

    // 线程调用的内部方法
    procedure NotifyFileChanged(const FileName: string; ChangedType: TFileChangeType; const WatchTarget: TWatchTarget);

    // 重新初始化所有监控对象的文件状态
    procedure ReinitAllFileStates;
  end;

implementation

{ TPollingThread }

{-------------------------------------------------------------------------------
  名称: TPollingThread.Create
  说明: 创建轮询线程实例，设置所属对象和轮询间隔
  参数: Owner - 所属对象
        Interval - 轮询间隔（毫秒）
  返回: 无
-------------------------------------------------------------------------------}
constructor TPollingThread.Create(Owner: TObject; Interval: Integer);
begin
  FOwner := Owner;
  FInterval := Interval;
  inherited Create(False);
end;

{-------------------------------------------------------------------------------
  名称: TPollingThread.Execute
  说明: 线程主循环，定时调用文件变化检查
  参数: 无
  返回: 无
-------------------------------------------------------------------------------}
procedure TPollingThread.Execute;
var
  WaitTime: Integer;
begin
  while not Terminated do
  begin
    // 检查文件变化
    TFileWatcher(FOwner).CheckChanges;
    // 等待指定间隔
    WaitTime := 0;
    while (not Terminated) and (WaitTime < FInterval) do
    begin
      Sleep(100);
      Inc(WaitTime, 100);
    end;
  end;
end;

{ TFileWatcher }

{-------------------------------------------------------------------------------
  名称: TFileWatcher.Create
  说明: 创建文件监控器实例，初始化成员变量
  参数: PollingInterval - 轮询间隔（毫秒），默认2000
  返回: 无
-------------------------------------------------------------------------------}
constructor TFileWatcher.Create(PollingInterval: Integer = 2000);
begin
  inherited Create;
  FWatchTargets := TList<TWatchTarget>.Create;
  FFileStates := TDictionary<string, TFileState>.Create;
  FActive := False;
  FPollingInterval := PollingInterval;
  FPollingThread := nil;
  FPaused := False;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.Destroy
  说明: 析构函数，释放资源
  参数: 无
  返回: 无
-------------------------------------------------------------------------------}
destructor TFileWatcher.Destroy;
begin
  StopWatching;
  FWatchTargets.Free;
  FFileStates.Free;
  inherited Destroy;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.AddFile
  说明: 添加单个文件到监控列表
  参数: FilePath - 文件路径
        MustExist - 是否必须存在
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.AddFile(const FilePath: string; MustExist: Boolean = False);
var
  Target: TWatchTarget;
begin
  if MustExist and (not FileExists(FilePath)) then
    raise Exception.CreateFmt('File not found: %s', [FilePath]);

  Target.Path := FilePath;
  Target.TargetType := wttFile;
  Target.IncludeSubdirs := False;
  Target.FileFilter := '';

  InternalAddTarget(Target);
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.AddDirectory
  说明: 添加目录到监控列表，可递归包含子目录
  参数: DirPath - 目录路径
        IncludeSubdirs - 是否包含子目录
        FileFilter - 文件过滤器
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.AddDirectory(const DirPath: string; IncludeSubdirs: Boolean; const FileFilter: string);
var
  Target: TWatchTarget;
begin
  //if not DirectoryExists(DirPath) then
  //  raise Exception.CreateFmt('Directory not found: %s', [DirPath]);

  Target.Path := DirPath;
  Target.TargetType := wttDirectory;
  Target.IncludeSubdirs := IncludeSubdirs;
  Target.FileFilter := FileFilter;

  InternalAddTarget(Target);
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.AddTarget
  说明: 添加自定义监控目标
  参数: Target - 监控目标信息
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.AddTarget(const Target: TWatchTarget);
begin
  InternalAddTarget(Target);
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.InternalAddTarget
  说明: 内部方法，添加监控目标并初始化状态
  参数: Target - 监控目标信息
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.InternalAddTarget(Target: TWatchTarget);
var
  i: Integer;
begin
  TMonitor.Enter(Self);
  try
    // 规范化目录路径
    if Target.TargetType = wttDirectory then
      Target.Path := IncludeTrailingPathDelimiter(Target.Path);

    // 检查是否已存在
    for i := 0 to FWatchTargets.Count - 1 do
    begin
      if SameText(FWatchTargets[i].Path, Target.Path) and
        (FWatchTargets[i].TargetType = Target.TargetType) then
        raise Exception.Create('File already in watch queue: ' + Target.Path);
    end;

    FWatchTargets.Add(Target);

    // 触发监控目标添加事件
    NotifyWatchTargetsChanged(Target, wtcAdded);

    // 如果已经在监控，则初始化文件状态
    if FActive then
    begin
      if Target.TargetType = wttFile then
      begin
        if not FFileStates.ContainsKey(LowerCase(Target.Path)) then
          FFileStates.Add(LowerCase(Target.Path), GetFileState(Target.Path));
      end
      else
      begin
        // 目录监控，收集所有文件
        var
        Files := TList<string>.Create;
        try
          CollectFiles(Target.Path, Target.IncludeSubdirs, Target.FileFilter, Files);
          for var FileName in Files do
          begin
            if not FFileStates.ContainsKey(LowerCase(FileName)) then
              FFileStates.Add(LowerCase(FileName), GetFileState(FileName));
          end;
        finally
          Files.Free;
        end;
      end;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.RemoveTarget
  说明: 移除指定路径的监控目标
  参数: Path - 文件或目录路径
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.RemoveTarget(const Path: string);
var
  i: Integer;
begin
  TMonitor.Enter(Self);
  try
    for i := FWatchTargets.Count - 1 downto 0 do
    begin
      if SameText(FWatchTargets[i].Path, Path) then
      begin
        var
        RemovedTarget := FWatchTargets[i];
        FWatchTargets.Delete(i);
        // 触发监控目标移除事件
        NotifyWatchTargetsChanged(RemovedTarget, wtcRemoved);
        Break;
      end;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.ClearTargets
  说明: 清空所有监控目标
  参数: 无
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.ClearTargets;
begin
  TMonitor.Enter(Self);
  try
    FWatchTargets.Clear;
    FFileStates.Clear;

    // 触发清空监控目标事件
    var
      EmptyTarget: TWatchTarget;
    FillChar(EmptyTarget, SizeOf(EmptyTarget), 0);
    NotifyWatchTargetsChanged(EmptyTarget, wtcCleared);
  finally
    TMonitor.Exit(Self);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.StartWatching
  说明: 启动文件监控，初始化所有文件状态
  参数: 无
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.StartWatching;
begin
  if not FActive then
  begin
    TMonitor.Enter(Self);
    try
      FActive := True;
      ReinitAllFileStates;
      FPollingThread := TPollingThread.Create(Self, FPollingInterval);
    finally
      TMonitor.Exit(Self);
    end;
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.StopWatching
  说明: 停止文件监控，释放线程和状态
  参数: 无
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.StopWatching;
begin
  if FActive then
  begin
    TMonitor.Enter(Self);
    try
      FActive := False;
      if Assigned(FPollingThread) then
      begin
        FPollingThread.Terminate;
        FPollingThread.WaitFor;
        FreeAndNil(FPollingThread);
      end;
      FFileStates.Clear;
    finally
      TMonitor.Exit(Self);
    end;
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.Pause
  说明: 暂停文件监控，但不停止轮询线程
  参数: 无
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.Pause;
begin
  TMonitor.Enter(Self);
  try
    FPaused := True;
  finally
    TMonitor.Exit(Self);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.Resume
  说明: 恢复文件监控，同时重新初始化所有文件状态
  参数: 无
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.Resume(AReinitAllFileStates: Boolean);
begin
  TMonitor.Enter(Self);
  try
    if AReinitAllFileStates then
      ReinitAllFileStates;
    FPaused := False;
  finally
    TMonitor.Exit(Self);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.GetTargetCount
  说明: 获取当前监控目标数量
  参数: 无
  返回: 监控目标数量
-------------------------------------------------------------------------------}
function TFileWatcher.GetTargetCount: Integer;
begin
  TMonitor.Enter(Self);
  try
    Result := FWatchTargets.Count;
  finally
    TMonitor.Exit(Self);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.GetTarget
  说明: 获取指定索引的监控目标
  参数: Index - 目标索引
  返回: 监控目标信息
-------------------------------------------------------------------------------}
function TFileWatcher.GetTarget(Index: Integer): TWatchTarget;
begin
  TMonitor.Enter(Self);
  try
    if (Index < 0) or (Index >= FWatchTargets.Count) then
      raise Exception.CreateFmt('Index out of bounds: %d', [Index]);
    Result := FWatchTargets[Index];
  finally
    TMonitor.Exit(Self);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.GetWatchedPathList
  说明: 获取所有监控路径列表
  参数: 无
  返回: 路径数组
-------------------------------------------------------------------------------}
function TFileWatcher.GetWatchedPathList: TArray<string>;
var
  i: Integer;
  list: TList<string>;
begin
  list := TList<string>.Create;
  TMonitor.Enter(Self);
  try
    for i := 0 to FWatchTargets.Count - 1 do
    begin
      list.Add(FWatchTargets[i].Path);
    end;
    Result := list.ToArray;
  finally
    TMonitor.Exit(Self);
    list.Free;
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.NotifyFileChanged
  说明: 通知文件变化事件
  参数: FileName - 文件名
        ChangedType - 变化类型
        WatchTarget - 监控目标
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.NotifyFileChanged(const FileName: string; ChangedType: TFileChangeType; const WatchTarget: TWatchTarget);
begin
  if Assigned(FOnFileChanged) then
  begin
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(FOnFileChanged) then
          FOnFileChanged(FileName, ChangedType, WatchTarget);
      end);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.CheckChanges
  说明: 检查所有监控文件的变化，触发相应事件
  参数: 无
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.CheckChanges;
var
  i: Integer;
  Target: TWatchTarget;
  Files: TList<string>;
  FileName: string;
  FileKey: string;
  OldState, NewState: TFileState;
  CurrentFiles: TDictionary<string, Boolean>;
  AllCurrentFiles: TList<string>;
begin
  if FPaused then
    Exit;

  TMonitor.Enter(Self);
  try
    CurrentFiles := TDictionary<string, Boolean>.Create;
    AllCurrentFiles := TList<string>.Create;
    try
      // 第一步：收集所有当前存在的文件
      for i := 0 to FWatchTargets.Count - 1 do
      begin
        Target := FWatchTargets[i];

        if Target.TargetType = wttFile then
        begin
          AllCurrentFiles.Add(Target.Path);
        end
        else
        begin
          Files := TList<string>.Create;
          try
            CollectFiles(Target.Path, Target.IncludeSubdirs, Target.FileFilter, Files);
            for FileName in Files do
              AllCurrentFiles.Add(FileName);
          finally
            Files.Free;
          end;
        end;
      end;

      // 第二步：处理删除的文件
      var
      KeysToRemove := TList<string>.Create;
      try
        for var Pair in FFileStates do
        begin
          // 检查文件是否还在当前监控列表中
          var
          IsCurrentFile := False;
          for FileName in AllCurrentFiles do
          begin
            if SameText(LowerCase(FileName), Pair.Key) then
            begin
              IsCurrentFile := True;
              Break;
            end;
          end;

          // 文件不在当前列表中，检查是否被删除
          if not IsCurrentFile and Pair.Value.Exists then
          begin
            NewState := GetFileState(Pair.Value.FileName);
            if not NewState.Exists then
            begin
              // 找到对应的监控目标并触发删除事件
              for i := 0 to FWatchTargets.Count - 1 do
              begin
                if ((FWatchTargets[i].TargetType = wttDirectory) and
                  Pair.Value.FileName.StartsWith(FWatchTargets[i].Path)) or
                  ((FWatchTargets[i].TargetType = wttFile) and
                  SameText(FWatchTargets[i].Path, Pair.Value.FileName)) then
                begin
                  NotifyFileChanged(Pair.Value.FileName, fctFileRemoved, FWatchTargets[i]);
                  Break;
                end;
              end;
            end;
          end;

          // 标记需要清理的文件状态
          if not IsCurrentFile then
            KeysToRemove.Add(Pair.Key);
        end;

        // 清理删除的文件状态
        for var Key in KeysToRemove do
          FFileStates.Remove(Key);
      finally
        KeysToRemove.Free;
      end;

      // 第三步：处理新增和修改的文件
      for i := 0 to FWatchTargets.Count - 1 do
      begin
        Target := FWatchTargets[i];
        Files := TList<string>.Create;
        try
          // 收集需要检查的文件
          if Target.TargetType = wttFile then
            Files.Add(Target.Path)
          else
            CollectFiles(Target.Path, Target.IncludeSubdirs, Target.FileFilter, Files);

          // 统一处理所有文件
          for FileName in Files do
          begin
            FileKey := LowerCase(FileName);
            CurrentFiles.Add(FileKey, True);
            NewState := GetFileState(FileName);

            if FFileStates.ContainsKey(FileKey) then
            begin
              OldState := FFileStates[FileKey];

              if not OldState.Exists and NewState.Exists then
              begin
                NotifyFileChanged(FileName, fctFileAdded, Target);
              end
              else if NewState.Exists and OldState.Exists then
              begin
                // 调试输出时间戳比较
                if (NewState.LastWriteTime <> OldState.LastWriteTime) or
                  (NewState.FileSize <> OldState.FileSize) then
                begin
                  NotifyFileChanged(FileName, fctFileModified, Target);
                end;
              end;

              FFileStates[FileKey] := NewState;
            end
            else
            begin
              FFileStates.Add(FileKey, NewState);
              if NewState.Exists then
                NotifyFileChanged(FileName, fctFileAdded, Target);
            end;
          end;
        finally
          Files.Free;
        end;
      end;

    finally
      CurrentFiles.Free;
      AllCurrentFiles.Free;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.GetFileState
  说明: 获取指定文件的当前状态（跨平台实现，不锁定文件）
  参数: FileName - 文件名
  返回: 文件状态记录
-------------------------------------------------------------------------------}
function TFileWatcher.GetFileState(const FileName: string): TFileState;
var
  SearchRec: TSearchRec;
begin
  Result.FileName := FileName;
  Result.Exists := FileExists(FileName);

  if Result.Exists then
  begin
    // 使用跨平台的 FindFirst 获取文件信息（不锁定文件）
    if FindFirst(FileName, faAnyFile, SearchRec) = 0 then
    begin
      try
        Result.LastWriteTime := SearchRec.TimeStamp;
        Result.FileSize := SearchRec.Size;
      finally
        FindClose(SearchRec);
      end;
    end
    else
    begin
      Result.LastWriteTime := 0;
      Result.FileSize := 0;
    end;
  end
  else
  begin
    Result.LastWriteTime := 0;
    Result.FileSize := 0;
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.CollectFiles
  说明: 递归收集目录下所有符合条件的文件
  参数: Path - 目录路径
        IncludeSubdirs - 是否递归子目录
        Filter - 文件过滤器
        Files - 收集到的文件列表
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.CollectFiles(const Path: string; IncludeSubdirs: Boolean; const Filter: string; Files: TList<string>);
var
  SearchRec: TSearchRec;
  FullPath: string;
begin
  FullPath := IncludeTrailingPathDelimiter(Path);

  if FindFirst(FullPath + '*.*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          if (SearchRec.Attr and faDirectory) <> 0 then
          begin
            // 子目录
            if IncludeSubdirs then
              CollectFiles(FullPath + SearchRec.Name, True, Filter, Files);
          end
          else
          begin
            // 文件
            if MatchesFilter(SearchRec.Name, Filter) then
              Files.Add(FullPath + SearchRec.Name);
          end;
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.MatchesFilter
  说明: 判断文件名是否匹配过滤器
  参数: FileName - 文件名
        Filter - 过滤表达式
  返回: 是否匹配
-------------------------------------------------------------------------------}
function TFileWatcher.MatchesFilter(const FileName, Filter: string): Boolean;
var
  Filters: TArray<string>;
  FilterItem: string;
  i: Integer;
begin
  Result := True;

  // 如果没有设置过滤器，接受所有文件
  if Trim(Filter) = '' then
    Exit;

  Result := False;
  Filters := Filter.Split([';']);

  for i := 0 to High(Filters) do
  begin
    FilterItem := Trim(Filters[i]);
    if FilterItem <> '' then
    begin
      // 简单通配符匹配
      if (FilterItem = '*') or (FilterItem = '*.*') then
      begin
        Result := True;
        Break;
      end
      else if FilterItem.StartsWith('*.') then
      begin
        if SameText(ExtractFileExt(FileName), FilterItem.Substring(1)) then
        begin
          Result := True;
          Break;
        end;
      end
      else if SameText(FileName, FilterItem) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.NotifyWatchTargetsChanged
  说明: 通知监控目标变化事件
  参数: Target - 监控目标
        ChangedType - 变化类型
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.NotifyWatchTargetsChanged(const Target: TWatchTarget; ChangedType: TWatchTargetChangeType);
begin
  if Assigned(FOnWatchTargetsChanged) then
  begin
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(FOnWatchTargetsChanged) then
          FOnWatchTargetsChanged(Target, ChangedType);
      end);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.ReinitAllFileStates
  说明: 重新初始化所有监控对象的文件状态
  参数: 无
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.ReinitAllFileStates;
var
  i: Integer;
begin
  TMonitor.Enter(Self);
  try
    FFileStates.Clear;
    for i := 0 to FWatchTargets.Count - 1 do
    begin
      try
        if FWatchTargets[i].TargetType = wttFile then
        begin
          FFileStates.Add(LowerCase(FWatchTargets[i].Path), GetFileState(FWatchTargets[i].Path));
        end
        else
        begin
          var
          Files := TList<string>.Create;
          try
            CollectFiles(FWatchTargets[i].Path, FWatchTargets[i].IncludeSubdirs, FWatchTargets[i].FileFilter, Files);
            for var FileName in Files do
            begin
              if not FFileStates.ContainsKey(LowerCase(FileName)) then
                FFileStates.Add(LowerCase(FileName), GetFileState(FileName));
            end;
          finally
            Files.Free;
          end;
        end;
      except
        // 忽略单个目标的异常，保证整体流程不中断
      end;
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

{-------------------------------------------------------------------------------
  名称: TFileWatcher.SetPollingInterval
  说明: 设置检查间隔
  参数: Value - 间隔值（毫秒）
  返回: 无
-------------------------------------------------------------------------------}
procedure TFileWatcher.SetPollingInterval(Value: Integer);
begin
  if FPollingInterval <> Value then
  begin
    FPollingInterval := Value;
    if Assigned(FPollingThread) then
      FPollingThread.FInterval := Value; // 让线程立即生效
  end;
end;

end.

// *************************************************************************** }
//
// Small Simple Tasks Library for Delphi 7
//
// Copyright (c) 2019 Dmitry Kornilov
//
// 
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************
unit Tasks;
interface
uses Classes,SyncObjs,SysUtils;
type

//------------------------------------------------------------------------------
  TQueue=class
  private
      _items:TList;
      constructor Create;
      procedure Add(o:TObject);
      function Get:TObject;
  end;

//------------------------------------------------------------------------------
  TAction=procedure(o:TObject);
  TTaskStatus=(tsInQueue,tsWorking,tsComplete,tsUnknown,tsException);


//------------------------------------------------------------------------------
  TTask=class
      destructor Destroy; override;
    public
      class function Build(action:TAction;parameters:TObject):TTask;overload;
      class function Build(action:TAction;parameters:TObject;syncCont:TAction):TTask;overload;
      procedure Run;
      function ContinueWith(a:TAction):TTask;
      function Join(t:TTask):TTask;

      function getTaskStatus:TTaskStatus;
      procedure setTaskStatus(s:TTaskStatus);
      property Status:TTaskStatus
        read getTaskStatus
        write setTaskStatus;
    private
      existsCont:boolean;
      action:TAction;
      parameters:TObject;
      syncCont:TAction;
      TaskCriticalSection:TCriticalSection;
      FStatus:TTaskStatus;
      continues:TList;
      JoinedTask:TTask;
      constructor Create;
  end;

//------------------------------------------------------------------------------
  TStringResult=class
     public
       result:String;
       task:TTask;
  end;


//------------------------------------------------------------------------------
  TMainThread = class (TThread)
  protected
    procedure Execute; override;
  private
    threads:TList;
    constructor Create;
  end;

//------------------------------------------------------------------------------
  TTaskThread= class (TThread)
  protected
    procedure Execute; override;
  private
    _queu:TQueue;
    ThreadCriticalSection: TCriticalSection;
    FWorking:boolean;
    currentTask:TTask;
    constructor Create;
    procedure SyncCall;
    function getWorking:boolean;
    procedure setWorking(b:boolean);
    property working:boolean
      read getWorking
      write setWorking;
  end;

var
  _queue:TQueue;
  _CriticalSection: TCriticalSection;
  _main_thread:TMainThread;
  _CancelFlag:boolean;

const
  MaxParallelism:integer=4;

implementation



//------------------------------------------------------------------------------
constructor TQueue.Create;
begin
  _items:=TList.Create;

end;

//------------------------------------------------------------------------------
procedure TQueue.Add(o:TObject);
begin
  _CriticalSection.Enter;
  _items.Add(o);
  _CriticalSection.Leave;
end;

//------------------------------------------------------------------------------
function TQueue.Get:TObject;
begin
  Result:=nil;
  _CriticalSection.Enter;
  if(_items.Count>0)then
  begin
    Result:=_items[0];
    _items.Delete(0);
  end;
  _CriticalSection.Leave;
end;





//------------------------------------------------------------------------------
constructor TMainThread.Create;
begin
   inherited Create(true);
   Self.Priority:=tpLower;
   Self.threads:=TList.Create;
end;


//------------------------------------------------------------------------------
procedure TMainThread.Execute;
var
  o:TObject;
  t:TTask;
  i:integer;
  tt:TTaskThread;
  added:boolean;
begin
   while(true)do
   begin
      o:=_queue.Get;
      if(o<>nil)then
      begin
        t:=o as TTask;
        added:=false;
        t.Status:=tsInQueue;
        for i:=0 to threads.Count-1 do
        begin
           tt:=TTaskThread(threads[i]);
           if(not tt.working)then
           begin
              tt._queu.Add(o);
              added:=true;
              break;
           end;
        end;
        if(not added)then
        begin
          tt:=TTaskThread(threads[0]);
          tt._queu.Add(o);
        end;
      end;
      if(_CancelFlag)then
        exit;
      Sleep(10);
   end;
end;

//------------------------------------------------------------------------------
class function TTask.Build(action: TAction;parameters:TObject): TTask;
begin
   Result:=TTask.Create;
   Result.action:=action;
   Result.parameters:=parameters;
   Result.syncCont:=nil;
   Result.existsCont:=false;
end;

//------------------------------------------------------------------------------
class function TTask.Build(action: TAction; parameters: TObject;
  syncCont: TAction): TTask;
begin
   Result:=TTask.Create;
   Result.action:=action;
   Result.parameters:=parameters;
   Result.syncCont:=syncCont;

   if(@syncCont<>nil)then
     Result.existsCont:=true;
end;

//------------------------------------------------------------------------------
function TTask.ContinueWith(a: TAction): TTask;
begin
  if(Status=tsUnknown)then
    continues.Add(@a);
  Result:=Self;
end;

//------------------------------------------------------------------------------
constructor TTask.Create;
begin
  Inherited;
  FStatus:=tsUnknown;
  TaskCriticalSection:=TCriticalSection.Create;
  continues:=TList.Create;
  JoinedTask:=nil;
end;

//------------------------------------------------------------------------------
destructor TTask.Destroy;
begin
  TaskCriticalSection.Free;
  continues.Free;
  inherited;
end;

//------------------------------------------------------------------------------
function TTask.getTaskStatus: TTaskStatus;
begin
  TaskCriticalSection.Enter;
  Result:=FStatus;
  TaskCriticalSection.Leave;
end;

//------------------------------------------------------------------------------
function TTask.Join(t: TTask):TTask;
begin
  t.JoinedTask:=Self;
  Result:=Self;
end;

//------------------------------------------------------------------------------
procedure TTask.Run;
begin
   Tasks._queue.Add(Self);
end;

//------------------------------------------------------------------------------
procedure TTask.setTaskStatus(s: TTaskStatus);
begin
  TaskCriticalSection.Enter;
  FStatus:=s;
  TaskCriticalSection.Leave;
end;

//------------------------------------------------------------------------------
constructor TTaskThread.Create;
begin
  Inherited Create(true);
  _queu:=TQueue.Create;
  ThreadCriticalSection:=TCriticalSection.Create;
end;

//------------------------------------------------------------------------------
procedure TTaskThread.Execute;
var
  o:TObject;
  t:TTask;
begin
   while true do
   begin
       o:=self._queu.Get;
       if(o<>nil)then
       begin
         t:=o as TTask;
         working:=true;
         currentTask:=t;
         t.Status:=tsWorking;
         try
           t.action(t.parameters);
         except
           t.Status:=tsException;
         end;
          if(t.continues.Count=0)then
          begin
           t.Status:=tsComplete;
           if((t.JoinedTask<>nil)and(t.JoinedTask.Status=tsUnknown) )then
            Tasks._queue.Add(t.JoinedTask);
             if(t.existsCont)then
             begin
               try
                Synchronize(SyncCall);
               except
                t.Status:=tsException;
               end;
             end;
          end
          else
          begin
             t.action:=t.continues[0];
             t.continues.Delete(0);
             Tasks._queue.Add(t);
          end;
         currentTask:=nil;
         working:=false;
       end;
       if(_CancelFlag)then
        exit;
       Sleep(10);
   end;
end;

//------------------------------------------------------------------------------
var
  i:integer;
  tt:TTaskThread;

//------------------------------------------------------------------------------
function TTaskThread.getWorking: boolean;
begin
  ThreadCriticalSection.Enter;
  Result:=FWorking;
  ThreadCriticalSection.Leave;
end;

//------------------------------------------------------------------------------
procedure TTaskThread.setWorking(b: boolean);
begin
  ThreadCriticalSection.Enter;
  FWorking:=b;
  ThreadCriticalSection.Leave;
end;

//------------------------------------------------------------------------------
procedure TTaskThread.SyncCall;
begin

   if((currentTask<>nil) and (currentTask.existsCont))then
    currentTask.syncCont(currentTask.parameters);

end;

//------------------------------------------------------------------------------
initialization

  _CancelFlag:=false;
  _CriticalSection:=TCriticalSection.Create;
  _queue:=TQueue.Create;
  _main_thread:=TMainThread.Create;
  _main_thread.FreeOnTerminate:=true;
  for i:=0 to MaxParallelism-1 do
  begin
    tt:=TTaskThread.Create;
    tt.FreeOnTerminate:=true;
    tt.Priority:=tpLower;
    _main_thread.threads.Add(tt);
    tt.Resume;
  end;
  _main_thread.Resume;


//------------------------------------------------------------------------------
finalization
   _CancelFlag:=true;
end.


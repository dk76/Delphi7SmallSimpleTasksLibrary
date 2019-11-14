unit MainFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, ADODB, Grids, DBGrids, Tasks, ExtCtrls, Parallel;

type
//------------------------------------------------------------------------------
  TMainForm = class(TForm)
    btnStartTasks: TButton;
    editText1: TMemo;
    tmr1: TTimer;
    btnCancel: TButton;
    btnForEach: TButton;
    procedure btnStartTasksClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure btnForEachClick(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation
{$R *.dfm}
//------------------------------------------------------------------------------
procedure CalcProc(o:TObject);
var
  r:TStringResult;
begin
   r:=o as TStringResult;
   r.result:=r.result+' thread id='+IntToStr(GetCurrentThreadId)+' ';
   Sleep(10);
end;

//------------------------------------------------------------------------------
procedure CalcContProc(o:TObject);
var
  r:TStringResult;
begin
   r:=o as TStringResult;
   r.result:=r.result+#10+'Continuos thread id='+IntToStr(GetCurrentThreadId)+' ';
   Sleep(10);
end;

//------------------------------------------------------------------------------
procedure CalcJoinedProc(o:TObject);
var
  r:TStringResult;
begin
   r:=o as TStringResult;
   r.result:=r.result+'Calc  Joined thread id='+IntToStr(GetCurrentThreadId)+' ';
   Sleep(10);
end;

//------------------------------------------------------------------------------
procedure CallbackProc(o:TObject);
var
  r:TStringResult;
begin
   r:=o as TStringResult;
   MainForm.editText1.Lines.Add('Callback '+r.result);
   if(r.task.Status=tsException)then
     MainForm.editText1.Lines.Add('Exception ');
   r.task.Free;
   r.Free;
end;

//------------------------------------------------------------------------------
procedure CallbackForEach(o:TObject);
var
  r:TStringResult;
begin
   r:=(o as TTaskParameter).o as TStringResult;
   r.task:=(o as TTaskParameter).task;
   MainForm.editText1.Lines.Add('Callback ForEach'+r.result);
   MainForm.editText1.Lines.Add('thread id='+IntToStr(GetCurrentThreadId)+' ');
   if(r.task.Status=tsException)then
     MainForm.editText1.Lines.Add('Exception ');
   r.task.Free;
   r.Free;
end;


//------------------------------------------------------------------------------
procedure ForEachProc(i:integer;o:TObject);
var
  s:TStringResult;
begin

   s:=o as TStringResult;

   s.result:=s.result+'='+IntToStr(i)+' thread id='+IntToStr(GetCurrentThreadId)+' ';
   Sleep(10);

end;

//------------------------------------------------------------------------------
procedure TMainForm.btnStartTasksClick(Sender: TObject);
var
  t,t_j:TTask;
  i,j:integer;
  data:TStringResult;
begin
  tmr1.Enabled:=true;

  for i:=0 to 10 do
  begin
    editText1.Lines.Add('Start Task'+IntToStr(i));

    //data
    data:=TStringResult.Create;
    data.result:='#'+IntToStr(i)+' ';

    //main task 
    t:=TTask.Build(CalcProc,data).ContinueWith(CalcContProc).ContinueWith(CalcContProc);
    data.task:=t;

    //joined task
    t_j:=TTask.Build(CalcJoinedProc,data,callbackProc).Join(t);

    t.Run;
  end;
end;


//------------------------------------------------------------------------------
procedure TMainForm.btnCancelClick(Sender: TObject);
begin
  tmr1.Enabled:=false;
  _CancelFlag:=true;
end;

//------------------------------------------------------------------------------
procedure TMainForm.tmr1Timer(Sender: TObject);
begin
  btnStartTasksClick(Sender);
end;

procedure TMainForm.btnForEachClick(Sender: TObject);
var
  l:TList;
  i:integer;
  s:TStringResult;
begin


  l:=TList.Create;
  for i:=0 to 100 do
  begin
     s:=TStringResult.Create;
     s.result:='Object #'+IntToStr(i);
     l.Add(s);
  end;

  Parallel.ForEach(l,ForEachProc,callbackForEach);

end;

end.

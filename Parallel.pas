unit Parallel;

interface
uses Tasks,Classes,SyncObjs,SysUtils;
type
  TForEachAction=procedure (i:integer;o:TObject);




  TTaskParameter=class
      proc:TForEachAction;
      index:integer;
      o:TObject;
      task:TTask;
  end;


  procedure ForEach(l:TList;proc:TForEachAction;callback:TAction); overload;
  procedure ForEach(l:TList;proc:TForEachAction); overload;

implementation
//------------------------------------------------------------------------------
  procedure CallForEachAction(o:TObject);
  var
    p:TTaskParameter;
  begin
    p:=o as TTaskParameter;
    p.proc(p.index,p.o);
  end;

//------------------------------------------------------------------------------
  procedure ForEach(l:TList;proc:TForEachAction;callback:TAction);
  var
    i:integer;
    t:TTask;
    p:TTaskParameter;
  begin
     if((l=nil)or(l.Count=0))then
       exit;

     for i:=0 to l.Count-1 do
     begin
         p:=TTaskParameter.Create;
         p.proc:=proc;
         p.index:=i;
         p.o:=l[i];
         t:=TTask.Build(CallForEachAction,p,callback);
         p.task:=t;
         t.Run;
     end;

  end;

procedure ForEach(l:TList;proc:TForEachAction);
begin
   ForEach(l,proc,nil);

end;


end.

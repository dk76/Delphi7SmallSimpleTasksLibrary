# Delphi7SmallSimpleTasksLibrary
Simple realization parallel tasks for Delphi 7


```delphi
//main task 
    t:=TTask.Build(CalcProc,data).ContinueWith(CalcContProc).ContinueWith(CalcContProc);

//joined task
    t_j:=TTask.Build(CalcJoinedProc,data,callbackProc).Join(t);

    t.Run;
```



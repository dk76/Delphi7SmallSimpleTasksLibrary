program TasksProject;

uses
  Forms,
  MainFrm in 'MainFrm.pas' {MainForm},
  Tasks in 'Tasks.pas',
  Parallel in 'Parallel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

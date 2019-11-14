object MainForm: TMainForm
  Left = 978
  Top = 252
  Width = 448
  Height = 517
  Caption = 'MainForm'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnStartTasks: TButton
    Left = 344
    Top = 8
    Width = 75
    Height = 25
    Caption = 'StartTasks'
    TabOrder = 0
    OnClick = btnStartTasksClick
  end
  object editText1: TMemo
    Left = 16
    Top = 8
    Width = 321
    Height = 449
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 344
    Top = 64
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 2
    OnClick = btnCancelClick
  end
  object btnForEach: TButton
    Left = 344
    Top = 32
    Width = 75
    Height = 25
    Caption = 'StartForEach'
    TabOrder = 3
    OnClick = btnForEachClick
  end
  object tmr1: TTimer
    Enabled = False
    OnTimer = tmr1Timer
    Left = 344
    Top = 112
  end
end

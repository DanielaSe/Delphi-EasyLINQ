object Form1: TForm1
  Left = 1
  Top = 1
  Anchors = [akTop]
  Caption = 'Form1'
  ClientHeight = 440
  ClientWidth = 888
  Color = clBtnFace
  Constraints.MinHeight = 300
  Constraints.MinWidth = 400
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Scaled = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    888
    440)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 39
    Width = 888
    Height = 401
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    ExplicitWidth = 622
  end
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Run'
    TabOrder = 1
    OnClick = Button1Click
  end
  object ComboBox1: TComboBox
    Left = 220
    Top = 8
    Width = 508
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    DropDownCount = 12
    TabOrder = 2
    Text = 'SELECT WHERE (City="Springfield")'
    Items.Strings = (
      'SELECT WHERE (City="Springfield")'
      'SELECT ORDER BY City,Value'
      'SELECT ORDER BY City,Value DESC'
      
        'SELECT TOP(3) WHERE (UPPER(Lastname) like "%M%") ORDER BY MySubT' +
        'ext.Text'
      'SELECT CALC(value=(value*32+4)/2)  ORDER BY value'
      
        'SELECT TOP(3) WHERE (LOWER(Firstname)="homer") OR (LOWER(Firstna' +
        'me)="marge") '
      'SELECT GROUP BY City WHERE (value<50) ORDER BY MySubRecord.Text'
      'SELECT WHERE (MySubText.Text="Sub3") OR (FirstName="Carl")'
      
        'UPDATE SET (Firstname="Homer", Lastname="Simpson") WHERE (City="' +
        'Shelbyville") OR (MySubText.Text="Sub4")'
      'UPDATE SET (Value=CALC(23*2-4)) WHERE (City="Springfield")')
    ExplicitWidth = 517
  end
  object cbMode: TComboBox
    Left = 89
    Top = 8
    Width = 125
    Height = 22
    Style = csOwnerDrawFixed
    ItemIndex = 0
    TabOrder = 3
    Text = 'Class'
    Items.Strings = (
      'Class'
      'Record (read only)')
  end
  object cbAggregate: TComboBox
    Left = 734
    Top = 8
    Width = 146
    Height = 21
    Anchors = [akTop, akRight]
    ItemIndex = 0
    TabOrder = 4
    Text = 'Max() of field "value"'
    Items.Strings = (
      'Max() of field "value"'
      'Min() of field "value"'
      'Sum() of field "value"'
      'Average() of field "value"'
      'Aggregate() of field "value"')
    ExplicitLeft = 743
  end
end

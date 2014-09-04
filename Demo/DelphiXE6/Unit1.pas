unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, EasyLINQ, Generics.Defaults, Generics.Collections, StdCtrls;

type
  {$M+}

  TMySubClass = class
  private
    fText       : String;
  published
    property Text: String read fText write fText;
  end;

  TMySubRecord = record
  private
    Text         : String;
    end;

  TMyClass = class
  private
    fFirstName   : String;
    fLastName    : String;
    fCity        : String;
    fValue       : Integer;
    fMySubClass  : TMySubclass;
    fMySubRecord : TMySubRecord;
  public
    constructor Create;
    destructor Destroy; override;
    function ToString: String; override;
  published
    property FirstName: String read fFirstName write fFirstName;
    property LastName: String read fLastName write fLastName;
    property City: String read fCity write fCity;
    property Value: Integer read fValue write fValue;
    property MySubText: TMySubclass read fMySubclass write fMySubclass;
    property MySubRecord: TMySubRecord read fMySubRecord write fMySubRecord;
    end;



  TMyRecord = record
  private
    FirstName    : String;
    LastName     : String;
    City         : String;
    Value        : Integer;
    MySubText    : TMySubRecord;
    function ToString: String;
    end;



  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    ComboBox1: TComboBox;
    cbMode: TComboBox;
    cbAggregate: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private-Deklarationen }
    RecordLinq    : TEasyLinQ<TMyRecord>;
    ClassLinq    : TEasyLinQ<TMyClass>;
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{$region '----> TMyClass'}

constructor TMyClass.Create;
begin
  fMySubClass := TMySubClass.Create;
  fMySubClass.Text := 'Sub';
end;



destructor TMyClass.Destroy;
begin
  fMySubClass.Free;
  inherited;
end;



function TMyClass.ToString: String;
begin
  Result := FirstName;
  while Length( result ) < 20 do result := result + ' ';
  Result := result + LastName;
  while Length( result ) < 40 do result := result + ' ';
  Result := result + City;
  while Length( result ) < 60 do result := result + ' ';
  Result := result + IntToStr( value );
  while Length( result ) < 80 do result := result + ' ';
  Result := result + MySubText.Text;
  while Length( result ) < 100 do result := result + ' ';
  Result := result + MySubRecord.Text;
end;

{$endregion}

{$region '----> TMyRecord'}

function TMyRecord.ToString: String;
begin
  Result := FirstName;
  while Length( result ) < 20 do result := result + ' ';
  Result := result + LastName;
  while Length( result ) < 40 do result := result + ' ';
  Result := result + City;
  while Length( result ) < 60 do result := result + ' ';
  Result := result + IntToStr( value );
  while Length( result ) < 80 do result := result + ' ';
  Result := result + MySubText.Text;
end;

{$endregion}


procedure TForm1.Button1Click(Sender: TObject);
var
  linq2   : TEasyLinQ<TMyRecord>;
  linq3   : TEasyLinQ<TMyClass>;
  v       : TMyRecord;
  c       : TMyClass;
  start   : Int64;
  stop    : Int64;
  freq    : Int64;
  e       : Extended;
begin
  Memo1.Lines.Clear;

  for c in ClassLinq do c.Value := Random( 100 );

  QueryPerformanceFrequency( freq );

  case cbMode.ItemIndex of
    0 : begin
          Memo1.Lines.Add( '---- original ' + StringOfChar( '-', 90 ) );
          for c in ClassLinq do Memo1.Lines.Add( c.ToString );

          Memo1.Lines.Add( '---- result ' + StringOfChar( '-', 92 ) );
          QueryPerformanceCounter( start );
          linq3 := ClassLinq.Execute( ComboBox1.Text );
          QueryPerformanceCounter( stop );
          for c in Linq3 do Memo1.Lines.Add( c.ToString );

          Memo1.Lines.Add( '---- aggregate ' + StringOfChar( '-', 89 ) );
          case cbAggregate.ItemIndex of
            0 : e :=  Linq3.Max('value');
            1 : e :=  Linq3.Min('value');
            2 : e :=  Linq3.Sum('value');
            3 : e :=  Linq3.Average('value');
            4 : e :=  Linq3.Aggregate('value');
            end;
          Memo1.Lines.Add( Extended.ToString( e ) );
          linq3.Free;
          end;
    1 : begin
          Memo1.Lines.Add( '---- original ' + StringOfChar( '-', 90 ) );
          for v in RecordLinq do Memo1.Lines.Add( v.ToString );

          Memo1.Lines.Add( '---- result ' + StringOfChar( '-', 92 ) );
          QueryPerformanceCounter( start );
          linq2 := RecordLinq.Execute( ComboBox1.Text );
          QueryPerformanceCounter( stop );
          for v in Linq2 do Memo1.Lines.Add( v.ToString );
          linq2.Free;
          end;
    end;
  Memo1.Lines.Add( '' );
  Memo1.Lines.Add( '' );
  Memo1.Lines.Add( 'Execution time: ' + FormatFloat('0.00', (stop - start) * 1000 / freq) + 'ms' );
end;



procedure TForm1.FormCreate(Sender: TObject);
const
  TXT_FIRSTNAME : Array [1..6] of String = ('Homer','Marge','Milhouse','Ned','Carl', 'Edna');
  TXT_LASTNAME  : Array [1..6] of String = ('Simpson','Simpson','van Houten','Flanders','Carlson', 'Krabappel' );
  TXT_CITY      : Array [1..6] of String  = ('Springfield', 'Springfield', 'Springfield', 'Shelbyville', 'Shelbyville', 'Shelbyville');
var
  i       : Integer;
  v       : TMyRecord;
  c       : TMyClass;
begin
  ReportMemoryLeaksOnShutDown := True;

  ClassLinq := TEasyLinQ<TMyClass>.Create;
  for i := 1 to 6 do begin
    c := TMyClass.Create;
    c.FirstName := TXT_FIRSTNAME[i];
    c.LastName  := TXT_LASTNAME[i];
    c.City      := TXT_CITY[i];
    c.Value     := Random( 100 );
    c.fMySubClass.Text := c.fMySubClass.Text + IntToStr( 6 - i );
    c.fMySubRecord.Text := 'rec' + IntToStr( 10 + i );
    ClassLinq.Add( c );
    end;

  RecordLinq := TEasyLinQ<TMyRecord>.Create;
  for i := 1 to 6 do begin
    v.FirstName := TXT_FIRSTNAME[i];
    v.LastName  := TXT_LASTNAME[i];
    v.City      := TXT_CITY[i];
    v.Value     := Random( 100 );
    v.MySubText.Text := 'Sub' + IntToStr( 6 - i );
    RecordLinq.Add( v );
    end;

end;




procedure TForm1.FormDestroy(Sender: TObject);
begin
  RecordLinq.Free;
  ClassLinq.Free;
end;







end.

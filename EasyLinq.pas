(**************************************************************************************************)
(*
(*  Copyright (c) 2010-2014 Daniela Sefzig
(*
(*  Description   A generic list which is able to execute basic SQL commands similar to Linq
(*  Filename      EasyLINQ.pas
(*  Version       v1.41
(*  Date          04.Sep.2014
(*  Project       EasyLINQ
(*  Info / Help   contact author at daniela.sefzig(a)alien.at
(*  Support       contact author at daniela.sefzig(a)alien.at
(*
(*  License       MPL v1.1 , GPL v3.0 or LGPL v3.0
(*
(*  Mozilla Public License (MPL) v1.1
(*  GNU General Public License (GPL) v3.0
(*  GNU Lesser General Public License (LGPL) v3.0
(*
(*  The contents of this file are subject to the Mozilla Public License
(*  Version 1.1 (the "License"); you may not use this file except in
(*  compliance with the License.
(*  You may obtain a copy of the License at http://www.mozilla.org/MPL .
(*
(*  Software distributed under the License is distributed on an "AS IS"
(*  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
(*  License for the specific language governing rights and limitations
(*  under the License.
(*
(*  The Original Code is "EasyLINQ.pas".
(*
(*  The Initial Developer of the Original Code is "Daniela Sefzig".
(*  Portions created by Initial Developer are Copyright (C) 2011.
(*  All Rights Reserved.
(*
(*  Contributor(s): -
(*
(*  Alternatively, the contents of this file may be used under the terms
(*  of the GNU General Public License Version 3.0 or later (the "GPL"), or the
(*  GNU Lesser General Public License Version 3.0 or later (the "LGPL"),
(*  in which case the provisions of GPL or the LGPL are applicable instead of
(*  those above. If you wish to allow use of your version of this file only
(*  under the terms of the GPL or the LGPL and not to allow others to use
(*  your version of this file under the MPL, indicate your decision by
(*  deleting the provisions above and replace them with the notice and
(*  other provisions required by the GPL or the LGPL. If you do not delete
(*  the provisions above, a recipient may use your version of this file
(*  under either the MPL, the GPL or the LGPL.
(*
(*
(*
(*  HTML:                               PlainText:
(*  www.mozilla.org/MPL/MPL-1.1.html    www.mozilla.org/MPL/MPL-1.1.txt
(*  www.gnu.org/licenses/gpl-3.0.html   www.gnu.org/licenses/gpl-3.0.txt
(*  www.gnu.org/licenses/lgpl-3.0.html  www.gnu.org/licenses/lgpl-3.0.txt
(*
(*
(*
(*
(*  Supported commands:
(*
(*  SELECT                                   Optional
(*  DISTINCT Fieldname                       Genereates groups
(*  TOP(x)                                   Returns only the first x objects
(*  CALC(x)                                  calculates an expression, supports:
(*                                           -+/*^() sin cos tan sqr log cot sec csc
(*  WHERE (...) AND/OR/XOR (...)             Filter, combine with AND, OR, XOR
(*        UPPER(field), LOWER(field), LIKE %x%
(*  GROUP BY field1, field2...               same as distinct
(*  ORDER BY field1, field2,...              sort order
(*        DESC, ASC
(*
(*  UPDATE SET (x = x, x = x)                update, writes new values into the fields
(*  UPDATE SET (x=CALC(x))
(*
(*
(*  History:
(*      v1.1 | 6.Sep.2011
(*         - Added CALC command
(*      v1.2 | 12.Sep.2011
(*         - parser (gettoken, wherecmd) changed
(*         - second "where" parameter can be a field
(*         - supports subclasses
(*         - UPDATE command added, second parameter can be a calculated field
(*      v1.2b | 13.Sep.2011
(*         - some minor bug fixes
(*         - support records in classes and records
(*      v1.3 | 29.Jan.2013
(*         - kompatible with Delphi XE3
(*         - 64Bit kompatible
(*         - "Where" function added
(*         - "OrderBy" function added
(*         - "Distinct" function added
(*         - "Move" function added
(*      v1.4 | 14.Aug.2014
(*         - tested with Delphi XE6 (Not on mac compiler)
(*         - Element Operators: First, Last
(*         - Custom Sequence Operators: Combine
(*         - Partitioning Operators: Take, Skip, Odd, Even
(*         - Generation Operators: Range, Repeat
(*         - Aggregate Operators: Aggregate, Average, Min, Max, Sum
(*      v1.41 | 4.Sep.2014
(*         - Bug in GetCMD with delete characters of like command (thanks to Bruno)
(*
(*
(**************************************************************************************************)
unit EasyLINQ;

interface

uses Windows, Classes, Generics.Defaults, Generics.Collections, Rtti,
     Calculator, TypInfo, RTLConsts, SysUtils;


{$TYPEINFO ON}
{$M+}



{$i EasyLINQ.inc}



type

  ELinQException = class(Exception);


  (*** l�sst sich Aufgrund eines Internen Fehlers bei < XE2 nicht in die Klasse verschieben ***)
{$ifndef DELPHI_XE2}
  TTokenTpye = (ttField, ttString, ttConst );
  TCombine = ( _AND, _OR, _XOR );
  TCharCase = (ccDefault, ccToUpper, ccToLower);
  TCommandMode = (wmIS, wmLess, wmUpper, wmIsLess, wmIsUpper, wmIsNot, wmLike );
{$endif}


  TEasyLINQ<T> = class(TEnumerable<T>)
  type
    {$ifdef DELPHI_XE2}
      TTokenTpye = (ttField, ttString, ttConst, ttCalculation );
      TCombine = ( _AND, _OR, _XOR );
      TCharCase = (ccDefault, ccToUpper, ccToLower);
      TCommandMode = (wmIS, wmLess, wmUpper, wmIsLess, wmIsUpper, wmIsNot, wmLike );
    {$endif}
    TFieldInfo = record
      Exists    : Boolean;
      TypeInfo  : TRttiType;
      Value     : TValue;
      TypeKind  : TTypeKind;
      FieldName : String;
      end;
    TWhereCMD = record
      Field    : String;
      Value    : String;
      Mode     : TCommandMode;
      TypeKind : TTypeKind;
      Combine  : TCombine;
      CharCase : TCharCase;
      Field2    : String;
      TypeKind2 : TTypeKind;
      end;
    TSortIndex = record
      obj     : TObject;
      value   : String;
      end;
  const
    StopAt       : TSysCharSet = ['<', '>', '=', ' ', '(', ')'];
  private
    fSortOrderDesc : Boolean;
    fCalculator    : TCalculator;
    fLookupTable   : Boolean;
    fContext       : TRttiContext;
    fTypeInfo      : TRttiType;
    fItems         : TList<T>;
    fOnNotify      : TCollectionNotifyEvent<T>;
    function GetItem(Index: Integer): T;
    procedure SetItem(Index: Integer; const Value: T);
    function GetCount: Integer;
    function Compare(const L, R: T; prop: String): integer;
    function UnquoteStr( str: String ): String;
    function GetCMD(var txt: String; fTypeInfo: TRttiType): TWhereCMD;
    function IsValid(item: T; cmd: TWhereCMD): Boolean;
    function GetToken(var str: String): String;
    procedure DoDistinct( FieldNames: String );
    procedure ExecOrderBy( const FieldNames: String );
    procedure ExecUpdate( const Commands: String );
    procedure GetFieldValue( FieldName: String; var Value: Double );
    procedure Calculate( txt: String );
    function GetValue( item: Pointer; FieldName: String ): TValue;
    procedure SetValue( const item: Pointer; FieldName: String; Value: Variant );
    function GetFieldInfo( item: Pointer;  FieldName: String ): TFieldInfo;
    function GetTypOfToken( str: String ): TTokenTpye;
  protected
    function DoGetEnumerator: TEnumerator<T>; override;
    procedure Notify(const Item: T; Action: TCollectionNotification); virtual;
  public
    constructor Create( LookupTable: Boolean = False );
    destructor Destroy; override;
    function Add( const Value: T ): Integer;
    procedure Remove( index :Integer );
    function Insert( index :Integer; const Value: T ): Integer;
    procedure Move(CurIndex, NewIndex: Integer);

    procedure Clear;
    function Execute( command: String ): TEasyLINQ<T>;
    function Where( command: String ): TEasyLINQ<T>;
    function OrderBy( field: String ): TEasyLINQ<T>;
    function Distinct( field: String ): TStringList;


    (* Element Operators *)
    property Items[Index: Integer]: T read GetItem write SetItem; default;
    function First: T;
    function Last: T;

    (* Custom Sequence Operators *)
    function Combine( source: TEasyLINQ<T> ): TEasyLINQ<T>;

    (* Partitioning Operators *)
    function Take( n: Integer ): TEasyLINQ<T>;
    function Skip( n: Integer ): TEasyLINQ<T>;
    function Odd: TEasyLINQ<T>;
    function Even: TEasyLINQ<T>;

    (* Generation Operators *)
    function Range( fromIndex, toIndex: Integer ): TEasyLINQ<T>;
    function &Repeat( Index, n: Integer ): TEasyLINQ<T>;

    (* Aggregate Operators *)
    function Aggregate( field: String ): Extended;
    function Average( field: String ): Extended;
    function Max( field: String ): Extended;
    function Min( field: String ): Extended;
    function Sum( field: String ): Extended;

    type
      TEnumerator = class(TEnumerator<T>)
      private
        FList: TEasyLINQ<T>;
        FIndex: Integer;
        function GetCurrent: T;
      protected
        function DoGetCurrent: T; override;
        function DoMoveNext: Boolean; override;
      public
        constructor Create(AList: TEasyLINQ<T>);
        property Current: T read GetCurrent;
        function MoveNext: Boolean;
      end;

    function GetEnumerator: TEnumerator; reintroduce;
  published
    property Count: Integer read GetCount;
    property IsLookupTable: Boolean read fLookupTable;
  end;



implementation


uses Dialogs, Controls, math, StrUtils;



{$region '----> constructor / destructor'}



(**************************************************************************************************)
(*  Create
(*
(**************************************************************************************************)
constructor TEasyLINQ<T>.Create( LookupTable: Boolean = False );
begin
  fLookupTable := LookupTable;
  fCalculator := TCalculator.Create;
  fCalculator.OnCalculatorGetFieldValue := GetFieldValue;
  fItems := TList<T>.Create;
  fContext := TRttiContext.Create;
  fTypeInfo := fContext.GetType( System.TypeInfo(T) );
end;



(**************************************************************************************************)
(*  Destroy
(*
(**************************************************************************************************)
destructor TEasyLINQ<T>.Destroy;
begin
  Clear;
  fItems.Free;
  fItems := nil;
  fCalculator.Free;
  inherited;
end;


{$endregion}

{$region '----> Enumerator'}


function TEasyLINQ<T>.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;



function TEasyLINQ<T>.DoGetEnumerator: TEnumerator<T>;
begin
  Result := GetEnumerator;
end;



constructor TEasyLINQ<T>.TEnumerator.Create(AList: TEasyLINQ<T>);
begin
  inherited Create;
  fList := AList;
  fIndex := -1;
end;



function TEasyLINQ<T>.TEnumerator.DoGetCurrent: T;
begin
  Result := GetCurrent;
end;



function TEasyLINQ<T>.TEnumerator.DoMoveNext: Boolean;
begin
  Result := MoveNext;
end;



function TEasyLINQ<T>.TEnumerator.GetCurrent: T;
begin
  Result := fList[fIndex];
end;



function TEasyLINQ<T>.TEnumerator.MoveNext: Boolean;
begin
  if fIndex >= fList.Count then
    Exit(False);
  Inc(fIndex);
  Result := fIndex < fList.Count;
end;


{$endregion}

{$region '----> default list operations'}

(**************************************************************************************************)
(*  Remove
(*
(**************************************************************************************************)
procedure TEasyLINQ<T>.Remove( index :Integer );
var
  item   : T;
begin
  if (index < 0) or (index > Count) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  if (not fLookupTable) and (fTypeInfo.TypeKind = tkClass) then begin
    item := fItems[index];
    FreeAndNil( item );
    end;
  fItems.Delete( index );
end;



(**************************************************************************************************)
(*  Add
(*
(**************************************************************************************************)
function TEasyLINQ<T>.Add( const Value: T ): Integer;
begin
  Result := fItems.Add( Value );
end;



(**************************************************************************************************)
(*  Move
(*
(**************************************************************************************************)
procedure TEasyLINQ<T>.Move(CurIndex, NewIndex: Integer);
begin
  fItems.Move( CurIndex, NewIndex );
end;



(**************************************************************************************************)
(*  Insert
(*
(**************************************************************************************************)
function TEasyLINQ<T>.Insert(index: Integer; const Value: T): Integer;
begin
  if (index < 0) or (index > Count) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  fItems.Insert( index, value );
end;



(**************************************************************************************************)
(*  GetCount
(*
(**************************************************************************************************)
function TEasyLINQ<T>.GetCount: Integer;
begin
  Result := fItems.Count;
end;



(**************************************************************************************************)
(*  GetItem
(*
(**************************************************************************************************)
function TEasyLINQ<T>.GetItem(index: Integer): T;
begin
  if (index < 0) or (index >= Count) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  Result := fItems[index]
end;


(**************************************************************************************************)
(*  Notify
(*
(**************************************************************************************************)
procedure TEasyLINQ<T>.Notify(const Item: T; Action: TCollectionNotification);
begin
  if Assigned(fOnNotify) then
    fOnNotify(Self, Item, Action);
end;



(**************************************************************************************************)
(*  SetItem
(*
(**************************************************************************************************)
procedure TEasyLINQ<T>.SetItem(Index: Integer; const Value: T);
var
  oldItem: T;
begin
  if (index < 0) or (index >= Count) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  oldItem := fItems[Index];
  fItems[Index] := Value;

  Notify(oldItem, cnRemoved);
  Notify(Value, cnAdded);

end;



(**************************************************************************************************)
(*  Clear
(*
(**************************************************************************************************)
procedure TEasyLINQ<T>.Clear;
var
  item  : T;
  i     : Integer;
begin
  if (not fLookupTable) and (fTypeInfo.TypeKind = tkClass) then
    for i := 0 to fItems.Count - 1 do begin
      item := fItems[i];
      FreeAndNil( item );
      end;
  fItems.Clear;
end;
{$endregion}

{$region '----> Functions'}



(**************************************************************************************************)
(*  GetFieldInfo
(*  Returns the Field Informations
(**************************************************************************************************)
function TEasyLINQ<T>.GetFieldInfo( item: Pointer; FieldName: String ): TFieldInfo;
var
  f      : String;
  x      : Integer;
  ft     : TRttiType;
  _f     : TRttiField;
  field  : TRttiField;
  _p     : TRttiProperty;
  prop   : TRttiProperty;
  a      : TArray<TRttiField>;
  v      : TValue;
  it     : T;
  p      : Pointer;
begin
  (*** reference to first entry, needed to search subclasses ***)
  if item = nil then begin
    it := fItems[0];
    item := @it;
    end;

  v := TValue.Empty;
  result.Exists := False;

  ft := fContext.GetType( System.TypeInfo(T) );
  repeat
    x := Pos( '.', FieldName );
    if x > 0 then begin
      f := Copy( FieldName, 1, x - 1 );
      Delete( FieldName, 1, x );
      field := ft.GetField( f );
      if field <> nil then v := field.GetValue( TObject(item^) )
      else begin
        prop := ft.GetProperty( f );
        if prop = nil then Exit;
        v := prop.GetValue( TObject(item^) );
        end;
      case v.Kind of
        tkClass: ft := fContext.GetType( v.AsObject.ClassType );
        tkRecord: ft := fContext.GetType( v.TypeInfo );
        end;
      end;
  until x = 0;

  result.FieldName := FieldName;
  result.TypeInfo := ft;
  prop := ft.GetProperty( FieldName );
  if prop <> nil then begin
    if v.IsEmpty then result.Value := prop.GetValue( TObject(item^) )
    else result.Value := prop.GetValue( v.AsObject );
    result.TypeKind := prop.PropertyType.TypeKind;
    result.Exists := True;
    end
  else begin
    field := ft.GetField( FieldName );
    if field <> nil then begin
      if v.IsEmpty then result.Value := field.GetValue( item )
      else result.Value := field.GetValue( v.GetReferenceToRawData );
      result.TypeKind := field.FieldType.TypeKind;
      result.Exists := True;
      end;
    end
end;



(**************************************************************************************************)
(*  GetValue
(*  helper for getting values
(**************************************************************************************************)
function TEasyLINQ<T>.GetValue( item: Pointer; FieldName: String ): TValue;
var
  FieldInfo : TFieldInfo;
begin
  result := TValue.Empty;
  FieldInfo := GetFieldInfo( item, FieldName );
  if not FieldInfo.Exists then Exit;
  case FieldInfo.TypeKind of
    tkChar, tkWString,
    tkUString, tkString : result := UnquoteStr( FieldInfo.Value.AsString );
    else result := FieldInfo.Value;
    end;
end;



(**************************************************************************************************)
(*  SetValue
(*  helper for settings values
(**************************************************************************************************)
procedure TEasyLINQ<T>.SetValue( const item: Pointer; FieldName: String; Value: Variant );
var
  prop      : TRttiProperty;
  field     : TRttiField;
  v         : TValue;
  FieldInfo : TFieldInfo;
begin
  FieldInfo := GetFieldInfo( item, FieldName );
  if FieldInfo.Exists then begin
    prop := FieldInfo.TypeInfo.GetProperty( FieldInfo.FieldName );
    if prop = nil then
      raise ELinQException.Create('TLinQ: Read only fields. Only properties are writeable');
    case prop.PropertyType.TypeKind of
      tkChar, tkWString,
      tkUString, tkString : prop.SetValue( TObject(item^), TValue.From<String>( Value ) );
      tkInt64, tkInteger  : prop.SetValue( TObject(item^), TValue.From<Integer>( Value ) );
      tkFloat             : prop.SetValue( TObject(item^), TValue.From<Double>( Value ) );
      end;
    end;
end;



(**************************************************************************************************)
(*  GetFieldValue
(*  Callback for TCalculator, loads the value of a field
(**************************************************************************************************)
procedure TEasyLINQ<T>.GetFieldValue( FieldName: String; var Value: Double );
var
  v     : TValue;
begin
  v := GetValue( fCalculator.ActiveItem, FieldName );
  if v.IsEmpty then Value := 0
  else
    case v.Kind of
      tkFloat,
      tkInt64,
      tkInteger : Value := v.AsCurrency;
      end;
end;



(**************************************************************************************************)
(*  Compare
(*
(**************************************************************************************************)
function TEasyLINQ<T>.Compare(const L, R: T; prop: String ): integer;
var
  vL     : TFieldInfo;
  vR     : TFieldInfo;
begin
  result := 0;
  vL := GetFieldInfo( @L, prop );
  vR := GetFieldInfo( @R, prop );
  case vL.TypeKind of
    tkChar, tkWString, tkUString, tkString : result := CompareText( vL.Value.AsString, vR.Value.AsString );
    tkInt64, tkInteger : if vL.Value.AsInteger < vR.Value.AsInteger then result := -1
                         else if vL.Value.AsInteger > vR.Value.AsInteger then result := 1;
    tkFloat            : if vL.Value.AsCurrency < vR.Value.AsCurrency then result := -1
                         else if vL.Value.AsCurrency > vR.Value.AsCurrency then result := 1;
    end;
end;



(**************************************************************************************************)
(*  OrderBy
(*  creates the sort order of the list
(**************************************************************************************************)
procedure TEasyLINQ<T>.ExecOrderBy(const FieldNames: String );
var
  sl         : TStringList;
begin

  sl := TStringList.Create;
  try
    sl.StrictDelimiter := True;
    sl.Delimiter := ',';
    sl.DelimitedText := FieldNames;

    fItems.Sort( TComparer<T>.Construct( {$region '...'}
       function (const L, R: T ): integer
       var
         str    : String;
       begin
         result := 0;
         for str in sl do begin
           Result := Compare( L, R, Trim( str ) );
           if Result <> 0 then Break;
           end;
         if fSortOrderDesc then Result := Result * -1;
       end {$endregion}     ) );

  finally
    sl.Free;
    end;
end;



(**************************************************************************************************)
(*  ExecUpdate
(*  executes the UPDATE command
(**************************************************************************************************)
procedure TEasyLINQ<T>.ExecUpdate( const Commands: String );
var
  cmd       : String;
  tmp       : String;
  param1    : String;
  param2    : Variant;
  value     : TValue;
  FieldInfo : TFieldInfo;
  item      : T;
begin
  for item in fItems do begin
    cmd := Trim( Commands );
    while cmd <> '' do begin
      param1 := GetToken( cmd );
      if Pos( '=', cmd ) <> 1 then
        raise ELinQException.Create('TLinQ: = required in Update expression');
      Delete( cmd, 1, 1 );
      param2 := GetToken( cmd );
      if LowerCase( param2 ) = 'calc' then begin
        tmp := GetToken( cmd );
        fCalculator.ActiveItem := @item;
        fCalculator.Expression( tmp );
        if fCalculator.Valid then Param2 := fCalculator.Result;
        end
      else
        case GetTypOfToken( param2 ) of
          ttString : Param2 := UnquoteStr( Param2 );
          ttField : begin
                      value := GetValue( @item, Param2 );
                      if value.IsEmpty then
                        raise ELinQException.Create('TLinQ: unknown parameter ' + Param2);
                      Param2 := FieldInfo.Value.AsVariant;
                      end;
          end;
      SetValue( @item, param1, param2 );
      Delete( cmd, 1, 1 );
      end;
   end;
end;



(**************************************************************************************************)
(*  Calculate
(*  executes the calculator
(**************************************************************************************************)
procedure TEasyLINQ<T>.Calculate( txt: String );
var
  field    : String;
  res      : Double;
  prop     : TRttiProperty;
  item     : T;
  i        : Integer;
begin
  field := GetToken( txt );
  if field = '' then Exit;
  Delete( txt, 1, 1 );
  for item in fItems do begin
    fCalculator.ActiveItem := @item;
    fCalculator.Expression( txt );
    if fCalculator.Valid then res := fCalculator.Result
    else res := 0;
    SetValue( @item, field, res );
    end;
end;



(**************************************************************************************************)
(*  Distinct
(*  uses TStringList as helper to create a disinct list
(**************************************************************************************************)
procedure TEasyLINQ<T>.DoDistinct( FieldNames: String );
var
  item         : T;
  sl           : TStringList;
  res          : TStringList;
  field        : String;
  str          : String;
  prop         : TRttiProperty;
  x            : Integer;
begin
  sl := TStringList.Create;
  res := TStringList.Create;
  try
    sl.StrictDelimiter := True;
    sl.Delimiter := ',';
    sl.DelimitedText := FieldNames;
    res.Duplicates := dupIgnore;
    res.Sorted := True;

    x := 0;
    while x < fItems.Count do begin
      str := '';
      item := fItems[x];
      for field in sl do str := str + GetValue( @item, field ).AsString;
      if res.IndexOf( str ) < 0 then begin
        res.Add( str );
        Inc( x );
        end
      else Remove( x );
      end;
  finally
    sl.Free;
    res.Free;
    end;
end;




(**************************************************************************************************)
(*  IsValid
(*  verify the values
(**************************************************************************************************)
function TEasyLINQ<T>.IsValid( item: T; cmd: TWhereCMD ): Boolean;
var
  v1     : Variant;
  v2     : Variant;
  str1   : String;
  str2   : String;
  m      : Integer;
begin
  Result := False;

  if cmd.Field2 <> '' then begin
    (*** second parameter is also a field ***)
    v1 := GetValue( @item, cmd.Field2 ).AsVariant;
    end
  else
    case cmd.TypeKind of
      tkChar, tkWString, tkUString, tkString : v1 := cmd.Value;
      tkInt64, tkInteger : v1 := StrToIntDef( cmd.Value, 0 );
      tkFloat            : v1 := StrToFloat( cmd.Value );
      else Exit( True );
      end;

  v2 := GetValue( @item, cmd.Field ).AsVariant;

  case cmd.CharCase of
    ccToUpper : v2 := WideUpperCase( v2 );
    ccToLower : v2 := WideLowerCase( v2 );
    end;

  case cmd.Mode of
    wmIS       : Result := v2 = v1;
    wmLess     : Result := v2 < v1;
    wmUpper    : Result := v2 > v1;
    wmIsLess   : Result := v2 <= v1;
    wmIsUpper  : Result := v2 >= v1;
    wmIsNot    : Result := v2 <> v1;
    wmLike     : begin
                   str1 := v1;
                   str2 := v2;
                   m := 0;
                   if Pos( '%', str1 ) = 1 then begin
                      m := m or 1;
                      Delete( str1, 1, 1 );
                      end;
                   if Pos( '%', str1 ) = Length( str1 ) then begin
                      m := m or 2;
                      Delete( str1, Length( str1 ), 1 );
                      end;
                   case m of
                     0 : Result := CompareText( str1, str2 ) = 0;
                     1 : Result := Pos( str1, str2 ) = Length( str2 ) - Length( str1 ) + 1;
                     2 : Result := Pos( str1, str2 ) = 1;
                     3 : Result := Pos( str1, str2 ) > 0;
                     end;
                   end;
    end;
end;


{$endregion}

{$region '----> Parser'}

(**************************************************************************************************)
(*  GetToken
(*  loads the next token from the string
(**************************************************************************************************)
function TEasyLINQ<T>.GetToken( var str: String ): String;
var
  i        : Integer;
  j        : Integer;
  x        : Integer;
  start    : Integer;
  ext      : Boolean;
  count    : Integer;
  fExtractCount : Integer;
begin
  str := TrimLeft( str );
  result := '';
  if str = '' then Exit;

  case IndexStr( str[1], ['"','''', '('] ) of
    0 : begin
          x := PosEx( '"', str, 2 );
          if x > 0 then begin
            Result := Trim( Copy( str, 1, x ) );
            Delete( str, 1, x );
            end
          else raise Exception.Create('TEasyLINQ: " missing');
          end;
    1 : begin
          x := PosEx( '''', str, 2 );
          if x > 0 then begin
            Result := Trim( Copy( str, 1, x - 1 ) );
            Delete( str, 1, x );
            end
          else raise Exception.Create('TEasyLINQ: '' missing');
          end;
    2 : begin
          count := 1;
          for x := 2 to Length( str ) do begin
            if str[x] = '(' then begin
              Inc( count );
              Continue;
              end;
            if str[x] = ')' then begin
              Dec( count );
              if count = 0 then begin
                Result := Trim( Copy( str, 2, x - 2 ) );
                Delete( str, 1, x );
                Exit;
                end;
              end;
            end;
          raise Exception.Create('TEasyLINQ: ) missing');
          end;
    else begin
      for x := 1 to Length( str ) do begin
        if CharInSet( str[x], StopAt ) then begin
          Result := Trim( Copy( str, 1, x - 1 ) );
          Delete( str, 1, x - 1 );
          str := TrimLeft( str );
          Exit;
          end;
        end;
      result := str;
      str := '';
      end;
    end;
  str := TrimLeft( str );
end;



(**************************************************************************************************)
(*  GetTypOfToken
(*
(**************************************************************************************************)
function TEasyLINQ<T>.GetTypOfToken( str: String ): TTokenTpye;
var
  s      : String;
  i      : Integer;
  calc   : Boolean;
begin
  Result := ttField;
  if str = '' then Exit;
  if (str[1] = '"') or (str[1] = '''') then Result := ttString;

  calc := False;
  for i := 1 to Length( str ) do begin
    if not CharInSet( str[i], ['0'..'9','.'] ) then Exit;
    end;
  Result := ttConst;
end;



(**************************************************************************************************)
(*  UnquoteStr
(*  remove quotes from string
(**************************************************************************************************)
function TEasyLINQ<T>.UnquoteStr( str: String ): String;
begin
  result := Trim( str );
  if result <> '' then
    if (result[1] = '''') or (result[1] = '"') or (result[1] = '(') then
      result := Copy( result, 2, Length( Result ) - 2 );

end;



(**************************************************************************************************)
(*  GetCMD
(*  parse commands for "where"
(**************************************************************************************************)
function TEasyLINQ<T>.GetCMD( var txt: String; fTypeInfo: TRttiType ): TWhereCMD;
var
  smode      : String;
  str        : String;
  tmp        : String;
  i          : Integer;
  x          : Integer;
  p          : Integer;
  FieldInfo  : TFieldInfo;
begin
  str := TrimLeft( txt );
  tmp := str;
  FillChar( result, SizeOf( result ), 0 );

  (*** expressions in round brackerts makes parsing easier ***)
  if str[1] <> '(' then begin
    if Pos( 'order', LowerCase( str ) ) = 0 then
      raise ELinQException.Create('TEasyLINQ: WHERE requires expressions in brackets (...)');
    Exit;
    end;

  (*** extract command ***)
  str := GetToken( txt );
  txt := TrimLeft( txt );


  tmp := GetToken( str );
  if LowerCase( tmp ) = 'upper' then begin
    result.CharCase := ccToUpper;
    tmp := GetToken( str );
    end;
  if LowerCase( tmp ) = 'lower' then begin
    result.CharCase := ccToLower;
    tmp := GetToken( str );
    end;
  (*** field name in tmp ***)
  Result.Field := tmp;
  FieldInfo := GetFieldInfo( nil, Result.Field );
  if not FieldInfo.Exists then Exit;
  result.TypeKind := FieldInfo.TypeKind;

  p := Pos( 'like', LowerCase( str ) );
  if (p > 0) and (p <= 2) then begin
    result.Mode := wmLike;
    Delete( str, 1, 5 );
    end
  else begin
    (*** scan operator ***)
    for i := 1 to Length( str ) do
      if not CharInSet(str[i], ['<','>','=', ' ']) then begin
        p := i;
        Break;
        end;
    smode := Trim( Copy( str, 1, p - 1 ) );

    if smode = '=' then result.Mode := wmIs;
    if smode = '<' then result.Mode := wmLess;
    if smode = '>' then result.Mode := wmUpper;
    if smode = '<=' then result.Mode := wmIsLess;
    if smode = '>=' then result.Mode := wmIsUpper;
    if smode = '<>' then result.Mode := wmIsNot;
    Delete( str, 1, p - 1 );
    end;
  str := TrimLeft( str );

  tmp := GetToken( str );
  if LowerCase( tmp ) = 'upper' then begin
    result.CharCase := ccToUpper;
    tmp := GetToken( str );
    end;
  if LowerCase( tmp ) = 'lower' then begin
    result.CharCase := ccToLower;
    tmp := GetToken( str );
    end;

  (*** is second parameter a field name? ***)
  Result.Value := tmp;
  case GetTypOfToken( Result.Value ) of
    ttField : begin
                FieldInfo := GetFieldInfo( nil, Result.Value );
                if FieldInfo.Exists then begin
                  Result.Field2 := Result.Value;
                  result.TypeKind2 := FieldInfo.TypeKind;
                  end
                else raise ELinQException.Create('TEasyLINQ: Unknown Field "' + Result.Value + '"');
                end;
    ttString : Result.Value := UnquoteStr( tmp );
    end;

  if txt <> '' then begin
    tmp := txt;
    str := LowerCase( GetToken( tmp ) );
    x := IndexStr( str, ['and','or','xor'] );
    end
  else x := -1;

  case x of
    0 : result.Combine := _AND;
    2 : result.Combine := _XOR;
    else result.Combine := _OR;
    end;
  if x >= 0 then txt := tmp;
end;

{$endregion}

{$region '----> Aggregate Operators'}



(**************************************************************************************************)
(*  Max
(*  Returns the max value
(**************************************************************************************************)
function TEasyLINQ<T>.Max( field: String ): Extended;
var
  list  : TEasyLINQ<T>;
  item  : T;
  value : TValue;
  v     : Extended;
begin
  result := -Infinite;
  list := Execute( 'SELECT ' + field );
  for item in list do begin
    value := GetValue( @item, field );
    if not value.IsEmpty then begin
      v := value.AsExtended;
      if result < v then result := v;
      end;
    end;
  list.Free;
end;



(**************************************************************************************************)
(*  Min
(*  Returns the min value
(**************************************************************************************************)
function TEasyLINQ<T>.Min( field: String ): Extended;
var
  list  : TEasyLINQ<T>;
  item  : T;
  value : TValue;
  v     : Extended;
begin
  result := Infinite;
  list := Execute( 'SELECT ' + field );
  for item in list do begin
    value := GetValue( @item, field );
    if not value.IsEmpty then begin
      v := value.AsExtended;
      if result > v then result := v;
      end;
    end;
  list.Free;
end;



(**************************************************************************************************)
(*  Average
(*  Calculates the average value in a list of values
(**************************************************************************************************)
function TEasyLINQ<T>.Average( field: String ): Extended;
var
  list  : TEasyLINQ<T>;
  item  : T;
  value : TValue;
  v     : Extended;
  c     : Integer;
begin
  list := Execute( 'SELECT ' + field );
  v := 0;
  c := list.Count;
  if c = 0 then Exit;
  for item in list do begin
    value := GetValue( @item, field );
    if not value.IsEmpty then v := v + value.AsExtended;
    end;
  list.Free;
  result := v / c;
end;



(**************************************************************************************************)
(*  Aggregate
(*  Calculates the product of values in a list of values
(**************************************************************************************************)
function TEasyLINQ<T>.Aggregate( field: String ): Extended;
var
  list  : TEasyLINQ<T>;
  item  : T;
  value : TValue;
begin
  list := Execute( 'SELECT ' + field );
  result := 1;
  for item in list do begin
    value := GetValue( @item, field );
    if not value.IsEmpty then result := result * value.AsExtended;
    end;
  list.Free;
end;



(**************************************************************************************************)
(*  Sum
(*  Calculates the sum
(**************************************************************************************************)
function TEasyLINQ<T>.Sum( field: String ): Extended;
var
  list  : TEasyLINQ<T>;
  item  : T;
  value : TValue;
  v     : Extended;
  c     : Integer;
begin
  result := 0;
  list := Execute( 'SELECT ' + field );
  c := list.Count;
  if c = 0 then Exit;
  for item in list do begin
    value := GetValue( @item, field );
    if not value.IsEmpty then result := result + value.AsExtended;
    end;
  list.Free;
end;

{$endregion}

{$region '----> Miscellaneous'}


(**************************************************************************************************)
(*  First
(*  Returns the first object
(**************************************************************************************************)
function TEasyLINQ<T>.First: T;
begin
  if fItems.Count = 0 then result := Default(T)
  else result := fItems[0];
end;



(**************************************************************************************************)
(*  Last
(*  Returns the last object
(**************************************************************************************************)
function TEasyLINQ<T>.Last: T;
begin
  if fItems.Count = 0 then result := Default(T)
  else result := fItems[fItems.Count - 1];
end;



(**************************************************************************************************)
(*  Combine
(*  Adds another TEasyList to the existing one
(**************************************************************************************************)
function TEasyLINQ<T>.Combine( source: TEasyLINQ<T> ): TEasyLINQ<T>;
var
  item  : T;
begin
  for item in source do fItems.Add( item );
  result := self;
end;

{$endregion}

{$region '----> Operations'}


(**************************************************************************************************)
(*  Distinct
(*  Returns a stringlist with the distinct values from the given field
(**************************************************************************************************)
function TEasyLINQ<T>.Distinct( field: String ): TStringList;
var
  list  : TEasyLINQ<T>;
  item  : T;
  value : TValue;
begin
  result := TStringList.Create;
  list := Execute( 'SELECT DISTINCT ' + field );
  for item in list do begin
    value := GetValue( @item, field );
    if not value.IsEmpty then result.Add( value.ToString );
    end;
  list.Free;
end;



(**************************************************************************************************)
(*  Range
(*  Returns the objects within a given range. Does not raise exceptions when out of range.
(**************************************************************************************************)
function TEasyLINQ<T>.Range( fromIndex, toIndex: Integer ): TEasyLINQ<T>;
var
  i : Integer;
begin
  result := TEasyLINQ<T>.Create;
  for i := fromIndex - 1 to toIndex - 1 do begin
    if toIndex >= fItems.Count then Break;
    result.Add( fItems[i] );
    end;
end;



(**************************************************************************************************)
(*  Repeat
(*  Repeats an object
(**************************************************************************************************)
function TEasyLINQ<T>.&Repeat( Index, n: Integer ): TEasyLINQ<T>;
var
  i : Integer;
begin
  result := TEasyLINQ<T>.Create;
  if (index < 0) or (index >= fItems.Count) then
    raise ELinQException.Create('TEasyLINQ: (Repeat) Out of range');
  i := n;
  while i > 0 do begin
    result.Add( fItems[Index] );
    Dec( i );
    end;
end;


(**************************************************************************************************)
(*  Take
(*  Takes the first n objects. Does not raise exceptions when out of range.
(**************************************************************************************************)
function TEasyLINQ<T>.Take( n: Integer ): TEasyLINQ<T>;
var
  i : Integer;
begin
  result := TEasyLINQ<T>.Create;
  if n <= 0 then Exit;
  for i := 0 to n - 1 do begin
    if i >= fItems.Count then Break;
    result.Add( fItems[i] );
    end;
end;


(**************************************************************************************************)
(*  Skip
(*  Skips the first n objects. Does not raise exceptions when out of range.
(**************************************************************************************************)
function TEasyLINQ<T>.Skip( n: Integer ): TEasyLINQ<T>;
var
  i : Integer;
begin
  result := TEasyLINQ<T>.Create;
  if n <= 0 then Exit;
  for i := n to fItems.Count - 1 do begin
    result.Add( fItems[i] );
    end;
end;



(**************************************************************************************************)
(*  Odd
(*
(**************************************************************************************************)
function TEasyLINQ<T>.Odd: TEasyLINQ<T>;
var
  i : Integer;
begin
  result := TEasyLINQ<T>.Create;
  i := 0;
  while i < fItems.Count do begin
    result.Add( fItems[i] );
    Inc( i, 2 );
    end;
end;



(**************************************************************************************************)
(*  Even
(*
(**************************************************************************************************)
function TEasyLINQ<T>.Even: TEasyLINQ<T>;
var
  i : Integer;
begin
  result := TEasyLINQ<T>.Create;
  i := 1;
  while i < fItems.Count do begin
    result.Add( fItems[i] );
    Inc( i, 2 );
    end;
end;




(**************************************************************************************************)
(*  OrderBy
(*
(**************************************************************************************************)
function TEasyLINQ<T>.OrderBy( field: String ): TEasyLINQ<T>;
begin
  result := Execute( 'SELECT ORDER BY ' + field );
end;



(**************************************************************************************************)
(*  Where
(*
(**************************************************************************************************)
function TEasyLINQ<T>.Where( command: String ): TEasyLINQ<T>;
begin
  result := Execute( 'SELECT WHERE ' + command );
end;



(**************************************************************************************************)
(*  Execute
(*
(**************************************************************************************************)
function TEasyLINQ<T>.Execute( command: String): TEasyLINQ<T>;
var
  orderby  : String;
  distinct : String;
  update   : String;
  old      : String;
  start    : Integer;
  stop     : Integer;
  token    : String;
  where    : TList<TWhereCMD>;
  cmd      : TWhereCMD;
  combine  : TCombine;
  item     : T;
  i        : Integer;
  accept   : Boolean;
  topEntries : Integer;
begin
  fSortOrderDesc := False;
  fContext := TRttiContext.Create;
  fTypeInfo := fContext.GetType( System.TypeInfo(T) );
  where := TList<TWhereCMD>.Create;
  try
    topEntries := -1;
    while command <> '' do begin
      token := LowerCase( GetToken( command ) );

      (*** select ***)
      if token = 'select' then Continue;

      (*** update ***)
      if token = 'update' then begin
        if fTypeInfo.TypeKind <> tkClass then
          raise ELinQException.Create('TEasyLINQ: Command "UPDATE" is only supported by classes');
        token := LowerCase( GetToken( command ) );
        if token = 'set' then begin
          command := TrimLeft( command );
          if (command <> '') and (command[1] <> '(') then
            raise ELinQException.Create('TEasyLINQ: ( required');
          update := GetToken( command );
          end;
        end;

      (*** top ***)
      if token = 'top' then begin
        token := GetToken( command );
        topEntries := StrToIntDef( UnquoteStr( token ), -1 );
        Continue;
        end;

      (*** distinct ***)
      if token = 'distinct' then begin
        distinct := GetToken( command );
        Continue;
        end;

      (*** calc ***)
      if token = 'calc' then begin
        if fTypeInfo.TypeKind <> tkClass then
          raise ELinQException.Create('TEasyLINQ: Command "CALC" is only supported by classes');
        token := GetToken( command );
        Calculate( token );
        continue;
        end;

      (*** where ***)
      if token = 'where' then begin
        repeat
           old := Command;
           cmd.Field := '';
           cmd.Value := '';
           cmd := GetCMD( Command, fTypeInfo );
           if (cmd.Field <> '') and (cmd.Value <> '') then where.Add( cmd )
           else command := old;
        until (cmd.Field = '') or (cmd.Value = '') or (Command = '');
        continue;
        end;

      (*** order by ***)
      if token = 'order' then begin
        token := LowerCase( GetToken( command ) );
        if token = 'by' then begin
          orderby := command;
          start := Pos( 'asc', LowerCase( orderby ) );
          if start > 0 then Delete( orderby, start, Length( orderby ) );
          start := Pos( 'desc', LowerCase( orderby ) );
          if start > 0 then begin
            Delete( orderby, start, Length( orderby ) );
            fSortOrderDesc := True;
            end;
          command := '';
          end;
        continue;
        end;

      (*** group by ***)
      if token = 'group' then begin
        token := LowerCase( GetToken( command ) );
        if token = 'by' then begin
          stop := Pos( 'where' , LowerCase( command ) );
          if stop = 0 then stop := Pos( 'order' , LowerCase( command ) );
          if stop = 0 then begin
            distinct := command;
            command := '';
            end
          else begin
            distinct := Trim(Copy( command, 1, stop - 1 ));
            System.Delete( command, 1, stop - 1 );
            end;
          end;
        continue;
        end;
      end;

    (*** Create result Lookup-List ***)
    result := TEasyLINQ<T>.Create( True );

    (*** where ***)
    if where.Count > 0 then begin
      for item in fItems do begin
        accept := False;
        combine := _OR;
        for cmd in where do begin
          case combine of
            _AND : accept := accept and IsValid( item, cmd );
            _OR  : accept := accept or IsValid( item, cmd );
            _XOR : accept := accept xor IsValid( item, cmd );
            end;
          combine := cmd.Combine;
          end;
        if accept then result.Add( item );
        end;
      end
    else
      for item in fItems do result.Add( item );

    (*** distinct same as group ***)
    if distinct <> '' then result.DoDistinct( distinct );

    (*** order by ***)
    if orderby <> '' then begin
      result.fSortOrderDesc := fSortOrderDesc;
      result.ExecOrderBy( orderBy );
      end;

    (*** top ***)
    if (topEntries > 0) and (result.Count > topEntries) then begin
      i := result.Count - topEntries;
      while i > 0 do begin
        Result.Remove( topEntries );
        Dec( i );
        end;
      end;

    (*** update ***)
    if update <> '' then result.ExecUpdate( update );

  finally
    where.Free;
    end;
end;


{$endregion}



end.

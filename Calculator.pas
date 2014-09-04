(**************************************************************************************************)
(*
(*  Copyright (c) 2004-2011 Daniela Sefzig
(*
(*  Description   Calculates an expression from a string
(*  Filename      calculator.pas
(*  Version       v2.0
(*  Date          06.09.2011
(*  Project       Calculator
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
(*  The Original Code is "calculator.pas".
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
(*  - + / * ^ ( ) sin cos tan sqr log cot sec csc
(*
(*  History:
(*      v2.0 | Daniela Sefzig | 6.9.2011
(*         - added callback for unknown commands
(*
(*
(**************************************************************************************************)
unit Calculator;

interface

uses Windows, Classes;


{$i EasyLinq.inc}


type
  TOnCalculatorGetFieldValue = procedure(FieldName: String; var value: Double ) of Object;

  TCalculator = class
  private
    fExpression : String;
    fFinished   : Boolean;
    fValid      : Boolean;
    fResult     : Currency;
    fResultStr  : String;
    fOnCalculatorGetFieldValue : TOnCalculatorGetFieldValue;
    function Calculate(s: string): Double;
  public
    ActiveItem : Pointer;
    procedure Expression( str: String );
    constructor Create;
  published
    property Finished: Boolean read fFinished;
    property Valid: Boolean read fValid;
    property Result: Currency read fResult;
    property ResultStr: String read fResultStr;
    property OnCalculatorGetFieldValue: TOnCalculatorGetFieldValue read fOnCalculatorGetFieldValue write fOnCalculatorGetFieldValue;
  end;



implementation

uses SysUtils, math, StrUtils;


{$region 'TCalculator'}

(**************************************************************************************************)
(*  Create
(*
(**************************************************************************************************)
constructor TCalculator.Create;
begin
  inherited Create;
end;



(**************************************************************************************************)
(*  Expression
(*  Übergibt die Rechenoperation und startet den Thread
(**************************************************************************************************)
procedure TCalculator.Expression( str: String );
begin
  fExpression := str;
  fFinished := False;
  fResult := Calculate( fExpression );
  fResultStr := FloatToStr( Result );
  if fValid then fValid := fResultStr <> fExpression;
  fFinished := True;
end;



(**************************************************************************************************)
(*  Calculate
(*  Berechnen
(**************************************************************************************************)
function TCalculator.Calculate(s: string): Double;

  function EatChar(const aSet: TSysCharSet; var ch: Char): Boolean;
  begin
    Result := ((s <> '') and (CharInSet(s[1], aSet ) ));
    if Result then begin
      ch := s[1];
      s := TrimLeft(Copy(s, 2, MaxInt));
      end;
  end;

  (*** Term ***)
  function Term: Double;

      (*** Rechenfunktionen bzw. Klammern ***)
      function Factor: Double;
      var
        ErrPos  : Integer;
        func    : Integer;
        op      : Char;
        i       : Integer;
        cmd     : String;
      begin
        (*** nachschauen ob variable oder mathefunktion ***)
        for i := 1 to Length( s ) do
          if CharInSet(s[i], ['+', '-', '(', ')', '/','*', '0'..'9' ]) then begin
            cmd := Copy( s, 1, i - 1 );
            Delete( s, 1, i - 1 );
            Break;
            end;

        if cmd <> '' then begin
          if Assigned( fOnCalculatorGetFieldValue ) then fOnCalculatorGetFieldValue( cmd, Result )
          else Result := 0;
          Exit;
          end;

        { TODO : Hier zusätzlich erweiterbare Klasse einbauen (wie schon im Java Gegenstück passiert) }
        func := -1;
        if cmd <> '' then
          func := IndexStr( cmd, ['sin','cos', 'tan', 'sqr', 'log', 'cot', 'sec', 'csc' ] );
        if func < 0 then begin
          if EatChar(['+', '-', '('], op) then
            (*** einfaches Zeichen ***)
            case op of
              '+': Result := Factor;
              '-': Result := -Factor;
              '(': begin
                     Result := Term;
                     if (not EatChar([')'], op)) then fValid := False;
                   end;
            else Result := 0; // calm compiler
            end
          else begin
              Val (s, Result, ErrPos);
              if (ErrPos = 0) then s := ''
              else s := TrimLeft(Copy(s, ErrPos, MaxInt));
            end;
          end
        else begin
          (*** erweiterte Funktionen ***)
          Delete( s, 1, 3 );
          try
            case func of
              0 : Result := Sin( Factor );
              1 : Result := Cos( Factor );
              2 : Result := Tan( Factor );
              3 : Result := Sqr( Factor );
              4 : Result := log2( Factor );
              5 : Result := cot( Factor );
              6 : Result := sec( Factor );
              7 : Result := csc( Factor );
              end;
          except
            fValid := False;
            end;
         end;
      end;

    (*** Summe bilden ***)
    function Summand: Double;
    var
      op: Char;
    begin
      Result := Factor;
      while EatChar(['*', '/', '^'], op) do
        case op of
          '^': Result := Power( Result, Factor );
          '*': Result := Result * Factor;
          '/': try
                 Result := Result / Factor;
               except
                 fValid := False;
                 end;
          end;
    end;

  var
    op: Char;
  begin
    Result := Summand;
    while EatChar(['+', '-'], op) do
      case op of
        '+': Result := Result + Summand;
        '-': Result := Result - Summand;
        end;
  end;

var
  NegSeperator  : Char;
{$ifndef Delphi_2010}
  fs            : TFormatSettings;
{$endif}
begin
  fValid := True;
  if Length( s ) <3 then begin
    fValid := False;
    Exit( 0 );
    end;
{$ifdef Delphi_2010}
  if DecimalSeparator = '.' then NegSeperator := ','
  else NegSeperator := '.';
  s := StringReplace( s, NegSeperator, DecimalSeparator, [rfReplaceAll, rfIgnoreCase] );
{$else}
  fs := TFormatSettings.Create;
  if fs.DecimalSeparator = '.' then NegSeperator := ','
  else NegSeperator := '.';
  s := StringReplace( s, NegSeperator, fs.DecimalSeparator, [rfReplaceAll, rfIgnoreCase] );
{$endif}
  s := LowerCase( Trim(s) );
  Result := Term;
  (*** wenn ungültig dann nix zurückgeben ***)
  if (s <> '') then begin
    fValid := False;
    Result := 0;
    end;
end;



{$endregion}



end.

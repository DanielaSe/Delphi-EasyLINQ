{$if CompilerVersion < 21.0} {$message Fatal 'Unsupported Compiler!'}
{$elseif CompilerVersion < 22.0} {$define DELPHI_2010}
{$elseif CompilerVersion < 23.0} {$define DELPHI_XE}
{$elseif CompilerVersion < 24.0} {$define DELPHI_XE2}
{$else}                          {$define DELPHI_XE3} {$ifend}

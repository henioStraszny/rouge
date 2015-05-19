# -*- coding: utf-8 -*- #

module Rouge
  module Lexers
    class Shell < RegexLexer
      title 'powershell'
      desc 'powershell'

      tag 'powershell'
      aliases 'posh'
      filenames '*.ps1', '*.psm1', '*.psd1'
      mimetypes 'application/x-powershell'

      KEYWORDS = %w(
		if else foreach return function do while until elseif begin for trap data dynamicparam end break throw param continue finally in switch exit filter try process catch
      ).join('|')

      OPERATORS = %w(
        -eq -ne -gt -ge -lt -le -Like -NotLike -Match -NotMatch -Contains -NotContains -In -NotIn -Replace
      ).join('|')

      BUILTINS = %w(
		Add-Content Add-History Add-Member Add-PSSnapin Clear-Content Clear-Item Clear-Item Property Clear-Variable Compare-Object ConvertFrom-SecureString Convert-Path ConvertTo-Html ConvertTo-SecureString Copy-Item Copy-ItemProperty Export-Alias Export-Clixml Export-Console Export-Csv ForEach-Object Format-Custom Format-List Format-Table Format-Wide Get-Acl Get-Alias Get-AuthenticodeSignature Get-ChildItem Get-Command Get-Content Get-Credential Get-Culture Get-Date Get-EventLog Get-ExecutionPolicy Get-Help Get-History Get-Host Get-Item Get-ItemProperty Get-Location Get-Member Get-PfxCertificate Get-Process Get-PSDrive Get-PSProvider Get-PSSnapin Get-Service Get-TraceSource Get-UICulture Get-Unique Get-Variable Get-WmiObject Group-Object Import-Alias Import-Clixml Import-Csv Invoke-Expression Invoke-History Invoke-Item Join-Path Measure-Command Measure-Object Move-Item Move-ItemProperty New-Alias New-Item New-ItemProperty New-Object New-PSDrive New-Service New-TimeSpan New-Variable Out-Default Out-File Out-Host Out-Null Out-Printer Out-String Pop-Location Push-Location Read-Host Remove-Item Remove-ItemProperty Remove-PSDrive Remove-PSSnapin Remove-Variable Rename-Item Rename-ItemProperty Resolve-Path Restart-Service Resume-Service Select-Object Select-String Set-Acl Set-Alias Set-AuthenticodeSignature Set-Content Set-Date Set-ExecutionPolicy Set-Item Set-ItemProperty Set-Location Set-PSDebug Set-Service Set-TraceSource Set-Variable Sort-Object Split-Path Start-Service Start-Sleep Start-Transcript Stop-Process Stop-Service Stop-Transcript Suspend-Service Tee-Object Test-Path Trace-Command Update-FormatData Update-TypeData Where-Object Write-Debug Write-Error Write-Host Write-Output Write-Progress Write-Verbose Write-Warning % ? ac asnp cat cd chdir clc clear clhy cli clp cls clv cnsn compare copy cp cpi cpp curl cvpa dbp del diff dir dnsn ebp echo epal epcsv epsn erase etsn exsn fc fl foreach ft fw gal gbp gc gci gcm gcs gdr ghy gi gjb gl gm gmo gp gps group gsn gsnp gsv gu gv gwmi h history icm iex ihy ii ipal ipcsv ipmo ipsn irm ise iwmi iwr kill lp ls man md measure mi mount move mp mv nal ndr ni nmo npssc nsn nv ogv oh popd ps pushd pwd r rbp rcjb rcsn rd rdr ren ri rjb rm rmdir rmo rni rnp rp rsn rsnp rujb rv rvpa rwmi sajb sal saps sasv sbp sc select set shcm si sl sleep sls sort sp spjb spps spsv start sujb sv swmi tee trcm type wget where wjb write
      ).join('|')

      state :basic do
        #rule %r{<#\b.*?#>\b}m, Comment::Multiline
        #rule /#.*$/, Comment

        rule /\b(#{KEYWORDS})\s*\b/i, Keyword
        rule /\bcase\b/, Keyword, :case

        rule /\b(#{BUILTINS})\s*\b(?!\.)/i, Name::Builtin

        rule /\b(#{OPERATORS})\s*\b/i, Operator
        rule /[\[\]{}()=]/, Operator
        rule /&&|\|\|/, Operator

      end

      state :double_quotes do
        # NB: "abc$" is literally the string abc$.
        # Here we prevent :interp from interpreting $" as a variable.
        rule /(?:\$#?)?"/, Str::Double, :pop!
        mixin :interp
        rule /[^"`\\$]+/, Str::Double
      end

      state :single_quotes do
        rule /'/, Str::Single, :pop!
        rule /[^']+/, Str::Single
      end

      state :data do
        rule /\s+/, Text
        rule /\\./, Str::Escape
        rule /\$?"/, Str::Double, :double_quotes

        # single quotes are much easier than double quotes - we can
        # literally just scan until the next single quote.
        # POSIX: Enclosing characters in single-quotes ( '' )
        # shall preserve the literal value of each character within the
        # single-quotes. A single-quote cannot occur within single-quotes.
        rule /$?'/, Str::Single, :single_quotes

        rule /\*/, Keyword

        rule /;/, Text
        rule /[^=\*\s{}()$"'`\\<]+/, Text
        rule /\d+(?= |\Z)/, Num
        rule /</, Text
        mixin :interp
      end

      state :curly do
        rule /}/, Keyword, :pop!
        rule /:-/, Keyword
        rule /[a-zA-Z0-9_]+/, Name::Variable
        rule /[^}:"`'$]+/, Punctuation
        mixin :root
      end

      state :paren do
        rule /\)/, Keyword, :pop!
        mixin :root
      end

      state :math do
        rule /\)\)/, Keyword, :pop!
        rule %r{[-+*/%^|&]|\*\*|\|\|}, Operator
        rule /\d+/, Num
        mixin :root
      end

      state :case do
        rule /\besac\b/, Keyword, :pop!
        rule /\|/, Punctuation
        rule /\)/, Punctuation, :case_stanza
        mixin :root
      end

      state :case_stanza do
        rule /;;/, Punctuation, :pop!
        mixin :root
      end

      state :backticks do
        rule /`/, Str::Backtick, :pop!
        mixin :root
      end

      state :interp do
        rule /\\$/, Str::Escape # line continuation
        rule /\\./, Str::Escape
        rule /\$\(\(/, Keyword, :math
        rule /\$\(/, Keyword, :paren
        rule /\${#?/, Keyword, :curly
        rule /`/, Str::Backtick, :backticks
        rule /\$#?(\w+|.)/, Name::Variable
      end

      state :root do
        mixin :basic
        mixin :data
      end
    end
  end
end

<#
.SYNOPSIS
    ArrivalLocationDetail C# FormScript生成の統合スクリプト

.DESCRIPTION
    Markdown → YAML → C# の一連の生成フローを実行します
    以下の処理を統合的に実行します:
    1. Markdownファイルから業務仕様を読み取り
    2. YAML定義ファイルを生成
    3. YAMLからC#コードを生成
    4. 既存のC#ファイルと比較

.PARAMETER Mode
    実行モード: 'full' (全処理), 'md2yaml' (Markdown→YAML), 'yaml2cs' (YAML→C#), 'compare' (比較のみ)

.PARAMETER WorkDir
    作業ディレクトリ（デフォルト: スクリプトと同じディレクトリ）

.EXAMPLE
    .\Master-Generate.ps1 -Mode full
    
.EXAMPLE
    .\Master-Generate.ps1 -Mode yaml2cs -WorkDir "C:\work\project"
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('full', 'md2yaml', 'yaml2cs', 'compare', 'validate')]
    [string]$Mode = 'full',
    
    [Parameter(Mandatory=$false)]
    [string]$WorkDir = $PSScriptRoot
)

# カラー出力関数
function Write-Step {
    param([string]$Message)
    Write-Host "`n$('='*80)" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "$('='*80)`n" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Yellow
}

function Write-Error2 {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# ファイルパスの設定
$mdFile = Join-Path $WorkDir "ArrivalLocationDetail.md"
$yamlFile = Join-Path $WorkDir "ArrivalLocationDetail.YAML"
$csOriginalFile = Join-Path $WorkDir "ArrivalLocationDetail.cs"
$csGeneratedFile = Join-Path $WorkDir "Generated_ArrivalLocationDetail.cs"
$commonTailFile = Join-Path $WorkDir "CommonTail.cs.template"

# スクリプトファイル
$md2yamlScript = Join-Path $WorkDir "Generate-YamlFromMarkdown.ps1"
$yaml2csScript = Join-Path $WorkDir "Generate-CSharpFromYaml.ps1"

# バナー表示
Clear-Host
Write-Host @"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   ArrivalLocationDetail C# FormScript Generator                   ║
║   YAML-Based Code Generation System                               ║
║                                                                   ║
║   Version: 1.0.0                                                  ║
║   Generated: $(Get-Date -Format "yyyy/MM/dd HH:mm:ss")                            ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`n作業ディレクトリ: $WorkDir" -ForegroundColor Gray
Write-Host "実行モード: $Mode`n" -ForegroundColor Gray

# ファイル存在確認
$filesToCheck = @{
    "Markdownファイル" = $mdFile
    "元のC#ファイル" = $csOriginalFile
    "共通処理テンプレート" = $commonTailFile
    "MD→YAMLスクリプト" = $md2yamlScript
    "YAML→C#スクリプト" = $yaml2csScript
}

Write-Step "ファイル存在確認"
$missingFiles = @()
foreach ($item in $filesToCheck.GetEnumerator()) {
    if (Test-Path $item.Value) {
        Write-Success "$($item.Key): $($item.Value)"
    } else {
        Write-Error2 "$($item.Key)が見つかりません: $($item.Value)"
        $missingFiles += $item.Key
    }
}

if ($missingFiles.Count -gt 0 -and $Mode -ne 'yaml2cs') {
    Write-Host "`n以下のファイルが不足しています:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

# ========================================
# Step 1: Markdown → YAML
# ========================================
if ($Mode -eq 'full' -or $Mode -eq 'md2yaml') {
    Write-Step "Step 1: Markdown → YAML 変換"
    
    if (Test-Path $yamlFile) {
        Write-Info "既存のYAMLファイルが存在します: $yamlFile"
        $overwrite = Read-Host "上書きしますか? (Y/N)"
        if ($overwrite -ne 'Y' -and $overwrite -ne 'y') {
            Write-Info "YAML生成をスキップします"
        } else {
            & $md2yamlScript -MarkdownPath $mdFile -OutputPath $yamlFile -CSharpReferencePath $csOriginalFile
        }
    } else {
        & $md2yamlScript -MarkdownPath $mdFile -OutputPath $yamlFile -CSharpReferencePath $csOriginalFile
    }
    
    if ($LASTEXITCODE -ne 0 -and -not (Test-Path $yamlFile)) {
        Write-Error2 "YAML生成に失敗しました"
        exit 1
    }
    
    Write-Success "YAMLファイル生成完了"
    
    # YAML検証
    Write-Info "YAMLファイルの構文を検証しています..."
    try {
        Import-Module powershell-yaml -ErrorAction Stop
        $yamlContent = Get-Content -Path $yamlFile -Raw
        $null = ConvertFrom-Yaml -Yaml $yamlContent
        Write-Success "YAML構文チェック: OK"
    } catch {
        Write-Error2 "YAML構文エラー: $($_.Exception.Message)"
        exit 1
    }
}

# ========================================
# Step 2: YAML → C#
# ========================================
if ($Mode -eq 'full' -or $Mode -eq 'yaml2cs') {
    Write-Step "Step 2: YAML → C# 変換"
    
    if (-not (Test-Path $yamlFile)) {
        Write-Error2 "YAMLファイルが見つかりません: $yamlFile"
        Write-Info "先に 'md2yaml' モードを実行してください"
        exit 1
    }
    
    if (Test-Path $csGeneratedFile) {
        Write-Info "既存の生成済みC#ファイルを削除します"
        Remove-Item $csGeneratedFile -Force
    }
    
    & $yaml2csScript -YamlPath $yamlFile -OutputPath $csGeneratedFile -CommonTailPath $commonTailFile
    
    if (-not (Test-Path $csGeneratedFile)) {
        Write-Error2 "C#コード生成に失敗しました"
        exit 1
    }
    
    Write-Success "C#コード生成完了"
    
    # 生成されたファイルの統計
    $csLines = (Get-Content $csGeneratedFile).Count
    $csSize = (Get-Item $csGeneratedFile).Length
    Write-Info "生成されたC#ファイル:"
    Write-Host "  - 行数: $csLines 行" -ForegroundColor White
    Write-Host "  - サイズ: $([math]::Round($csSize/1KB, 2)) KB" -ForegroundColor White
}

# ========================================
# Step 3: 比較とバリデーション
# ========================================
if ($Mode -eq 'full' -or $Mode -eq 'compare') {
    Write-Step "Step 3: コード比較とバリデーション"
    
    if (-not (Test-Path $csGeneratedFile)) {
        Write-Error2 "生成されたC#ファイルが見つかりません"
        exit 1
    }
    
    if (Test-Path $csOriginalFile) {
        Write-Info "元のファイルと生成されたファイルを比較しています..."
        
        $originalLines = Get-Content $csOriginalFile
        $generatedLines = Get-Content $csGeneratedFile
        
        Write-Host "`n比較結果:" -ForegroundColor Yellow
        Write-Host "  - 元のファイル: $($originalLines.Count) 行" -ForegroundColor White
        Write-Host "  - 生成ファイル: $($generatedLines.Count) 行" -ForegroundColor White
        Write-Host "  - 差分: $([Math]::Abs($originalLines.Count - $generatedLines.Count)) 行" -ForegroundColor White
        
        # 簡易差分チェック
        $diffCount = 0
        $maxLines = [Math]::Max($originalLines.Count, $generatedLines.Count)
        
        for ($i = 0; $i -lt [Math]::Min($originalLines.Count, $generatedLines.Count); $i++) {
            if ($originalLines[$i].Trim() -ne $generatedLines[$i].Trim()) {
                $diffCount++
            }
        }
        
        Write-Host "  - 異なる行数: $diffCount 行" -ForegroundColor White
        
        if ($diffCount -eq 0 -and $originalLines.Count -eq $generatedLines.Count) {
            Write-Success "ファイルは完全に一致しています!"
        } elseif ($diffCount -lt 10) {
            Write-Info "わずかな差異があります。手動で確認してください。"
        } else {
            Write-Info "大きな差異があります。詳細な比較には git diff や VS Code の比較機能を使用してください。"
        }
        
        # VS Codeで比較を開く（オプション）
        $openCompare = Read-Host "`nVS Codeで比較表示しますか? (Y/N)"
        if ($openCompare -eq 'Y' -or $openCompare -eq 'y') {
            code --diff $csOriginalFile $csGeneratedFile
            Write-Success "VS Codeで比較表示を開きました"
        }
    } else {
        Write-Info "元のC#ファイルが存在しないため、比較をスキップします"
    }
}

# ========================================
# Step 4: 構文検証（オプション）
# ========================================
if ($Mode -eq 'validate') {
    Write-Step "Step 4: C# 構文検証"
    
    if (-not (Test-Path $csGeneratedFile)) {
        Write-Error2 "検証するC#ファイルが見つかりません"
        exit 1
    }
    
    Write-Info "C#構文の基本検証を実行しています..."
    
    $csContent = Get-Content $csGeneratedFile -Raw
    
    # 基本的な構文チェック
    $checks = @{
        "名前空間宣言" = ($csContent -match "namespace\s+\w+")
        "クラス宣言" = ($csContent -match "public\s+class\s+\w+\s*:\s*FormScript")
        "using文" = ($csContent -match "using\s+System;")
        "参照設定" = ($csContent -match "//<ref>.*\.dll</ref>")
        "メソッド定義" = ($csContent -match "public\s+void\s+\w+\s*\(")
        "波括弧の対応" = (($csContent -split '\{').Count -eq ($csContent -split '\}').Count)
    }
    
    Write-Host "`n検証結果:" -ForegroundColor Yellow
    $allPassed = $true
    foreach ($check in $checks.GetEnumerator()) {
        if ($check.Value) {
            Write-Host "  ✓ $($check.Key)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $($check.Key)" -ForegroundColor Red
            $allPassed = $false
        }
    }
    
    if ($allPassed) {
        Write-Success "`nすべての基本検証に合格しました!"
        Write-Info "完全な検証には、実際のビルド環境でのコンパイルを推奨します"
    } else {
        Write-Error2 "`n一部の検証に失敗しました。生成されたコードを確認してください。"
    }
}

# ========================================
# 完了メッセージ
# ========================================
Write-Step "処理完了"

Write-Host @"

📋 生成されたファイル:
   - YAML定義: $yamlFile
   - C#コード:  $csGeneratedFile

📝 次のステップ:
   1. 生成されたYAMLファイルを確認・編集
   2. 必要に応じて再生成: .\Master-Generate.ps1 -Mode yaml2cs
   3. VS Codeで比較: code --diff $csOriginalFile $csGeneratedFile
   4. 実際のビルド環境でコンパイルテスト

🔧 その他のコマンド:
   - Markdown→YAML のみ: .\Master-Generate.ps1 -Mode md2yaml
   - YAML→C# のみ:      .\Master-Generate.ps1 -Mode yaml2cs
   - 比較のみ:          .\Master-Generate.ps1 -Mode compare
   - 検証のみ:          .\Master-Generate.ps1 -Mode validate

"@ -ForegroundColor White

Write-Success "すべての処理が完了しました!`n"

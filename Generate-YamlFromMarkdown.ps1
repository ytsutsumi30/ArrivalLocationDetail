<#
.SYNOPSIS
    MarkdownファイルからYAML定義ファイルを生成します

.DESCRIPTION
    ArrivalLocationDetail.mdファイルを解析し、
    C#コード生成用のYAML定義ファイルを生成します

.PARAMETER MarkdownPath
    入力Markdownファイルのパス

.PARAMETER OutputPath
    出力YAMLファイルのパス

.PARAMETER CSharpReferencePath
    参照用の既存C#ファイルパス（オプション）

.EXAMPLE
    .\Generate-YamlFromMarkdown.ps1 -MarkdownPath "ArrivalLocationDetail.md" -CSharpReferencePath "ArrivalLocationDetail.cs"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$MarkdownPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory=$false)]
    [string]$CSharpReferencePath
)

# PowerShell-Yamlモジュールのインストール確認
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "powershell-yamlモジュールをインストールしています..." -ForegroundColor Yellow
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}

Import-Module powershell-yaml

# 出力パスが指定されていない場合
if (-not $OutputPath) {
    $basePath = Split-Path $MarkdownPath -Parent
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($MarkdownPath)
    $OutputPath = Join-Path $basePath "$fileName.YAML"
}

Write-Host "Markdownファイルを読み込んでいます: $MarkdownPath" -ForegroundColor Cyan
$mdContent = Get-Content -Path $MarkdownPath -Raw -Encoding UTF8

# C#ファイルの参照
$csContent = ""
if ($CSharpReferencePath -and (Test-Path $CSharpReferencePath)) {
    Write-Host "参照用C#ファイルを読み込んでいます: $CSharpReferencePath" -ForegroundColor Cyan
    $csContent = Get-Content -Path $CSharpReferencePath -Raw -Encoding UTF8
}

# Markdownから情報を抽出する関数
function Extract-Section {
    param(
        [string]$Content,
        [string]$HeaderPattern
    )
    
    if ($Content -match "(?s)$HeaderPattern\s*\n(.+?)(?=\n##|\z)") {
        return $matches[1].Trim()
    }
    return ""
}

# テーブルからデータを抽出する関数
function Extract-TableData {
    param(
        [string]$TableText
    )
    
    $lines = $TableText -split "`n" | Where-Object { $_.Trim() -and $_ -notmatch "^\|[-:\s|]+\|$" }
    $result = @()
    
    $headers = @()
    $isFirst = $true
    
    foreach ($line in $lines) {
        if ($line -match "^\|(.+)\|$") {
            $cells = $matches[1] -split "\|" | ForEach-Object { $_.Trim() }
            
            if ($isFirst) {
                $headers = $cells
                $isFirst = $false
            }
            else {
                $row = @{}
                for ($i = 0; $i -lt [Math]::Min($headers.Count, $cells.Count); $i++) {
                    $row[$headers[$i]] = $cells[$i]
                }
                $result += $row
            }
        }
    }
    
    return $result
}

# C#コードからクラス定義を抽出する関数
function Extract-CSharpClass {
    param(
        [string]$Content,
        [string]$ClassName
    )
    
    $pattern = "(?s)public class $ClassName\s*\{(.+?)\n\s*\}"
    if ($Content -match $pattern) {
        return $matches[1]
    }
    return ""
}

# C#プロパティを解析する関数
function Parse-CSharpProperties {
    param(
        [string]$ClassContent
    )
    
    $properties = @()
    $lines = $ClassContent -split "`n"
    
    $currentComment = ""
    foreach ($line in $lines) {
        $line = $line.Trim()
        
        # コメント行
        if ($line -match "^//\s*(.+)$") {
            $currentComment = $matches[1]
        }
        # JsonPropertyアトリビュート
        elseif ($line -match '\[JsonProperty\("([^"]+)"\)\]') {
            $jsonProp = $matches[1]
            $nextLineIndex = $lines.IndexOf($line) + 1
            if ($nextLineIndex -lt $lines.Count) {
                $nextLine = $lines[$nextLineIndex].Trim()
                if ($nextLine -match 'public\s+(\S+)\s+(\w+)\s*\{') {
                    $properties += @{
                        name = $matches[2]
                        type = $matches[1]
                        json_property = $jsonProp
                        description = $currentComment
                    }
                    $currentComment = ""
                }
            }
        }
    }
    
    return $properties
}

# YAML構造の構築
Write-Host "YAML構造を構築しています..." -ForegroundColor Cyan

$yamlData = [ordered]@{
    metadata = [ordered]@{
        name = "ArrivalLocationDetail"
        description = "納入場所詳細管理FormScript"
        namespace = "Mongoose.FormScripts"
        version = "1.0.0"
        generated_from = "ArrivalLocationDetail.md"
    }
    
    references = @(
        "Newtonsoft.Json.dll"
    )
    
    usings = @(
        "System"
        "Mongoose.IDO.Protocol"
        "Mongoose.Scripting"
        "Mongoose.Core.Common"
        "Mongoose.Core.DataAccess"
        "System.Collections.Generic"
        "System.IO"
        "System.Linq"
        "System.Net"
        "System.Text"
        "System.Web"
        "Newtonsoft.Json"
    )
    
    global_variables = @()
    data_classes = @()
    business_methods = @()
    common_classes = @()
    common_methods = @()
}

# Markdownからグローバル変数の抽出
$globalVarsSection = Extract-Section -Content $mdContent -HeaderPattern "### 12\.3 業務固有設定値"
if ($globalVarsSection) {
    Write-Host "グローバル変数を抽出しています..." -ForegroundColor Yellow
    
    # デフォルトのグローバル変数を追加
    $yamlData.global_variables = @(
        [ordered]@{
            name = "gIDOName"
            type = "string"
            value = "ue_ADV_SLCoitems"
            description = "ターゲットIDO名"
        }
        [ordered]@{
            name = "gSSO"
            type = "string"
            value = "1"
            description = "SSOの使用、基本は1　1：はい　0：いいえ"
        }
        [ordered]@{
            name = "gServerId"
            type = "string"
            value = "0"
            description = "APIサーバのID、詳しくはAPIサーバ関連"
        }
        [ordered]@{
            name = "gSuiteContext"
            type = "string"
            value = "CSI"
            description = "APIスイートのコンテキスト、同上"
        }
        [ordered]@{
            name = "gContentType"
            type = "string"
            value = "application/json"
            description = "返り値のタイプ、基本設定不要もしくは`"application/json`""
        }
        [ordered]@{
            name = "gTimeout"
            type = "string"
            value = "10000"
            description = "タイムアウト設定"
        }
        [ordered]@{
            name = "gSiteName"
            type = "string"
            value = "Q72Q74BY8XUT3SKY_TRN_AJP"
            description = "ターゲットIDOが存在するサイト名"
        }
    )
}

# C#ファイルからクラス定義を抽出
if ($csContent) {
    Write-Host "C#ファイルからクラス定義を抽出しています..." -ForegroundColor Yellow
    
    # cItemクラスの抽出
    $cItemClass = Extract-CSharpClass -Content $csContent -ClassName "cItem"
    if ($cItemClass) {
        $cItemProps = Parse-CSharpProperties -ClassContent $cItemClass
        
        $yamlData.data_classes += [ordered]@{
            name = "cItem"
            description = "取得データ、更新データ作成のクラス"
            properties = $cItemProps
        }
    }
    
    # WebJSONObjectクラスの抽出
    $webJsonClass = Extract-CSharpClass -Content $csContent -ClassName "WebJSONObject"
    if ($webJsonClass) {
        $webJsonProps = Parse-CSharpProperties -ClassContent $webJsonClass
        
        $yamlData.data_classes += [ordered]@{
            name = "WebJSONObject"
            description = "web対応JSON整形用クラス"
            properties = $webJsonProps
        }
    }
    
    # 共通クラスの抽出
    $commonClassNames = @("getJSONObject", "Property", "Change", "UpdateJSONObject")
    foreach ($className in $commonClassNames) {
        $classContent = Extract-CSharpClass -Content $csContent -ClassName $className
        if ($classContent) {
            $props = Parse-CSharpProperties -ClassContent $classContent
            
            $description = switch ($className) {
                "getJSONObject" { "JSONからデータ取得用のクラス" }
                "Property" { "一番内側の Properties 配列の要素を表すクラス" }
                "Change" { "Changes 配列の要素を表すクラス" }
                "UpdateJSONObject" { "JSON全体のルートオブジェクトを表すクラス" }
            }
            
            $yamlData.common_classes += [ordered]@{
                name = $className
                description = $description
                properties = $props
            }
        }
    }
}

# 業務メソッドの定義
Write-Host "業務メソッドを定義しています..." -ForegroundColor Yellow

$yamlData.business_methods = @(
    [ordered]@{
        name = "callAPI"
        access = "public"
        return_type = "void"
        description = "APIを呼び出してデータ取得・グリッド表示を行う"
        parameters = @(
            [ordered]@{
                name = "mode"
                type = "int"
                description = "操作モード（0:取得, 1:挿入, 2:更新, 4:削除）"
            }
        )
        properties_get = @(
            [ordered]@{ name = "Item"; modified = $true }
            [ordered]@{ name = "Description"; modified = $true }
            [ordered]@{ name = "QtyOrderedConv"; modified = $true }
            [ordered]@{ name = "QtyShipped"; modified = $true }
            [ordered]@{ name = "CoNum"; modified = $false }
            [ordered]@{ name = "ue_Uf_update_time_from_mongoose"; modified = $true }
            [ordered]@{ name = "ue_Uf_updator_from_mongoose"; modified = $true }
            [ordered]@{ name = "RecordDate"; modified = $true }
            [ordered]@{ name = "RowPointer"; modified = $true }
            [ordered]@{ name = "_ItemId"; modified = $true }
            [ordered]@{ name = "CoLine"; modified = $false }
            [ordered]@{ name = "CoRelease"; modified = $false }
        )
        properties_update = @(
            [ordered]@{ name = "ue_Uf_update_time_from_mongoose"; value_source = "timestamp"; modified = $true }
            [ordered]@{ name = "ue_Uf_updator_from_mongoose"; value_source = "variable:User"; modified = $true }
            [ordered]@{ name = "CoNum"; value_source = "variable:selectCoNum"; modified = $false }
            [ordered]@{ name = "CoLine"; value_source = "variable:selectCoLine"; modified = $false }
            [ordered]@{ name = "CoRelease"; value_source = "variable:selectCoRelease"; modified = $false }
            [ordered]@{ name = "RecordDate"; value_source = "variable:selectRecordDate"; modified = $true; mode_exclude = @(1) }
            [ordered]@{ name = "RowPointer"; value_source = "variable:selectRowPointer"; modified = $true; mode_exclude = @(1) }
            [ordered]@{ name = "_ItemId"; value_source = "variable:selectItemId"; modified = $true; mode_exclude = @(1) }
        )
    }
    [ordered]@{
        name = "GenerateFilter"
        access = "private"
        return_type = "string"
        description = "フィルター文字列を自動生成する"
        filter_conditions = @(
            [ordered]@{ variable = "gCoNum"; field = "CoNum" }
            [ordered]@{ variable = "gStat"; field = "Stat" }
        )
    }
    [ordered]@{
        name = "GenerateWebSetJson"
        access = "private"
        return_type = "string"
        description = "web用データをJSON文字列を生成"
        parameters = @(
            [ordered]@{
                name = "resultList"
                type = "List<cItem>"
                description = "整形結果リスト"
            }
        )
        web_json_mapping = @(
            [ordered]@{ target = "DeliveryLocation"; source = "variable:gAdr0Name" }
            [ordered]@{ target = "ShipDate"; source = "variable:gProjectedDate" }
            [ordered]@{ target = "ShipLocation"; source = "variable:gWhse" }
            [ordered]@{ target = "DeliveryStatus"; source = "variable:gStat" }
            [ordered]@{ target = "Items"; source = "parameter:resultList" }
        )
    }
    [ordered]@{
        name = "setParameterFormRun"
        access = "public"
        return_type = "void"
        description = "画面遷移時の変数設定"
        is_placeholder = $true
    }
)

# 共通メソッドの定義
$yamlData.common_methods = @(
    [ordered]@{
        name = "getData"
        access = "private"
        return_type = "string"
        description = "データをアップデート・取得する"
        is_common = $true
        source = "common_tail"
    }
    [ordered]@{
        name = "GenerateChangeSetJson"
        access = "private"
        return_type = "string"
        description = "Update用JSON文字列を自動生成する"
        is_common = $true
        source = "common_tail"
    }
)

# YAMLファイルへの書き込み
Write-Host "YAMLファイルを生成しています..." -ForegroundColor Cyan

$yamlText = ConvertTo-Yaml -Data $yamlData -Options @{ }
$yamlText | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "`n✅ YAML定義ファイルの生成が完了しました!" -ForegroundColor Green
Write-Host "出力ファイル: $OutputPath" -ForegroundColor Cyan
Write-Host "`n生成されたYAMLの統計:" -ForegroundColor Yellow
Write-Host "  - グローバル変数: $($yamlData.global_variables.Count)" -ForegroundColor White
Write-Host "  - データクラス: $($yamlData.data_classes.Count)" -ForegroundColor White
Write-Host "  - 業務メソッド: $($yamlData.business_methods.Count)" -ForegroundColor White
Write-Host "  - 共通クラス: $($yamlData.common_classes.Count)" -ForegroundColor White
Write-Host "  - 共通メソッド: $($yamlData.common_methods.Count)" -ForegroundColor White

Write-Host "`n次のステップ:" -ForegroundColor Yellow
Write-Host "  1. 生成されたYAMLファイルを確認・編集" -ForegroundColor White
Write-Host "  2. Generate-CSharpFromYaml.ps1でC#コードを生成" -ForegroundColor White
Write-Host "     例: .\Generate-CSharpFromYaml.ps1 -YamlPath '$OutputPath'" -ForegroundColor Gray

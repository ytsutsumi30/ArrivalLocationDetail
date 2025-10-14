<#
.SYNOPSIS
    YAMLファイルからC# FormScriptコードを生成します

.DESCRIPTION
    ArrivalLocationDetail.YAMLファイルを読み込み、
    業務固有処理（178行目まで）と共通処理（178行目以降）を組み合わせて
    完全なC#コードを生成します

.PARAMETER YamlPath
    入力YAMLファイルのパス

.PARAMETER OutputPath
    出力C#ファイルのパス

.PARAMETER CommonTailPath
    共通処理テンプレートファイルのパス（オプション）

.EXAMPLE
    .\Generate-CSharpFromYaml.ps1 -YamlPath "ArrivalLocationDetail.YAML" -OutputPath "Generated_ArrivalLocationDetail.cs"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$YamlPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory=$false)]
    [string]$CommonTailPath
)

# PowerShell-Yamlモジュールのインストール確認
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "powershell-yamlモジュールをインストールしています..." -ForegroundColor Yellow
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}

Import-Module powershell-yaml

# YAMLファイルの読み込み
Write-Host "YAMLファイルを読み込んでいます: $YamlPath" -ForegroundColor Cyan
$yamlContent = Get-Content -Path $YamlPath -Raw -Encoding UTF8
$config = ConvertFrom-Yaml -Yaml $yamlContent

# 出力パスが指定されていない場合
if (-not $OutputPath) {
    $basePath = Split-Path $YamlPath -Parent
    if (-not $basePath) {
        $basePath = Get-Location
    }
    $fileName = "Generated_$($config.metadata.name).cs"
    $OutputPath = Join-Path $basePath $fileName
}

# 共通処理テンプレートの読み込み
$commonTailContent = ""
if ($CommonTailPath -and (Test-Path $CommonTailPath)) {
    $commonTailContent = Get-Content -Path $CommonTailPath -Raw -Encoding UTF8
}

# C#コードの生成開始
$sb = [System.Text.StringBuilder]::new()

# ========================================
# ヘッダー部分
# ========================================

# 参照設定
foreach ($ref in $config.references) {
    [void]$sb.AppendLine("//<ref>$ref</ref>")
}

# using文
foreach ($using in $config.usings) {
    [void]$sb.AppendLine("using $using;")
}

[void]$sb.AppendLine()
[void]$sb.AppendLine("namespace $($config.metadata.namespace)")
[void]$sb.AppendLine("{")

# クラス宣言
[void]$sb.AppendLine("   public class $($config.metadata.name) : FormScript")
[void]$sb.AppendLine("   {")

# ========================================
# グローバル変数
# ========================================
[void]$sb.AppendLine("      /// <summary>")
[void]$sb.AppendLine("      /// グローバル変数")
[void]$sb.AppendLine("      /// </summary>")

foreach ($var in $config.global_variables) {
    [void]$sb.AppendLine("      $($var.type) $($var.name) = `"$($var.value)`";        // $($var.description)")
}

[void]$sb.AppendLine()

# ========================================
# データクラス（業務固有）
# ========================================
foreach ($dataClass in $config.data_classes) {
    [void]$sb.AppendLine("      /// <summary>")
    [void]$sb.AppendLine("      /// $($dataClass.description)")
    [void]$sb.AppendLine("      /// </summary>")
    [void]$sb.AppendLine("      public class $($dataClass.name)")
    [void]$sb.AppendLine("      {")
    
    foreach ($prop in $dataClass.properties) {
        if ($prop.description) {
            [void]$sb.AppendLine("         // $($prop.description)")
        }
        [void]$sb.AppendLine("         [JsonProperty(`"$($prop.json_property)`")]")
        [void]$sb.AppendLine("         public $($prop.type) $($prop.name) { get; set; }")
        [void]$sb.AppendLine()
    }
    
    [void]$sb.AppendLine("      }")
    [void]$sb.AppendLine()
}

# ========================================
# 業務固有メソッド: callAPI
# ========================================
$callApiMethod = $config.business_methods | Where-Object { $_.name -eq "callAPI" }
if ($callApiMethod) {
    [void]$sb.AppendLine("      /// <summary>")
    [void]$sb.AppendLine("      /// $($callApiMethod.description)")
    [void]$sb.AppendLine("      /// </summary>")
    
    foreach ($param in $callApiMethod.parameters) {
        [void]$sb.AppendLine("      /// <param name=`"$($param.name)`">$($param.description)</param>")
    }
    
    $paramStr = ($callApiMethod.parameters | ForEach-Object { "$($_.type) $($_.name)" }) -join ", "
    [void]$sb.AppendLine("      $($callApiMethod.access) $($callApiMethod.return_type) $($callApiMethod.name)($paramStr){")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("         List<Property> propertiesList = new List<Property>();")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("         //使用するプロパティのデータリストを作成")
    [void]$sb.AppendLine("         if(mode == 0){")
    
    # 取得モードのプロパティリスト
    foreach ($prop in $callApiMethod.properties_get) {
        $modifiedStr = if ($prop.modified) { "true" } else { "false" }
        [void]$sb.AppendLine("            propertiesList.Add(new Property { Name = `"$($prop.name)`", Value = `"`", Modified = $modifiedStr });")
    }
    
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("         }")
    [void]$sb.AppendLine("         //データ更新用、get時不要")
    [void]$sb.AppendLine("         else{")
    [void]$sb.AppendLine("            // 時間設定")
    [void]$sb.AppendLine("            TimeZoneInfo jstZone = TimeZoneInfo.FindSystemTimeZoneById(`"Tokyo Standard Time`");")
    [void]$sb.AppendLine("            DateTime utcNow = DateTime.UtcNow;")
    [void]$sb.AppendLine("            DateTime jstNow = TimeZoneInfo.ConvertTimeFromUtc(utcNow, jstZone);")
    [void]$sb.AppendLine()
    
    # 更新モードのプロパティリスト
    foreach ($prop in $callApiMethod.properties_update) {
        $value = ""
        $modifiedStr = if ($prop.modified) { "true" } else { "false" }
        $modifiedParam = if ($prop.modified_mode) { "(mode==1?true:false)" } else { $modifiedStr }
        
        if ($prop.value_source -eq "timestamp") {
            $value = "jstNow.ToString()"
        }
        elseif ($prop.value_source -match "^variable:(.+)$") {
            $varName = $matches[1]
            $value = "ThisForm.Variables(`"$varName`").Value"
        }
        
        # mode_excludeがある場合
        if ($prop.mode_exclude) {
            $excludeCondition = "mode != $($prop.mode_exclude[0])"
            [void]$sb.AppendLine("            //データ特定用、insert時は不要")
            [void]$sb.AppendLine("            if($excludeCondition){")
            [void]$sb.AppendLine("               propertiesList.Add(new Property { Name = `"$($prop.name)`", Value = $value, Modified = $modifiedParam });")
            if ($prop -eq ($callApiMethod.properties_update | Where-Object { $_.mode_exclude } | Select-Object -Last 1)) {
                [void]$sb.AppendLine("            }        ")
            }
        }
        else {
            [void]$sb.AppendLine("            propertiesList.Add(new Property { Name = `"$($prop.name)`", Value = $value, Modified = $modifiedParam });")
        }
    }
    
    [void]$sb.AppendLine("         }")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("         //データを取得")
    [void]$sb.AppendLine("         string JSONResponse = getData(mode,gIDOName,propertiesList);")
    [void]$sb.AppendLine("         // webに移行、grid更新する必要がなくなった")
    [void]$sb.AppendLine("         if(mode != 0)return;")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("         //取得した結果はJSONなので、bodyを処理しデータを取得")
    [void]$sb.AppendLine("         List<cItem> itemsList = JsonConvert.DeserializeObject<getJSONObject>(JSONResponse).Items;")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("         //処理結果を変数に格納")
    [void]$sb.AppendLine("         ThisForm.Variables(`"vJSONResult`").Value = GenerateWebSetJson(itemsList);")
    [void]$sb.AppendLine("      }")
    [void]$sb.AppendLine()
}

# ========================================
# 業務固有メソッド: GenerateFilter
# ========================================
$filterMethod = $config.business_methods | Where-Object { $_.name -eq "GenerateFilter" }
if ($filterMethod) {
    [void]$sb.AppendLine("      /// <summary>")
    [void]$sb.AppendLine("      /// $($filterMethod.description)")
    [void]$sb.AppendLine("      /// </summary>")
    [void]$sb.AppendLine("      /// <returns>フィルター文字列</returns>  ")
    [void]$sb.AppendLine("      $($filterMethod.access) $($filterMethod.return_type) $($filterMethod.name)(){")
    [void]$sb.AppendLine("         string header = `"&filter=`";")
    [void]$sb.AppendLine("         string filter = `"`";")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("         // 検索欄から変数を獲得")
    
    foreach ($condition in $filterMethod.filter_conditions) {
        [void]$sb.AppendLine("         // $($condition.field)")
        [void]$sb.AppendLine("         if(ThisForm.Variables(`"$($condition.variable)`").Value != `"`"){")
        [void]$sb.AppendLine("            // 接続詞追加")
        [void]$sb.AppendLine("            if(filter != `"`"){filter += `" and `";}")
        [void]$sb.AppendLine("            // 検索値追加")
        [void]$sb.AppendLine("            filter += `$`"$($condition.field)=\'{ThisForm.Variables(`"$($condition.variable)`").Value}\'`";")
        [void]$sb.AppendLine("         }")
    }
    
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("         // 作成したフィルターを返す")
    [void]$sb.AppendLine("         if (filter == `"`"){")
    [void]$sb.AppendLine("            return `"`";")
    [void]$sb.AppendLine("         }")
    [void]$sb.AppendLine("         else")
    [void]$sb.AppendLine("         {")
    [void]$sb.AppendLine("            return header + filter;")
    [void]$sb.AppendLine("         }")
    [void]$sb.AppendLine("      }")
    [void]$sb.AppendLine()
}

# ========================================
# 業務固有メソッド: setParameterFormRun
# ========================================
$setParamMethod = $config.business_methods | Where-Object { $_.name -eq "setParameterFormRun" }
if ($setParamMethod) {
    [void]$sb.AppendLine("      /// <summary>")
    [void]$sb.AppendLine("      /// $($setParamMethod.description)")
    [void]$sb.AppendLine("      /// </summary>")
    [void]$sb.AppendLine("      $($setParamMethod.access) $($setParamMethod.return_type) $($setParamMethod.name)(){")
    [void]$sb.AppendLine("         // グリッドの値を変数に持たせる")
    [void]$sb.AppendLine("         // 将来の拡張用にプレースホルダーとして残します")
    [void]$sb.AppendLine("      }")
    [void]$sb.AppendLine()
}

# ========================================
# 業務固有メソッド: GenerateWebSetJson
# ========================================
$webJsonMethod = $config.business_methods | Where-Object { $_.name -eq "GenerateWebSetJson" }
if ($webJsonMethod) {
    [void]$sb.AppendLine("      /// <summary>")
    [void]$sb.AppendLine("      /// $($webJsonMethod.description)")
    [void]$sb.AppendLine("      /// </summary>")
    
    foreach ($param in $webJsonMethod.parameters) {
        [void]$sb.AppendLine("      /// <param name=`"$($param.name)`">$($param.description)</param>")
    }
    [void]$sb.AppendLine("      /// <returns>web用JSON文字列</returns>")
    
    $paramStr = ($webJsonMethod.parameters | ForEach-Object { "$($_.type) $($_.name)" }) -join ", "
    [void]$sb.AppendLine("      $($webJsonMethod.access) $($webJsonMethod.return_type) $($webJsonMethod.name)($paramStr){")
    [void]$sb.AppendLine("         // オブジェクトを作成")
    [void]$sb.AppendLine("         var responseObject = new WebJSONObject")
    [void]$sb.AppendLine("         {")
    
    foreach ($mapping in $webJsonMethod.web_json_mapping) {
        if ($mapping.source -match "^variable:(.+)$") {
            $varName = $matches[1]
            [void]$sb.AppendLine("            $($mapping.target) = ThisForm.Variables(`"$varName`").Value ,")
        }
        elseif ($mapping.source -match "^parameter:(.+)$") {
            $paramName = $matches[1]
            [void]$sb.AppendLine("            $($mapping.target) = $paramName")
        }
    }
    
    [void]$sb.AppendLine("         };")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("         // Formatting.Indented で整形して出力")
    [void]$sb.AppendLine("         string jsonString = JsonConvert.SerializeObject(responseObject, Formatting.Indented);")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("         return jsonString;")
    [void]$sb.AppendLine("      }")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("      ")
}

# ========================================
# 共通処理の挿入
# ========================================
[void]$sb.AppendLine("      //API取得JSONリスト化用クラス")
[void]$sb.AppendLine()

foreach ($commonClass in $config.common_classes) {
    [void]$sb.AppendLine("      /// <summary>")
    [void]$sb.AppendLine("      /// $($commonClass.description)")
    [void]$sb.AppendLine("      /// </summary>")
    [void]$sb.AppendLine("      public class $($commonClass.name)")
    [void]$sb.AppendLine("      {")
    
    foreach ($prop in $commonClass.properties) {
        [void]$sb.AppendLine("         [JsonProperty(`"$($prop.json_property)`")]")
        
        if ($prop.default_value) {
            [void]$sb.AppendLine("         public $($prop.type) $($prop.name) { get; set; } = $($prop.default_value);")
        }
        else {
            [void]$sb.AppendLine("         public $($prop.type) $($prop.name) { get; set; }")
        }
        [void]$sb.AppendLine()
    }
    
    [void]$sb.AppendLine("      }")
    [void]$sb.AppendLine()
}

# 共通メソッドの追加（実際の実装は元のファイルから取得）
if ($commonTailContent) {
    [void]$sb.AppendLine($commonTailContent)
}
else {
    [void]$sb.AppendLine("      // 共通メソッドは元のファイルから取得してください")
    [void]$sb.AppendLine("      // getData, GenerateChangeSetJsonなど")
}

# ========================================
# クラスとネームスペースの終了
# ========================================
[void]$sb.AppendLine("   }")
[void]$sb.AppendLine("}")

# ファイルへの書き込み
$csCode = $sb.ToString()
$csCode | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "`n✅ C#コードの生成が完了しました!" -ForegroundColor Green
Write-Host "出力ファイル: $OutputPath" -ForegroundColor Cyan
Write-Host "`n生成されたコードの統計:" -ForegroundColor Yellow
Write-Host "  - 行数: $(($csCode -split "`n").Count)" -ForegroundColor White
Write-Host "  - データクラス数: $($config.data_classes.Count)" -ForegroundColor White
Write-Host "  - 業務メソッド数: $($config.business_methods.Count)" -ForegroundColor White
Write-Host "  - 共通クラス数: $($config.common_classes.Count)" -ForegroundColor White

# プレビュー表示
Write-Host "`n最初の30行のプレビュー:" -ForegroundColor Yellow
($csCode -split "`n" | Select-Object -First 30) -join "`n" | Write-Host -ForegroundColor Gray

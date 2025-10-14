# ArrivalLocationDetail コード生成システム - 使用ガイド

## 🎯 概要

このシステムは、YAML定義ファイルからC# FormScriptコードを自動生成するツールです。
Excelマクロの代わりに、PowerShellスクリプトとYAMLを使用して、より保守性の高いコード生成を実現します。

## 📊 従来の方式との比較

### 従来（Excelベース）
```
┌─────────────────┐
│ Excel           │
│ - SpecDataシート │ → マクロ実行 → C#コード
│ - CommonTailシート│
└─────────────────┘
```

### 新方式（YAMLベース）
```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Markdown     │ →   │ YAML         │ →   │ C#コード     │
│ 設計書       │     │ 定義ファイル │     │ 完全版       │
└──────────────┘     └──────────────┘     └──────────────┘
        ↓                    ↓                    ↓
    仕様管理            構造化定義           実装コード
```

## 🚀 基本的な使い方

### 方法1: 全自動生成（最も簡単）

```powershell
# すべてを一度に実行
.\Master-Generate.ps1 -Mode full
```

これで完了です！以下が自動的に実行されます:
1. ✅ Markdown → YAML変換
2. ✅ YAML → C#変換
3. ✅ コード比較
4. ✅ 構文検証

### 方法2: YAMLから生成（推奨）

すでにYAMLファイルがある場合:

```powershell
.\Generate-CSharpFromYaml.ps1 -YamlPath "ArrivalLocationDetail.YAML"
```

### 方法3: 個別実行

```powershell
# ステップ1: Markdown → YAML
.\Generate-YamlFromMarkdown.ps1 `
    -MarkdownPath "ArrivalLocationDetail.md" `
    -CSharpReferencePath "ArrivalLocationDetail.cs"

# ステップ2: YAML → C#
.\Generate-CSharpFromYaml.ps1 `
    -YamlPath "ArrivalLocationDetail.YAML" `
    -CommonTailPath "CommonTail.cs.template"
```

## 📝 YAMLファイルの編集

### YAMLファイルの構造

```yaml
# メタ情報
metadata:
  name: ArrivalLocationDetail
  namespace: Mongoose.FormScripts
  version: "1.0.0"

# グローバル変数（業務固有）
global_variables:
  - name: gIDOName
    type: string
    value: "ue_ADV_SLCoitems"

# データクラス（業務固有）
data_classes:
  - name: cItem
    properties:
      - name: Item
        type: string
        json_property: "Item"

# 業務メソッド
business_methods:
  - name: callAPI
    access: public
    return_type: void

# 共通クラス・メソッド
common_classes: [...]
common_methods: [...]
```

### 変更の流れ

1. **YAMLを編集**
   ```powershell
   code ArrivalLocationDetail.YAML
   ```

2. **再生成**
   ```powershell
   .\Generate-CSharpFromYaml.ps1 -YamlPath "ArrivalLocationDetail.YAML"
   ```

3. **確認**
   ```powershell
   code --diff ArrivalLocationDetail.cs Generated_ArrivalLocationDetail.cs
   ```

## 🎨 よくある編集例

### 例1: グローバル変数の変更

```yaml
# YAMLファイルを編集
global_variables:
  - name: gIDOName
    type: string
    value: "ue_NEW_IDO_NAME"  # ← 変更
    description: "ターゲットIDO名"
```

### 例2: 新しいプロパティの追加

```yaml
data_classes:
  - name: cItem
    properties:
      # 既存のプロパティ...
      
      # 新しいプロパティを追加
      - name: NewProperty
        type: string
        json_property: "NewProperty"
        description: "新しいプロパティ"
```

### 例3: フィルター条件の追加

```yaml
business_methods:
  - name: GenerateFilter
    filter_conditions:
      - variable: gCoNum
        field: CoNum
      - variable: gStat
        field: Stat
      # 新しいフィルター条件を追加
      - variable: gWhse
        field: Whse
```

## 🔧 カスタマイズポイント

### 業務固有処理（1-177行）

これらは `ArrivalLocationDetail.YAML` で定義:

- ✏️ **グローバル変数**: `global_variables`
- ✏️ **データクラス**: `data_classes`
- ✏️ **業務メソッド**: `business_methods`

**編集後**: `.\Generate-CSharpFromYaml.ps1` で再生成

### 共通処理（178行目以降）

これらは `CommonTail.cs.template` で定義:

- ✏️ getData()メソッド
- ✏️ GenerateChangeSetJson()メソッド
- ✏️ 共通クラス（Property, Change等）

**編集後**: `.\Generate-CSharpFromYaml.ps1` で再生成

## 📂 ファイルの役割

| ファイル名 | 役割 | 編集 |
|----------|------|------|
| `ArrivalLocationDetail.md` | 設計書（参照用） | ❌ 生成には不要 |
| `ArrivalLocationDetail.YAML` | **定義ファイル（中心）** | ✅ ここを編集 |
| `CommonTail.cs.template` | 共通処理テンプレート | ✅ 必要に応じて |
| `Generated_ArrivalLocationDetail.cs` | 生成されたコード | ❌ 自動生成 |
| `ArrivalLocationDetail.cs` | 元のコード（比較用） | 📖 参照のみ |

## 🎯 実践ワークフロー

### シナリオ1: IDO名を変更したい

```powershell
# 1. YAMLを編集
code ArrivalLocationDetail.YAML
# → global_variables の gIDOName を変更

# 2. 再生成
.\Generate-CSharpFromYaml.ps1 -YamlPath "ArrivalLocationDetail.YAML"

# 3. 確認
code Generated_ArrivalLocationDetail.cs
```

### シナリオ2: 新しいプロパティを追加

```powershell
# 1. YAMLを編集
code ArrivalLocationDetail.YAML
# → data_classes の cItem に新プロパティを追加

# 2. 再生成
.\Generate-CSharpFromYaml.ps1 -YamlPath "ArrivalLocationDetail.YAML"

# 3. callAPIメソッドのプロパティリストも更新
code ArrivalLocationDetail.YAML
# → business_methods の callAPI の properties_get に追加

# 4. 再生成
.\Generate-CSharpFromYaml.ps1 -YamlPath "ArrivalLocationDetail.YAML"
```

### シナリオ3: 共通処理を修正

```powershell
# 1. テンプレートを編集
code CommonTail.cs.template
# → getData() メソッドなどを修正

# 2. 再生成
.\Generate-CSharpFromYaml.ps1 -YamlPath "ArrivalLocationDetail.YAML" -CommonTailPath "CommonTail.cs.template"
```

## ✅ 動作確認チェックリスト

生成後に以下を確認:

```powershell
# 1. ファイルが生成されたか
Test-Path "Generated_ArrivalLocationDetail.cs"

# 2. 構文検証
.\Master-Generate.ps1 -Mode validate

# 3. 元のファイルと比較
.\Master-Generate.ps1 -Mode compare

# 4. VS Codeで開いて確認
code Generated_ArrivalLocationDetail.cs
```

## 🐛 トラブルシューティング

### エラー: powershell-yamlモジュールがない

```powershell
Install-Module -Name powershell-yaml -Force -Scope CurrentUser
```

### エラー: YAMLの構文エラー

```powershell
# YAML検証
Import-Module powershell-yaml
$yaml = Get-Content "ArrivalLocationDetail.YAML" -Raw
try {
    ConvertFrom-Yaml -Yaml $yaml
    Write-Host "✅ YAML構文OK"
} catch {
    Write-Host "❌ YAML構文エラー: $($_.Exception.Message)"
}
```

### 生成されたコードが空

```powershell
# パスを絶対パスで指定してみる
$yamlPath = Resolve-Path "ArrivalLocationDetail.YAML"
.\Generate-CSharpFromYaml.ps1 -YamlPath $yamlPath
```

### 共通処理が含まれていない

```powershell
# CommonTailパスを明示的に指定
.\Generate-CSharpFromYaml.ps1 `
    -YamlPath "ArrivalLocationDetail.YAML" `
    -CommonTailPath "CommonTail.cs.template"
```

## 💡 ヒント

### VSCodeで快適に編集

1. **YAML拡張機能をインストール**
   ```
   Ctrl+Shift+X → "YAML" で検索
   → "YAML" by Red Hat をインストール
   ```

2. **設定でYAMLのフォーマットを有効化**
   ```json
   {
     "yaml.format.enable": true,
     "yaml.validate": true
   }
   ```

### Git管理

```powershell
# 重要なファイルをコミット
git add ArrivalLocationDetail.YAML
git add CommonTail.cs.template
git add *.ps1
git commit -m "Add YAML-based code generation"

# 生成されたファイルは.gitignoreに
echo "Generated_*.cs" >> .gitignore
```

## 📚 さらに学ぶ

詳細は以下を参照:

- 📖 **README.md** - 全体概要とリファレンス
- 📖 **ArrivalLocationDetail.md** - 業務仕様書
- 💻 **Master-Generate.ps1** - 統合スクリプト
- 🔧 **Generate-CSharpFromYaml.ps1** - コード生成ロジック

## ❓ FAQ

**Q: Excelマクロとの違いは?**
A: YAMLはテキストファイルなので、Gitで管理しやすく、差分も見やすいです。

**Q: 元のExcelファイルは必要?**
A: いいえ。YAMLとPowerShellスクリプトだけで完結します。

**Q: 複数のFormScriptに対応できる?**
A: はい。YAMLファイルを複製して、各FormScript用に編集できます。

**Q: 生成されたコードは手で編集していい?**
A: 生成されたコード自体は編集せず、YAMLを編集して再生成することを推奨します。

---

**🎉 これであなたもYAMLベースのコード生成マスター！**

困ったときは `.\Master-Generate.ps1 -Mode validate` でチェック!

# GitHub リポジトリ作成ガイド

## ❌ 現在のエラー
```
remote: Repository not found.
fatal: repository 'https://github.com/ytsutsumi30/ArrivalLocationDetail.git/' not found
```

このエラーは、GitHubにリポジトリがまだ作成されていないことを示しています。

## ✅ 解決方法

### オプション1: GitHubでリポジトリを作成（推奨）

1. **GitHubにアクセス**
   - ブラウザで https://github.com を開く
   - ログイン

2. **新しいリポジトリを作成**
   - 右上の「+」→「New repository」をクリック
   - または https://github.com/new を直接開く

3. **リポジトリの設定**
   ```
   Repository name: ArrivalLocationDetail
   Description: YAML-based C# FormScript generation system
   Visibility: Public または Private（お好みで）
   
   ⚠️ 重要: 以下のオプションはチェックを外してください
   □ Add a README file
   □ Add .gitignore
   □ Choose a license
   
   （既にローカルでファイルがあるため）
   ```

4. **「Create repository」をクリック**

5. **表示されるコマンドは無視して、以下を実行**

### オプション2: GitHub CLIを使用（コマンドライン）

```powershell
# GitHub CLIがインストールされている場合
gh repo create ArrivalLocationDetail --public --source=. --remote=origin --push
```

---

## 🚀 リポジトリ作成後の手順

GitHubでリポジトリを作成したら、以下のコマンドを実行してください：

```powershell
# 既にリモートが設定されているので、そのままプッシュ
git push -u origin master
```

### 認証が求められた場合

#### Windows認証情報マネージャーを使用
1. ブラウザが開いてGitHubログインを求められる
2. ログインすると自動的に認証が完了

#### Personal Access Token (PAT) を使用
もし認証エラーが出る場合：

1. **PATを生成**
   - https://github.com/settings/tokens
   - 「Generate new token」→「Generate new token (classic)」
   - スコープで「repo」にチェック
   - トークンをコピー

2. **認証情報を更新**
```powershell
# リモートURLをトークン付きに変更
git remote set-url origin https://YOUR_TOKEN@github.com/ytsutsumi30/ArrivalLocationDetail.git
```

---

## 📝 別の方法: リポジトリ名を変更

もし別の名前でリポジトリを作成した場合：

```powershell
# 既存のリモートを削除
git remote remove origin

# 新しいURLで追加
git remote add origin https://github.com/ytsutsumi30/NEW_REPO_NAME.git

# プッシュ
git push -u origin master
```

---

## 🔍 トラブルシューティング

### エラー: "Support for password authentication was removed"

```powershell
# Personal Access Tokenを使用
git remote set-url origin https://YOUR_TOKEN@github.com/ytsutsumi30/ArrivalLocationDetail.git
git push -u origin master
```

### エラー: "Permission denied"

```powershell
# SSH認証に変更
git remote set-url origin git@github.com:ytsutsumi30/ArrivalLocationDetail.git
git push -u origin master
```

---

## ✅ 成功後の確認

```powershell
# リモートブランチの確認
git branch -r

# ログの確認
git log --oneline --all

# GitHubで確認
# https://github.com/ytsutsumi30/ArrivalLocationDetail
```

---

**次のステップ**: 
1. ブラウザで https://github.com/new を開く
2. リポジトリ名「ArrivalLocationDetail」で作成
3. README/gitignore/licenseは追加しない
4. `git push -u origin master` を実行

# Git Push ガイド

## 現在の状態
✅ Gitリポジトリの初期化完了  
✅ 24ファイルを最初のコミットに追加  
✅ コミットID: 71d8c2d

## 次のステップ: リモートリポジトリへのPush

### オプション1: GitHub を使用する場合

```powershell
# 1. GitHubでリポジトリを作成（Webブラウザで）
#    例: https://github.com/yourusername/ArrivalLocationDetail

# 2. リモートリポジトリを追加
git remote add origin https://github.com/yourusername/ArrivalLocationDetail.git

# 3. プッシュ（初回）
git push -u origin master
# または main ブランチの場合
# git branch -M main
# git push -u origin main
```

### オプション2: Azure DevOps を使用する場合

```powershell
# 1. Azure DevOpsでリポジトリを作成

# 2. リモートリポジトリを追加
git remote add origin https://dev.azure.com/organization/project/_git/ArrivalLocationDetail

# 3. プッシュ
git push -u origin master
```

### オプション3: GitLab を使用する場合

```powershell
# 1. GitLabでリポジトリを作成

# 2. リモートリポジトリを追加
git remote add origin https://gitlab.com/yourusername/ArrivalLocationDetail.git

# 3. プッシュ
git push -u origin master
```

### オプション4: 既存のリモートリポジトリがある場合

```powershell
# リモートリポジトリのURLを指定してください
$remoteUrl = "YOUR_REPOSITORY_URL_HERE"
git remote add origin $remoteUrl
git push -u origin master
```

## 認証について

### HTTPS認証の場合
- ユーザー名とパスワード（または Personal Access Token）が必要
- 初回プッシュ時に認証情報を求められます

### SSH認証の場合
```powershell
# SSHキーを生成（未作成の場合）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 公開鍵をGitサービスに登録
cat ~/.ssh/id_ed25519.pub

# SSH URLでリモートを追加
git remote add origin git@github.com:yourusername/ArrivalLocationDetail.git
git push -u origin master
```

## 確認コマンド

```powershell
# リモート設定の確認
git remote -v

# コミット履歴の確認
git log --oneline

# 現在のブランチ確認
git branch
```

## トラブルシューティング

### エラー: "fatal: remote origin already exists"
```powershell
# 既存のリモートを削除して再設定
git remote remove origin
git remote add origin YOUR_REPOSITORY_URL
```

### エラー: "! [rejected] master -> master (fetch first)"
```powershell
# リモートの変更を取得してマージ
git pull origin master --allow-unrelated-histories
git push -u origin master
```

### プッシュ前に変更を加えたい場合
```powershell
# ファイルを編集後
git add .
git commit -m "Update: your message"
git push
```

## 推奨: README.md をリポジトリのルートに
現在のREADME.mdは素晴らしい内容です！
GitHubなどでリポジトリを開いたときに自動的に表示されます。

---

**次のアクション**: 
1. リモートリポジトリのURLを取得
2. `git remote add origin URL` を実行
3. `git push -u origin master` を実行

リモートリポジトリのURLを教えていただければ、正確なコマンドをお伝えします！

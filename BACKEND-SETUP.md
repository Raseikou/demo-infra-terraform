# Terraform Backend Setup Guide

このリポジトリでは、Terraform の state を S3 に保存し、DynamoDB でロック管理する構成を採用しています。

state は次の 2 層に分かれています。

- `backend/` → `backend/bootstrap.tfstate`
- `practice-06/` → `practice-06/terraform.tfstate`

## アーキテクチャ

```text
Backend Infrastructure（一度作成し、その後リモート state に引き継ぐ）
├── S3 Bucket（Terraform state 保存先）
│   ├── KMS 暗号化
│   ├── バージョニング
│   ├── アクセスログ
│   ├── ライフサイクル設定
│   └── パブリックアクセス遮断
├── DynamoDB Table（state lock）
├── KMS Key
├── IAM User（CI/CD 用）
└── Logging Bucket

Practice-06
└── 上記 backend を利用して EC2 をデプロイ
```

## セットアップ手順

### Step 1: Backend 基盤を初期作成する

この作業は基本的に一度だけ行います。

#### GitHub Actions で実行する場合

1. GitHub リポジトリの `Actions` を開く
2. `Backend Setup (One-Time Initialization)` を選ぶ
3. `Run workflow` を押す
4. 完了後、summary に出力された backend 情報を確認する

この workflow は最初だけローカル state で backend 資源を作成します。  
あわせて `backend-bootstrap-state` artifact も保存するので、途中失敗時の保険になります。

#### ローカルで実行する場合

```bash
cd backend
terraform init -backend=false
terraform plan
terraform apply
terraform output
```

### Step 2: backend 自身をリモート state に引き継ぐ

backend 基盤ができたら、次は `backend/` の state 自体を S3 に移します。

先に GitHub Repository Variables を設定してください。

- `TF_STATE_BUCKET`
- `TF_LOCK_TABLE`
- `TF_STATE_KMS_KEY_ARN`

その後、`Actions` から `Backend State Recovery` を実行します。

この workflow は次の処理を行います。

- `backend/bootstrap.tfstate` を使うように remote backend を初期化
- 既存の S3 / DynamoDB / KMS / IAM User を Terraform state に import
- `terraform apply` を実行して state とコードを整合させる

### Step 3: Backend 情報を確認する

完了後に確認したい代表的な値:

```text
S3 Bucket:        demo-infra-terraform-state-123456789012
DynamoDB Table:   terraform-state-lock
KMS Key ARN:      arn:aws:kms:ap-northeast-1:123456789012:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### Step 4: Practice-06 を自動デプロイする

`practice-06/**` の変更が `main` に入ると `terraform-apply` workflow が走ります。

1. plan を生成
2. `production` environment の承認を待つ
3. 承認後に apply を実行

### Step 5: state が S3 に保存されていることを確認する

```bash
aws s3 ls s3://demo-infra-terraform-state-123456789012/backend/
aws s3 ls s3://demo-infra-terraform-state-123456789012/practice-06/
```

想定される state key:

- `backend/bootstrap.tfstate`
- `practice-06/terraform.tfstate`

## セキュリティ上のポイント

- state ファイルは KMS で暗号化される
- S3 バケットはパブリックアクセスを禁止
- DynamoDB lock により同時 apply を防ぐ
- S3 versioning で過去 state の復旧が可能
- CI/CD 用 IAM ユーザーは最小権限に絞る

## よく使う操作

### リモート state を使って初期化する

```bash
terraform init
```

### state からリソースだけ外す

```bash
terraform state rm aws_instance.web
```

### 既存リソースを import する

```bash
terraform import aws_instance.web i-0123456789abcdef0
```

## ディレクトリ構成

```text
backend/
├── backend.tf         # backend 用の remote state key
├── terraform.tf       # Terraform / provider 設定
├── main.tf            # S3 / logging / lifecycle
├── kms.tf             # KMS key と policy
├── dynamodb.tf        # state lock table
├── iam.tf             # IAM user と権限
├── variables.tf       # backend 変数
├── terraform.tfvars   # backend 既定値
└── outputs.tf         # backend 出力

practice-06/
├── backend.tf         # practice-06 用 backend 設定
├── main.tf            # EC2 / Security Group
├── variables.tf       # アプリ変数
├── terraform.tfvars   # アプリ既定値
└── outputs.tf         # 出力値

.github/workflows/
├── backend-init.yml
├── backend-state-recovery.yml
├── terraform-pr-check.yml
└── terraform-apply.yml
```

## トラブルシュート

### `AccessDenied` が出る

GitHub Secrets の `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` を確認してください。

### lock が残って apply できない

```bash
aws dynamodb delete-item --table-name terraform-state-lock \
  --key '{"LockID":{"S":"practice-06/terraform.tfstate"}}'
```

### state を古い版に戻したい

```bash
aws s3api list-object-versions --bucket demo-infra-terraform-state-xxx

aws s3api get-object --bucket demo-infra-terraform-state-xxx \
  --key practice-06/terraform.tfstate \
  --version-id <VERSION_ID> state.backup

aws s3 cp state.backup s3://demo-infra-terraform-state-xxx/practice-06/terraform.tfstate
```

### なぜ IAM Access Key を Terraform 管理しないのか

Access key の secret は作成時に一度しか表示されません。  
そのため、runner 上の一時 state が失われたときに復旧しづらくなります。  
このリポジトリでは IAM user と policy だけを Terraform 管理し、実際の Access Key は GitHub Secrets 側で運用します。

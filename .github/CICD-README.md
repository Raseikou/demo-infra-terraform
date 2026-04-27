# CI/CD Workflow Guide

このドキュメントは、このリポジトリで使っている GitHub Actions の CI/CD フローを学習用に整理したものです。

対象 workflow:

- `terraform-pr-check.yml`
- `backend-init.yml`
- `backend-state-recovery.yml`
- `terraform-apply.yml`

## 全体像

```text
PR 作成
  ↓
terraform-pr-check
  ↓
backend 関連を main に反映
  ↓
backend-init
  ↓
backend-state-recovery
  ↓
practice-06 を main に反映
  ↓
terraform-apply
```

## 1. terraform-pr-check.yml

目的:

- PR に含まれる Terraform の変更を事前に検証する
- 変更されていないディレクトリはチェックしない

主な job:

### `terraform-check`

実行内容:

1. リポジトリを checkout
2. Terraform をセットアップ
3. PR の差分から、変更された Terraform ディレクトリを抽出
4. 各ディレクトリに対して以下を実行
   - `terraform fmt -check -recursive`
   - `terraform init -backend=false`
   - `terraform validate`
5. 結果を PR コメントにまとめて投稿

ポイント:

- `backend=false` を使うことで、実際の remote backend につながずに静的検証だけ行う
- `backend/` と `practice-06/` を同時に巻き込まないため、PR の責務が分かりやすい

## 2. backend-init.yml

目的:

- Terraform state 用の基盤を最初に作る
- 具体的には S3 / DynamoDB / KMS / IAM を作る

主な job:

### `backend`

実行内容:

1. checkout
2. Terraform セットアップ
3. `backend/` に対して `fmt`
4. `terraform init -backend=false`
   - 初回は backend バケット自体がまだ存在しないため、remote backend を使わない
5. `terraform validate`
6. `terraform plan`
7. `terraform apply`
8. 一時的な state を artifact として保存
9. bucket / table / KMS ARN を summary に表示

ポイント:

- これは「backend を生み出すための bootstrap workflow」
- この時点では `backend/` 自身の state はまだローカル由来

## 3. backend-state-recovery.yml

目的:

- `backend-init` で作成済みの backend リソースを、正式に S3 state 管理へ移す

主な job:

### `recover`

実行内容:

1. checkout
2. Terraform セットアップ
3. Repository Variables の存在確認
   - `TF_STATE_BUCKET`
   - `TF_LOCK_TABLE`
   - `TF_STATE_KMS_KEY_ARN`
4. `backend/` を remote backend で `init -reconfigure`
5. 既存リソースを `terraform import`
   - KMS key
   - KMS alias
   - state bucket
   - log bucket
   - DynamoDB table
   - IAM user
6. `terraform apply` で state とコードを整合
7. recovery 完了情報を summary に表示

ポイント:

- backend 用の state key は `backend/bootstrap.tfstate`
- 一度この workflow が成功すれば、backend も通常の Terraform 管理対象になる

## 4. terraform-apply.yml

目的:

- `practice-06` の plan / approval / apply を自動化する

主な jobs:

### `preflight`

実行内容:

- backend に必要な Repository Variables が入っているか確認
- 足りない場合は後続 job を止める

### `plan`

実行内容:

1. checkout
2. Terraform セットアップ
3. `practice-06` の `fmt`
4. `terraform init`
   - `bucket`
   - `dynamodb_table`
   - `kms_key_id`
   - `region`
   を `-backend-config` で注入
5. `terraform validate`
6. `terraform plan`
7. plan artifact を保存

### `approval`

実行内容:

- `production` environment の手動承認を待つ

### `apply`

実行内容:

1. plan artifact をダウンロード
2. 再度 `terraform init`
3. 保存済み plan を使って `terraform apply`
4. output を summary に表示

### `notify`

実行内容:

- 最終結果をまとめて表示
- backend 変数不足で skip されたのか、成功したのか、失敗したのかを明示する

## Variables / Secrets の使い分け

Repository Variables:

- `TF_STATE_BUCKET`
- `TF_LOCK_TABLE`
- `TF_STATE_KMS_KEY_ARN`

Repository Secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

考え方:

- backend の値は構成情報なので Variables
- AWS 認証情報は秘匿情報なので Secrets

## 学習ポイント

この CI/CD 構成で学べること:

- Terraform backend を後から安全に導入する流れ
- bootstrap と本運用 state を分ける考え方
- PR チェックと deploy workflow の責務分離
- GitHub Actions の Variables / Secrets / Environment 承認の使い分け
- `terraform plan` と `terraform apply` を artifact でつなぐ方法

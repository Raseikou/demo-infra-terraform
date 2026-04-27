# このディレクトリは `practice-06` 用のアプリケーション構成です。
#
# 実際の state はローカルではなく、S3 backend に保存されます。
# backend 側の初期化と state recovery が終わったあとに利用してください。
#
# 基本的な流れ:
# 1. backend 用の S3 / DynamoDB / KMS を用意する
# 2. GitHub Repository Variables に backend 情報を設定する
# 3. `terraform-apply` workflow で `practice-06` を plan / apply する

# 这个目录用来初始化 S3 backend 和 DynamoDB table
# 
# 使用步骤：
# 1. cd practice-06
# 2. terraform init
# 3. terraform apply
# 4. 记录输出的 S3 bucket 名称
# 5. 更新 backend.tf 中的 bucket 名称

# 第一次运行时，terraform 会将 state 存储在本地
# apply 完成后，手动迁移到 S3（参考 README.md）

# Terraform Backend - Production Grade Setup

本项目使用企业级 Terraform 后端架构，所有 state 文件持久化存储在 S3，支持版本管理、加密和并发锁定。

当前分成两个 state 层级：

- `backend/` → `backend/bootstrap.tfstate`
- `practice-06/` → `practice-06/terraform.tfstate`

## 🏗️ 架构设计

```
Backend Infrastructure (创建一次，然后接管到远程 state)
├── S3 Bucket (state 存储)
│   ├── KMS 加密
│   ├── 版本控制 (90天保留)
│   ├── 访问日志
│   ├── 生命周期管理
│   └── 公开访问阻止
├── DynamoDB Table (状态锁)
│   ├── 按需计费
│   ├── KMS 加密
│   └── 点对点恢复
├── KMS Key (加密密钥)
├── IAM User (CI/CD 凭证)
│   ├── S3 访问权限
│   ├── DynamoDB 权限
│   └── KMS 权限
└── Logging Bucket (审计日志)

Practice-06 (应用部署)
└── 使用共享后端 (S3 + DynamoDB)
```

## 📋 部署步骤

### Step 1: 初始化 Backend 基础设施

⚠️ **重要**: 此步骤只需运行**一次**。Backend 创建后，所有 Terraform 配置都会使用同一个后端。

**方案 A: 使用 GitHub Actions（推荐） 🔄**

1. 进入 GitHub 仓库
2. **Actions** 标签页
3. 左边选择 "Backend Setup (One-Time Initialization)"
4. 点击 "Run workflow" 按钮
5. 保持默认设置，点击绿色 "Run workflow"
6. 等待工作流完成（约 2-3 分钟）

这个 workflow 会先用临时本地 state 完成 bootstrap，并上传 `backend-bootstrap-state` artifact 作为保护网。

**方案 B: 本地手动部署**

```bash
cd backend

# 初始化
terraform init -backend=false

# 查看计划
terraform plan

# 部署
terraform apply

# 查看输出
terraform output
```

### Step 2: 将 backend/ 自身接管到远程 State

⚠️ **重要**: 这一步专门解决 backend bootstrap 完成后 state 还在 runner 本地的问题。

1. 先在 GitHub 仓库中设置 repository variables：
   - `TF_STATE_BUCKET`
   - `TF_LOCK_TABLE`
   - `TF_STATE_KMS_KEY_ARN`
2. 进入 **Actions**
3. 运行 `Backend State Recovery`
4. 工作流会：
   - 以 `backend/bootstrap.tfstate` 初始化远程 backend
   - 导入现有的 S3 / DynamoDB / KMS / IAM user 资源
   - 执行一次 `terraform apply`，把剩余配置同步到远程 state

### Step 3: 获取 Backend 配置信息

工作流完成后，查看日志中的输出，记录以下信息：

```
S3 Bucket:        demo-infra-terraform-state-123456789012
DynamoDB Table:   terraform-state-lock
KMS Key ARN:      arn:aws:kms:ap-northeast-1:123456789012:key/12345678-1234-1234-1234-123456789012
```

### Step 4: 自动部署 Practice-06

推送到 main 分支后，GitHub Actions 自动运行：

1. **terraform-apply workflow** 启动
2. ✅ **Plan phase**: 生成执行计划
3. ⏸️ **Approval phase**: 等待手动批准（环境保护规则）
4. 点击 GitHub Actions 日志中的 "Review deployments" 按钮
5. 选择 "production" 环境，点击 "Approve and deploy"
6. ✅ **Apply phase**: 执行部署

### Step 5: 验证 State 文件持久化

部署完成后，验证 state 已存储在 S3：

```bash
# 列出 S3 中的 state 文件
aws s3 ls s3://demo-infra-terraform-state-123456789012/backend/
aws s3 ls s3://demo-infra-terraform-state-123456789012/practice-06/

# 输出应显示：
# 2026-04-21 10:30:45       12345 backend/bootstrap.tfstate
# 2026-04-21 10:31:02       12345 practice-06/terraform.tfstate

# 查看 state 版本
aws s3api list-object-versions \
  --bucket demo-infra-terraform-state-123456789012 \
  --prefix practice-06/
```

## 🔐 安全特性

✅ **已启用的企业级安全**:

| 特性 | 说明 |
|---|---|
| **KMS 加密** | 所有 state 文件使用 KMS 加密（不是基础的 SSE-S3） |
| **S3 Versioning** | 支持恢复 state 的历史版本（保留 90 天） |
| **DynamoDB 锁** | 防止并发修改 state 文件 |
| **访问日志** | 所有 S3 操作记录在单独的 logging bucket |
| **公开访问防止** | S3 阻止所有公开访问 |
| **SSL/TLS** | 仅允许加密传输（拒绝 HTTP） |
| **IAM 最小权限** | CI/CD 用户仅有必需的权限 |
| **生命周期管理** | 自动删除过期版本，节省成本 |

## 📊 成本估算

当前配置（按需计费）的月度成本：

```
S3 Storage:           ~$0.15/GB
DynamoDB:             ~$1.25 (按需)
KMS:                  ~$1.00
Data Transfer:        按使用量
────────────────────────────
预计月度成本:          ~$3-10 (取决于 state 大小和 API 调用)
```

## 🔄 常见操作

### 本地开发中使用远程 State

在任何 Terraform 目录中，after 配置好 `backend.tf`：

```bash
terraform init

# 第一次会提示：
# Do you want to copy existing state ...? (yes/no)
# 选择 yes 迁移本地 state 到 S3
```

### 导入现有资源

```bash
terraform import aws_instance.web i-0123456789abcdef0
```

### 删除 State 文件（谨慎！）

```bash
# 删除特定的 state 版本
aws s3 rm s3://demo-infra-terraform-state-xxx/practice-06/terraform.tfstate

# 注意：这会导致 Terraform 无法管理该资源
# 恢复办法：从 S3 版本历史中还原
```

### 从 State 中删除资源（但不删除 AWS 资源）

```bash
terraform state rm aws_instance.web
```

## 📖 文件说明

```
backend/                          # Backend 基础设施代码
├── backend.tf                    # backend/ 自己的远程 state key
├── terraform.tf                  # Provider 和默认标签配置
├── main.tf                       # S3 bucket + logging + lifecycle
├── kms.tf                        # KMS 密钥和策略
├── dynamodb.tf                   # State locking table
├── iam.tf                        # CI/CD IAM 用户和权限（不含 access key）
├── variables.tf                  # 可配置参数
├── terraform.tfvars              # 默认值
└── outputs.tf                    # 导出配置信息

practice-06/                      # 应用部署示例
├── backend.tf                    # ← 配置指向远程后端
├── main.tf                       # EC2 和 SG 定义
├── variables.tf                  # 应用参数
├── terraform.tfvars              # 应用配置值
└── outputs.tf                    # 应用输出

.github/workflows/
├── backend-init.yml              # 一次性初始化 backend
├── backend-state-recovery.yml    # 将 backend/ 接管到远程 state
├── terraform-pr-check.yml        # PR 代码检查 (fmt + validate)
└── terraform-apply.yml           # 自动部署 practice-06
```

## ❤️ 手动 Backend 清理（如果需要）

如果要删除 backend 基础设施（谨慎，会失去所有 state！）：

```bash
cd backend

# 移除 prevent_destroy 保护
terraform apply -replace="aws_dynamodb_table.terraform_lock"

# 销毁所有资源
terraform destroy
```

## 🆘 故障排除

### Q: terraform init 报错 "AccessDenied"
**A**: CI/CD IAM 用户凭证不正确，检查 GitHub Secrets 中的 AWS_ACCESS_KEY_ID 和 AWS_SECRET_ACCESS_KEY

### Q: DynamoDB Lock 超时
**A**: 前一个 terraform 操作未正常完成。在 AWS 控制台删除 DynamoDB 中的旧 lock 记录：
```bash
aws dynamodb delete-item --table-name terraform-state-lock \
  --key '{"LockID":{"S":"practice-06/terraform.tfstate"}}'
```

### Q: 如何回滚到之前的 state 版本？
**A**: 使用 S3 versioning：
```bash
# 列出版本
aws s3api list-object-versions --bucket demo-infra-terraform-state-xxx

# 下载旧版本
aws s3api get-object --bucket demo-infra-terraform-state-xxx \
  --key practice-06/terraform.tfstate \
  --version-id <VERSION_ID> state.backup

# 替换当前版本
aws s3 cp state.backup s3://demo-infra-terraform-state-xxx/practice-06/terraform.tfstate
```

### Q: 为什么 Terraform 不再管理 IAM Access Key？
**A**: Access key 的 secret 只会在创建时显示一次。把它放进 Terraform state 会让 runner 失败后的 state recovery 变得很脆弱。当前方案只管理 IAM user 和权限，实际 key 保存在 GitHub Secrets 中，按需在 AWS IAM 控制台手动轮换即可。

---

**更新时间**: 2026-04-21  
**最后验证**: Production-ready ✅

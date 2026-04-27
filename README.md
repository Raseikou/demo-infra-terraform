# demo-infra-terraform

Terraform infrastructure practice with GitHub Actions CI/CD pipeline and production-grade S3 backend state management.

## 📁 Project Structure

```
.
├── backend/                    # Production-grade backend infrastructure
│                              # (S3, DynamoDB, KMS, IAM) - configure once
├── practice-06/               # Practice deployment with S3 backend
│
├── practice-0[1-5]/           # Legacy practice directories (archived)
│
├── BACKEND-SETUP.md          # 👈 Start here: Backend initialization guide
├── TERRAFORM-WORKFLOW.md     # CI/CD workflow documentation
└── README.md                 # This file
```

## 🚀 Quick Start

### For First-Time Setup

1. **Initialize Terraform Backend** (one-time only)
   - Run `Backend Setup (One-Time Initialization)`
   - This creates S3 / DynamoDB / KMS / IAM resources using temporary local state

2. **Adopt backend state into S3**
   - Run `Backend State Recovery`
   - This stores the `backend/` stack at `backend/bootstrap.tfstate`

3. **Set repository variables**
   - `TF_STATE_BUCKET`
   - `TF_LOCK_TABLE`
   - `TF_STATE_KMS_KEY_ARN`

4. **Approve & Deploy practice-06**
   - Push `practice-06` changes to `main`
   - CI/CD auto-runs `terraform-apply`
   - Approve in GitHub → resources deployed with persistent state

### For Development

```bash
# Clone repository
git clone https://github.com/Raseikou/demo-infra-terraform.git
cd demo-infra-terraform

# Create feature branch for changes
git checkout -b feature/your-feature

# Test locally (after backend is initialized)
cd practice-06
terraform plan

# Push and create PR
git push origin feature/your-feature
```

## 🔐 Security Features

✅ Enterprise-grade state management:
- **KMS Encryption** - All state files encrypted with customer-managed keys
- **S3 Versioning** - 90-day retention for recovery
- **State Locking** - DynamoDB prevents concurrent modifications
- **Access Logging** - Audit trail for all S3 operations
- **IAM Least Privilege** - CI/CD user has minimal required permissions
- **State Layering** - `backend/` and `practice-06/` use separate S3 state keys

## 📚 Documentation

| Document | Purpose |
|---|---|
| [BACKEND-SETUP.md](BACKEND-SETUP.md) | Backend initialization, architecture, deployment steps |
| [.github/CICD-README.md](.github/CICD-README.md) | Japanese guide for each CI/CD workflow and job |
| [TERRAFORM-WORKFLOW.md](TERRAFORM-WORKFLOW.md) | CI/CD workflows, approval gates, troubleshooting |

## 🔄 CI/CD Pipeline

```
PR opened
    ↓
terraform-pr-check (fmt + init + validate for changed dirs)
    ↓ Merge backend changes to main
Backend Setup (bootstrap resources with local state)
    ↓
Backend State Recovery (adopt backend/ into S3 state)
    ↓
Push practice-06 changes to main
    ↓
terraform-apply (plan + approval + apply)
    ↓
State persisted in S3 ✅
```

## 📝 AWS Secrets Required

Configure these in GitHub Repository Settings → Secrets:

- `AWS_REGION` - e.g., `ap-northeast-1`
- `AWS_ACCESS_KEY_ID` - CI/CD IAM user credentials
- `AWS_SECRET_ACCESS_KEY` - CI/CD IAM user credentials

Configure these in GitHub Repository Settings → Variables:

- `TF_STATE_BUCKET`
- `TF_LOCK_TABLE`
- `TF_STATE_KMS_KEY_ARN`

## 💡 Key Differences from Legacy Practice-04/05

| Aspect | Practice-04/05 | Practice-06 |
|---|---|---|
| State Storage | Ephemeral runner (lost) | Persistent S3 |
| Encryption | None | KMS |
| Versioning | No | Yes (90 days) |
| Locking | None | DynamoDB |
| Audit Trail | None | S3 access logs |

## ⚠️ Important Notes

- Backend Infrastructure is created once and shared by all practices
- `backend/` state lives at `backend/bootstrap.tfstate`
- `practice-06/` state lives at `practice-06/terraform.tfstate`
- `terraform init` after any `backend.tf` changes
- State files contain sensitive data (credentials, passwords) - keep S3 private
- GitHub Actions runner is ephemeral; state persists only in S3
- IAM access keys are stored in GitHub Secrets, not managed by Terraform state

## 🛠️ Troubleshooting

### Backend workflow fails with "AccessDenied"
→ Check AWS credentials in GitHub Secrets

### terraform apply hangs
→ Check for DynamoDB state locks: see BACKEND-SETUP.md § Troubleshooting

### State file out of sync
→ Re-initialize with `terraform init` and verify S3 bucket name

See [BACKEND-SETUP.md](BACKEND-SETUP.md) for more FAQs.

---

**Status**: ✅ Production-Ready  
**Last Updated**: 2026-04-21  
**Terraform**: 1.5.0  
**AWS Provider**: 5.0.0

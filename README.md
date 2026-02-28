# Shopfast Terraform

## Structure

```
shopfast/
├── main.tf                          # Root module
├── variables.tf                     # All input variables
├── outputs.tf                       # ALB DNS, CloudFront domain, DB endpoint
├── bootstrap/                       # Run once to create the S3 state bucket
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── envs/
│   ├── prod/prod.tfvars
│   ├── staging/staging.tfvars
│   └── dev/dev.tfvars
└── modules/
    ├── vpc/                         # VPC, subnets, NAT gateway, SSM endpoints
    ├── compute/                     # IAM, security groups, ALB, ASGs, CloudFront
    ├── database/                    # RDS PostgreSQL, subnet group, security group
    └── pipeline/                    # CodePipeline, CodeBuild, CodeDeploy (blue/green)
```

---

## Environment differences

| Setting          | prod           | staging        | dev          |
|------------------|----------------|----------------|--------------|
| EC2 type         | t3.medium      | t3.micro       | t3.micro     |
| RDS type         | db.t3.medium   | db.t3.micro    | db.t3.micro  |
| RDS Multi-AZ     | true           | false          | false        |
| ASG desired      | 3              | 2              | 1            |
| VPC CIDR         | 10.0.0.0/16    | 10.1.0.0/16    | 10.2.0.0/16  |
| Deploy branch    | main           | staging        | dev          |

---

## First-time setup

Run bootstrap once before anything else.

```bash
cd bootstrap/
terraform init
terraform apply
cd ..
```

---

## Deploying each environment

### staging
```bash
terraform init -backend-config="key=shopfast/staging/terraform.tfstate"
terraform plan  -var-file="envs/staging/staging.tfvars"
terraform apply -var-file="envs/staging/staging.tfvars"
```

### dev
```bash
terraform init  -backend-config="key=shopfast/dev/terraform.tfstate" -reconfigure
terraform plan  -var-file="envs/dev/dev.tfvars"
terraform apply -var-file="envs/dev/dev.tfvars"
```

### prod
```bash
terraform init  -backend-config="key=shopfast/prod/terraform.tfstate" -reconfigure
terraform plan  -var-file="envs/prod/prod.tfvars"
terraform apply -var-file="envs/prod/prod.tfvars"
```

---

## After apply - authorise GitHub connection

Go to AWS Console > Developer Tools > Settings > Connections.
Find the connection named {env}-shopfast-github and click Update pending connection.
The pipeline will not run until the connection status is AVAILABLE.

---

## Connecting to instances (SSM Session Manager)

No SSH keys or bastion hosts needed. All three SSM endpoints are provisioned
inside the VPC so private instances can connect without NAT.

```bash
# List running instances
aws ec2 describe-instances \
  --region eu-west-2 \
  --filters "Name=tag:Environment,Values=staging" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].{ID:InstanceId,AZ:Placement.AvailabilityZone}" \
  --output table

# Connect
aws ssm start-session --target <instance-id> --region eu-west-2
```

---

## Secrets

Database credentials are managed by AWS Secrets Manager via
manage_master_user_password = true. Get the secret ARN with:

```bash
terraform output db_secret_arn
```

Do not put passwords in .tfvars files.

---

## Destroying an environment

```bash
terraform init  -backend-config="key=shopfast/staging/terraform.tfstate" -reconfigure
terraform destroy -var-file="envs/staging/staging.tfvars"
```

To destroy bootstrap (removes the state bucket - do this last and only if
shutting everything down permanently):
1. Remove both lifecycle { prevent_destroy = true } blocks from bootstrap/main.tf
2. Empty the S3 bucket manually in the AWS Console first
3. Run: cd bootstrap && terraform destroy

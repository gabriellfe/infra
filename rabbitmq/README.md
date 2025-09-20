# RabbitMQ Cluster with S3 Backup

This Terraform module creates a RabbitMQ cluster with automatic backup and restore functionality using Amazon S3.

## Features

- **Automatic Backup**: RabbitMQ definitions are exported to S3 every 15 minutes via cron
- **Startup Restore**: On startup, nodes attempt to import the latest definitions from S3
- **High Availability**: Cluster with configurable number of nodes
- **Dead Node Cleanup**: Automatic removal of inactive cluster nodes

## S3 Backup Functionality

### Export Process
- Runs every 15 minutes via cron job (`/etc/cron.d/export_rabbitmq_definitions`)
- Exports definitions using RabbitMQ Management API
- Uploads to S3 with timestamp and as latest version
- Logs to `/var/log/export_definitions.log`

### Import Process
- Runs automatically on startup after cluster join
- Downloads latest definitions from S3
- Imports via RabbitMQ Management API
- Logs the process for troubleshooting

### S3 Structure
```
s3://your-backup-bucket/
└── definitions/
    ├── rabbitmq_definitions_latest.json
    ├── rabbitmq_definitions_20240920_143000.json
    └── rabbitmq_definitions_20240920_142500.json
```

## Usage

```hcl
module "rabbitmq" {
  source = "./rabbitmq"
  
  vpc_id           = "vpc-12345678"
  subnet_ids       = ["subnet-12345678", "subnet-87654321"]
  ssh_key_name     = "my-key-pair"
  cidr_blocks      = ["10.0.0.0/16"]
  
  # S3 Backup Configuration
  rabbitmq_backup_bucket = "my-rabbitmq-backup-bucket"
  create_backup_bucket   = true
  
  # Cluster Configuration
  min_size     = 2
  desired_size = 3
  max_size     = 5
  
  # Instance Configuration
  instance_type = "m5.large"
  is_public     = false
}
```

## Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `rabbitmq_backup_bucket` | S3 bucket name for RabbitMQ definitions backup | `string` | - | yes |
| `create_backup_bucket` | Whether to create the S3 backup bucket | `bool` | `true` | no |

## Outputs

| Output | Description |
|--------|-------------|
| `backup_bucket_name` | Name of the S3 bucket used for backup |
| `backup_bucket_arn` | ARN of the S3 bucket (if created) |

## Manual Operations

### Manual Export
```bash
sudo /root/export_definitions.sh
```

### Manual Import
```bash
sudo /root/import_definitions.sh
```

### Check Logs
```bash
# Export logs
sudo tail -f /var/log/export_definitions.log

# Import logs
sudo journalctl -u cloud-init -f

# Cron logs
sudo tail -f /var/log/cron.log
```

## Troubleshooting

1. **Backup not working**: Check IAM permissions for S3 access
2. **Import failing**: Ensure RabbitMQ Management API is accessible
3. **Bucket not found**: Verify bucket name and region settings
4. **Permissions errors**: Check that the bucket exists and the IAM role has proper permissions

## IAM Permissions

The module automatically creates the necessary IAM permissions for:
- Reading/writing to the backup bucket
- Listing bucket contents
- EC2 and Auto Scaling describe permissions

## Lifecycle Management

- S3 bucket versioning is enabled
- Objects expire after 30 days
- Old versions expire after 7 days

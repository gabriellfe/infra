variable "region" {
  default = "us-east-1"
}

module "network" {
  source          = "./network"
  vpc_name        = "rabbitmq-vpc"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  Environment     = "Development"
  vpc_cidr        = "10.0.0.0/16"
}

module "rabbit" {
  source        = "./rabbitmq"
  vpc_id        = module.network.vpc_id
  ssh_key_name  = "jenkins"
  subnet_ids    = module.network.public_subnet_ids
  min_size      = "3"
  max_size      = "3"
  desired_size  = "3"
  instance_type = "t3.medium"
  is_public     = true
  Environment   = "Development"
  cidr_blocks   = [module.network.vpc_cidr]

    # S3 Backup Configuration
  rabbitmq_backup_bucket = "rabbitmq-backup-bucket"
  create_backup_bucket   = true
}
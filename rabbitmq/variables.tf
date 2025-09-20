variable "vpc_id" {
}

variable "ssh_key_name" {
}

variable "name" {
  default = "main"
}

variable "min_size" {
  description = "Minimum number of RabbitMQ nodes"
  default     = 2
}

variable "desired_size" {
  description = "Desired number of RabbitMQ nodes"
  default     = 2
}

variable "max_size" {
  description = "Maximum number of RabbitMQ nodes"
  default     = 2
}

variable "is_public" {
  description = "Whether the RabbitMQ nodes should be public or private"
  default     = false
  type        = bool
}

variable "subnet_ids" {
  description = "Subnets for RabbitMQ nodes"
  type        = list(string)
}

variable "instance_type" {
  default = "m5.large"
}

variable "instance_volume_type" {
  default = "standard"
}

variable "instance_volume_size" {
  default = "0"
}

variable "instance_volume_iops" {
  default = "0"
}

variable "Environment" {
  default = "Development"
  type    = string
}

variable "cidr_blocks" {
    type = list(string)
}

variable "rabbitmq_backup_bucket" {
  description = "S3 bucket name for RabbitMQ definitions backup"
  type        = string
}

variable "create_backup_bucket" {
  description = "Whether to create the S3 backup bucket"
  type        = bool
  default     = true
}

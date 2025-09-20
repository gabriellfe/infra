variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "secure-eks-cluster"
}

variable "node_group_size" {
  type    = number
  default = 3
}

variable "Environment" {
  type    = string
  default = "Development"
}

variable "subnet_ids" {
  type    = list(string)
  default = ["subnet-12345678", "subnet-23456789", "subnet-34567890"]
}

variable "vpc_id" {
  type    = string
  default = "Development"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}


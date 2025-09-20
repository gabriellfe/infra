variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "Environment" {
  type    = string
  default = "Development"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_name" {
  type    = string
  default = "main-vpc"
}
variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string

}

variable "public_subnets" {
  description = "public_subnets CIDR"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance Type"
  type        = string
}
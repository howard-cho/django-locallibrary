variable "aws_region" {
  default = "us-west-1"
}

variable "instance_type" {
  default = "t3.small"
}

variable "public_key_path" {
  description = "Path to your SSH public key"
  type        = string
}

variable "private_key_path" {
  description = "Path to your SSH private key"
  type        = string
}

variable "source_ip" {
  description = "Source public IP in CIDR notation, e.g. 1.2.3.4/32"
  type        = string
}

variable "howardcho_zone_id" {
  description = "Route53 zone ID from the foundation config"
  type        = string
}
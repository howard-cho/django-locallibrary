variable "aws_region" {
  default = "us-west-1"
}

variable "public_key_path" {
  description = "Path to your SSH public key"
  type        = string
}

variable "source_ip" {
  description = "Source public IP in CIDR notation, e.g. 1.2.3.4/32"
  type        = string
}
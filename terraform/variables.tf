variable "aws_region" {
  default = "us-west-1"
}

variable "public_key_path" {
  description = "Path to your SSH public key"
  type        = string
}
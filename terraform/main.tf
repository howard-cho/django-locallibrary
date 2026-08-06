resource "aws_vpc" "locallibrary_vpc" {
  cidr_block           = "10.10.1.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "locallibrary_subnet" {
  vpc_id                  = aws_vpc.locallibrary_vpc.id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
}

resource "aws_internet_gateway" "locallibrary_igw" {
  vpc_id = aws_vpc.locallibrary_vpc.id
}

resource "aws_route_table" "locallibrary_rt" {
  vpc_id = aws_vpc.locallibrary_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.locallibrary_igw.id
  }
}

resource "aws_route_table_association" "locallibrary_rta" {
  subnet_id      = aws_subnet.locallibrary_subnet.id
  route_table_id = aws_route_table.locallibrary_rt.id
}

# Security group to allow connection from source IP
resource "aws_security_group" "locallibrary_sg" {
  name   = "locallibrary-sg"
  vpc_id = aws_vpc.locallibrary_vpc.id

  ingress {
    description = "Allow SSH from source IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.source_ip]
  }

  ingress {
    description = "Allow HTTPS from source IP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.source_ip]
  }

  # Allow all outbound traffic, needed for apt
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM policies for EC2 instance to allow Route53
resource "aws_iam_role" "library_role" {
  name = "library-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "library_profile" {
  name = "library-instance-profile"
  role = aws_iam_role.library_role.name
}

resource "aws_iam_role_policy" "library_route53_dns01" {
  name = "library-route53-dns01-challenge"
  role = aws_iam_role.library_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "route53:GetChange"
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect   = "Allow"
        Action   = "route53:ChangeResourceRecordSets"
        Resource = "arn:aws:route53:::hostedzone/${var.howardcho_zone_id}"
      },
      {
        Effect   = "Allow"
        Action   = "route53:ListHostedZones"
        Resource = "*"
      }
    ]
  })
}

# EC2 instance for hosting the app
resource "aws_key_pair" "locallibrary_key" {
  key_name   = "locallibrary-key"
  public_key = file(var.public_key_path)
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "locallibrary_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.locallibrary_subnet.id
  key_name               = aws_key_pair.locallibrary_key.key_name
  vpc_security_group_ids = [aws_security_group.locallibrary_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.library_profile.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "locallibrary-instance"
  }
}

resource "time_sleep" "wait_for_ssh" {
  depends_on      = [aws_instance.locallibrary_instance]
  create_duration = "60s"
}

# Add the EC2 instance to known_hosts
resource "null_resource" "add_instance_to_known_hosts" {
  depends_on = [time_sleep.wait_for_ssh]
  provisioner "local-exec" {
    when    = create
    command = <<EOF
      ssh-keyscan -H ${aws_instance.locallibrary_instance.public_ip} >> ~/.ssh/known_hosts
    EOF
  }
}

output "instance_public_ip" {
  value = aws_instance.locallibrary_instance.public_ip
}

resource "null_resource" "write_ansible_inventory" {
  provisioner "local-exec" {
    when    = create
    command = <<EOF
      echo "[nginx]" > ../ansible/inventory.ini
      echo "${aws_instance.locallibrary_instance.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}" >> ../ansible/inventory.ini
    EOF
  }
}

resource "null_resource" "install_nginx" {
  depends_on = [null_resource.add_instance_to_known_hosts, null_resource.write_ansible_inventory]
  provisioner "local-exec" {
    when    = create
    command = <<EOF
      ansible-playbook -i ../ansible/inventory.ini ../ansible/playbook.yaml
    EOF
  }
}
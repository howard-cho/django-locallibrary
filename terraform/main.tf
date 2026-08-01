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

resource "aws_route53_zone" "howardcho" {
  name = "howardcho.com"
}

# resource "aws_route53_record" "locallibrary" {
#     zone_id = aws_route53_zone.howardcho.zone_id
#     name = "library.howardcho.com"
#     type "A"
#     ttl = 300
#     records = []
# }

resource "aws_route53_record" "caa" {
  zone_id = aws_route53_zone.howardcho.zone_id
  name    = "howardcho.com"
  type    = "CAA"
  ttl     = 300
  records = ["0 issue \"letsencrypt.org\""]
}

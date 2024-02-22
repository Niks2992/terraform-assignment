resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr[count.index]
  map_public_ip_on_launch = "true"
  availability_zone = var.availability_zone[count.index]

  tags = {
    Name = "${var.vpc_name}-private-subnet-${count.index}"
  }
}

resource "aws_subnet" "public" {
  count = length(var.private_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr[count.index]
  map_public_ip_on_launch = "true"
  availability_zone = var.availability_zone[count.index]

  tags = {
    Name = "${var.vpc_name}-public-subnet-${count.index}"
  }
}

# It enables our vpc to connect to the internet
# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.vpc.id
#   tags = {
#     Name = "asg-igw"
#   }
# }
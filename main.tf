provider "aws" {
  region = var.region
}

##########################
# VPC and Networking
##########################

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = { Name = "MainVPC" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "MainIGW" }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "PublicRouteTable" }
}

##########################
# Subnets
##########################

# Public Subnet 1
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet1_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags = { Name = "PublicSubnet1" }
}

# Public Subnet 2
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet2_cidr
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true
  tags = { Name = "PublicSubnet2" }
}

# Private Subnet
resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zones[0]
  tags = { Name = "PrivateSubnet1" }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public1_assoc" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2_assoc" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

##########################
# Security Groups
##########################

# Public EC2 SG (allow HTTP + SSH)
resource "aws_security_group" "public_sg" {
  name   = "public-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Private RDS SG (allow MySQL from public subnets)
resource "aws_security_group" "private_sg" {
  name   = "private-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##########################
# EC2 Instances
##########################

# EC2 in Public Subnet 1
resource "aws_instance" "ec2_public1" {
  ami                    = var.ec2_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  tags = { Name = "EC2Public1" }
}

# EC2 in Public Subnet 2
resource "aws_instance" "ec2_public2" {
  ami                    = var.ec2_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public2.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  tags = { Name = "EC2Public2" }
}

##########################
# Load Balancer (ALB)
##########################

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Attach EC2 instances to target group
resource "aws_lb_target_group_attachment" "ec2_public1_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.ec2_public1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "ec2_public2_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.ec2_public2.id
  port             = 80
}

##########################
# RDS Database (Free Tier)
##########################

resource "aws_db_subnet_group" "db_subnets" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.private1.id]
}

resource "aws_db_instance" "db" {
  identifier             = "tf-db"
  engine                 = "mysql"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false
  storage_type           = "gp2"
}

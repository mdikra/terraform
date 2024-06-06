provider "aws" {
	region = "us-east-1"
}

#creating vpc
resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "ikram_VPC"
  }
}
#creating 1st public subnet
resource "aws_subnet" "pubsub1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "PubSub1"
  }
}

#creating 2nd public subnet
resource "aws_subnet" "pubsub2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "PubSub2"
  }
}

#creating internet Gateway
resource "aws_internet_gateway" "My_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "ikram_IG"
  }
}

#creating routetable
resource "aws_route_table" "Public_RT" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.My_igw.id
    }

    tags = {
        Name = "Pub_RT"
    }
}

#associating route table
resource "aws_route_table_association" "Pub_RT_ass1" {
    subnet_id = aws_subnet.pubsub1.id
    route_table_id = aws_route_table.Public_RT.id
}

resource "aws_route_table_association" "Pub_RT_ass2" {
    subnet_id = aws_subnet.pubsub2.id
    route_table_id = aws_route_table.Public_RT.id
}

#creating 1st private subnet
resource "aws_subnet" "prisub1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "PriSub1"
  }
}

#creating 2nd private subnet
resource "aws_subnet" "prisub2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "PriSub2"
  }
}

#creating elastic IP with NAT Gateway
resource "aws_eip" "nat_gw_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.pubsub1.id

  tags = {
    Name = "MY_NAT_GAT"
  }
}

#creating routetable
resource "aws_route_table" "Private_RT" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gw.id
    }

    tags = {
        Name = "Pri_RT"
    }
}

resource "aws_route_table_association" "Pri_RT_ass1" {
    subnet_id = aws_subnet.prisub1.id
    route_table_id = aws_route_table.Private_RT.id
}

resource "aws_route_table_association" "Pri_RT_ass2" {
    subnet_id = aws_subnet.prisub2.id
    route_table_id = aws_route_table.Private_RT.id
}

#creating security group for frontend server
resource "aws_security_group" "Frontend_Security" {
  name        = "My_Front_SG"
  description = "Allow SSH inbound connections"
  vpc_id = aws_vpc.my_vpc.id

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
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "My_Front_SG"
  }
}

#creating security group for Backend server
resource "aws_security_group" "Backend_Security" {
  name        = "My_Back_SG"
  description = "Allow outbound connections"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "My_Back_SG"
  }
}

resource "aws_security_group" "Security-Group" {
  name        = "common-SG"
  description = "Allow SSH inbound connections"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "common-SG"
  }
}

resource "aws_db_parameter_group" "testing" {
    name = "testing"
    family = "postgres13"

    parameter {
      name = "log_connections"
      value = "1"
    }
}

#creting EC2 instance for web-application
resource "aws_instance" "front_instance" {
  ami           = "ami-0e001c9271cf7f3b9"
  instance_type = "t3.micro"
  key_name = "terra"
  vpc_security_group_ids = [ aws_security_group.Frontend_Security.id ]
  subnet_id = aws_subnet.pubsub1.id
  associate_public_ip_address = true

  tags = {
    Name = "Web-application"
  }
}

#creting EC2 instance for Postgresql
resource "aws_instance" "back_instance" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t3.micro"
  key_name = "terra"
  vpc_security_group_ids = [ aws_security_group.Backend_Security.id ]
  subnet_id = aws_subnet.prisub1.id
  associate_public_ip_address = false

  tags = {
    Name = "PostgreSQL"
  }
}

#creating RDS Database 
resource "aws_db_subnet_group" "db_subnet_group" {
  name = "db_subnet_group"
  subnet_ids = [aws_subnet.prisub1.id,aws_subnet.prisub2.id]

  tags = {
    Name = "Static_Backend"
  }
}

#creating Postgresql-database
resource "aws_db_instance" "testing" {
  instance_class         = "db.t3.micro"
  allocated_storage      = 200
  storage_type		     = "gp3"
  engine                 = "postgres"
  identifier             = "rds"
  engine_version         = "PostgreSQl 16.2-R2"
  username               = "postgres"
  password               = "admin123"
  db_name                = "PostgreSQL"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.Backend_Security.id]
  parameter_group_name = aws_db_parameter_group.testing.name
  skip_final_snapshot    = true
}
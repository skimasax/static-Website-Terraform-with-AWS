provider "aws" {
  region = "us-east-1"
}

#create VPC
resource "aws_vpc" "static_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

#create public subnet 1
resource "aws_subnet" "public_subnet" { 
  vpc_id                  = aws_vpc.static_vpc.id
  cidr_block              = "10.0.0.0/24" 
  availability_zone      = "us-east-1a" 
  map_public_ip_on_launch = true
  tags = {
    Name = "Static Subnet1"
  }
}


# Create a security group
resource "aws_security_group" "staticSG" {
  vpc_id     = aws_vpc.static_vpc.id
  name_prefix = "checkpoint-sg"
  description = "Checkpoint security group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
}

#createKeyPair
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-keypair" 
  public_key = file("~/.ssh/id_rsa.pub") 
}


# Create AWS instance
# Create AWS instance
resource "aws_instance" "staticInstance" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.staticSG.id]
  associate_public_ip_address = true
  
  tags = {
    Name = "staticWebsiteInstance"
  }
  
  # connection {
  #   type        = "ssh"
  #   user        = "ubuntu"
  #   private_key = file("~/.ssh/id_rsa")
  #   host        = self.public_ip
  # }
  
  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo apt update",
  #     "sudo apt install -y apache2",
  #     "sudo systemctl start apache2",
  #     "sudo systemctl enable apache2",
  #     "sudo rm -rf /var/www/html/*",  # Remove default Apache files
  #     "wget https://www.tooplate.com/zip-templates/2137_barista_cafe.zip",
  #     "unzip -d /var/www/html/ 2137_barista_cafe.zip",
  #     "sudo mv /var/www/html/2137_barista_cafe/* /var/www/html/",  # Move extracted files
  #   ]
  # }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.static_vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.static_vpc.id
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}


provider "aws" {
  region     = "ap-south-1"
  profile = "saba1121"
}


// vpc 

resource "aws_vpc" "myvpc_resourcename" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "myvpc1"
         }
}
output "printvpc_id" {
      value = aws_vpc.myvpc_resourcename.id
                 }


// internet gateway

resource "aws_internet_gateway" "resource_igw" {
  vpc_id = aws_vpc.myvpc_resourcename.id

  tags = {
    Name = "myvpc1_internet_gateway"
  }
}

// public subnet

resource "aws_subnet" "resourcename_publicsubnet" {
  vpc_id     = aws_vpc.myvpc_resourcename.id
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"
  


  tags = {
    Name = "mysubnet1"
  }
}

// routing table

resource "aws_route_table" "routingtable" {
  vpc_id = aws_vpc.myvpc_resourcename.id

  
  

  tags = {
    Name = "routing_table"
  }
}



// attaching routing table with subnet1

resource "aws_route_table_association" "rt_attach_subnet" {
  subnet_id      = aws_subnet.resourcename_publicsubnet.id
  route_table_id = aws_route_table.routingtable.id
}

resource "aws_route" "r" {
  route_table_id            = aws_route_table.routingtable.id
  destination_cidr_block    = "0.0.0.0/0"
  
    gateway_id = aws_internet_gateway.resource_igw.id
}


//Creating keypairs

resource "tls_private_key" "skey" {
  algorithm   = "RSA"
                                  }

resource "aws_key_pair" "resource_key" {
  key_name   = "tabu123"
  public_key = tls_private_key.skey.public_key_openssh 
				       }

resource "local_file" "key_file" {
  content = tls_private_key.skey.private_key_pem
  filename = "tabu123.pem"
   				 }

// Creating Security group for my instance

resource "aws_security_group" "securitygroup" {                      
  name        = "launch-wizard-1"
  description = "this security group will allow traffic at port 80"
    vpc_id = aws_vpc.myvpc_resourcename.id
      
  ingress {
    description = "http is allowed"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
ingress {
    description = "ssh is allowed"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
	egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
  tags = {
    Name = "security_group"                   
  }
}

variable "enter_your_security_group" {
 type = string
  default = "launch-wizard-1"
				     }                                               


// Launch instance

resource "aws_instance" "myinstance" {
  ami           = "ami-7e257211"
  instance_type = "t2.micro"
  key_name = aws_key_pair.resource_key.key_name
  vpc_security_group_ids = [ aws_security_group.securitygroup.id ]                
  subnet_id      = aws_subnet.resourcename_publicsubnet.id
tags = {
   	  Name = "wordpress_os"
       	        }
}




// private subnet

resource "aws_subnet" "resourcename_privatesubnet2" {
  vpc_id     = aws_vpc.myvpc_resourcename.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "mysubnet2"
  }
}



// attaching routing table with subnet2

resource "aws_route_table_association" "rt_attach_subnet2" {
  subnet_id      = aws_subnet.resourcename_privatesubnet2.id
  route_table_id = aws_route_table.routingtable.id
}


   
// Creating Security group for mysql instance

resource "aws_security_group" "securitygroup2" {                      
  name        = "launch-wizard-2"
  description = "this security group will allow traffic at port 80"
    vpc_id = aws_vpc.myvpc_resourcename.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
   ingress {
    description = "mysql"
    from_port   = 0
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

	egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
  tags = {
    Name = "security_group_mysql"                   
  }
}
     
// mysql database instance



resource "aws_instance" "mysqlinstance_rn" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name = aws_key_pair.resource_key.key_name
      
  vpc_security_group_ids = [ aws_security_group.securitygroup2.id ]               
  subnet_id = aws_subnet.resourcename_privatesubnet2.id 
tags = {
   	  Name = "mysql_os"
       	        }

                                         }

                                          





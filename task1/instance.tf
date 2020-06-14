provider "aws" {
region = "ap-south-1"
profile = "tabu"
}

//creating key pair
resource "aws_key_pair" "keypair" {
  key_name   = "keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41"
}

variable"enter_my_keyname"{
  type = string
  default = "keypair"
}

//creating security group
resource "aws_security_group" "firewall" {
 name = "firewall"
 description = "this will allow traffic at port 80"

ingress{
 description ="http is allowed"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks =[ "0.0.0.0/0" ]  
              }
ingress{
 description ="ssh is allowed"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks =[ "0.0.0.0/0" ]  
             }
 tags = {
    Name = "firewall"
  }
}
variable "enter_my_security_group" {
 type = string
 default = "firewall"
}

//launch Instance
resource "aws_instance" "RS_instance" {
  ami           = "ami-005956c5f0f757d37"
  instance_type = "t2.micro"
  
  key_name = var.enter_my_keyname
   security_groups = [ var.enter_my_security_group ]
  tags = {
    Name = "terra_OS"
  }
}

//printing availability zone of os
output "resource_name_to_print_az" {
      value = aws_instance.RS_instance.availability_zone
}

//creating EBS volume
resource "aws_ebs_volume" "RS_ebs" {
  availability_zone = aws_instance.RS_instance.availability_zone
  size              = 2
 
 tags = {
    Name = "volume1"
  }
}

//Attaching EBS volume
resource "aws_volume_attachment" "RS_volume" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.RS_ebs.id
  instance_id = aws_instance.RS_instance.id 
}

//creating s3 bucket
resource "aws_s3_bucket" "asdfgbucket" {
  bucket = "asdfgbucket"
  acl    = "public-read"
 tags = {
    Name        = "My_bucket"
    Environment = "Dev"
  }
}

//creating cloudfront distribution
locals {
s3_origin_id = "mys3"
}
resource "aws_cloudfront_distribution" "RS_cloudfront" {
  origin {
    domain_name = aws_s3_bucket.asdfgbucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
         }

  enabled             = true
  is_ipv6_enabled     = true
 comment ="some comment"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

 forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

 # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

 min_ttl = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
# Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

//creating snapshot
resource "aws_ebs_snapshot" "resource_name_of_snapshot" {
  volume_id = aws_ebs_volume.RS_ebs.id              

  tags = {
    Name = "My_OS"
  }
}

//complete code of task 1


provider "aws" {
  region = "ap-south-1"
  profile = "tabu"
}


//Creating keypairs

resource "tls_private_key" "privatekey" {
  algorithm   = "RSA"
                                  }

resource "aws_key_pair" "resource_key" {
  key_name   = "saba_12"
  public_key = tls_private_key.privatekey.public_key_openssh 
				       }

resource "local_file" "key_file" {
  content = tls_private_key.privatekey.private_key_pem
  filename = "saba_12.pem"
   				 }

				 
// Creating Security group

resource "aws_security_group" "securitygroups" {                      
  name        = "launch-wizard-4"
  description = "this security group will allow traffic at port 80"
  
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
  default = "launch-wizard-4"
				     }  

					 
// Launch instance

resource "aws_instance" "myin" {
  ami           = "ami-005956c5f0f757d37"
  instance_type = "t2.micro"
  key_name = aws_key_pair.resource_key.key_name
  security_groups = [var.enter_your_security_group]                 
  
tags = {
   	  Name = "My_OS"
       	        }


// Creating remote connection

 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.privatekey.private_key_pem
    host     = aws_instance.myin.public_ip
  		}

provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo service httpd start",

             ]
  			  

  	 
			  }
				     }

// Printing availability zone of OS  	

output "printaz" {
      value = aws_instance.myin.availability_zone
                 }


// Creating EBS Volume

resource "aws_ebs_volume" "ebsvolume" {                             
  availability_zone = aws_instance.myin.availability_zone

  size              = 2
 
 	 tags = {
    	   Name = "vol1"
  		}
		}
		
		
		
// Attaching Volume EBS to Instance    

resource "aws_volume_attachment" "volumeattached" {              
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebsvolume.id
  instance_id = aws_instance.myin.id
  force_detach = true 
						  }


// Printing IP address of OS

output "myos_ip" {
  value = aws_instance.myin.public_ip
      		 }

			 
// Copying IP address of OS in a file

resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.myin.public_ip} > publicip.txt"
  				 }
				       }
					   
					   
					   
resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.volumeattached,
  	     ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.privatekey.private_key_pem
    host     = aws_instance.myin.public_ip
  	     }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/sdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/sabacs12/images.git /var/www/html/"   
    ]
  }
}


// Creating S3 bucket

resource "aws_s3_bucket" "s3buckets" {
  bucket = "bucket158338"
  acl    = "public-read"

  tags = {
    Name        = "bucket158338"
    Envirnoment = "Dev" 
  }
  
}



// Creating Cloudfront Distribution

locals {
s3_origin_id = "saba12345"
       }


resource "aws_cloudfront_distribution" "cloudfront_distribution" {
                  origin {
                      domain_name = aws_s3_bucket.s3buckets.bucket_regional_domain_name
                      origin_id   = local.s3_origin_id
                      
                         }

  enabled             = true
  is_ipv6_enabled     = true
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

    				min_ttl                = 0
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



// Creating Snapshot of EBS Volume

resource "aws_ebs_snapshot" "snapshot" {
  volume_id = aws_ebs_volume.ebsvolume.id              

  tags = {
    Name = "My_OS"
  	 }
				       }



resource "null_resource" "nulllocal1"  {

depends_on = [
    null_resource.nullremote3,
  	     ]

	provisioner "local-exec" {
	    command = "start chrome  ${aws_instance.myin.public_ip}/terra.jpg"
  				 }
				       }




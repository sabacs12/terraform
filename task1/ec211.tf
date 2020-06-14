provider "aws" {
  region = "ap-south-1"
  profile = "tabu"
}

//creating instance
resource "aws_instance" "myos" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "newkey"
  security_groups = [ "launch-wizard-2" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Best Buy/Downloads/newkey.pem")
    host     = aws_instance.myos.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "wos1"
  }

}

//creating volume
resource "aws_ebs_volume" "esb1" {
  availability_zone = aws_instance.myos.availability_zone
  size              = 2
  tags = {
    Name = "websl"
  }
}

//Attaching volume
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.esb1.id
  instance_id = aws_instance.myos.id
  force_detach = true
}


output "myos_ip" {
  value = aws_instance.myos.public_ip
}


resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.myos.public_ip} > public_ip.txt"
  	}
}



resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.ebs_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Best Buy/Downloads/newkey.pem")
    host     = aws_instance.myos.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/sabacs12/image.git /var/www/html/"
    ]
  }
}

resource "null_resource" "nulllocal1"  {


depends_on = [
    null_resource.nullremote3,
  ]

	provisioner "local-exec" {
	    command = "start chrome  ${aws_instance.myos.public_ip}/terra.jpj"
  	}
}

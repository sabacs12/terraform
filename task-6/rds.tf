provider "aws" {
  region  = "ap-south-1"
profile = "saba9554"
}


resource "aws_db_instance" "rds_rn" {
  allocated_storage    = 5
  max_allocated_storage = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb_task6"
  username             = "task"
  password             = "taskdb123"
  parameter_group_name = "default.mysql5.7"
  port = 3306
  publicly_accessible = true


}

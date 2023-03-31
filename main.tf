terraform {
  required_providers {
    aws = {
    source  = "hashicorp/aws"
    version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}



provider "aws" {
         region = "eu-central-1"
 }
 data "aws_ami" "ubuntu" {
   most_recent = true
 
   filter {
     name = "name"
     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
   }
 
   filter {
     name = "virtualization-type"
     values = ["hvm"]
   }
 
   owners = ["099720109477"] # Canonical
 }
 resource "aws_security_group" "security_terraform2" {
   name = "security_terraform2"
   vpc_id = "vpc-03d9774797f85663b"
   description = "security group for terraform"
 
   ingress {
     from_port = 80
     to_port = 80
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }

   ingress {
    description = "MYSQL"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
   egress {
     from_port = 0
     to_port = 65535
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
 
   tags = {
     Name = "security_terraform2"
   }
 }

resource "aws_security_group" "RDS_allow_rule" {
  name = "RDS_allow_rule"
  vpc_id = "vpc-03d9774797f85663b"
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.security_terraform2.id}"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow ec2"
  }

}


 resource "aws_launch_configuration" "launch_conf" {
   image_id = data.aws_ami.ubuntu.id
   instance_type = "t2.micro"
   key_name = "DmitrijsM"
   security_groups = ["security_terraform2"]
   user_data = filebase64("script.sh")
 
   lifecycle {
       create_before_destroy = true
   }
 }
 resource "aws_autoscaling_group" "asg_1" {
   availability_zones = ["eu-central-1a", "eu-central-1b"]
   desired_capacity = 2
   max_size = 4
   min_size = 2
   load_balancers = [aws_elb.dmitrijs1.id]
   launch_configuration = aws_launch_configuration.launch_conf.id
 
   lifecycle {
       create_before_destroy = true
   }
 }
 resource "aws_elb" "dmitrijs1" {
   name = "dmitrijs1"
   availability_zones = ["eu-central-1a", "eu-central-1b"]
 
   listener {
     instance_port = 80
     instance_protocol = "http"
     lb_port = 80
     lb_protocol = "http"
   }
 
   health_check {
     healthy_threshold = 2
     unhealthy_threshold = 2
     timeout = 3
     target = "HTTP:80/"
     interval = 30
   }
   cross_zone_load_balancing = true
   idle_timeout = 400
   connection_draining = true
   connection_draining_timeout = 400
 
   tags = {
     Name = "dmitrijs1"
   }
 }
 output "elb_dns_name" {
 value = aws_elb.dmitrijs1.dns_name
 }

resource "aws_db_instance" "wordpressdb" {
allocated_storage = 10
identifier = "wordpressdb"
storage_type = "gp2"
engine = "mysql"
engine_version = "8.0"
instance_class = "db.t2.micro"
name = "wordpressdb"
username = "wordpress"
password = "wordpress123"
publicly_accessible    = true
skip_final_snapshot    = true


  tags = {
    Name = "ExampleRDSServerInstance"
  }
}

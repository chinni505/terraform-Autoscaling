provider "aws" {
region = "us-east-1"
}

data "aws_availability_zones" "all" {}

variable "server_port" 
{
description = "server usage ports"
default = 80
}

resource "aws_launch_configuration" "testserver"
{

image_id = 	"ami-55ef662f"
instance_type = "t2.micro"
security_groups = ["${aws_security_group.instance.id}"]
user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              echo "hello world" > /var/www/html/index.html
              service httpd start
              EOF

lifecycle {

create_before_destroy = true
	
   }
}

 
resource "aws_autoscaling_group" "testserver"
{
	launch_configuration = "${aws_launch_configuration.testserver.id}"
	availability_zones = ["${data.aws_availability_zones.all.names}"]
	min_size = 2
	max_size = 5
    load_balancers = ["${aws_elb.testserver.name}"]
    health_check_type = "ELB"
	
	tag {
	     key  = "Name"
	     value = "terraform-ASG-Example"
	     propagate_at_launch = true
	}

}

resource "aws_security_group" "instance" {
name = "example-sg1"
ingress {
from_port = "${var.server_port}"
to_port  = "${var.server_port}"
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port = "${var.server_port}"
to_port  = "${var.server_port}"
protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}


   lifecycle {
   create_before_destroy = true
   }

}


resource "aws_elb" "testserver" {
	
name = "terraform-asg-elb"
availability_zones = ["${data.aws_availability_zones.all.names}"]
security_groups = ["${aws_security_group.instance.id}"]


listener {
	
lb_port  = "${var.server_port}"
lb_protocol = "http"
instance_port = "${var.server_port}"
instance_protocol = "http"

}

health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }

}


output "elb_dns_name" {
value = "${aws_elb.testserver.dns_name}"
}


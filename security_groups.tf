###################################
#### BEGIN: ELB TIER RESOURCES ####
###################################

# elb1 Security Group
# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group" "elb1" {
  name = "elb1"
  description = "Allow services from the interwebs to the ELB subnet"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.prod1.id}"
}

#####################################
#### BEGIN: CACHE TIER RESOURCES ####
#####################################

# varnish-cache Security Group
# TODO: Update to include access from Mgmt Subnet (or SG) on port 22 (SSH)

resource "aws_security_group" "varnish-cache" {
  name = "varnish-cache"
  description = "Allow services from the ELB subnet to Varnish servers"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.elb1.id}"]
  }
  vpc_id = "${aws_vpc.prod1.id}"
}

resource "aws_security_group" "app-internal-elb" {
  name = "internal-elb"
  description = "Allow services from Varnish to the internal instances"
  ingress {
    from_port = 8001
    to_port = 8001
    protocol = "tcp"
    security_groups = ["${aws_security_group.varnish-cache.id}"]
  }
  vpc_id = "${aws_vpc.prod1.id}"
}

###################################
#### BEGIN: APP TIER RESOURCES ####
###################################

# app1 Security Group
# TODO: Update to include access from Mgmt Subnet (or SG) on port 22 (SSH)
# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group" "app1" {
  name = "app1"
  description = "Allow services from the ELB subnet to the App1 subnet"
  ingress {
    from_port = 8001
    to_port = 8001
    protocol = "tcp"
    security_groups = ["${aws_security_group.app-internal-elb.id}"]
  }
  vpc_id = "${aws_vpc.prod1.id}"
}

resource "aws_security_group" "app1_admin" {
  name = "app1_admin"
  description = "Selectively allow access to the administrative interface"
  ingress {
    from_port = 80
    to_port = 8001
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = "${aws_vpc.prod1.id}"
}

####################################
#### BEGIN: DATA TIER RESOURCES ####
####################################

# data1 Security Group
# https://www.terraform.io/docs/providers/aws/r/security_group.html
# TODO: Update to include access from Mgmt Subnet (or SG) on port 22 (SSH)
resource "aws_security_group" "data1" {
  name = "data1"
  description = "Allow services from the app subnets to the data1 subnet"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = ["${aws_security_group.app1.id}","${aws_security_group.app1_admin.id}"]
  }

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_groups = ["${aws_security_group.app1.id}","${aws_security_group.app1_admin.id}"]
  }

  vpc_id = "${aws_vpc.prod1.id}"
}

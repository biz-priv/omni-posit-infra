variable "allowed_ips" {
  description = "IP CIDR blocks that are allowed access to the resources"
  type        = list(string)
  default     = ["203.0.113.0/32", "203.0.114.0/32"]  # Example IPs, replace with actual corporate and VPN IPs
}

resource "aws_instance" "example_instance_from_terraform" {
  ami           = "ami-041feb57c611358bd"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet-using-terraform.id
  vpc_security_group_ids = [aws_security_group.new-sg-using-terraform.id]

  tags = {
    Name = "ExampleInstanceFromTerraform"
  }
}

resource "aws_route53_record" "subdomain" {
  zone_id = var.route53_zone_id 
  name    = "posittest"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.example_instance_from_terraform.private_ip]
}

resource "aws_acm_certificate" "cert-using-terraform" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name = "PositAcmCertificate"
  }
}

resource "aws_route53_record" "cert_validation" {

  for_each = {
    for dvo in aws_acm_certificate.cert-using-terraform.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name = each.value.name
  type = each.value.type
  zone_id = aws_route53_record.subdomain.zone_id
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "validated_cert_using_terraform" {
  certificate_arn         = aws_acm_certificate.cert-using-terraform.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

resource "aws_lb_listener" "https_listener_using_terraform" {
  load_balancer_arn = aws_lb.new-lb-using-terraform.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.validated_cert_using_terraform.certificate_arn
  
  default_action {
    type = "fixed-response"
    
    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }
}

resource "aws_internet_gateway" "igw-using-terraform" {
  vpc_id = aws_vpc.vpc-using-terraform.id 
}

resource "aws_route_table" "route-table-using-terraform" {
  vpc_id = aws_vpc.vpc-using-terraform.id  
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-using-terraform.id
  }
}

resource "aws_vpc" "vpc-using-terraform" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet-using-terraform" {
  vpc_id            = aws_vpc.vpc-using-terraform.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet-using-terraform2" {
  vpc_id            = aws_vpc.vpc-using-terraform.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_route_table_association" "route-table-association-using-terraform" {
  subnet_id      = aws_subnet.subnet-using-terraform2.id
  route_table_id = aws_route_table.route-table-using-terraform.id
}

resource "aws_lb" "new-lb-using-terraform" {
  name                       = "new-lb-using-terraform"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.new-sg-using-terraform.id]
  enable_deletion_protection = false
  subnets                    = [aws_subnet.subnet-using-terraform.id, aws_subnet.subnet-using-terraform2.id]
}

resource "aws_security_group" "new-sg-using-terraform" {
  name        = "new-sg-using-terraform"
  description = "Allows traffic from corporate IPs and VPN"
  vpc_id      = aws_vpc.vpc-using-terraform.id
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
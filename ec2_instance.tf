variable "allowed_ips" {
  description = "IP CIDR blocks that are allowed access to the resources"
  type        = list(string)
  default     = ["203.0.113.0/32", "203.0.114.0/32"]  # Have to be replaced with actual corporate and VPN IP
}

# resource "aws_ami_launch_permission" "ami_share_from_terraform" {
#   image_id      = var.ami_id
#   account_id    = var.target_account_id
# }

resource "aws_instance" "example_instance_from_terraform" {
  ami           = var.example_ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet-using-terraform2.id
  vpc_security_group_ids = [aws_security_group.new-sg-using-terraform.id]
  associate_public_ip_address = true

  tags = {
    Name = "ExampleInstanceFromTerraform"
  }
}

resource "aws_instance" "new_posit_instance_from_terraform" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet-using-terraform.id
  vpc_security_group_ids = [aws_security_group.new-sg-using-terraform.id]
  associate_public_ip_address = true

  tags = {
    Name = "PositAMIInstance"
  }
}

resource "aws_route53_record" "subdomain" {
  zone_id = var.route53_zone_id 
  name    = var.subdomain_name
  type    = var.record_type
  ttl     = var.ttl
  records = [aws_instance.example_instance_from_terraform.public_ip, aws_instance.new_posit_instance_from_terraform.public_ip]

  # alias {
  #   name                   = aws_lb.new-lb-using-terraform.dns_name
  #   zone_id                = aws_lb.new-lb-using-terraform.zone_id
  #   evaluate_target_health = false
  # }
  # records = [aws_instance.example_instance_from_terraform.public_ip, aws_lb.new-lb-using-terraform.dns_name]
}

resource "aws_acm_certificate" "cert-using-terraform" {
  domain_name       = var.domain_name
  validation_method = var.acm_validation_method

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

# resource "aws_lb_listener" "https_listener_using_terraform" {
#   load_balancer_arn = aws_lb.new-lb-using-terraform.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = var.ssl_policy
#   certificate_arn   = aws_acm_certificate_validation.validated_cert_using_terraform.certificate_arn
  
#   default_action {
#     type = "fixed-response"
    
#     fixed_response {
#       content_type = "text/plain"
#       message_body = "OK"
#       status_code  = "200"
#     }
#   }
# }

resource "aws_lb_listener" "https_listener_using_terraform" {
  load_balancer_arn = aws_lb.new-lb-using-terraform.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = aws_acm_certificate_validation.validated_cert_using_terraform.certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.new-tg-using-terraform.arn
  }
}


resource "aws_internet_gateway" "igw-using-terraform" {
  vpc_id = aws_vpc.vpc-using-terraform.id 
}

resource "aws_route_table" "route-table-using-terraform" {
  vpc_id = aws_vpc.vpc-using-terraform.id  
  
  route {
    cidr_block = var.igw_cidr_block
    gateway_id = aws_internet_gateway.igw-using-terraform.id
  }
}

resource "aws_vpc" "vpc-using-terraform" {
  cidr_block = var.vpc_cidr_block
}

resource "aws_subnet" "subnet-using-terraform" {
  vpc_id            = aws_vpc.vpc-using-terraform.id
  cidr_block        = var.first_subnet_cidr_block
  availability_zone = var.first_subnet_az
}

resource "aws_subnet" "subnet-using-terraform2" {
  vpc_id            = aws_vpc.vpc-using-terraform.id
  cidr_block        = var.second_subnet_cidr_block
  availability_zone = var.second_subnet_az
}

resource "aws_route_table_association" "route-table-association-using-terraform" {
  subnet_id      = aws_subnet.subnet-using-terraform2.id
  route_table_id = aws_route_table.route-table-using-terraform.id
}

resource "aws_lb" "new-lb-using-terraform" {
  name                       = "new-lb-using-terraform"
  internal                   = false
  load_balancer_type         = var.lb_type
  security_groups            = [aws_security_group.new-sg-using-terraform.id]
  enable_deletion_protection = false
  subnets                    = [aws_subnet.subnet-using-terraform.id, aws_subnet.subnet-using-terraform2.id]
}

resource "aws_lb_target_group" "new-tg-using-terraform" {
  name     = "new-tg-using-terraform"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc-using-terraform.id
}

resource "aws_lb_target_group_attachment" "attach_instance_to_tg" {
  target_group_arn = aws_lb_target_group.new-tg-using-terraform.arn
  # target_id        = aws_instance.new_posit_instance_from_terraform.id
  target_id        = aws_instance.example_instance_from_terraform.id
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
    cidr_blocks = [var.igw_cidr_block]
  }
}
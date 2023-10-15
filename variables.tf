variable "subnet_ids" {
  description = "The subnet IDs for the load balancer"
  type        = list(string)
}

variable "vpc_id" {
  description = "The VPC ID where the security group will be created"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the ACM certificate"
  type        = string
}

variable "route53_zone_id" {
  description = "The Route53 Zone ID"
  type        = string
}
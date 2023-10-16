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

variable "ami_id" {
  type        = string
  description = "The ID of the AMI to share"
  default     = "ami-0557a15b87f6559cf"
}

variable "target_account_id" {
  type        = string
  description = "The AWS account ID to which to share the AMI" 
}
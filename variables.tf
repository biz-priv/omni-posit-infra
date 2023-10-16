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

variable "ssl_policy" {
  type        = string
  description = "The SSL policy of the ELB"
}

variable "acm_validation_method" {
  type        = string
  description = "ACM validation method"
}

variable "subdomain_name" {
  type        = string
  description = "The name of the subdomain"
}

variable "record_type" {
  type        = string
  description = "The type of the record"
}

variable "ttl" {
  type        = string
  description = "time to live"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The cidr block of the vpc"
}

variable "first_subnet_cidr_block" {
  type        = string
  description = "The cidr block of the first subnet"
}

variable "second_subnet_cidr_block" {
  type        = string
  description = "The cidr block of the second subnet"
}

variable "first_subnet_az" {
  type        = string
  description = "The availability zone of the first subnet"
}

variable "second_subnet_az" {
  type        = string
  description = "The availability zone of the second subnet"
}

variable "igw_cidr_block" {
  type        = string
  description = "The cidr block for igw"
}

variable "lb_type" {
  type        = string
  description = "Load balancer type"
}





variable "dns_zone_id" {
  description = "Route53 hosted zone ID from DNS infrastructure"
  type        = string
}

variable "dns_certificate_arn_regional" {
  description = "Regional ACM certificate ARN from DNS infrastructure"
  type        = string
}

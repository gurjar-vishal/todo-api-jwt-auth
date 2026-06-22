variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "db_url" {
  description = "PostgreSQL connection string for RDS"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Secret key used to sign JWTs"
  type        = string
  sensitive   = true
}

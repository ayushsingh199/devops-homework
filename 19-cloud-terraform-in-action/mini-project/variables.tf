variable "aws_region" {
  description = "AWS region for the Session 19 infrastructure."
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for app data."
  type        = string
  default     = "ayush-devops-homework-session19-data"
}

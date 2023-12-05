variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "Name of lambda function as seen in the console"
  type        = string
  default     = "myDNDtest_func1123"
}

variable "accountID" {
  description = "AWS acc ID"
  type        = string
}

variable "endpoint_path" {
  description = "e.g apigw/paladinTest aka GET endpoint"
  type        = string
  default     = "paladinTest"
}

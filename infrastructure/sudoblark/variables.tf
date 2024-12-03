variable "environment" {
  description = "Which environment this is being instantiated in."
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Must be either dev, test or prod"
  }
  default = "prod"
}

variable "application_name" {
  description = "Name of the application utilising the resource resource."
  type        = string
  default     = "monsternames-api"
}
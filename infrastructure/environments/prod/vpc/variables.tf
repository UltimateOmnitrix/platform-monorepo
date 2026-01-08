variable "project_id" { type = string }
variable "region" { type = string }

variable "github_repo" {
  type        = string
  description = "The GitHub repository (passed by tfvars but not used by VPC)"
  default     = "" # Optional: prevents errors if not passed
}

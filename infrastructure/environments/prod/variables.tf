variable "project_id" {
  type = string
}

# YOU MUST ADD THIS BLOCK HERE
variable "github_repo" {
  description = "The GitHub repository to trust for WIF"
  type        = string
}

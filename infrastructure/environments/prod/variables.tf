variable "project_id" {
  type        = string
  description = "The GCP Project ID"
}
variable "github_repo" {
  description = "The GitHub repository to trust for WIF"
  type        = string
} # Matches the module's input

# Provide 
provider "google" {
  credentials = file("token.json")
  project     = var.project_name
  region      = var.region
  zone        = var.zone
}

# Configure the backend
terraform {
  backend "gcs" {
    bucket      = var.bucket_name
    prefix      = "terraform/state"
    credentials = "token.json"
  }
}
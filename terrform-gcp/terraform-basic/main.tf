terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.6.0"
    }
  }
}

provider "google" {
  # Credentials only needs to be set if you do not have the GOOGLE_APPLICATION_CREDENTIALS set
  #  credentials = 
  project = "de-zoomcamp2025-448100"
  region  = "us-central1"
}

resource "google_storage_bucket" "suman-bucket" {
  name          = "dezoomcamp-bucket2025"
  location      = "US"
  force_destroy = true

  # Optional, but recommended settings:
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  // versioning {
  //   enabled = true
  // }

  lifecycle_rule {
    action {
      //type = "Delete"
      type = "AbortIncompleteMultipartUpload"
    }
    condition {
      age = 1 // days
    }
  }
}
resource "google_bigquery_dataset" "demo_dataset" {
    dataset_id = "demo_dataset"
}
 
resource "google_storage_bucket_object" "demo_file" {
    name   = "demo_file.txt"
    bucket = google_storage_bucket.suman-bucket.name
    source = "./suman-demofile.txt"
}  
  



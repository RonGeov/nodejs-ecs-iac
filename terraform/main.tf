terraform {
  backend "s3" {
    bucket         = "terraform-test-iac1234-bucket" // Specify your S3 bucket name
    key            = "terraform.tfstate"           // Specify the name for the state file in the bucket
    region         = "ap-south-1"                   // Specify the region of your S3 bucket
  }
}

# Terraform Project to implment AWS data pipeline services (S3, Glue, Crawler and Athena) to analyze NYC Trip data using Athena service

### This project is developed as a part of my terraform a Infrastructure as a Code(IaaC) knowledge learning.

### I have used NYC Trip data in the form of parquet. You can find the data [here](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page).

<br>

### Project Overview

👉 &nbsp; This project contains terrform script to create AWS services on cloud as a part of Infrastructre as a Code. Please find below steps that that are performed in this script

👉 &nbsp; Created S3 bucket and load NYC trip data inside the bucket

👉 &nbsp; Created AWS Glue Catalog or Database so that Glue Crawler will craw the NYC Trip data and create table for schema inside the DB

👉 &nbsp; Created a IAM role which will assume GlueSericeRole, which is required to access S3 objects, creating a glue crawler and crawling data from S3 to create schema table under Glue database

👉 &nbsp; Created S3 access policy which will be assigned to IAM role that we have created in above step.

👉 &nbsp; Attached GlueSericeRolePolicy and our cusstom S3 policy to IAM Glue role that we created.

👉 &nbsp; Finally created a Glue Crawler which will crawl the data from S3 locationn and create a table for schema inside the database.

<br>

## Tech stack

- HashiCorp Terraform
- AWS CLI
- Visual Studio Code
- AWS Glue
- AWS S3
- AWS Athena

<br>

## Prerequisiites

- Terraform
- Active AWS account
- AWS CLI installed (make sure you have setup a profile with your access key and secret acsess key)

<br>

## Project Walkthrough

### Provider Configuration

```hcl
provider "aws" {
    region = "us-east-2"
    profile = "default"
}
```

Configures the AWS provider to use the us-east-2 region and the default AWS CLI profile for authentication.

### S3 Bucket Configuration

```hcl
resource "aws_s3_bucket" "aws_s3_bucket_demo" {
    bucket = "amz-s3-tf-001-${random_id.random_id_genarator.hex}"
    tags = {
        project_type = "dev"
    }
}
```

Creates an S3 bucket with a unique name using the generated random ID. The bucket is tagged with project_type = "dev".

### S3 Object Configuration

```hcl
resource "aws_s3_object" "nyc_data" {
    bucket = aws_s3_bucket.aws_s3_bucket_demo.id
    key = "data/yellow_tripdata_2023-01.parquet"
    source = "./data/yellow_tripdata_2023-01.parquet"

    tags = {
        project_type = "dev"
    }
}
```

Uploads a Parquet file containing NYC taxi trip data to the S3 bucket under the key data/yellow_tripdata_2023-01.parquet. Tags the object with project_type = "dev".

### Glue Catalog Database Configuration

```hcl
resource "aws_glue_catalog_database" "taxitrip_db" {
    name = "taxitripdb"
}
```

Creates a Glue catalog database named taxitripdb.

### IAM Role for Glue Crawler

```hcl
resource "aws_iam_role" "glue_crawler_role" {
    name = "taxitriptfrole"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
```

Creates an IAM role named taxitriptfrole with a trust policy that allows AWS Glue to assume the role.

### IAM Policy for S3 Access

```hcl
resource "aws_iam_policy" "glue_crwaler_policy_access_s3" {
    name = "gluecrwaleraccesss3tripdata"
    path = "/"
    description = "this policy gives glue crawler access to S3"

    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Resource": [
            "${aws_s3_bucket.aws_s3_bucket_demo.arn}/data/*"
        ]
      }
  ]
  })
}
```

Defines an IAM policy named gluecrwaleraccesss3tripdata that grants the Glue crawler permission to get and put objects in the specified S3 bucket path.

### Attach Policies to IAM Role

```hcl
resource "aws_iam_role_policy_attachment" "attaching_srvice_role" {
    role = aws_iam_role.glue_crawler_role.id
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "attaching_s3_policy" {
    role = aws_iam_role.glue_crawler_role.id
    policy_arn = aws_iam_policy.glue_crwaler_policy_access_s3.arn
}
```

Attaches the AWS managed Glue service role policy and the custom S3 access policy to the IAM role.

### Glue Crawler Configuration

```hcl
resource "aws_glue_crawler" "trip_data_crawler" {
    name = "trip_data_crawler"
    role = aws_iam_role.glue_crawler_role.id
    database_name = aws_glue_catalog_database.taxitrip_db.name
    table_prefix = "NYC_taxi_trip_"
    s3_target {
        path = "s3://${aws_s3_bucket.aws_s3_bucket_demo.id}/data"
    }

    tags = {
        project_type = "taxi_trip_analysis"
    }
}
```

Creates a Glue crawler named trip*data_crawler that uses the specified IAM role. It targets the S3 path for the data and stores the metadata in the Glue database with a table prefix NYC_taxi_trip*.

## Run this script as below

### First Initialize the terraform using below command

```hcl
terraform init
```

### Now run,below command to allow terraform to create above services on AWS cloud.

```hcl
terraform apply --auto-approve
```

## Note

- The script uses the jsonencode function to create the JSON structure for the IAM policy.

- The random_id resource ensures the S3 bucket name is unique, preventing naming conflicts.

Data file has been deleted since file size exceeded for github push. You can find the lnk for dataset in description.

## Referance/Tutorial that I followed

- [Tutorial](https://www.youtube.com/watch?v=cx4_nl0CfbQ&list=PL4frYFvCedZaro8HeiymxSkmg6zrjnQsb&index=7)

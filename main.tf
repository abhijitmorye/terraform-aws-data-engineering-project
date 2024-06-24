provider "aws" {
    region = "us-east-2"
    profile = "default"
}

resource "random_id" "random_id_genarator" {
    byte_length = 8
}

resource "aws_s3_bucket" "aws_s3_bucket_demo" {
    bucket = "amz-s3-tf-001-${random_id.random_id_genarator.hex}"
    tags = { 
        project_type = "dev"
    }

}

resource "aws_s3_object" "nyc_data" {
    bucket = aws_s3_bucket.aws_s3_bucket_demo.id
    key = "data/yellow_tripdata_2023-01.parquet"
    source = "./data/yellow_tripdata_2023-01.parquet"

    tags = {
        project_type = "dev"
    }
}

resource "aws_glue_catalog_database" "taxitrip_db" {
    name = "taxitripdb"
}

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

resource "aws_iam_role_policy_attachment" "attaching_srvice_role" {
    role = aws_iam_role.glue_crawler_role.id
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "attaching_s3_policy" {
    role = aws_iam_role.glue_crawler_role.id 
    policy_arn = aws_iam_policy.glue_crwaler_policy_access_s3.arn
  
}

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

# resource "aws_athena_workgroup" "taxi_trip_analysis_workgroup" {

#     name = "taxi_trip_analysis_workgroup"
#     force_destroy = true 

#     configuration {
#       result_configuration {
#         output_location = "s3://${aws_s3_bucket.aws_s3_bucket_demo.id}/queryresults"
#       }
#     }
  
# }
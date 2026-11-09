# Assertions on the data module's outputs: naming, defaults and the
# cross-references infrastructure.tf resolves. The AWS provider is mocked,
# so this runs without credentials.

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name   = "eu-west-2"
      region = "eu-west-2"
    }
  }
}

variables {
  dns_zone_id                  = "Z0123456789TESTZONE"
  dns_certificate_arn_regional = "arn:aws:acm:eu-west-2:123456789012:certificate/test"
}

run "buckets" {
  command = plan

  assert {
    condition     = output.buckets_map["assets"].full_name == "aws-sudoblark-production-monsternames-api-assets"
    error_message = "Bucket names must carry the account-project-application prefix."
  }

  assert {
    condition     = output.buckets_map["assets"].arn == "arn:aws:s3:::aws-sudoblark-production-monsternames-api-assets"
    error_message = "Bucket ARNs must be computed from the full name."
  }

  assert {
    condition     = output.buckets_map["assets"].days_retention == null
    error_message = "The assets bucket holds the Swagger docs, so its objects must never expire."
  }

  assert {
    condition     = output.buckets_map["assets"].versioning == false
    error_message = "The assets bucket must not be versioned, matching its CKV_AWS_21 skip."
  }

  assert {
    condition     = output.buckets_map["assets"].multipart_retention == 7
    error_message = "Buckets must default to aborting incomplete multipart uploads after 7 days."
  }
}

run "iam_roles" {
  command = plan

  assert {
    condition     = output.iam_roles_map["backend-lambda"].arn == "arn:aws:iam::123456789012:role/aws-sudoblark-production-monsternames-api-backend-lambda"
    error_message = "Role ARNs must be computed from the account ID and full name."
  }

  assert {
    condition = (
      output.iam_roles_map["api-gateway"].policy_statements[0].resources == ["arn:aws:s3:::aws-sudoblark-production-monsternames-api-assets"] &&
      output.iam_roles_map["api-gateway"].policy_statements[1].resources == ["arn:aws:s3:::aws-sudoblark-production-monsternames-api-assets/*"]
    )
    error_message = "Bucket short names in policy resources must resolve to bucket ARNs."
  }

  assert {
    condition = one([
      for statement in output.iam_roles_map["backend-lambda"].policy_statements : statement.resources
      if statement.sid == "AllowCloudWatchLogs"
    ]) == ["arn:aws:logs:eu-west-2:123456789012:log-group:/aws/lambda/aws-sudoblark-production-monsternames-api-*"]
    error_message = "logs:* must resolve to this project's Lambda log groups."
  }

  assert {
    condition = one([
      for statement in output.iam_roles_map["backend-lambda"].policy_statements : statement.resources
      if statement.sid == "AllowReadWriteNameTables"
    ]) == [for table in output.dynamodb_tables : table.arn]
    error_message = "dynamodb:* must resolve to exactly the tables in dynamodb_tables.tf."
  }
}

run "dynamodb_tables" {
  command = plan

  assert {
    condition     = output.dynamodb_tables_map["goblin-first-name"].full_name == "aws-sudoblark-production-monsternames-api-goblin-first-name"
    error_message = "Table names must carry the account-project-application prefix."
  }

  assert {
    condition     = output.dynamodb_tables_map["goblin-first-name"].arn == "arn:aws:dynamodb:eu-west-2:123456789012:table/aws-sudoblark-production-monsternames-api-goblin-first-name"
    error_message = "Table ARNs must be computed from the region, account ID and full name."
  }

  assert {
    condition     = sum([for table in output.dynamodb_tables : length(table.items)]) == 320
    error_message = "Every name in application/seed_data must load as a seed item."
  }

  assert {
    condition     = contains(output.dynamodb_tables_map["skeleton-first-name"].items, "Reginald")
    error_message = "Seed items must be the values in the table's JSON file."
  }
}

run "lambdas" {
  command = plan

  assert {
    condition     = output.lambdas_map["backend"].function_name == "aws-sudoblark-production-monsternames-api-backend"
    error_message = "Lambda function names must carry the account-project-application prefix."
  }

  assert {
    condition     = output.lambdas_map["backend"].role_arn == output.iam_roles_map["backend-lambda"].arn
    error_message = "role_name must resolve to the role's ARN."
  }

  assert {
    condition     = output.lambdas_map["backend"].lambda_layers == ["arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPythonV2:73"]
    error_message = "powertools-python must resolve to the Powertools layer ARN in this region."
  }

  assert {
    condition     = output.lambdas_map["backend"].timeout <= 29
    error_message = "The backend Lambda must not outlive API Gateway's 29-second integration timeout."
  }

  assert {
    condition     = output.lambdas_map["backend"].environment_variables["LOG_LEVEL"] == "INFO"
    error_message = "Production must log at INFO, so request data stays out of CloudWatch."
  }
}

run "api_gateways" {
  command = plan

  assert {
    condition     = output.api_gateways_map["backend"].full_name == "aws-sudoblark-production-monsternames-api-backend"
    error_message = "API names must carry the account-project-application prefix."
  }

  assert {
    condition     = output.api_gateways_map["backend"].allowed_lambda_function_names == [output.lambdas_map["backend"].function_name]
    error_message = "allowed_lambda_names must resolve to Lambda function names."
  }

  assert {
    condition = output.api_gateways_map["backend"].template_variables == {
      backend_lambda_arn       = output.lambdas_map["backend"].arn
      aws_region_name          = "eu-west-2"
      asset_bucket_name        = output.buckets_map["assets"].full_name
      swagger_index_path       = "swagger_ui/index.html"
      api_gateway_iam_role_arn = output.iam_roles_map["api-gateway"].arn
    }
    error_message = "OpenAPI template variables must resolve to real ARNs, names and the region."
  }

  assert {
    condition = output.api_gateways_map["backend"].custom_domain == {
      domain_name     = "monsternames.sudoblark.com"
      certificate_arn = var.dns_certificate_arn_regional
    }
    error_message = "subdomain_name must resolve to a sudoblark.com domain with the regional certificate."
  }
}

run "s3_files" {
  command = plan

  assert {
    condition = alltrue([
      for file in output.s3_files : file.bucket_id == output.buckets_map[file.bucket_name].full_name
    ])
    error_message = "bucket_name must resolve to the bucket's full name."
  }
}

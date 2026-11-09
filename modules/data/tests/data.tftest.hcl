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
      if statement.sid == "AllowReadNameTables"
    ]) == [for table in output.dynamodb_tables : table.arn]
    error_message = "dynamodb:* must resolve to exactly the tables in dynamodb_tables.tf."
  }

  assert {
    condition = flatten([
      for statement in output.iam_roles_map["backend-lambda"].policy_statements : statement.actions
      if startswith(statement.actions[0], "dynamodb:")
    ]) == ["dynamodb:Scan"]
    error_message = "The API is read-only, so the backend may only Scan its tables."
  }
}

run "dynamodb_tables" {
  command = plan

  assert {
    condition = sort(keys(output.dynamodb_tables_map)) == tolist([
      "goatmen-first-name", "goblin-first-name", "goblin-last-name", "ogre-first-name",
      "orc-first-name", "orc-last-name", "skeleton-first-name", "skeleton-last-name",
      "troll-first-name", "troll-last-name",
    ])
    error_message = "Each monster in monsters.tf must get one table per name list, and no others."
  }

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

  assert {
    condition = jsondecode(output.lambdas_map["backend"].environment_variables["MONSTER_TABLES"]) == {
      for monster in ["goatmen", "goblin", "ogre", "orc", "skeleton", "troll"] : monster => {
        first_name = output.dynamodb_tables_map["${monster}-first-name"].full_name
        last_name  = try(output.dynamodb_tables_map["${monster}-last-name"].full_name, null)
      }
    }
    error_message = "MONSTER_TABLES must map every monster to its tables' full names."
  }

  assert {
    condition     = jsondecode(output.lambdas_map["backend"].environment_variables["MONSTER_TABLES"])["goatmen"].last_name == null
    error_message = "A monster without last names must have a null last_name table."
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
    condition     = output.api_gateways_map["backend"].api_keys == []
    error_message = "The API is read-only, so it has no API keys."
  }

  assert {
    condition = {
      for key, value in output.api_gateways_map["backend"].template_variables : key => value
      if !contains(["monsters", "include_integrations"], key)
      } == {
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

run "openapi_spec" {
  command = plan

  variables {
    monster_paths = ["/goatmen", "/goblin", "/ogre", "/orc", "/skeleton", "/troll"]
  }

  assert {
    condition = sort(keys(yamldecode(templatefile(
      output.api_gateways_map["backend"].openapi_spec_path,
      output.api_gateways_map["backend"].template_variables
    )).paths)) == sort(concat(["/", "/openapi"], var.monster_paths))
    error_message = "The API's spec must have a path for every monster in monsters.tf, plus / and /openapi."
  }

  assert {
    condition = alltrue([
      for path in var.monster_paths : strcontains(
        yamldecode(templatefile(
          output.api_gateways_map["backend"].openapi_spec_path,
          output.api_gateways_map["backend"].template_variables
        )).paths[path].get["x-amazon-apigateway-integration"].uri,
        output.lambdas_map["backend"].arn
      )
    ])
    error_message = "Every monster path in the API's spec must invoke the backend Lambda."
  }

  assert {
    condition = [
      for tag in yamldecode(templatefile(
        output.api_gateways_map["backend"].openapi_spec_path,
        output.api_gateways_map["backend"].template_variables
      )).tags : tag.name
    ] == ["goatmen", "goblin", "ogre", "orc", "skeleton", "troll"]
    error_message = "The spec must have a tag for every monster in monsters.tf."
  }

  assert {
    condition = (
      yamldecode(templatefile(
        output.api_gateways_map["backend"].openapi_spec_path,
        output.api_gateways_map["backend"].template_variables
      )).paths["/goatmen"].get.responses["200"]["$ref"] == "#/components/responses/200GetFirstName" &&
      yamldecode(templatefile(
        output.api_gateways_map["backend"].openapi_spec_path,
        output.api_gateways_map["backend"].template_variables
      )).paths["/goblin"].get.responses["200"]["$ref"] == "#/components/responses/200GetFirstAndLastName"
    )
    error_message = "A monster's 200 response must include last_name only when it has last names."
  }

  assert {
    condition = sort(keys(yamldecode(templatefile(
      output.s3_files_map["openapi-spec"].source_path,
      output.s3_files_map["openapi-spec"].template_variables
    )).paths)) == sort(concat(["/", "/openapi"], var.monster_paths))
    error_message = "The public spec must document the same paths as the API's."
  }

  assert {
    condition = alltrue([
      for path, operations in yamldecode(templatefile(
        output.s3_files_map["openapi-spec"].source_path,
        output.s3_files_map["openapi-spec"].template_variables
      )).paths : !contains(keys(operations.get), "x-amazon-apigateway-integration")
    ])
    error_message = "The public spec at /openapi must not publish integration blocks."
  }

  assert {
    condition = !strcontains(templatefile(
      output.s3_files_map["openapi-spec"].source_path,
      output.s3_files_map["openapi-spec"].template_variables
    ), "arn:aws:")
    error_message = "The public spec at /openapi must not publish any ARNs."
  }
}

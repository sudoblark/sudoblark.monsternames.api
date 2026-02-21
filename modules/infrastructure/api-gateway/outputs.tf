output "api_gateways" {
  description = "Map of created API Gateways with their attributes"
  value = {
    for name, api in aws_api_gateway_rest_api.api : name => {
      id               = api.id
      arn              = api.arn
      name             = api.name
      root_resource_id = api.root_resource_id
      execution_arn    = api.execution_arn
      created_date     = api.created_date
    }
  }
}

output "api_gateway_stages" {
  description = "Map of API Gateway stages"
  value = {
    for name, stage in aws_api_gateway_stage.production : name => {
      id            = stage.id
      arn           = stage.arn
      invoke_url    = stage.invoke_url
      execution_arn = stage.execution_arn
    }
  }
}

output "api_gateway_urls" {
  description = "Map of API Gateway invoke URLs"
  value = {
    for name, stage in aws_api_gateway_stage.production : name => stage.invoke_url
  }
}

output "api_keys" {
  description = "Map of created API keys"
  value = {
    for key, api_key in aws_api_gateway_api_key.keys : key => {
      id    = api_key.id
      value = api_key.value
      name  = api_key.name
    }
  }
  sensitive = true
}

output "custom_domains" {
  description = "Map of custom domain configurations"
  value = {
    for name, domain in aws_api_gateway_domain_name.custom_domain : name => {
      domain_name                   = domain.domain_name
      regional_domain_name          = domain.regional_domain_name
      regional_hosted_zone_id       = domain.regional_hosted_zone_id
      cloudfront_domain_name        = domain.cloudfront_domain_name
      cloudfront_zone_id            = domain.cloudfront_zone_id
      certificate_arn               = domain.regional_certificate_arn
    }
  }
}

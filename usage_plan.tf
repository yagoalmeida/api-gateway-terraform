variable "usage_plan_name" {
  default = "usage-plan-api-test"
}
resource "aws_api_gateway_usage_plan" "api-test-usage-plan" {
  depends_on  = [aws_api_gateway_rest_api.api-test, aws_api_gateway_stage.api-test]
  name        = "usage-plan-api-test"
  description = "usage-plan-api-test"

  api_stages {
    api_id = aws_api_gateway_rest_api.api-test.id
    stage  = aws_api_gateway_stage.api-test.stage_name
  }

  quota_settings {
    limit  = 100
    offset = 2
    period = "WEEK"
  }

  throttle_settings {
    burst_limit = 5
    rate_limit  = 10
  }
}
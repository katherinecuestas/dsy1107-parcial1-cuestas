data "archive_file" "pretoken_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/pretoken.js"
  output_path = "${path.module}/lambda/pretoken.zip"
}

resource "aws_lambda_function" "pretoken_scopes" {
  function_name    = "pretoken-scopes-parcial1-dsy1107-${var.estudiante}"
  filename         = data.archive_file.pretoken_zip.output_path
  source_code_hash = data.archive_file.pretoken_zip.output_base64sha256
  handler          = "pretoken.handler"
  runtime          = "nodejs20.x"
  role             = "arn:aws:iam::${data.aws_caller_identity.actual.account_id}:role/LabRole"
  timeout          = 5
}

resource "aws_lambda_permission" "cognito_invoca_pretoken" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pretoken_scopes.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.pool.arn
}

locals {
  url_amplify = "https://${aws_amplify_branch.main.branch_name}.${aws_amplify_app.front.default_domain}"
}

locals {
  dominio_hosted_ui = var.cognito_dominio != "" ? var.cognito_dominio : "dsy1107-ng-${var.estudiante}"
}

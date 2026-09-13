# =============================================================================
# Outputs — valores que Terraform imprime despues de aplicar, para no tener
# que ir a buscarlos a mano en la consola de AWS cada vez que se necesitan.
# =============================================================================

output "user_pool_id" {
  description = "Identificador del User Pool."
  value       = aws_cognito_user_pool.pool.id
}

output "client_id" {
  description = "Client ID de la SPA. Tu backend lo valida contra el claim client_id del access_token."
  value       = aws_cognito_user_pool_client.spa.id
}

output "dominio_cognito" {
  description = "Dominio del Hosted UI: aqui viven /oauth2/authorize, /oauth2/token y /oauth2/userInfo."
  value       = "https://${aws_cognito_user_pool_domain.hosted_ui.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "issuer" {
  description = "Emisor de los tokens. Tu SecurityConfig.java lo usa como issuer-uri."
  value       = "https://${aws_cognito_user_pool.pool.endpoint}"
}

output "discovery_url" {
  description = "Documento de descubrimiento OIDC, con todos los endpoints declarados."
  value       = "https://${aws_cognito_user_pool.pool.endpoint}/.well-known/openid-configuration"
}

output "jwks_url" {
  description = "Claves publicas con las que se verifica la firma de cada token."
  value       = "https://${aws_cognito_user_pool.pool.endpoint}/.well-known/jwks.json"
}

output "url_userinfo" {
  description = "Endpoint /userInfo de OIDC: la identidad del usuario segun Cognito."
  value       = "https://${aws_cognito_user_pool_domain.hosted_ui.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/userInfo"
}

output "usuario_demo_solicitante" {
  description = "Correo del usuario de prueba con rol solicitante."
  value       = aws_cognito_user.solicitante_demo.username
}

output "usuario_demo_aprobador" {
  description = "Correo del usuario de prueba con rol aprobador."
  value       = aws_cognito_user.aprobador_demo.username
}

# -----------------------------------------------------------------------------
# Configuracion lista para el frontend Angular. Angular no lee variables de
# entorno del navegador, asi que la app hace fetch de un config.json estatico
# al arrancar. Nada de esto es secreto: el client_id de una SPA es publico,
# lo que protege el flujo es PKCE.
#
#     terraform output -raw config_frontend > ../frontend/public/config.json
# -----------------------------------------------------------------------------

output "config_frontend" {
  description = "Contenido listo para frontend/public/config.json en local (localhost:4200)."
  value       = <<-EOT
    {
      "region": "${var.aws_region}",
      "cognitoDomain": "https://${aws_cognito_user_pool_domain.hosted_ui.domain}.auth.${var.aws_region}.amazoncognito.com",
      "clientId": "${aws_cognito_user_pool_client.spa.id}",
      "redirectUri": "${var.callback_urls[0]}",
      "apiUrl": "${aws_apigatewayv2_api.api.api_endpoint}"
    }
  EOT
}

# El gemelo de config_frontend para el build que se sube a Amplify. La unica
# diferencia es redirectUri: alla el front vive en el dominio de Amplify, no
# en localhost. Subir el build con el config de localhost es el fallo mas
# comun del despliegue: Cognito corta en /authorize con redirect_mismatch.
output "config_frontend_hosted" {
  description = "Contenido de public/config.json para el build que se publica en Amplify."
  value       = <<-EOT
    {
      "region": "${var.aws_region}",
      "cognitoDomain": "https://${aws_cognito_user_pool_domain.hosted_ui.domain}.auth.${var.aws_region}.amazoncognito.com",
      "clientId": "${aws_cognito_user_pool_client.spa.id}",
      "redirectUri": "${local.url_amplify}/",
      "apiUrl": "${aws_apigatewayv2_api.api.api_endpoint}"
    }
  EOT
}

output "url_solicitudes" {
  description = "Ruta protegida de solicitudes. Sin Authorization: Bearer <token> responde 401."
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/solicitudes"
}

output "probar_sin_token" {
  description = "Debe responder 401 — la mitad del ejercicio de seguridad."
  value       = "curl -s -o /dev/null -w 'HTTP %%{http_code}\\n' ${aws_apigatewayv2_api.api.api_endpoint}/solicitudes"
}

# -----------------------------------------------------------------------------
# Identificadores que consume scripts/publicar-ecs.sh para reapuntar las
# integraciones despues de cada despliegue. Sin balanceador, la IP de la task
# cambia cada vez y el script es quien la actualiza — hay que reapuntar las
# DOS integraciones de solicitudes, no solo una.
# -----------------------------------------------------------------------------

output "api_id" {
  description = "Id del HTTP API. Lo lee publicar-ecs.sh."
  value       = aws_apigatewayv2_api.api.id
}

output "integracion_solicitudes_coleccion_id" {
  description = "Id de la integracion de /solicitudes (GET, POST). Lo lee publicar-ecs.sh."
  value       = aws_apigatewayv2_integration.solicitudes_coleccion.id
}

output "integracion_solicitudes_elemento_id" {
  description = "Id de la integracion de /solicitudes/{id} y sus sub-rutas (editar, aprobar, rechazar, cancelar). Lo lee publicar-ecs.sh."
  value       = aws_apigatewayv2_integration.solicitudes_elemento.id
}

# -----------------------------------------------------------------------------
# La Lambda de scopes: util para depurarla desde la consola de AWS o desde la
# CLI sin tener que ir a buscar el ARN a mano.
# -----------------------------------------------------------------------------

output "lambda_pretoken_arn" {
  description = "ARN de la Lambda de pre-token trigger. Sirve para revisar sus logs en CloudWatch."
  value       = aws_lambda_function.pretoken_scopes.arn
}

output "lambda_pretoken_logs" {
  description = "Comando para ver los logs de la Lambda en vivo."
  value       = "aws logs tail /aws/lambda/${aws_lambda_function.pretoken_scopes.function_name} --follow"
}

resource "aws_apigatewayv2_api" "api" {
  name          = "api-parcial1-dsy1107-${var.estudiante}"
  protocol_type = "HTTP"
  description   = "DSY1107 1.2.9 (Angular) - mindicador.cl protegido con Cognito"

  # Sin esto el navegador bloquea la respuesta por Same-Origin Policy, aunque
  # la API responda 200. Postman no lo nota; el front si.
  cors_configuration {
    # El origen de Amplify va SIN barra final: un header Origin nunca la lleva.
    # Es el error espejo del de callback_urls, que si la exige.
    allow_origins = concat(var.origenes_frontend, [local.url_amplify])
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]

    # "authorization" es el header que obliga al preflight OPTIONS. Si falta
    # aqui, el navegador cancela la peticion antes de enviarla.
    allow_headers = ["authorization", "content-type"]
    max_age       = 300
  }
}


resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.api.id
  name             = "cognito-jwt"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    # El access token de Cognito no trae claim "aud" sino "client_id".
    # API Gateway compara contra este valor de todas formas.
    audience = [aws_cognito_user_pool_client.spa.id]

    # .endpoint devuelve "cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXX",
    # sin esquema. El issuer del token lo lleva, por eso se antepone https://.
    issuer = "https://${aws_cognito_user_pool.pool.endpoint}"
  }
}

resource "aws_apigatewayv2_integration" "solicitudes_coleccion" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://52.91.255.143:8080/solicitudes"
  payload_format_version = "1.0"

  lifecycle {
    ignore_changes = [integration_uri]
  }
}

resource "aws_apigatewayv2_integration" "solicitudes_elemento" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://52.91.255.143:8080/solicitudes/{proxy}"
  payload_format_version = "1.0"

  lifecycle {
    ignore_changes = [integration_uri]
  }
}

resource "aws_apigatewayv2_route" "solicitudes_coleccion_get" {
  api_id               = aws_apigatewayv2_api.api.id
  route_key            = "GET /solicitudes"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito.id
  authorization_scopes = ["solicitud:leer"]
  target               = "integrations/${aws_apigatewayv2_integration.solicitudes_coleccion.id}"
}

resource "aws_apigatewayv2_route" "solicitudes_coleccion_post" {
  api_id               = aws_apigatewayv2_api.api.id
  route_key            = "POST /solicitudes"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito.id
  authorization_scopes = ["solicitud:crear"]
  target               = "integrations/${aws_apigatewayv2_integration.solicitudes_coleccion.id}"
}


resource "aws_apigatewayv2_route" "solicitudes_elemento_get" {
  api_id               = aws_apigatewayv2_api.api.id
  route_key            = "GET /solicitudes/{proxy+}"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito.id
  authorization_scopes = ["solicitud:leer"]
  target               = "integrations/${aws_apigatewayv2_integration.solicitudes_elemento.id}"
}

# {proxy+} greedy: valido porque es el ultimo segmento de la ruta.
resource "aws_apigatewayv2_route" "solicitudes_elemento_editar" {
  api_id               = aws_apigatewayv2_api.api.id
  route_key            = "PUT /solicitudes/{proxy+}"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito.id
  authorization_scopes = ["solicitud:crear"]
  target               = "integrations/${aws_apigatewayv2_integration.solicitudes_elemento.id}"
}

# {proxy} sin "+": un solo segmento, no greedy. Un greedy no puede ir seguido
# de mas path literal ("/aprobar"), y el nombre "proxy" tiene que calzar con
# el placeholder que ya usa integration_uri en solicitudes_elemento.
resource "aws_apigatewayv2_route" "solicitudes_elemento_aprobar" {
  api_id               = aws_apigatewayv2_api.api.id
  route_key            = "PUT /solicitudes/{proxy}/aprobar"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito.id
  authorization_scopes = ["solicitud:aprobar"]
  target               = "integrations/${aws_apigatewayv2_integration.solicitudes_elemento.id}"
}

resource "aws_apigatewayv2_route" "solicitudes_elemento_rechazar" {
  api_id               = aws_apigatewayv2_api.api.id
  route_key            = "PUT /solicitudes/{proxy}/rechazar"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito.id
  authorization_scopes = ["solicitud:rechazar"]
  target               = "integrations/${aws_apigatewayv2_integration.solicitudes_elemento.id}"
}

resource "aws_apigatewayv2_route" "solicitudes_elemento_delete" {
  api_id               = aws_apigatewayv2_api.api.id
  route_key            = "DELETE /solicitudes/{proxy+}"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito.id
  authorization_scopes = ["solicitud:cancelar"]
  target               = "integrations/${aws_apigatewayv2_integration.solicitudes_elemento.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
  description = "Stage por defecto - URL sin prefijo de etapa"
}

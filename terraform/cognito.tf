resource "aws_cognito_user_pool" "pool" {
  name = "dsy1107-ng-${var.estudiante}"

  # Login con email, sin username separado
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Protege el pool de un destroy/recreate accidental
  deletion_protection = "ACTIVE"

  # Explícito, aunque sea el default: fue decisión, no olvido
  mfa_configuration = "OFF"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  # Nadie se auto-registra: los roles se asignan a mano
  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  tags = {
    Proyecto   = "parcial1-dsy1107"
    Estudiante = var.estudiante
    Origen     = "terraform"
  }
}


resource "aws_cognito_user_pool_client" "spa" {
  name = "spa-angular"
  # user_pool_id conecta este cliente al directorio de usuarios que ya creamos.
  # Sin esta línea, Cognito no sabría a qué User Pool pertenece esta app.
  user_pool_id = aws_cognito_user_pool.pool.id

  # false porque es una SPA: el código corre en el navegador del usuario,
  # cualquiera podría abrir DevTools y leer un secreto si existiera.
  # Por eso el login usa PKCE en vez de un client_secret.
  generate_secret = false

  explicit_auth_flows = [
    #"ALLOW_USER_SRP_AUTH",       login con protocolo seguro: la contraseña nunca viaja en texto plano
    "ALLOW_REFRESH_TOKEN_AUTH", # permite renovar el access token sin pedir la contraseña de nuevo
  ]

  # Activa OAuth2 en este cliente. Sin esto en true, callback_urls, logout_urls,
  # allowed_oauth_scopes y allowed_oauth_flows quedan sin efecto, aunque los escribas.
  allowed_oauth_flows_user_pool_client = true

  # "code" = Authorization Code Flow, el mismo que vimos en el mapa del aeropuerto:
  # Cognito entrega un código temporal, y ese código se cambia por el JWT usando PKCE.
  allowed_oauth_flows = ["code"]

  # Scopes de identidad (OIDC), distintos a los scopes de negocio (solicitud:aprobar, etc.)
  # que va a inyectar la Lambda de pre-token trigger más adelante.
  allowed_oauth_scopes = ["openid", "email", "profile"]

  callback_urls = var.callback_urls # a dónde vuelve el navegador después del login
  logout_urls   = var.logout_urls   # a dónde vuelve después del logout

  supported_identity_providers = ["COGNITO"] # el único proveedor de identidad es el propio Cognito
  # Define cuánto dura cada token antes de expirar, y en qué unidad.
  # Sin esto, Cognito usa defaults (horas para access/id, días para refresh)
  # que quedan implícitos y sin que tú los hayas decidido conscientemente.
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  access_token_validity  = 60 # el access token dura 1 hora: bastante corto,
  id_token_validity      = 60 # así si alguien lo roba, la ventana de daño es limitada
  refresh_token_validity = 30 # 30 días para no forzar login constante

  # Evita que un atacante pueda distinguir "usuario no existe" de "contraseña
  # incorrecta" al intentar loguearse — con esto activado, Cognito responde
  # el mismo error genérico en ambos casos, dificultando enumerar usuarios
  # válidos por fuerza bruta.
  prevent_user_existence_errors = "ENABLED"

  # Permite invalidar el refresh token si el usuario cierra sesión o si
  # detectas actividad sospechosa — sin esto, un refresh token robado
  # sigue siendo válido hasta que expire solo, aunque el usuario "cierre sesión".
  enable_token_revocation = true
}

resource "aws_cognito_user_pool_domain" "hosted_ui" {
  domain                = local.dominio_hosted_ui
  user_pool_id          = aws_cognito_user_pool.pool.id
  managed_login_version = 1
}

resource "aws_cognito_user" "demo" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = "test@duoc.cl"
  password     = "Duoc2026"

  attributes = {
    email          = "test@duoc.cl"
    email_verified = true
    name           = "oscar"
  }

  message_action = "SUPPRESS"
}

resource "aws_cognito_user" "solicitante_demo" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = "solicitante@duoc.cl"
  password     = "Duoc2026"

  attributes = {
    email          = "solicitante@duoc.cl"
    email_verified = true
    name           = "Solicitante Demo"
  }

  message_action = "SUPPRESS"
}

resource "aws_cognito_user" "aprobador_demo" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = "aprobador@duoc.cl"
  password     = "Duoc2026"

  attributes = {
    email          = "aprobador@duoc.cl"
    email_verified = true
    name           = "Aprobador Demo"
  }

  message_action = "SUPPRESS"
}

resource "aws_cognito_user_group" "solicitantes" {
  name         = "solicitantes"
  user_pool_id = aws_cognito_user_pool.pool.id
  description  = "Puede crear y ver sus propias solicitudes"
}

resource "aws_cognito_user_group" "aprobadores" {
  name         = "aprobadores"
  user_pool_id = aws_cognito_user_pool.pool.id
  description  = "Puede ver todas las solicitudes pendientes y aprobar/rechazar"
}


resource "aws_cognito_user_in_group" "solicitante_en_grupo" {
  user_pool_id = aws_cognito_user_pool.pool.id
  group_name   = aws_cognito_user_group.solicitantes.name
  username     = aws_cognito_user.solicitante_demo.username
}


resource "aws_cognito_user_in_group" "aprobador_en_grupo" {
  user_pool_id = aws_cognito_user_pool.pool.id
  group_name   = aws_cognito_user_group.aprobadores.name
  username     = aws_cognito_user.aprobador_demo.username
}


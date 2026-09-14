variable "estudiante" {
  description = "Tu apellido en minusculas. Hace unicos el user pool, el dominio y la API."
  type        = string
  default     = "cuestas"
  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.estudiante))
    error_message = "Solo minusculas, numeros y guiones, entre 3 y 20 caracteres. El dominio de Cognito es global: 'perez' sirve, 'Perez' no."
  }
}

variable "aws_region" {
  description = "Region donde se despliega todo. El issuer del token depende de esta region."
  type        = string
  default     = "us-east-1"
}

variable "callback_urls" {
  description = "URLs a las que el Hosted UI puede devolver el authorization code. Debe coincidir EXACTA con redirect_uri del front."
  type        = list(string)
  default     = ["http://localhost:4200/", "http://localhost:5173/", "https://main.d2ii8hclnf0dvz.amplifyapp.com/"]
}

variable "logout_urls" {
  description = "URLs a las que Cognito puede volver despues del logout."
  type        = list(string)
  default     = ["http://localhost:4200/", "http://localhost:5173/", "https://main.d2ii8hclnf0dvz.amplifyapp.com/"]
}

variable "cognito_dominio" {
  description = "Dominio del Hosted UI. Vacio lo deriva de var.estudiante. Cambiar solo si quedo retenido."
  type        = string
  default     = ""

  validation {
    condition     = var.cognito_dominio == "" || can(regex("^[a-z0-9-]{3,63}$", var.cognito_dominio))
    error_message = "Solo minusculas, numeros y guiones."
  }
}

#apigateway


variable "backend_url" {
  description = "La API publica que queda detras del API Manager. Es la misma de la actividad 1.1.2."
  type        = string
  default     = "https://mindicador.cl/api"
}

variable "origenes_frontend" {
  description = "Origenes autorizados por CORS en el API Gateway: ng serve (4200) y Vite (5173)."
  type        = list(string)
  default     = ["http://localhost:4200", "http://localhost:5173"]
}

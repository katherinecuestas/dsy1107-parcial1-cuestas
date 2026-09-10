resource "aws_amplify_app" "front" {
  name = "dsy1107-${var.estudiante}"

  # WEB = sitio estatico. El build de Angular son archivos, no un servidor.
  platform = "WEB"

  # Una SPA sirve index.html para cualquier ruta; sin esto, todo lo que no sea
  # "/" responde 404. La lista de extensiones excluye json a proposito: si no,
  # esta misma regla se tragaria /config.json y la app arrancaria sin
  # configuracion.
  custom_rule {
    source = "</^[^.]+$|\\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|woff2|ttf|map|json|webp)$)([^.]+$)/>"
    target = "/index.html"
    status = "200"
  }
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.front.id
  branch_name = "main"
  framework   = "Angular"
  stage       = "PRODUCTION"
}


output "amplify_app_id" {
  description = "ID de la app. Lo necesita 'aws amplify create-deployment' para subir el zip."
  value       = aws_amplify_app.front.id
}

output "amplify_url" {
  description = "URL publica del front. Va en callback_urls, logout_urls y CORS (paso siguiente)."
  value       = local.url_amplify
}

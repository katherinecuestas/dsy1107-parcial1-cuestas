# Este bloque configura los requisitos de Terraform para el proyecto. Primero indicamos que necesitamos Terraform 1.5 o superior. Después declaramos que utilizaremos el provider de AWS de HashiCorp, en una versión compatible con la 5.100. El provider es el que permite que Terraform se comunique con AWS y pueda administrar nuestros recursos.
# Configuración general de Terraform
terraform {

  # Indica que para ejecutar este proyecto necesitamos
  # Terraform versión 1.5 o superior.
  required_version = ">= 1.5"

  # Aquí indicamos qué proveedores necesita Terraform.
  # Un provider permite que Terraform se comunique con una plataforma,
  # en este caso AWS.
  required_providers {

    # Declaramos que utilizaremos el provider de AWS.
    aws = {

      # Indica de dónde debe descargar Terraform el provider de AWS.
      # "hashicorp/aws" es el provider de AWS mantenido por HashiCorp.
      source = "hashicorp/aws"

      # Usamos una versión compatible con la serie 5.100 del provider.
      # Esta versión permite utilizar funcionalidades que necesita
      # nuestro proyecto, como managed_login_version de Cognito.
      version = "~> 5.100"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

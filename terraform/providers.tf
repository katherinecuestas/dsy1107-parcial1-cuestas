# Configura el provider "aws" que versions.tf ya declaro como requisito.
# Aqui no se pide el plugin, se le dice COMO usarlo: en que region trabaja
# y que credenciales toma (estas ultimas no se ven: llegan del entorno,
# por ejemplo las variables temporales de AWS Academy).
provider "aws" {

  # Region donde se crean TODOS los recursos (Cognito, API Gateway, ECS,
  # RDS, Amplify). Sale de la variable, no queda fija aqui, porque el
  # issuer del token de Cognito depende de esta region (ver variables.tf).
  region = var.aws_region

  # Tags que Terraform agrega automaticamente a cada recurso que soporte
  # tags, sin tener que repetirlas en cada .tf. Sirven para identificar,
  # en una cuenta compartida como AWS Academy, que recursos son de quien.
  default_tags {
    tags = {
      Proyecto   = "parcial1-dsy1107"
      Estudiante = var.estudiante # viene de terraform.tfvars
      Origen     = "terraform"    # marca que el recurso no se creo a mano en la consola
    }
  }
}

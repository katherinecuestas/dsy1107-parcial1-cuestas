# EP1 — Sistema de Solicitante/Aprobador
**DSY1107 · Katherine Cuestas**

## Resumen

Sistema de gestión de solicitudes (ej. vacaciones) con dos roles diferenciados
mediante Cognito Groups: **solicitante** y **aprobador**.

- Backend: Spring Boot, desplegado en ECS Fargate
- Frontend: Angular, con login Authorization Code + PKCE contra Cognito
- Base de datos: PostgreSQL en RDS
- API Gateway con JWT Authorizer (autenticación) + validación de roles en el
  backend (autorización, patron BFF)

## Funcionalidad implementada

- **Solicitante**: CRUD completo desde el frontend
  - Crear solicitud (tipo, fecha inicio, fecha fin)
  - Listar sus propias solicitudes
  - Editar una solicitud (solo mientras este PENDIENTE)
  - Cancelar una solicitud (soft delete: cambia a estado CANCELADA,
    solo mientras este PENDIENTE)
- **Aprobador**: revisa solicitudes pendientes y aprueba/rechaza con comentario

## Roles y seguridad

- Grupos de Cognito: `solicitantes` y `aprobadores`
- El backend valida el grupo del usuario (claim `cognito:groups` del JWT)
  antes de permitir aprobar/rechazar/ver pendientes
- El backend valida que el usuario sea el dueno de una solicitud antes de
  permitir editarla o cancelarla
- Doble validacion de JWT: en el API Gateway (Authorizer) y en el backend
  (Spring Security, patron BFF)

## Usuarios de prueba

| Usuario | Contrasena | Rol |
|---|---|---|
| solicitante@duoc.cl | Duoc2026 | solicitantes |
| aprobador@duoc.cl | Duoc2026 | aprobadores |

## Pipelines de CI/CD

Los 4 pipelines requeridos existen en .github/workflows/:

- backend_compile.yml - pasa en verde
- frontend_compile.yml - pasa en verde
- backend_deploy.yml - configurado para desplegar a ECS, pero requiere
  credenciales de AWS Academy (temporales, expiran en horas) como secrets
  de GitHub. Como el Learner Lab no permite credenciales permanentes, el
  pipeline de despliegue automatico no puede mantenerse funcionando de forma
  continua entre sesiones.
- frontend_deploy.yml - mismo caso que el anterior, para Amplify

El despliegue SI funciona correctamente, se ejecuta manualmente con:

    scripts/publicar-ecs.sh       # backend
    scripts/publicar-amplify.sh   # frontend

Evidencia: el backend esta actualmente desplegado y respondiendo, accesible
a traves del API Gateway en https://1rzpo2jdte.execute-api.us-east-1.amazonaws.com

## Como probar

1. Abrir el frontend (local: localhost:4200)
2. Iniciar sesion como solicitante@duoc.cl (password: Duoc2026)
3. Crear una solicitud
4. Cerrar sesion, iniciar sesion como aprobador@duoc.cl (password: Duoc2026)
5. Ver la solicitud en "Solicitudes pendientes", aprobar con un comentario

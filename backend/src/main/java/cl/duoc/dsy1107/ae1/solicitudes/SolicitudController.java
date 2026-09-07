package cl.duoc.dsy1107.ae1.solicitudes;

import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/solicitudes")
public class SolicitudController {

    private final SolicitudService service;

    public SolicitudController(SolicitudService service) {
        this.service = service;
    }

    // El solicitante crea su propia solicitud. El email sale del JWT,
    // nunca del body: así nadie puede crear una solicitud a nombre de otro.
    @PostMapping
    public ResponseEntity<SolicitudVista> crear(@RequestBody SolicitudNueva body,
            @AuthenticationPrincipal Jwt jwt) {
        String email = jwt.getSubject();
        Solicitud creada = service.crear(body.tipo(), body.fechaInicio(), body.fechaFin(), email);
        SolicitudVista vista = SolicitudVista.desde(creada);
        return ResponseEntity.created(URI.create("/solicitudes/" + creada.getId())).body(vista);
    }

    // El solicitante edita SU PROPIA solicitud (validado en el Service),
    // y SOLO si sigue pendiente (validado en la entidad).
    @PutMapping("/{id}")
    public SolicitudVista editar(@PathVariable Long id, @RequestBody SolicitudNueva body,
            @AuthenticationPrincipal Jwt jwt) {
        String email = jwt.getSubject();
        Solicitud editada = service.editar(id, body.tipo(), body.fechaInicio(), body.fechaFin(), email);
        return SolicitudVista.desde(editada);
    }

    // "Eliminar" = borrado logico (cancelar). El HTTP sigue siendo DELETE,
    // pero internamente la fila NO se borra, solo cambia de estado.
    @DeleteMapping("/{id}")
    public SolicitudVista cancelar(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt) {
        String email = jwt.getSubject();
        return SolicitudVista.desde(service.cancelar(id, email));
    }

    // El solicitante ve SOLO sus propias solicitudes.
    @GetMapping("/mias")
    public List<SolicitudVista> misSolicitudes(@AuthenticationPrincipal Jwt jwt) {
        String email = jwt.getSubject();
        return service.listarPorSolicitante(email).stream()
                .map(SolicitudVista::desde)
                .toList();
    }

    // El aprobador ve TODAS las solicitudes pendientes.
    @GetMapping("/pendientes")
    public List<SolicitudVista> pendientes(@AuthenticationPrincipal Jwt jwt) {
        exigirGrupo(jwt, "aprobadores");
        return service.listarPendientes().stream()
                .map(SolicitudVista::desde)
                .toList();
    }

    @GetMapping("/{id}")
    public SolicitudVista verUna(@PathVariable Long id) {
        return SolicitudVista.desde(service.buscarPorId(id));
    }

    // El aprobador aprueba con un comentario.
    @PutMapping("/{id}/aprobar")
    public SolicitudVista aprobar(@PathVariable Long id, @RequestBody ComentarioAprobacion body,
            @AuthenticationPrincipal Jwt jwt) {
        exigirGrupo(jwt, "aprobadores");
        return SolicitudVista.desde(service.aprobar(id, body.comentario()));
    }

    // El aprobador rechaza con un comentario.
    @PutMapping("/{id}/rechazar")
    public SolicitudVista rechazar(@PathVariable Long id, @RequestBody ComentarioAprobacion body,
            @AuthenticationPrincipal Jwt jwt) {
        exigirGrupo(jwt, "aprobadores");
        return SolicitudVista.desde(service.rechazar(id, body.comentario()));
    }

    // Lanza 403 si el JWT no trae el grupo requerido en "cognito:groups".
    private void exigirGrupo(Jwt jwt, String grupoRequerido) {
        List<String> grupos = jwt.getClaimAsStringList("cognito:groups");
        if (grupos == null || !grupos.contains(grupoRequerido)) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.FORBIDDEN,
                    "Se requiere el grupo '" + grupoRequerido + "'");
        }
    }

    // Convierte "no se puede editar/cancelar en este estado" en un 409
    // Conflict (el codigo correcto quando el estado actual del recurso
    // impide la operacion), en vez de un 500 generico.
    @org.springframework.web.bind.annotation.ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<String> manejarEstadoInvalido(IllegalStateException ex) {
        return ResponseEntity.status(org.springframework.http.HttpStatus.CONFLICT)
                .body(ex.getMessage());
    }

    // ------- Records de entrada y salida (NUNCA se expone la entidad JPA) -------

    public record SolicitudNueva(
            @NotBlank String tipo,
            Instant fechaInicio,
            Instant fechaFin) {
    }

    public record ComentarioAprobacion(String comentario) {
    }

    public record SolicitudVista(
            Long id, String tipo, Instant fechaInicio, Instant fechaFin,
            EstadoSolicitud estado, String comentario, String solicitanteEmail, Instant creadoEn) {
        static SolicitudVista desde(Solicitud s) {
            return new SolicitudVista(s.getId(), s.getTipo(), s.getFechaInicio(), s.getFechaFin(),
                    s.getEstado(), s.getComentario(), s.getSolicitanteEmail(), s.getCreadoEn());
        }
    }
}
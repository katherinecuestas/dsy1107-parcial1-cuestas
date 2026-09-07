package cl.duoc.dsy1107.ae1.solicitudes;

import org.springframework.stereotype.Service;
import java.time.Instant;
import java.util.List;

@Service
public class SolicitudService {

    private final SolicitudRepository repository;

    public SolicitudService(SolicitudRepository repository) {
        this.repository = repository;
    }

    public Solicitud crear(String tipo, Instant fechaInicio, Instant fechaFin, String solicitanteEmail) {
        Solicitud nueva = new Solicitud(tipo, fechaInicio, fechaFin, solicitanteEmail, Instant.now());
        return repository.save(nueva);
    }

    public List<Solicitud> listarPorSolicitante(String solicitanteEmail) {
        return repository.findBySolicitanteEmail(solicitanteEmail);
    }

    public List<Solicitud> listarPendientes() {
        return repository.findByEstado(EstadoSolicitud.PENDIENTE);
    }

    public List<Solicitud> listarTodas() {
        return repository.findAll();
    }

    public Solicitud buscarPorId(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new SolicitudNoEncontradaException(id));
    }

    public Solicitud aprobar(Long id, String comentario) {
        Solicitud solicitud = buscarPorId(id);
        solicitud.aprobar(comentario);
        return repository.save(solicitud);
    }

    public Solicitud rechazar(Long id, String comentario) {
        Solicitud solicitud = buscarPorId(id);
        solicitud.rechazar(comentario);
        return repository.save(solicitud);
    }

    // El solicitante edita SU PROPIA solicitud. Verificamos dueño Y estado
    // (el estado lo valida la entidad misma, en editar()).
    public Solicitud editar(Long id, String tipo, Instant fechaInicio, Instant fechaFin,
            String solicitanteEmail) {
        Solicitud solicitud = buscarPorId(id);
        exigirDueno(solicitud, solicitanteEmail);
        solicitud.editar(tipo, fechaInicio, fechaFin);
        return repository.save(solicitud);
    }

    // Cancelar = borrado logico. Mismo patron: verificar dueño, delegar
    // la regla de estado a la entidad.
    public Solicitud cancelar(Long id, String solicitanteEmail) {
        Solicitud solicitud = buscarPorId(id);
        exigirDueno(solicitud, solicitanteEmail);
        solicitud.cancelar();
        return repository.save(solicitud);
    }

    // Nadie puede editar o cancelar la solicitud de otra persona, aunque
    // esté "pendiente". Esta es la version de "autorizacion" que SI
    // necesita el Service (necesita comparar contra el JWT).
    private void exigirDueno(Solicitud solicitud, String solicitanteEmail) {
        if (!solicitud.getSolicitanteEmail().equals(solicitanteEmail)) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.FORBIDDEN,
                    "No puedes modificar una solicitud que no es tuya");
        }
    }
}
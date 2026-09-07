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
}
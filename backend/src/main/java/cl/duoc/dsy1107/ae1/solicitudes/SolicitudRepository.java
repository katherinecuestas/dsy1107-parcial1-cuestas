package cl.duoc.dsy1107.ae1.solicitudes;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SolicitudRepository extends JpaRepository<Solicitud, Long> {
    List<Solicitud> findBySolicitanteEmail(String solicitanteEmail);
    List<Solicitud> findByEstado(EstadoSolicitud estado);
}
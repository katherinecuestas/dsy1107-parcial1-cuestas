package cl.duoc.dsy1107.ae1.solicitudes;

public class SolicitudNoEncontradaException extends RuntimeException {
    public SolicitudNoEncontradaException(Long id) {
        super("No existe la solicitud con id " + id);
    }
}
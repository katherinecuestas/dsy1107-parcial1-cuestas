package cl.duoc.dsy1107.ae1.solicitudes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "solicitud")
public class Solicitud {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 60)
    private String tipo;

    @Column(name = "fecha_inicio", nullable = false)
    private Instant fechaInicio;

    @Column(name = "fecha_fin", nullable = false)
    private Instant fechaFin;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EstadoSolicitud estado;

    @Column(length = 300)
    private String comentario;

    @Column(name = "solicitante_email", nullable = false, length = 120)
    private String solicitanteEmail;

    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    protected Solicitud() {
    }

    public Solicitud(String tipo, Instant fechaInicio, Instant fechaFin,
            String solicitanteEmail, Instant creadoEn) {
        this.tipo = tipo;
        this.fechaInicio = fechaInicio;
        this.fechaFin = fechaFin;
        this.solicitanteEmail = solicitanteEmail;
        this.creadoEn = creadoEn;
        this.estado = EstadoSolicitud.PENDIENTE;
    }

    public Long getId() {
        return id;
    }

    public String getTipo() {
        return tipo;
    }

    public Instant getFechaInicio() {
        return fechaInicio;
    }

    public Instant getFechaFin() {
        return fechaFin;
    }

    public EstadoSolicitud getEstado() {
        return estado;
    }

    public String getComentario() {
        return comentario;
    }

    public String getSolicitanteEmail() {
        return solicitanteEmail;
    }

    public Instant getCreadoEn() {
        return creadoEn;
    }

    public void aprobar(String comentario) {
        this.estado = EstadoSolicitud.APROBADA;
        this.comentario = comentario;
    }

    public void rechazar(String comentario) {
        this.estado = EstadoSolicitud.RECHAZADA;
        this.comentario = comentario;
    }

    // El solicitante edita SOLO si sigue pendiente. Si ya fue decidida
    // (aprobada/rechazada/cancelada), lanza un error: editar una decisión
    // ya tomada rompería la integridad del flujo de aprobación.
    public void editar(String tipo, Instant fechaInicio, Instant fechaFin) {
        if (this.estado != EstadoSolicitud.PENDIENTE) {
            throw new IllegalStateException(
                    "No se puede editar una solicitud en estado " + this.estado);
        }
        this.tipo = tipo;
        this.fechaInicio = fechaInicio;
        this.fechaFin = fechaFin;
    }

    // "Borrado logico": no se elimina la fila, se marca como cancelada.
    // Solo se puede cancelar mientras sigue pendiente.
    public void cancelar() {
        if (this.estado != EstadoSolicitud.PENDIENTE) {
            throw new IllegalStateException(
                    "No se puede cancelar una solicitud en estado " + this.estado);
        }
        this.estado = EstadoSolicitud.CANCELADA;
    }
}
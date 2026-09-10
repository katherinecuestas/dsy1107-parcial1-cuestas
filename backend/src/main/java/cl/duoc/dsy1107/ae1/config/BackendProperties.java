package cl.duoc.dsy1107.ae1.config;

import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Todo lo configurable del backend, en un solo lugar y sin valores quemados en
 * el codigo. Los defaults viven en application.yml; cualquiera se puede pisar
 * con una variable de entorno, que es como se configurara el dia que esto
 * corra en un contenedor.
 */
@ConfigurationProperties(prefix = "backend")
public record BackendProperties(Cors cors) {

    /**
     * Origenes que pueden llamar a este backend desde un navegador.
     *
     * En el despliegue real el CORS lo resuelve el API Gateway (actividad 1.1.4)
     * y el navegador nunca habla con este servicio. Esto existe para el modo
     * local: "ng serve" en :4200 apuntando derecho al :8080, sin AWS de por
     * medio.
     */
    public record Cors(List<String> origenes) {
    }
}

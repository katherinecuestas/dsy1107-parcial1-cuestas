package cl.duoc.dsy1107.ae1.web;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Traduce las excepciones de los servicios a codigos HTTP.
 *
 * Que el error salga en JSON y con un codigo correcto no es cosmetica: el front
 * de la actividad muestra SIEMPRE el status (ver Resultado en api.service.ts).
 * Un 500 generico con una pagina de error de Spring no le dice nada al alumno;
 * un 502 con "el origen respondio 503" le dice exactamente quien fallo.
 *
 * Vive en el paquete web y no dentro de un paquete de dominio porque es
 * global por definicion: atiende lo que venga, no un dominio en particular.
 * Tenerlo escondido dentro de un paquete de dominio invita a que el
 * siguiente escriba un segundo manejador sin saber que este existia.
 */
@RestControllerAdvice
public class ManejadorDeErrores {

    /**
     * @param error   que paso, en una linea
     * @param detalle el porque, cuando se sabe
     * @param momento cuando, para poder cruzarlo con los logs
     */
    public record ErrorHttp(String error, String detalle, Instant momento) {
    }

    /**
     * El cuerpo no paso las validaciones de @Valid.
     *
     * 400 y no 422: el recurso ni siquiera se pudo interpretar como valido, y
     * 400 es lo que cualquier cliente HTTP entiende sin documentacion.
     *
     * Se devuelve campo por campo en vez de una frase suelta. La diferencia se
     * ve al depurar desde el front: "el precio no puede ser negativo" obliga a
     * leer el JSON entero para saber cual de los dos numeros era; un mapa
     * {"precio": "..."} lo dice.
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Cuerpo400> invalido(MethodArgumentNotValidException e) {
        Map<String, String> campos = e.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.toMap(
                        FieldError::getField,
                        f -> f.getDefaultMessage() == null ? "valor invalido" : f.getDefaultMessage(),
                        (primero, segundo) -> primero));

        return ResponseEntity.badRequest()
                .body(new Cuerpo400("El cuerpo de la peticion no es valido", campos, Instant.now()));
    }

    public record Cuerpo400(String error, Map<String, String> campos, Instant momento) {
    }
}

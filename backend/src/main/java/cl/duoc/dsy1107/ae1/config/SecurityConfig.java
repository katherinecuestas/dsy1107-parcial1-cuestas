package cl.duoc.dsy1107.ae1.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
// Correcto
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtDecoders;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

        @Value("${spring.security.oauth2.resourceserver.jwt.issuer-uri}")
        private String issuerUri;

        @Value("${cognito.app-client-id}")
        private String appClientIdEsperado;

        @Bean
        public JwtDecoder jwtDecoder() {
                NimbusJwtDecoder decoder = (NimbusJwtDecoder) JwtDecoders.fromIssuerLocation(issuerUri);

                // El decoder por defecto de Spring valida firma, issuer y expiracion,
                // pero NUNCA valida client_id/aud. Eso lo agregamos aqui.
                OAuth2TokenValidator<Jwt> validadorDefault = JwtValidators.createDefaultWithIssuer(issuerUri);

                // El access_token de Cognito trae el App Client ID en "client_id",
                // no en "aud" (eso solo pasa en el id_token). Confirmado con la
                // documentacion real del proyecto y con el propio comentario del
                // profesor en apigateway.tf.
                OAuth2TokenValidator<Jwt> validadorClientId = jwt -> {
                        String clientId = jwt.getClaimAsString("client_id");
                        if (appClientIdEsperado.equals(clientId)) {
                                return OAuth2TokenValidatorResult.success();
                        }
                        return OAuth2TokenValidatorResult.failure(
                                        new OAuth2Error("invalid_token",
                                                        "client_id no coincide con el App Client esperado", null));
                };

                decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(validadorDefault, validadorClientId));
                return decoder;
        }

        @Bean
        public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
                http
                                .sessionManagement(session -> session
                                                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                                .csrf(csrf -> csrf.disable())
                                .formLogin(form -> form.disable())
                                .httpBasic(basic -> basic.disable())

                                .authorizeHttpRequests(auth -> auth
                                                .requestMatchers("/actuator/health").permitAll()
                                                .anyRequest().authenticated())

                                .oauth2ResourceServer(oauth2 -> oauth2.jwt(jwt -> {
                                }));

                return http.build();
        }
}
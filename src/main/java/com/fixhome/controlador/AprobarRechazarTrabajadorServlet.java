package com.fixhome.controlador;

import com.fixhome.conexion.Conexion;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.util.Properties;
import javax.mail.Message;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(name = "AprobarRechazarTrabajadorServlet", urlPatterns = {"/AprobarRechazarTrabajadorServlet"})
public class AprobarRechazarTrabajadorServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String idTrabajadorStr = request.getParameter("idTrabajador");
        String correoTrabajador = request.getParameter("correoTrabajador"); // <-- Correo del trabajador registrado
        String nombreTrabajador = request.getParameter("nombreTrabajador");
        String accion = request.getParameter("accion");
        String observaciones = request.getParameter("observaciones");

        if (idTrabajadorStr == null || accion == null) {
            response.sendRedirect(request.getContextPath() + "/admin/solicitudes.jsp?error=datos_incompletos");
            return;
        }

        int idTrabajador = Integer.parseInt(idTrabajadorStr);
        String nuevoEstado = "aprobar".equals(accion) ? "aceptado" : "rechazado";

        try (Connection conn = Conexion.conectar()) {

            // 1. Actualizar el estado del trabajador en la base de datos
            String sql = "UPDATE trabajadores SET estado_registro = ?, observaciones_revision = ?, fecha_revision = ? WHERE id_trabajador = ?";
            try (PreparedStatement pst = conn.prepareStatement(sql)) {
                pst.setString(1, nuevoEstado);
                pst.setString(2, observaciones != null ? observaciones : "");
                pst.setTimestamp(3, new Timestamp(System.currentTimeMillis()));
                pst.setInt(4, idTrabajador);
                pst.executeUpdate();
            }

            // 2. Enviar el correo directamente a la dirección registrada por el trabajador
            enviarCorreoNotificacion(correoTrabajador, nombreTrabajador, nuevoEstado, observaciones);

            // 3. Redirigir con éxito
            response.sendRedirect(request.getContextPath() + "/admin/solicitudes.jsp?exito=actualizado");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/admin/solicitudes.jsp?error=1");
        }
    }

    // Método auxiliar para enviar correos usando JavaMail
    private void enviarCorreoNotificacion(String para, String nombre, String estado, String observaciones) {
        // CONFIGURACIÓN DE CORREO (Puedes usar una cuenta de Gmail de prueba)
        final String remitente = "soporte.fixhome@gmail.com"; // Reemplaza con tu correo real
        final String password = "plbq drtc vuiv mlbs"; // Contraseña de aplicación de Gmail

        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");

        Session session = Session.getInstance(props, new javax.mail.Authenticator() {
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(remitente, password);
            }
        });

        try {
            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(remitente, "FixHome Soporte"));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(para));

            if ("aceptado".equals(estado)) {
                message.setSubject("¡Felicidades! Tu cuenta en FixHome ha sido APROBADA");
                message.setContent("Hola <strong>" + nombre + "</strong>,<br><br>"
                        + "Nos alegra informarte que tu documentación ha sido validada con éxito por nuestro equipo administrativo.<br>"
                        + "Ya puedes iniciar sesión en el portal de trabajadores de FixHome y comenzar a aceptar solicitudes de servicio.<br><br>"
                        + "¡Bienvenido a la red de especialistas!", "text/html;charset=UTF-8");
            } else {
                message.setSubject("Actualización sobre tu solicitud de registro en FixHome");
                message.setContent("Hola <strong>" + nombre + "</strong>,<br><br>"
                        + "Lamentamos informarte que tu solicitud de registro como trabajador no ha sido aprobada tras la revisión de tus documentos.<br>"
                        + (observaciones != null && !observaciones.trim().isEmpty() ? "<strong>Motivo / Observaciones:</strong> " + observaciones + "<br><br>" : "")
                        + "Puedes ponerte en contacto con soporte si tienes dudas o deseas volver a postularte.", "text/html;charset=UTF-8");
            }

            Transport.send(message);
        } catch (Exception e) {
            e.printStackTrace(); // Si no tienes configurado el SMTP aún, esto imprimirá el error sin romper la app
        }
    }
}

package com.fixhome.controlador;

import com.fixhome.conexion.Conexion;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "LoginTrabajadorServlet", urlPatterns = {"/LoginTrabajadorServlet"})
public class LoginTrabajadorServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        
        String correo = request.getParameter("correo");
        String password = request.getParameter("password");

        if (correo == null || password == null || correo.trim().isEmpty() || password.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/login-trabajador.jsp?error=campos_vacios");
            return;
        }

        try (Connection conn = Conexion.conectar()) {
            
            // Consultamos al usuario, su contraseña en texto plano y su estado de registro como trabajador
            String sql = "SELECT u.id_usuario, u.nombre, u.contrasena_hash, t.estado_registro " +
                         "FROM usuarios u " +
                         "INNER JOIN trabajadores t ON u.id_usuario = t.id_trabajador " +
                         "WHERE u.correo = ?";
            
            try (PreparedStatement pst = conn.prepareStatement(sql)) {
                pst.setString(1, correo.trim());
                
                try (ResultSet rs = pst.executeQuery()) {
                    if (rs.next()) {
                        int idUsuario = rs.getInt("id_usuario");
                        String storedPassword = rs.getString("contrasena_hash"); // Contraseña en texto plano guardada en BD
                        String estadoRegistro = rs.getString("estado_registro");
                        
                        // 1. Verificamos si la contraseña coincide exactamente
                        if (password.equals(storedPassword)) {
                            
                            // 2. Verificamos si el administrador ya aprobó su cuenta
                            if ("aceptado".equals(estadoRegistro)) {
                                // ¡Credenciales correctas y cuenta aprobada! Creamos la sesión
                                HttpSession session = request.getSession();
                                session.setAttribute("idUsuario", idUsuario);
                                session.setAttribute("correoUsuario", correo);
                                
                                response.sendRedirect(request.getContextPath() + "/trabajador/dashboard-trabajador.jsp");
                            } else {
                                // La cuenta aún está pendiente de aprobación o fue rechazada
                                response.sendRedirect(request.getContextPath() + "/login-trabajador.jsp?error=cuenta_pendiente");
                            }
                            
                        } else {
                            // Contraseña incorrecta
                            response.sendRedirect(request.getContextPath() + "/login-trabajador.jsp?error=credenciales_invalidas");
                        }
                        
                    } else {
                        // El correo no existe en la tabla de trabajadores
                        response.sendRedirect(request.getContextPath() + "/login-trabajador.jsp?error=credenciales_invalidas");
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/login-trabajador.jsp?error=sistema");
        }
    }
}
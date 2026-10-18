<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.fixhome.conexion.Conexion"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.List"%>



<%!
    private static class Documento {

        String tipo;
        String ruta;
        String estado;
    }

    private String escapar(String texto) {
        if (texto == null) {
            return "";
        }
        return texto.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
%>

<%
    if (session.getAttribute("idAdministrador") == null && session.getAttribute("idUsuario") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String ruta = request.getContextPath();
    String idParam = request.getParameter("id");

    if (idParam == null || idParam.trim().isEmpty()) {
        response.sendRedirect(ruta + "/admin/solicitudes.jsp");
        return;
    }

    int idTrabajador = Integer.parseInt(idParam);

    String nombre = "", apellidos = "", correo = "", telefono = "", curp = "", domicilio = "", descripcion = "", estadoRegistro = "", fechaRegistro = "";
    List<Documento> documentos = new ArrayList<>();
    List<String> servicios = new ArrayList<>();

    boolean encontrado = false;

    try (Connection conexion = Conexion.conectar()) {

        // 1. Obtener datos del usuario y del trabajador
        String sqlTrabajador = "SELECT u.nombre, u.apellidos, u.correo, u.telefono, u.fecha_registro, "
                + "t.curp, t.domicilio, t.descripcion_experiencia, t.estado_registro "
                + "FROM usuarios u "
                + "INNER JOIN trabajadores t ON t.id_trabajador = u.id_usuario "
                + "WHERE t.id_trabajador = ?";

        try (PreparedStatement ps = conexion.prepareStatement(sqlTrabajador)) {
            ps.setInt(1, idTrabajador);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    encontrado = true;
                    nombre = rs.getString("nombre");
                    apellidos = rs.getString("apellidos");
                    correo = rs.getString("correo");
                    telefono = rs.getString("telefono");
                    fechaRegistro = rs.getString("fecha_registro");
                    curp = rs.getString("curp");
                    domicilio = rs.getString("domicilio");
                    descripcion = rs.getString("descripcion_experiencia");
                    estadoRegistro = rs.getString("estado_registro");
                }
            }
        }

        if (encontrado) {
            // 2. Obtener documentos subidos
            String sqlDocs = "SELECT tipo, ruta_archivo, estado FROM documentos_trabajador WHERE id_trabajador = ?";
            try (PreparedStatement psDocs = conexion.prepareStatement(sqlDocs)) {
                psDocs.setInt(1, idTrabajador);
                try (ResultSet rsDocs = psDocs.executeQuery()) {
                    while (rsDocs.next()) {
                        Documento doc = new Documento();
                        doc.tipo = rsDocs.getString("tipo");
                        doc.ruta = rsDocs.getString("ruta_archivo");
                        doc.estado = rsDocs.getString("estado");
                        documentos.add(doc);
                    }
                }
            }

            // 3. Obtener servicios asociados
            String sqlServs = "SELECT s.nombre FROM servicios s "
                    + "INNER JOIN trabajador_servicios ts ON ts.id_servicio = s.id_servicio "
                    + "WHERE ts.id_trabajador = ?";
            try (PreparedStatement psServs = conexion.prepareStatement(sqlServs)) {
                psServs.setInt(1, idTrabajador);
                try (ResultSet rsServs = psServs.executeQuery()) {
                    while (rsServs.next()) {
                        servicios.add(rsServs.getString("nombre"));
                    }
                }
            }
        }

    } catch (SQLException e) {
        application.log("Error al obtener detalle del trabajador en FixHome", e);
    }

    if (!encontrado) {
        response.sendRedirect(ruta + "/admin/solicitudes.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Detalle de Solicitud | FixHome Admin</title>
        <link rel="stylesheet" href="<%= ruta%>/ESTILOS-CSS/estilo-principal.css">
        <link rel="stylesheet" href="<%= ruta%>/ESTILOS-CSS/estilo-detallesolicitud.css">
    </head>
    <body class="pagina-admin">

        <aside class="barra-admin">
            <a href="<%= ruta%>/admin/index.jsp" class="logo">
                <img src="<%= ruta%>/Imagenes/logo.png" alt=""> FixHome
            </a>
            <nav class="menu-admin">
                <a href="<%= ruta%>/admin/index.jsp">Inicio</a>
                <a href="<%= ruta%>/admin/usuarios.jsp">Usuarios</a>
                <a href="<%= ruta%>/admin/trabajadores.jsp">Trabajadores</a>
                <a href="<%= ruta%>/admin/solicitudes.jsp" class="activo">Solicitudes</a>
                <a href="<%= ruta%>/admin/configuracion.jsp">Configuración</a>
            </nav>
        </aside>

        <div class="contenido-admin">
            <jsp:include page="encabezado-admin.jsp"/>

            <main class="principal-admin">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                    <div>
                        <a href="<%= ruta%>/admin/solicitudes.jsp" style="color: #666; text-decoration: none; font-size: 14px;">← Volver a solicitudes</a>
                        <h1 style="color: #0c3b2e; margin-top: 5px;">Revisión de Aspirante REG-000<%= idTrabajador%></h1>
                    </div>
                    <span class="badge-estado badge-<%= estadoRegistro%>"><%= estadoRegistro%></span>
                </div>

                <div class="contenedor-detalle">

                    <!-- Columna Izquierda: Información Principal -->
                    <div>
                        <!-- Tarjeta Datos Personales -->
                        <div class="tarjeta-admin">
                            <h3>Información del Especialista</h3>
                            <div class="grid-datos">
                                <div class="dato-item">
                                    <label>Nombre Completo</label>
                                    <p><%= escapar(nombre + " " + apellidos)%></p>
                                </div>
                                <div class="dato-item">
                                    <label>Correo Electrónico</label>
                                    <p><%= escapar(correo)%></p>
                                </div>
                                <div class="dato-item">
                                    <label>Teléfono</label>
                                    <p><%= escapar(telefono != null ? telefono : "Sin registrar")%></p>
                                </div>
                                <div class="dato-item">
                                    <label>CURP</label>
                                    <p><%= escapar(curp)%></p>
                                </div>
                                <div class="dato-item" style="grid-column: span 2;">
                                    <label>Domicilio</label>
                                    <p><%= escapar(domicilio)%></p>
                                </div>
                            </div>
                        </div>

                        <!-- Tarjeta Experiencia y Servicios -->
                        <div class="tarjeta-admin">
                            <h3>Experiencia Laboral</h3>
                            <div class="dato-item" style="margin-bottom: 16px;">
                                <label>Descripción de experiencia</label>
                                <p style="white-space: pre-line;"><%= escapar(descripcion)%></p>
                            </div>
                            <div class="dato-item">
                                <label>Servicios que ofrece</label>
                                <div style="margin-top: 8px;">
                                    <% if (servicios.isEmpty()) { %>
                                    <p style="color: #888;">No especificó servicios en el registro.</p>
                                    <% } else {
                                        for (String serv : servicios) {%>
                                    <span class="chip-servicio">✓ <%= escapar(serv)%></span>
                                    <%  }
                                        } %>
                                </div>
                            </div>
                        </div>

                        <!-- Tarjeta Documentación Subida -->
                        <div class="tarjeta-admin">
                            <h3>Documentos Adjuntos y Trabajos</h3>
                            <ul class="lista-docs">
                                <% if (documentos.isEmpty()) { %>
                                <p style="color: #888;">No se encontraron archivos subidos.</p>
                                <% } else {
                                    for (Documento doc : documentos) {
                                        // Traducir el tipo de documento para que se vea profesional en pantalla
                                        String nombreTipoDoc = doc.tipo;
                                        if ("ine".equals(doc.tipo))
                                            nombreTipoDoc = "Identificación Oficial (INE)";
                                        else if ("curp".equals(doc.tipo))
                                            nombreTipoDoc = "Constancia CURP";
                                        else if ("comprobante_domicilio".equals(doc.tipo))
                                            nombreTipoDoc = "Comprobante de Domicilio";
                                        else if ("foto_trabajo".equals(doc.tipo))
                                            nombreTipoDoc = "Foto de Trabajo Realizado";
                                %>
                                <li class="item-doc">
                                    <div>
                                        <strong style="display: block; font-size: 14px; color: #0c3b2e;"><%= escapar(nombreTipoDoc)%></strong>
                                        <span style="font-size: 11px; color: #777;">Estado: <%= escapar(doc.estado)%></span>
                                    </div>
                                    <a href="<%= ruta%>/<%= escapar(doc.ruta)%>" target="_blank" class="btn-ver-doc">📄 Ver Archivo</a>
                                </li>
                                <%  }
            } %>
                            </ul>
                        </div>

                        <!-- Columna Derecha: Panel de Decisión -->
                        <div>
                            <div class="tarjeta-admin" style="position: sticky; top: 20px;">
                                <h3>Resolución de la Solicitud</h3>
                                <p style="font-size: 13px; color: #666; margin-bottom: 20px;">
                                    Al tomar una decisión, el estado del trabajador se actualizará en la base de datos y se le enviará una notificación por correo electrónico.
                                </p>

                                <% if ("pendiente".equals(estadoRegistro)) {%>
                                <form action="<%= ruta%>/AprobarRechazarTrabajadorServlet" method="POST">
                                    <input type="hidden" name="idTrabajador" value="<%= idTrabajador%>">
                                    <input type="hidden" name="correoTrabajador" value="<%= correo%>">
                                    <input type="hidden" name="nombreTrabajador" value="<%= nombre%>">

                                    <div style="margin-bottom: 16px;">
                                        <label for="observaciones" style="display: block; font-size: 12px; font-weight: bold; color: #555; margin-bottom: 6px;">
                                            Observaciones / Motivo (Opcional):
                                        </label>
                                        <textarea id="observaciones" name="observaciones" rows="3" placeholder="Ingresa notas o razón en caso de rechazo..." style="width: 100%; border: 1px solid #ccc; border-radius: 8px; padding: 10px; font-family: inherit; font-size: 13px;"></textarea>
                                    </div>

                                    <button type="submit" name="accion" value="aprobar" class="btn-accion-aprobar">
                                        ✓ Aprobar y Notificar por Correo
                                    </button>

                                    <button type="submit" name="accion" value="rechazar" class="btn-accion-rechazar">
                                        ✕ Rechazar y Notificar por Correo
                                    </button>
                                </form>
                                <% } else {%>
                                <div style="text-align: center; padding: 20px; background: #f9f9f9; border-radius: 8px;">
                                    <strong>Esta solicitud ya ha sido evaluada.</strong>
                                    <p style="font-size: 13px; color: #666; margin-top: 6px;">
                                        Estado actual: <strong><%= estadoRegistro%></strong>
                                    </p>
                                </div>
                                <% }%>
                            </div>
                        </div>

                    </div>
            </main>
        </div>

    </body>
</html>
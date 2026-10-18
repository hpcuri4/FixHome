<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.fixhome.conexion.Conexion"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.List"%>
<%@page import="java.util.UUID"%>
<%@page import="java.text.SimpleDateFormat"%>

<%!
    private static class SolicitudTrabajadorFila {
        int idTrabajador;
        String folio;
        String nombreCompleto;
        String correo;
        String telefono;
        String fechaRegistro;
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

    private String nombreEstado(String estado) {
        if ("pendiente".equals(estado)) {
            return "Pendiente";
        }
        if ("aceptado".equals(estado) || "aceptada".equals(estado)) {
            return "Aceptado";
        }
        if ("rechazado".equals(estado) || "rechazada".equals(estado)) {
            return "Rechazado";
        }
        return "Sin estado";
    }

    private String claseEstado(String estado) {
        if ("pendiente".equals(estado)) {
            return "solicitud-pendiente";
        }
        if ("aceptado".equals(estado) || "aceptada".equals(estado)) {
            return "solicitud-aceptada";
        }
        return "solicitud-cancelada";
    }
%>

<%
    if (session.getAttribute("idAdministrador") == null && session.getAttribute("idUsuario") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    response.setHeader("Cache-Control", "no-store");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String ruta = request.getContextPath();

    if (session.getAttribute("tokenCerrarSesion") == null) {
        session.setAttribute(
            "tokenCerrarSesion",
            UUID.randomUUID().toString()
        );
    }

    String tokenCerrarSesion = (String) session.getAttribute("tokenCerrarSesion");

    String buscar = request.getParameter("buscar");
    String estado = request.getParameter("estado");

    if (buscar == null) {
        buscar = "";
    }

    buscar = buscar.trim();

    if (!"pendiente".equals(estado)
            && !"aceptado".equals(estado)
            && !"rechazado".equals(estado)) {
        estado = "";
    }

    int totalSolicitudes = 0;
    int totalPendientes = 0;
    int totalAceptadas = 0;

    boolean errorDatos = false;

    List<SolicitudTrabajadorFila> solicitudes = new ArrayList<>();

    try (Connection conexion = Conexion.conectar()) {

        // 1. Contadores generales de solicitudes de trabajadores
        String sqlTotales =
            "SELECT COUNT(*) AS total, " +
            " COALESCE(SUM(t.estado_registro = 'pendiente'), 0) AS pendientes, " +
            " COALESCE(SUM(t.estado_registro = 'aceptado'), 0) AS aceptadas " +
            " FROM trabajadores t";

        try (PreparedStatement consulta = conexion.prepareStatement(sqlTotales);
             ResultSet resultado = consulta.executeQuery()) {

            if (resultado.next()) {
                totalSolicitudes = resultado.getInt("total");
                totalPendientes = resultado.getInt("pendientes");
                totalAceptadas = resultado.getInt("aceptadas");
            }
        }

        // 2. Consulta de solicitudes de registro de trabajadores
        String sql =
            "SELECT t.id_trabajador, " +
            " CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo, " +
            " u.correo, u.telefono, u.fecha_registro, " +
            " t.estado_registro " +
            " FROM trabajadores t " +
            " INNER JOIN usuarios u ON u.id_usuario = t.id_trabajador " +
            " WHERE (" +
            " CONCAT(u.nombre, ' ', u.apellidos) LIKE ? " +
            " OR u.correo LIKE ? " +
            " OR CAST(t.id_trabajador AS CHAR) LIKE ? " +
            " OR CONCAT('REG-', LPAD(t.id_trabajador, 5, '0')) LIKE ?" +
            " ) ";

        if (!estado.isEmpty()) {
            sql += " AND t.estado_registro = ? ";
        }

        sql += " ORDER BY u.fecha_registro DESC";

        try (PreparedStatement consulta = conexion.prepareStatement(sql)) {

            String coincidencia = "%" + buscar + "%";

            consulta.setString(1, coincidencia);
            consulta.setString(2, coincidencia);
            consulta.setString(3, coincidencia);
            consulta.setString(4, coincidencia);

            if (!estado.isEmpty()) {
                consulta.setString(5, estado);
            }

            try (ResultSet resultado = consulta.executeQuery()) {

                SimpleDateFormat formato = new SimpleDateFormat("dd/MM/yyyy HH:mm");

                while (resultado.next()) {

                    SolicitudTrabajadorFila solicitud = new SolicitudTrabajadorFila();

                    solicitud.idTrabajador = resultado.getInt("id_trabajador");
                    solicitud.folio = String.format(java.util.Locale.ROOT, "REG-%05d", solicitud.idTrabajador);
                    solicitud.nombreCompleto = resultado.getString("nombre_completo");
                    solicitud.correo = resultado.getString("correo");
                    solicitud.telefono = resultado.getString("telefono");

                    java.sql.Timestamp fecha = resultado.getTimestamp("fecha_registro");
                    solicitud.fechaRegistro = (fecha == null) ? "Sin fecha" : formato.format(fecha);

                    solicitud.estado = resultado.getString("estado_registro");

                    solicitudes.add(solicitud);
                }
            }
        }

    } catch (SQLException e) {
        errorDatos = true;
        application.log("Error al consultar las solicitudes de trabajadores en FixHome.", e);
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Solicitudes de Registro | FixHome</title>
    <link rel="stylesheet" href="<%= ruta %>/ESTILOS-CSS/estilo-principal.css">
</head>

<body class="pagina-admin pagina-solicitudes">

    <!-- Iconos de contorno -->
    <svg class="iconos-admin" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" style="position:absolute;width:0;height:0;overflow:hidden">
        <symbol id="icono-inicio" viewBox="0 0 24 24">
            <g fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <path d="M3 10 12 3l9 7"></path>
                <path d="M5 9v12h5v-7h4v7h5V9"></path>
            </g>
        </symbol>
        <symbol id="icono-usuarios" viewBox="0 0 24 24">
            <g fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="9" cy="7" r="3.5"></circle>
                <path d="M2 21v-3a7 7 0 0 1 14 0v3"></path>
                <path d="M17 3.5a3.5 3.5 0 0 1 0 7"></path>
                <path d="M19 14a6 6 0 0 1 3 5v2"></path>
            </g>
        </symbol>
        <symbol id="icono-trabajadores" viewBox="0 0 24 24">
            <g fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <path d="M14.7 6.3a5.5 5.5 0 0 0-7 7L3 18a2.1 2.1 0 0 0 3 3l4.7-4.7a5.5 5.5 0 0 0 7-7l-3.5 3.5-3-3z"></path>
            </g>
        </symbol>
        <symbol id="icono-solicitudes" viewBox="0 0 24 24">
            <g fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <rect x="5" y="2" width="14" height="20" rx="2"></rect>
                <path d="M9 7h6M9 11h6M9 15h4"></path>
            </g>
        </symbol>
        <symbol id="icono-configuracion" viewBox="0 0 24 24">
            <g fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <path d="m9 3 .6-2h4.8l.6 2 2 1.2 2.1-.4 2.4 4.2-1.4 1.6v2.4l1.4 1.6-2.4 4.2-2.1-.4-2 1.2-.6 2H9.6l-.6-2-2-1.2-2.1.4-2.4-4.2 1.4-1.6V9.6L2.5 8l2.4-4.2 2.1.4z"></path>
                <circle cx="12" cy="10.8" r="3"></circle>
            </g>
        </symbol>
        <symbol id="icono-reloj" viewBox="0 0 24 24">
            <g fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="9"></circle>
                <path d="M12 7v5l3 2"></path>
            </g>
        </symbol>
        <symbol id="icono-aceptadas" viewBox="0 0 24 24">
            <g fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="9"></circle>
                <path d="m7 12 3 3 7-7"></path>
            </g>
        </symbol>
    </svg>

    <!-- Menú lateral -->
    <aside class="barra-admin">
        <a href="<%= ruta %>/admin/index.jsp" class="logo">
            <img src="<%= ruta %>/Imagenes/logo.png" alt="">
            FixHome
        </a>

        <nav class="menu-admin" aria-label="Navegación del administrador">
            <a href="<%= ruta %>/admin/index.jsp">
                <svg class="icono-admin" aria-hidden="true"><use href="#icono-inicio"></use></svg>
                Inicio
            </a>
            <a href="<%= ruta %>/admin/usuarios.jsp">
                <svg class="icono-admin" aria-hidden="true"><use href="#icono-usuarios"></use></svg>
                Usuarios
            </a>
            <a href="<%= ruta %>/admin/trabajadores.jsp">
                <svg class="icono-admin" aria-hidden="true"><use href="#icono-trabajadores"></use></svg>
                Trabajadores
            </a>
            <a href="<%= ruta %>/admin/solicitudes.jsp" class="activo" aria-current="page">
                <svg class="icono-admin" aria-hidden="true"><use href="#icono-solicitudes"></use></svg>
                Solicitudes
            </a>
            <a href="<%= ruta %>/admin/configuracion.jsp">
                <svg class="icono-admin" aria-hidden="true"><use href="#icono-configuracion"></use></svg>
                Configuración
            </a>
        </nav>
    </aside>

    <div class="contenido-admin">
        <!-- Encabezado superior -->
        <jsp:include page="encabezado-admin.jsp"/>

        <main class="principal-admin">

            <section class="titulo-admin">
                <h1>Solicitudes de Registro de Trabajadores</h1>
            </section>

            <% if (!errorDatos) { %>

                <!-- Contadores -->
                <section class="resumen-admin resumen-solicitudes" aria-label="Resumen de solicitudes">

                    <article class="tarjeta-resumen">
                        <div class="imagen-resumen">
                            <svg class="icono-admin" aria-hidden="true"><use href="#icono-solicitudes"></use></svg>
                        </div>
                        <div>
                            <p class="numero-resumen"><%= totalSolicitudes %></p>
                            <h2>Solicitudes totales</h2>
                        </div>
                    </article>

                    <article class="tarjeta-resumen">
                        <div class="imagen-resumen imagen-resumen-naranja">
                            <svg class="icono-admin" aria-hidden="true"><use href="#icono-reloj"></use></svg>
                        </div>
                        <div>
                            <p class="numero-resumen"><%= totalPendientes %></p>
                            <h2>Pendientes por revisar</h2>
                        </div>
                    </article>

                    <article class="tarjeta-resumen">
                        <div class="imagen-resumen">
                            <svg class="icono-admin" aria-hidden="true"><use href="#icono-aceptadas"></use></svg>
                        </div>
                        <div>
                            <p class="numero-resumen"><%= totalAceptadas %></p>
                            <h2>Aprobadas</h2>
                        </div>
                    </article>

                </section>

            <% } %>

            <!-- Buscador y filtro -->
            <form class="filtros-usuarios" action="<%= ruta %>/admin/solicitudes.jsp" method="get">

                <div class="campo-busqueda-usuarios">
                    <label for="buscar-solicitud">Buscar solicitud</label>
                    <input type="search" id="buscar-solicitud" name="buscar" placeholder="Folio, correo o nombre del aspirante" value="<%= escapar(buscar) %>">
                </div>

                <div class="campo-estado-usuarios">
                    <label for="estado-solicitud">Estado</label>
                    <select id="estado-solicitud" name="estado">
                        <option value="">Todos</option>
                        <option value="pendiente" <%= "pendiente".equals(estado) ? "selected" : "" %>>Pendientes</option>
                        <option value="aceptado" <%= "aceptado".equals(estado) ? "selected" : "" %>>Aceptadas</option>
                        <option value="rechazado" <%= "rechazado".equals(estado) ? "selected" : "" %>>Rechazadas</option>
                    </select>
                </div>

                <button type="submit" class="boton-buscar-usuarios">Buscar</button>
                <a href="<%= ruta %>/admin/solicitudes.jsp" class="limpiar-filtros-usuarios">Limpiar</a>

            </form>

            <% if (errorDatos) { %>

                <div class="error-admin" role="alert">
                    No se pudieron cargar las solicitudes. Intenta nuevamente.
                </div>

            <% } else { %>

                <section class="listado-usuarios" aria-labelledby="titulo-listado-solicitudes">

                    <div class="encabezado-listado-usuarios">
                        <h2 id="titulo-listado-solicitudes">Aspirantes registrados</h2>
                        <span class="total-usuarios"><%= solicitudes.size() %> resultados</span>
                    </div>

                    <% if (solicitudes.isEmpty()) { %>

                        <div class="sin-usuarios">
                            <h3>No se encontraron solicitudes de registro</h3>
                            <p>Si ya hay registros, prueba con otra búsqueda o selecciona un estado diferente.</p>
                        </div>

                    <% } else { %>

                        <div class="contenedor-tabla-usuarios">
                            <table class="tabla-usuarios tabla-solicitudes">
                                <thead>
                                    <tr>
                                        <th scope="col">Folio</th>
                                        <th scope="col">Nombre del Trabajador</th>
                                        <th scope="col">Correo Electrónico</th>
                                        <th scope="col">Teléfono</th>
                                        <th scope="col">Fecha Registro</th>
                                        <th scope="col">Estado</th>
                                        <th scope="col">Acciones</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (SolicitudTrabajadorFila solicitud : solicitudes) { %>
                                        <tr>
                                            <td class="folio-solicitud">
                                                <%= escapar(solicitud.folio) %>
                                            </td>
                                            <td>
                                                <span class="nombre-usuario">
                                                    <%= escapar(solicitud.nombreCompleto) %>
                                                </span>
                                            </td>
                                            <td>
                                                <%= escapar(solicitud.correo) %>
                                            </td>
                                            <td>
                                                <%= escapar(solicitud.telefono != null ? solicitud.telefono : "N/A") %>
                                            </td>
                                            <td>
                                                <%= escapar(solicitud.fechaRegistro) %>
                                            </td>
                                            <td>
                                                <span class="estado-solicitud <%= claseEstado(solicitud.estado) %>">
                                                    <%= nombreEstado(solicitud.estado) %>
                                                </span>
                                            </td>
                                            <td>
                                                <a class="boton-perfil-usuario"
                                                   href="<%= ruta %>/admin/detalle-solicitud.jsp?id=<%= solicitud.idTrabajador %>"
                                                   aria-label="Revisar solicitud <%= escapar(solicitud.folio) %>">
                                                    Revisar
                                                </a>
                                            </td>
                                        </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>

                    <% } %>

                </section>

            <% } %>

        </main>
    </div>

</body>
</html>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FixHome | Registro en Revisión</title>
    <link rel="stylesheet" href="<%= request.getContextPath()%>/ESTILOS-CSS/estilo-logincliente.css">
    <link rel="stylesheet" href="<%= request.getContextPath()%>/ESTILOS-CSS/estilo-principal.css">
    <style>
        .contenedor-confirmacion {
            max-width: 580px;
            margin: 60px auto;
            background: #ffffff;
            border-radius: 16px;
            padding: 40px;
            text-align: center;
            box-shadow: 0 10px 25px rgba(0,0,0,0.05);
            border: 1px solid #e0e0e0;
        }
        .icono-exito {
            width: 80px;
            height: 80px;
            background: #e8f5e9;
            color: #2e7d32;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 40px;
            margin: 0 auto 24px auto;
        }
        .titulo-confirmacion {
            color: #0c3b2e;
            font-size: 26px;
            font-weight: 700;
            margin-bottom: 12px;
        }
        .texto-confirmacion {
            color: #555555;
            font-size: 15px;
            line-height: 1.6;
            margin-bottom: 24px;
        }
        .tarjeta-pasos {
            background: #f4f6f4;
            border: 1px solid #d0ded4;
            border-radius: 12px;
            padding: 20px;
            text-align: left;
            margin-bottom: 30px;
        }
        .tarjeta-pasos h4 {
            color: #0c3b2e;
            margin-bottom: 12px;
            font-size: 15px;
        }
        .tarjeta-pasos ul {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        .tarjeta-pasos li {
            font-size: 13px;
            color: #2c4c3e;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .btn-inicio {
            display: inline-block;
            background: #0c3b2e;
            color: #ffffff;
            padding: 14px 28px;
            border-radius: 10px;
            font-weight: 600;
            text-decoration: none;
            transition: background 0.2s;
        }
        .btn-inicio:hover {
            background: #06241c;
        }
    </style>
</head>
<body class="pagina-login-cliente">
    <header class="encabezado-login">
        <a href="<%= request.getContextPath()%>/index.html" class="logo">
            <img src="<%= request.getContextPath()%>/Imagenes/logo.png" alt="Logo FixHome">
            FixHome
        </a>
    </header>

    <main class="contenedor-confirmacion">
        <div class="icono-exito">📋</div>
        <h1 class="titulo-confirmacion">¡Solicitud recibida con éxito!</h1>
        <p class="texto-confirmacion">
            Gracias por registrarte en <strong>FixHome</strong>. Hemos recibido tu información y la documentación adjunta. Tu perfil ha ingresado a nuestra fase de validación.
        </p>

        <div class="tarjeta-pasos">
            <h4>Próximos pasos:</h4>
            <ul>
                <li>⏳ <strong>Inspección:</strong> El equipo administrativo verificará la validez de tu documentación (INE, CURP y comprobante de domicilio).</li>
                <li>📧 <strong>Notificación:</strong> Recibirás un correo electrónico con la resolución de tu solicitud en los próximos días.</li>
                <li>🔑 <strong>Acceso:</strong> Una vez aprobada tu cuenta, podrás iniciar sesión y comenzar a recibir solicitudes de clientes.</li>
            </ul>
        </div>

        <a href="<%= request.getContextPath()%>/index.html" class="btn-inicio">Volver a la página principal</a>
    </main>
</body>
</html>
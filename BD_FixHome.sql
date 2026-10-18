CREATE DATABASE IF NOT EXISTS fixhome
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE fixhome;

-- 1. DATOS DE ACCESO Y PERFIL
-- La baja de una cuenta se realiza cambiando activo a FALSE.

CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    contrasena_hash VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    foto_perfil VARCHAR(500),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;

-- 2. CLIENTES

CREATE TABLE clientes (
    id_cliente INT PRIMARY KEY,
    FOREIGN KEY (id_cliente)
        REFERENCES usuarios(id_usuario)
) ENGINE = InnoDB;

-- 3. ADMINISTRADORES

CREATE TABLE administradores (
    id_administrador INT PRIMARY KEY,
    notificar_registros BOOLEAN NOT NULL DEFAULT TRUE,
    notificar_avisos BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (id_administrador)
        REFERENCES usuarios(id_usuario)
) ENGINE = InnoDB;

-- 4. TRABAJADORES
-- La aprobación del registro es distinta de aceptar un servicio.

CREATE TABLE trabajadores (
    id_trabajador INT PRIMARY KEY,
    curp VARCHAR(18) NOT NULL UNIQUE,
    domicilio VARCHAR(300) NOT NULL,
    descripcion_experiencia TEXT,
    estado_registro ENUM(
        'pendiente',
        'aceptado',
        'rechazado'
    ) NOT NULL DEFAULT 'pendiente',
    observaciones_revision TEXT,
    revisado_por INT,
    fecha_revision DATETIME,

    FOREIGN KEY (id_trabajador)
        REFERENCES usuarios(id_usuario),

    FOREIGN KEY (revisado_por)
        REFERENCES administradores(id_administrador)
) ENGINE = InnoDB;

-- 5. DOCUMENTOS DEL TRABAJADOR
-- Se guarda la ruta del archivo, no el archivo completo.
-- Un trabajador puede enviar varias fotos de sus trabajos.

CREATE TABLE documentos_trabajador (
    id_documento INT AUTO_INCREMENT PRIMARY KEY,
    id_trabajador INT NOT NULL,
    tipo ENUM(
        'comprobante_domicilio',
        'curp',
        'foto_trabajo'
    ) NOT NULL,
    ruta_archivo VARCHAR(500) NOT NULL,
    estado ENUM(
        'pendiente',
        'validado',
        'rechazado'
    ) NOT NULL DEFAULT 'pendiente',
    observaciones TEXT,
    fecha_subida DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_trabajador)
        REFERENCES trabajadores(id_trabajador)
) ENGINE = InnoDB;

-- 6. CATÁLOGO DE SERVICIOS

CREATE TABLE servicios (
    id_servicio INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE = InnoDB;

-- 7. SERVICIOS OFRECIDOS POR CADA TRABAJADOR
-- Un trabajador puede ofrecer varios servicios.
-- Un servicio puede ser ofrecido por varios trabajadores.

CREATE TABLE trabajador_servicios (
    id_trabajador INT NOT NULL,
    id_servicio INT NOT NULL,

    PRIMARY KEY (id_trabajador, id_servicio),

    FOREIGN KEY (id_trabajador)
        REFERENCES trabajadores(id_trabajador),

    FOREIGN KEY (id_servicio)
        REFERENCES servicios(id_servicio)
) ENGINE = InnoDB;

-- 8. SOLICITUDES DE SERVICIO
-- id_trabajador queda vacío hasta que alguien acepta.
-- La ubicación se conserva en la solicitud para el historial.

CREATE TABLE solicitudes (
    id_solicitud INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_servicio INT NOT NULL,
    id_trabajador INT,
    tipo_trabajo ENUM(
        'instalacion',
        'reparacion'
    ) NOT NULL,
    descripcion TEXT NOT NULL,
    direccion VARCHAR(300) NOT NULL,
    referencias_ubicacion VARCHAR(300),
    fecha_solicitud DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_programada DATETIME,
    fecha_aceptacion DATETIME,
    fecha_finalizacion DATETIME,
    estado ENUM(
        'pendiente',
        'aceptada',
        'finalizada',
        'cancelada'
    ) NOT NULL DEFAULT 'pendiente',
    monto_acordado DECIMAL(10,2),
    motivo_cancelacion TEXT,

    CONSTRAINT chk_monto_solicitud
        CHECK (monto_acordado IS NULL OR monto_acordado >= 0),

    CONSTRAINT chk_asignacion_solicitud
        CHECK (
            estado NOT IN ('aceptada', 'finalizada')
            OR id_trabajador IS NOT NULL
        ),

    FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),

    FOREIGN KEY (id_servicio)
        REFERENCES servicios(id_servicio),

    -- Garantiza que el trabajador ofrece el servicio solicitado.
    FOREIGN KEY (id_trabajador, id_servicio)
        REFERENCES trabajador_servicios(id_trabajador, id_servicio),

    INDEX idx_cliente_estado (id_cliente, estado),
    INDEX idx_trabajador_estado (id_trabajador, estado),
    INDEX idx_estado_fecha (estado, fecha_solicitud)
) ENGINE = InnoDB;

-- 9. PAGOS
-- El proyecto utiliza pagos simulados.
-- No se guardan números de tarjeta ni CVV.
-- La comisión queda sin definir hasta que se acuerde.

CREATE TABLE pagos (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_solicitud INT NOT NULL UNIQUE,
    metodo ENUM(
        'tarjeta',
        'efectivo'
    ) NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    comision_fixhome DECIMAL(10,2),
    estado ENUM(
        'pendiente',
        'pagado',
        'cancelado'
    ) NOT NULL DEFAULT 'pendiente',
    es_simulado BOOLEAN NOT NULL DEFAULT TRUE,
    referencia VARCHAR(100),
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_pago DATETIME,

    CONSTRAINT chk_monto_pago
        CHECK (monto >= 0),

    CONSTRAINT chk_comision_pago
        CHECK (
            comision_fixhome IS NULL
            OR (comision_fixhome >= 0 AND comision_fixhome <= monto)
        ),

    FOREIGN KEY (id_solicitud)
        REFERENCES solicitudes(id_solicitud)
) ENGINE = InnoDB;

-- 10. CALIFICACIONES
-- Una calificación por solicitud.
-- El cliente y trabajador se obtienen de la solicitud.

CREATE TABLE calificaciones (
    id_calificacion INT AUTO_INCREMENT PRIMARY KEY,
    id_solicitud INT NOT NULL UNIQUE,
    puntuacion TINYINT NOT NULL,
    comentario TEXT,
    fecha_calificacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_puntuacion
        CHECK (puntuacion BETWEEN 1 AND 5),

    FOREIGN KEY (id_solicitud)
        REFERENCES solicitudes(id_solicitud)
) ENGINE = InnoDB;

-- LISTADO DEL PANEL: SOLO TRABAJADORES ACEPTADOS Y ACTIVOS

CREATE VIEW vista_trabajadores_activos AS
SELECT
    t.id_trabajador,
    u.nombre,
    u.apellidos,
    u.correo,
    u.telefono,
    t.descripcion_experiencia
FROM trabajadores AS t
INNER JOIN usuarios AS u
    ON u.id_usuario = t.id_trabajador
WHERE t.estado_registro = 'aceptado'
  AND u.activo = TRUE;

-- VER LAS TABLAS CREADAS

SHOW TABLES;
SHOW CREATE TABLE usuarios;


INSERT INTO usuarios (
    nombre,
    apellidos,
    correo,
    contrasena_hash,
    activo
)
VALUES (
    'Administrador',
    'FixHome',
    'admin@fixhome.com',
    'admin123',
    TRUE
);

INSERT INTO administradores (id_administrador)
SELECT id_usuario
FROM usuarios
WHERE correo = 'admin@fixhome.com';

SELECT
    u.id_usuario,
    u.nombre,
    u.correo,
    u.activo
FROM usuarios AS u
INNER JOIN administradores AS a
    ON a.id_administrador = u.id_usuario;
    
    USE fixhome;

SELECT
    u.id_usuario,
    u.correo,
    u.activo,
    a.id_administrador,
    CHAR_LENGTH(u.contrasena_hash) AS longitud_hash,
    LEFT(u.contrasena_hash, 4) AS inicio_hash
FROM usuarios AS u
LEFT JOIN administradores AS a
    ON a.id_administrador = u.id_usuario
WHERE u.correo = 'admin@fixhome.com';


-- Administrador, Usuario y Trabajador de prueba

UPDATE usuarios
SET contrasena_hash = '$2a$12$q4Xetw/j.Nngu3LqF4EM1.mM2tUPLum6/XZ7sxjXCDL.VoG5oitWi'
WHERE id_usuario = 1
  AND correo = 'admin@fixhome.com';
  
  USE fixhome;

-- 1. Insertar el usuario general (con su contraseña o hash de prueba)
INSERT INTO usuarios (
    nombre,
    apellidos,
    correo,
    contrasena_hash,
    telefono,
    activo
)
VALUES (
    'Pablo',
    'Martinez Garcia',
    'cliente@fixhome.com',
    '$2a$12$q4Xetw/j.Nngu3LqF4EM1.mM2tUPLum6/XZ7sxjXCDL.VoG5oitWi', -- contraseña: 123456
    '5512345678',
    TRUE
);

-- 2. Registrar el ID generado en la tabla dependiente de clientes
INSERT INTO clientes (id_cliente)
VALUES (LAST_INSERT_ID());

-- Trabajador

-- 1. Insertar el usuario base del trabajador
INSERT INTO usuarios (
    nombre,
    apellidos,
    correo,
    contrasena_hash,
    telefono,
    activo
)
VALUES (
    'Roberto',
    'Sánchez Pérez',
    'trabajador@fixhome.com',
    '$2a$12$q4Xetw/j.Nngu3LqF4EM1.mM2tUPLum6/XZ7sxjXCDL.VoG5oitWi', -- Contraseña de prueba: 123456 (igual que el cliente)
    '5587654321',
    TRUE
);

-- 2. Registrar el ID generado en la tabla de trabajadores con sus datos obligatorios y estado 'aceptado'
INSERT INTO trabajadores (
    id_trabajador,
    curp,
    domicilio,
    descripcion_experiencia,
    estado_registro
)
VALUES (
    LAST_INSERT_ID(),
    'SAPR850101HDFMSR09',
    'Av. Central #123, Col. Centro, CDMX',
    'Especialista en instalaciones eléctricas residenciales, cableado estructurado y sistemas de iluminación con más de 5 años de experiencia.',
    'aceptado'
);

INSERT INTO servicios (nombre, descripcion, activo) VALUES 
('Plomería', 'Reparación e instalación de tuberías, grifos y sanitarios.', TRUE),
('Electricidad', 'Instalaciones eléctricas, cableado y mantenimiento.', TRUE),
('Carpintería', 'Fabricación y reparación de muebles de madera.', TRUE),
('Pintura', 'Pintura residencial y comercial, interiores y exteriores.', TRUE),
('Jardinería', 'Mantenimiento de áreas verdes y poda de árboles.', TRUE),
('Limpieza', 'Limpieza profunda de hogares y oficinas.', TRUE);
  

  select * from usuarios;
  select * from trabajadores;
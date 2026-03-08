-- ============================================================
-- MINIMARKET DB — SCHEMA INICIAL COMPLETO
-- Motor: PostgreSQL 15+
-- Extensiones: uuid-ossp, pgcrypto
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- ROLES
-- ============================================================
CREATE TABLE roles (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    activo      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- USUARIOS
-- ============================================================
CREATE TABLE usuarios (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rol_id              INTEGER NOT NULL REFERENCES roles(id),
    nombre_completo     VARCHAR(150) NOT NULL,
    email               VARCHAR(150) NOT NULL UNIQUE,
    username            VARCHAR(50) NOT NULL UNIQUE,
    password_hash       VARCHAR(255) NOT NULL,
    activo              BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_login        TIMESTAMPTZ,
    intentos_fallidos   SMALLINT NOT NULL DEFAULT 0,
    bloqueado_hasta     TIMESTAMPTZ,
    reset_token         VARCHAR(255),
    reset_token_expira  TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

-- ============================================================
-- REFRESH TOKENS
-- ============================================================
CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id  UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    token       VARCHAR(512) NOT NULL UNIQUE,
    expira_en   TIMESTAMPTZ NOT NULL,
    revocado    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- CATEGORIAS
-- ============================================================
CREATE TABLE categorias (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    descripcion     TEXT,
    parent_id       INTEGER REFERENCES categorias(id),
    icono           VARCHAR(100),
    color_hex       VARCHAR(7),
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PROVEEDORES
-- ============================================================
CREATE TABLE proveedores (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre_empresa  VARCHAR(150) NOT NULL,
    nit_ruc         VARCHAR(20),
    contacto        VARCHAR(100),
    telefono        VARCHAR(20),
    email           VARCHAR(150),
    direccion       TEXT,
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

-- ============================================================
-- UNIDADES DE MEDIDA
-- ============================================================
CREATE TABLE unidades_medida (
    id      SERIAL PRIMARY KEY,
    nombre  VARCHAR(50) NOT NULL,
    simbolo VARCHAR(10) NOT NULL
);

-- ============================================================
-- PRODUCTOS
-- ============================================================
CREATE TABLE productos (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    categoria_id        INTEGER REFERENCES categorias(id),
    proveedor_id        UUID REFERENCES proveedores(id),
    unidad_medida_id    INTEGER NOT NULL REFERENCES unidades_medida(id),
    codigo_barras       VARCHAR(50) UNIQUE,
    nombre              VARCHAR(200) NOT NULL,
    descripcion         TEXT,
    precio_compra       NUMERIC(12, 2) NOT NULL DEFAULT 0,
    precio_venta        NUMERIC(12, 2) NOT NULL,
    margen_ganancia     NUMERIC(5, 2) GENERATED ALWAYS AS (
                            CASE WHEN precio_compra > 0
                                 THEN ROUND(((precio_venta - precio_compra) / precio_compra * 100), 2)
                                 ELSE 0
                            END
                        ) STORED,
    stock_actual        NUMERIC(12, 3) NOT NULL DEFAULT 0,
    stock_minimo        NUMERIC(12, 3) NOT NULL DEFAULT 5,
    stock_maximo        NUMERIC(12, 3),
    imagen_url          VARCHAR(500),
    aplica_impuesto     BOOLEAN NOT NULL DEFAULT FALSE,
    porcentaje_impuesto NUMERIC(5, 2) NOT NULL DEFAULT 0,
    activo              BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

-- ============================================================
-- PRODUCTO VARIANTES
-- ============================================================
CREATE TABLE producto_variantes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    producto_id     UUID NOT NULL REFERENCES productos(id),
    nombre_variante VARCHAR(100) NOT NULL,
    codigo_barras   VARCHAR(50) UNIQUE,
    precio_venta    NUMERIC(12, 2),
    stock_actual    NUMERIC(12, 3) NOT NULL DEFAULT 0,
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- DESCUENTOS
-- ============================================================
CREATE TABLE descuentos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre          VARCHAR(100) NOT NULL,
    tipo            VARCHAR(20) NOT NULL CHECK (tipo IN ('PORCENTAJE', 'MONTO_FIJO')),
    valor           NUMERIC(10, 2) NOT NULL,
    aplica_a        VARCHAR(20) NOT NULL CHECK (aplica_a IN ('PRODUCTO', 'CATEGORIA', 'GLOBAL')),
    producto_id     UUID REFERENCES productos(id),
    categoria_id    INTEGER REFERENCES categorias(id),
    cantidad_minima NUMERIC(12, 3) DEFAULT 1,
    fecha_inicio    DATE NOT NULL,
    fecha_fin       DATE,
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- CAJAS (TURNOS)
-- ============================================================
CREATE TABLE cajas (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id          UUID NOT NULL REFERENCES usuarios(id),
    monto_apertura      NUMERIC(12, 2) NOT NULL DEFAULT 0,
    monto_cierre        NUMERIC(12, 2),
    monto_esperado      NUMERIC(12, 2),
    diferencia          NUMERIC(12, 2),
    hora_apertura       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    hora_cierre         TIMESTAMPTZ,
    estado              VARCHAR(20) NOT NULL DEFAULT 'ABIERTA' CHECK (estado IN ('ABIERTA', 'CERRADA')),
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- VENTAS
-- ============================================================
CREATE TABLE ventas (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    caja_id             UUID NOT NULL REFERENCES cajas(id),
    usuario_id          UUID NOT NULL REFERENCES usuarios(id),
    numero_recibo       VARCHAR(30) NOT NULL UNIQUE,
    subtotal            NUMERIC(12, 2) NOT NULL,
    descuento_monto     NUMERIC(12, 2) NOT NULL DEFAULT 0,
    impuesto_monto      NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total               NUMERIC(12, 2) NOT NULL,
    estado              VARCHAR(20) NOT NULL DEFAULT 'COMPLETADA'
                            CHECK (estado IN ('COMPLETADA', 'ANULADA')),
    motivo_anulacion    TEXT,
    anulada_por         UUID REFERENCES usuarios(id),
    anulada_en          TIMESTAMPTZ,
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- VENTA ITEMS
-- ============================================================
CREATE TABLE venta_items (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venta_id            UUID NOT NULL REFERENCES ventas(id),
    producto_id         UUID NOT NULL REFERENCES productos(id),
    variante_id         UUID REFERENCES producto_variantes(id),
    nombre_producto     VARCHAR(200) NOT NULL,
    codigo_barras       VARCHAR(50),
    cantidad            NUMERIC(12, 3) NOT NULL,
    precio_unitario     NUMERIC(12, 2) NOT NULL,
    precio_costo        NUMERIC(12, 2) NOT NULL,
    descuento_item      NUMERIC(12, 2) NOT NULL DEFAULT 0,
    subtotal            NUMERIC(12, 2) NOT NULL,
    impuesto_item       NUMERIC(12, 2) NOT NULL DEFAULT 0
);

-- ============================================================
-- PAGOS
-- ============================================================
CREATE TABLE pagos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venta_id        UUID NOT NULL REFERENCES ventas(id),
    metodo_pago     VARCHAR(30) NOT NULL
                        CHECK (metodo_pago IN ('EFECTIVO', 'TARJETA_DEBITO',
                               'TARJETA_CREDITO', 'QR', 'OTRO')),
    monto           NUMERIC(12, 2) NOT NULL,
    referencia      VARCHAR(100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- COMPRAS (INGRESOS DE MERCADERÍA)
-- ============================================================
CREATE TABLE compras (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proveedor_id        UUID REFERENCES proveedores(id),
    usuario_id          UUID NOT NULL REFERENCES usuarios(id),
    numero_factura      VARCHAR(50),
    fecha_compra        DATE NOT NULL DEFAULT CURRENT_DATE,
    subtotal            NUMERIC(12, 2) NOT NULL,
    impuesto_monto      NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total               NUMERIC(12, 2) NOT NULL,
    estado              VARCHAR(20) NOT NULL DEFAULT 'CONFIRMADA'
                            CHECK (estado IN ('BORRADOR', 'CONFIRMADA', 'ANULADA')),
    motivo_anulacion    TEXT,
    observaciones       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- COMPRA ITEMS
-- ============================================================
CREATE TABLE compra_items (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    compra_id           UUID NOT NULL REFERENCES compras(id),
    producto_id         UUID NOT NULL REFERENCES productos(id),
    variante_id         UUID REFERENCES producto_variantes(id),
    cantidad            NUMERIC(12, 3) NOT NULL,
    precio_unitario     NUMERIC(12, 2) NOT NULL,
    subtotal            NUMERIC(12, 2) NOT NULL
);

-- ============================================================
-- MOVIMIENTOS INVENTARIO (KARDEX)
-- ============================================================
CREATE TABLE movimientos_inventario (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    producto_id         UUID NOT NULL REFERENCES productos(id),
    variante_id         UUID REFERENCES producto_variantes(id),
    usuario_id          UUID NOT NULL REFERENCES usuarios(id),
    tipo_movimiento     VARCHAR(30) NOT NULL
                            CHECK (tipo_movimiento IN (
                                'VENTA', 'COMPRA', 'AJUSTE_ENTRADA',
                                'AJUSTE_SALIDA', 'MERMA', 'DEVOLUCION'
                            )),
    referencia_id       UUID,
    referencia_tipo     VARCHAR(20),
    cantidad_cambio     NUMERIC(12, 3) NOT NULL,
    stock_anterior      NUMERIC(12, 3) NOT NULL,
    stock_resultante    NUMERIC(12, 3) NOT NULL,
    precio_costo        NUMERIC(12, 2),
    observacion         TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- AJUSTES INVENTARIO
-- ============================================================
CREATE TABLE ajustes_inventario (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id          UUID NOT NULL REFERENCES usuarios(id),
    producto_id         UUID NOT NULL REFERENCES productos(id),
    stock_sistema       NUMERIC(12, 3) NOT NULL,
    stock_fisico        NUMERIC(12, 3) NOT NULL,
    diferencia          NUMERIC(12, 3) GENERATED ALWAYS AS (stock_fisico - stock_sistema) STORED,
    motivo              TEXT NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PREDICCIONES IA
-- ============================================================
CREATE TABLE predicciones_ia (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    producto_id         UUID NOT NULL REFERENCES productos(id),
    algoritmo           VARCHAR(30) NOT NULL,
    periodo_dias        SMALLINT NOT NULL,
    unidades_predichas  NUMERIC(12, 3) NOT NULL,
    mae                 NUMERIC(10, 4),
    mape                NUMERIC(10, 4),
    rmse                NUMERIC(10, 4),
    confianza           NUMERIC(5, 2),
    fecha_prediccion    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valido_hasta        DATE NOT NULL
);

-- ============================================================
-- SUGERENCIAS RECOMPRA
-- ============================================================
CREATE TABLE sugerencias_recompra (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    producto_id         UUID NOT NULL REFERENCES productos(id),
    prediccion_id       UUID REFERENCES predicciones_ia(id),
    proveedor_id        UUID REFERENCES proveedores(id),
    cantidad_sugerida   NUMERIC(12, 3) NOT NULL,
    fecha_limite_pedido DATE,
    estado              VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                            CHECK (estado IN ('PENDIENTE', 'APROBADA', 'RECHAZADA', 'CONVERTIDA')),
    aprobada_por        UUID REFERENCES usuarios(id),
    cantidad_aprobada   NUMERIC(12, 3),
    compra_generada_id  UUID REFERENCES compras(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- CONFIGURACION NEGOCIO
-- ============================================================
CREATE TABLE configuracion_negocio (
    id          SERIAL PRIMARY KEY,
    clave       VARCHAR(100) NOT NULL UNIQUE,
    valor       TEXT NOT NULL,
    descripcion TEXT,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- AUDITORIA
-- ============================================================
CREATE TABLE auditoria (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id       UUID REFERENCES usuarios(id),
    username         VARCHAR(50),
    accion           VARCHAR(100) NOT NULL,
    modulo           VARCHAR(50) NOT NULL,
    recurso_id       VARCHAR(100),
    datos_anteriores JSONB,
    datos_nuevos     JSONB,
    ip_address       INET,
    user_agent       TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- ÍNDICES DE RENDIMIENTO
-- ============================================================
CREATE INDEX idx_productos_codigo_barras ON productos(codigo_barras);
CREATE INDEX idx_productos_categoria     ON productos(categoria_id);
CREATE INDEX idx_productos_activo        ON productos(activo) WHERE deleted_at IS NULL;
CREATE INDEX idx_ventas_caja             ON ventas(caja_id);
CREATE INDEX idx_ventas_usuario          ON ventas(usuario_id);
CREATE INDEX idx_ventas_created_at       ON ventas(created_at DESC);
CREATE INDEX idx_ventas_estado           ON ventas(estado);
CREATE INDEX idx_venta_items_venta       ON venta_items(venta_id);
CREATE INDEX idx_venta_items_producto    ON venta_items(producto_id);
CREATE INDEX idx_movimientos_producto    ON movimientos_inventario(producto_id);
CREATE INDEX idx_movimientos_created_at  ON movimientos_inventario(created_at DESC);
CREATE INDEX idx_auditoria_usuario       ON auditoria(usuario_id);
CREATE INDEX idx_auditoria_created_at    ON auditoria(created_at DESC);
CREATE INDEX idx_refresh_tokens_token    ON refresh_tokens(token);
CREATE INDEX idx_cajas_usuario           ON cajas(usuario_id);
CREATE INDEX idx_cajas_estado            ON cajas(estado);

-- ============================================================
-- DATOS INICIALES (SEED)
-- ============================================================
INSERT INTO roles (nombre, descripcion) VALUES
    ('ADMINISTRADOR', 'Acceso completo al sistema'),
    ('VENDEDOR', 'Acceso al punto de venta');

INSERT INTO unidades_medida (nombre, simbolo) VALUES
    ('Unidad', 'und'),
    ('Kilogramo', 'kg'),
    ('Gramo', 'g'),
    ('Litro', 'L'),
    ('Mililitro', 'ml'),
    ('Metro', 'm'),
    ('Caja', 'cja'),
    ('Docena', 'doc');

INSERT INTO categorias (nombre, descripcion, color_hex) VALUES
    ('Bebidas',     'Refrescos, aguas, jugos',           '#7AAACE'),
    ('Panadería',   'Pan fresco y productos de bakery',  '#D69E2E'),
    ('Lácteos',     'Leche, queso, yogurt',              '#9CD5FF'),
    ('Limpieza',    'Productos de aseo del hogar',       '#38A169'),
    ('Snacks',      'Galletas, papas, dulces',           '#E53E3E'),
    ('Aceites',     'Aceites vegetales y grasas',        '#355872'),
    ('Granos',      'Arroz, azúcar, harinas',            '#F6E05E'),
    ('Higiene',     'Cuidado personal',                  '#9F7AEA');

INSERT INTO configuracion_negocio (clave, valor, descripcion) VALUES
    ('nombre_negocio',       'Mi Minimarket',            'Nombre del negocio'),
    ('direccion',            'Av. Siempre Viva 742',     'Dirección del negocio'),
    ('telefono',             '2-123456',                 'Teléfono de contacto'),
    ('nit_ruc',              '1234567',                  'NIT o RUC del negocio'),
    ('email_alertas',        '',                         'Email para alertas de stock'),
    ('porcentaje_iva',       '13',                       'Porcentaje de IVA'),
    ('moneda_simbolo',       'Bs.',                      'Símbolo de la moneda'),
    ('recibo_mensaje_pie',   '¡Gracias por su compra!', 'Mensaje en pie de recibo'),
    ('recibo_encabezado',    '',                         'Mensaje de encabezado del recibo'),
    ('sesion_timeout_min',   '30',                       'Minutos de inactividad'),
    ('max_intentos_login',   '5',                        'Intentos fallidos antes de bloquear'),
    ('duracion_bloqueo_min', '15',                       'Minutos de bloqueo de cuenta'),
    ('metodos_pago',         'EFECTIVO,TARJETA_DEBITO,TARJETA_CREDITO,QR', 'Métodos de pago habilitados');

-- ============================================================
-- USUARIO ADMINISTRADOR INICIAL
-- Password: Admin123! (hash BCrypt con 12 rounds)
-- ============================================================
INSERT INTO usuarios (rol_id, nombre_completo, email, username, password_hash) VALUES
    (1, 'Administrador del Sistema', 'admin@minimarket.com', 'admin',
     '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LGqvB2pUbJ0ZWZoOa');

-- ============================================================
-- PRODUCTOS DE EJEMPLO (DEMO)
-- ============================================================
INSERT INTO proveedores (nombre_empresa, contacto, telefono, email) VALUES
    ('Distribuidora Norte S.A.', 'Carlos Mamani', '70012345', 'vnorte@demo.com'),
    ('Importadora Sur Ltda.',    'Ana Quispe',    '71023456', 'isur@demo.com');

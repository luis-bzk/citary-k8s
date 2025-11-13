-- ============================================================================
-- EXTENSIÓN SAAS - SISTEMA DE SUSCRIPCIONES Y PAGOS
-- Tablas adicionales para convertir el sistema en SaaS
-- ============================================================================
-- ============================================================================
-- SCHEMAS ADICIONALES
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS billing;

-- Sistema de facturación y pagos
CREATE SCHEMA IF NOT EXISTS saas;

-- Configuración SaaS y planes
-- ============================================================================
-- TIPOS ENUMERADOS ADICIONALES
-- ============================================================================
-- Estados de suscripción
CREATE TYPE saas.subscription_status AS ENUM(
  'trial', -- Período de prueba
  'active', -- Activa y pagada
  'past_due', -- Pago vencido
  'canceled', -- Cancelada por usuario
  'suspended', -- Suspendida por falta de pago
  'expired' -- Expirada
);

-- Tipos de planes
CREATE TYPE saas.plan_type AS ENUM(
  'free', -- Plan gratuito
  'basic', -- Plan básico
  'professional', -- Plan profesional
  'enterprise', -- Plan empresarial
  'custom' -- Plan personalizado
);

-- Intervalos de facturación
CREATE TYPE billing.billing_interval AS ENUM(
  'monthly', -- Mensual
  'quarterly', -- Trimestral
  'annually', -- Anual
  'one_time' -- Pago único
);

-- Estados de factura
CREATE TYPE billing.invoice_status AS ENUM(
  'draft', -- Borrador
  'pending', -- Pendiente de pago
  'paid', -- Pagada
  'overdue', -- Vencida
  'cancelled', -- Cancelada
  'refunded' -- Reembolsada
);

-- Métodos de pago
CREATE TYPE billing.payment_method_type AS ENUM(
  'credit_card', -- Tarjeta de crédito
  'debit_card', -- Tarjeta de débito
  'bank_transfer', -- Transferencia bancaria
  'paypal', -- PayPal
  'stripe', -- Stripe
  'mercadopago', -- MercadoPago
  'other' -- Otro método
);

-- Estados de pago
CREATE TYPE billing.payment_status AS ENUM(
  'pending', -- Pendiente
  'processing', -- Procesando
  'completed', -- Completado
  'failed', -- Falló
  'cancelled', -- Cancelado
  'refunded' -- Reembolsado
);

-- Tipos de límites
CREATE TYPE saas.limit_type AS ENUM(
  'appointments_per_month', -- Citas por mes
  'active_patients', -- Pacientes activos
  'storage_gb', -- Almacenamiento en GB
  'api_calls_per_month', -- Llamadas API por mes
  'locations', -- Número de ubicaciones
  'professionals', -- Número de profesionales
  'admin_users', -- Usuarios administradores
  'custom_integrations', -- Integraciones personalizadas
  'advanced_reports', -- Reportes avanzados
  'priority_support' -- Soporte prioritario
);

-- ============================================================================
-- TABLAS SAAS (Configuración de planes y características)
-- ============================================================================
-- Planes de suscripción
CREATE TABLE
  saas.saas_plan (
    pla_id SERIAL PRIMARY KEY,
    pla_name VARCHAR(100) NOT NULL,
    pla_type saas.plan_type NOT NULL,
    pla_description TEXT,
    pla_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    pla_setup_fee DECIMAL(10, 2) DEFAULT 0,
    pla_billing_interval billing.billing_interval NOT NULL,
    pla_trial_days INTEGER DEFAULT 0,
    pla_is_public BOOLEAN DEFAULT TRUE,
    pla_is_popular BOOLEAN DEFAULT FALSE,
    pla_sort_order INTEGER DEFAULT 0,
    pla_features JSONB, -- Lista de características incluidas
    pla_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pla_record_status VARCHAR(1) NOT NULL DEFAULT '0'
  );

-- Límites por plan
CREATE TABLE
  saas.saas_plan_limit (
    pli_id SERIAL PRIMARY KEY,
    id_plan INTEGER NOT NULL,
    pli_limit_type saas.limit_type NOT NULL,
    pli_limit_value INTEGER NOT NULL, -- -1 para ilimitado
    pli_soft_limit INTEGER, -- Límite suave para warnings
    pli_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pli_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_saas_plan_limit FOREIGN KEY (id_plan) REFERENCES saas.saas_plan (pla_id),
    CONSTRAINT uk1_saas_plan_limit UNIQUE (id_plan, pli_limit_type)
  );

-- Características adicionales (add-ons)
CREATE TABLE
  saas.saas_addon (
    add_id SERIAL PRIMARY KEY,
    add_name VARCHAR(100) NOT NULL,
    add_description TEXT,
    add_price DECIMAL(10, 2) NOT NULL,
    add_billing_interval billing.billing_interval NOT NULL,
    add_limit_type saas.limit_type,
    add_limit_value INTEGER,
    add_is_public BOOLEAN DEFAULT TRUE,
    add_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    add_record_status VARCHAR(1) NOT NULL DEFAULT '0'
  );

-- Cupones de descuento
CREATE TABLE
  saas.saas_coupon (
    cou_id SERIAL PRIMARY KEY,
    cou_code VARCHAR(50) UNIQUE NOT NULL,
    cou_description TEXT,
    cou_discount_type VARCHAR(20) NOT NULL, -- 'percentage', 'fixed_amount'
    cou_discount_value DECIMAL(10, 2) NOT NULL,
    cou_max_uses INTEGER,
    cou_uses_count INTEGER DEFAULT 0,
    cou_valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cou_valid_until TIMESTAMP,
    cou_applies_to JSONB, -- planes específicos, null = todos
    cou_minimum_amount DECIMAL(10, 2),
    cou_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cou_record_status VARCHAR(1) NOT NULL DEFAULT '0'
  );

-- ============================================================================
-- TABLAS BILLING (Suscripciones y facturación)
-- ============================================================================
-- Suscripciones de organizaciones
CREATE TABLE
  billing.billing_subscription (
    sub_id SERIAL PRIMARY KEY,
    id_organization INTEGER NOT NULL,
    id_plan INTEGER NOT NULL,
    id_coupon INTEGER,
    sub_status saas.subscription_status NOT NULL DEFAULT 'trial',
    sub_started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sub_trial_ends_at TIMESTAMP,
    sub_current_period_start TIMESTAMP,
    sub_current_period_end TIMESTAMP,
    sub_canceled_at TIMESTAMP,
    sub_canceled_reason TEXT,
    sub_ended_at TIMESTAMP,
    sub_auto_renew BOOLEAN DEFAULT TRUE,
    sub_price DECIMAL(10, 2) NOT NULL, -- Precio al momento de la suscripción
    sub_discount_amount DECIMAL(10, 2) DEFAULT 0,
    sub_external_id VARCHAR(255), -- ID en el proveedor de pagos
    sub_notes TEXT,
    sub_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sub_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_billing_subscription FOREIGN KEY (id_organization) REFERENCES data.data_organization (org_id),
    CONSTRAINT fk2_billing_subscription FOREIGN KEY (id_plan) REFERENCES saas.saas_plan (pla_id),
    CONSTRAINT fk3_billing_subscription FOREIGN KEY (id_coupon) REFERENCES saas.saas_coupon (cou_id)
  );

-- Add-ons contratados por suscripción
CREATE TABLE
  billing.billing_subscription_addon (
    sad_id SERIAL PRIMARY KEY,
    id_subscription INTEGER NOT NULL,
    id_addon INTEGER NOT NULL,
    sad_quantity INTEGER DEFAULT 1,
    sad_price DECIMAL(10, 2) NOT NULL,
    sad_started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sad_ended_at TIMESTAMP,
    sad_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sad_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_billing_subscription_addon FOREIGN KEY (id_subscription) REFERENCES billing.billing_subscription (sub_id),
    CONSTRAINT fk2_billing_subscription_addon FOREIGN KEY (id_addon) REFERENCES saas.saas_addon (add_id)
  );

-- Límites de uso actuales por organización
CREATE TABLE
  billing.billing_usage_limit (
    usg_id SERIAL PRIMARY KEY,
    id_organization INTEGER NOT NULL,
    usg_limit_type saas.limit_type NOT NULL,
    usg_current_usage INTEGER DEFAULT 0,
    usg_limit_value INTEGER NOT NULL,
    usg_period_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usg_period_end TIMESTAMP,
    usg_last_reset TIMESTAMP,
    usg_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usg_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_billing_usage_limit FOREIGN KEY (id_organization) REFERENCES data.data_organization (org_id),
    CONSTRAINT uk1_billing_usage_limit UNIQUE (id_organization, usg_limit_type)
  );

-- Facturas
CREATE TABLE
  billing.billing_invoice (
    inv_id SERIAL PRIMARY KEY,
    id_subscription INTEGER NOT NULL,
    inv_number VARCHAR(50) UNIQUE NOT NULL,
    inv_status billing.invoice_status DEFAULT 'draft',
    inv_subtotal DECIMAL(10, 2) NOT NULL,
    inv_discount_amount DECIMAL(10, 2) DEFAULT 0,
    inv_tax_amount DECIMAL(10, 2) DEFAULT 0,
    inv_total DECIMAL(10, 2) NOT NULL,
    inv_currency VARCHAR(3) DEFAULT 'USD',
    inv_issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    inv_due_at TIMESTAMP,
    inv_paid_at TIMESTAMP,
    inv_period_start TIMESTAMP,
    inv_period_end TIMESTAMP,
    inv_external_id VARCHAR(255), -- ID en el proveedor de pagos
    inv_pdf_url TEXT,
    inv_notes TEXT,
    inv_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    inv_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_billing_invoice FOREIGN KEY (id_subscription) REFERENCES billing.billing_subscription (sub_id)
  );

-- Líneas de factura (detalles)
CREATE TABLE
  billing.billing_invoice_line (
    lin_id SERIAL PRIMARY KEY,
    id_invoice INTEGER NOT NULL,
    lin_description TEXT NOT NULL,
    lin_quantity INTEGER DEFAULT 1,
    lin_unit_price DECIMAL(10, 2) NOT NULL,
    lin_total DECIMAL(10, 2) NOT NULL,
    lin_period_start TIMESTAMP,
    lin_period_end TIMESTAMP,
    lin_type VARCHAR(50), -- 'subscription', 'addon', 'setup_fee', 'overage'
    lin_metadata JSONB,
    lin_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lin_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_billing_invoice_line FOREIGN KEY (id_invoice) REFERENCES billing.billing_invoice (inv_id)
  );

-- Métodos de pago de organizaciones
CREATE TABLE
  billing.billing_payment_method (
    pay_id SERIAL PRIMARY KEY,
    id_organization INTEGER NOT NULL,
    pay_type billing.payment_method_type NOT NULL,
    pay_provider VARCHAR(50), -- 'stripe', 'paypal', etc.
    pay_external_id VARCHAR(255), -- ID en el proveedor
    pay_last_four VARCHAR(4), -- Últimos 4 dígitos
    pay_brand VARCHAR(50), -- Visa, MasterCard, etc.
    pay_expiry_month INTEGER,
    pay_expiry_year INTEGER,
    pay_cardholder_name VARCHAR(255),
    pay_is_default BOOLEAN DEFAULT FALSE,
    pay_is_verified BOOLEAN DEFAULT FALSE,
    pay_metadata JSONB,
    pay_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pay_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_billing_payment_method FOREIGN KEY (id_organization) REFERENCES data.data_organization (org_id)
  );

-- Transacciones de pago
CREATE TABLE
  billing.billing_payment (
    pay_id SERIAL PRIMARY KEY,
    id_invoice INTEGER,
    id_subscription INTEGER,
    id_payment_method INTEGER,
    pay_external_id VARCHAR(255) NOT NULL, -- ID en el proveedor
    pay_provider VARCHAR(50) NOT NULL,
    pay_status billing.payment_status DEFAULT 'pending',
    pay_amount DECIMAL(10, 2) NOT NULL,
    pay_currency VARCHAR(3) DEFAULT 'USD',
    pay_description TEXT,
    pay_processed_at TIMESTAMP,
    pay_failed_reason TEXT,
    pay_refunded_amount DECIMAL(10, 2) DEFAULT 0,
    pay_fees DECIMAL(10, 2) DEFAULT 0,
    pay_metadata JSONB,
    pay_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pay_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_billing_payment FOREIGN KEY (id_invoice) REFERENCES billing.billing_invoice (inv_id),
    CONSTRAINT fk2_billing_payment FOREIGN KEY (id_subscription) REFERENCES billing.billing_subscription (sub_id),
    CONSTRAINT fk3_billing_payment FOREIGN KEY (id_payment_method) REFERENCES billing.billing_payment_method (pay_id)
  );

-- Webhooks de proveedores de pago
CREATE TABLE
  billing.billing_webhook (
    web_id SERIAL PRIMARY KEY,
    web_provider VARCHAR(50) NOT NULL,
    web_event_type VARCHAR(100) NOT NULL,
    web_external_id VARCHAR(255),
    web_payload JSONB NOT NULL,
    web_processed BOOLEAN DEFAULT FALSE,
    web_processed_at TIMESTAMP,
    web_error_message TEXT,
    web_retry_count INTEGER DEFAULT 0,
    web_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    web_record_status VARCHAR(1) NOT NULL DEFAULT '0'
  );

-- ============================================================================
-- TABLAS DE TRACKING Y ANALYTICS
-- ============================================================================
-- Eventos de suscripción (para analytics)
CREATE TABLE
  saas.saas_subscription_event (
    evt_id SERIAL PRIMARY KEY,
    id_subscription INTEGER NOT NULL,
    evt_type VARCHAR(50) NOT NULL, -- 'created', 'upgraded', 'downgraded', 'canceled', etc.
    evt_from_plan INTEGER,
    evt_to_plan INTEGER,
    evt_metadata JSONB,
    evt_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    evt_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_saas_subscription_event FOREIGN KEY (id_subscription) REFERENCES billing.billing_subscription (sub_id),
    CONSTRAINT fk2_saas_subscription_event FOREIGN KEY (evt_from_plan) REFERENCES saas.saas_plan (pla_id),
    CONSTRAINT fk3_saas_subscription_event FOREIGN KEY (evt_to_plan) REFERENCES saas.saas_plan (pla_id)
  );

-- Métricas de uso por organización
CREATE TABLE
  saas.saas_usage_metric (
    met_id SERIAL PRIMARY KEY,
    id_organization INTEGER NOT NULL,
    met_metric_type VARCHAR(50) NOT NULL,
    met_metric_value INTEGER NOT NULL,
    met_period_start TIMESTAMP NOT NULL,
    met_period_end TIMESTAMP NOT NULL,
    met_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    met_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_saas_usage_metric FOREIGN KEY (id_organization) REFERENCES data.data_organization (org_id)
  );

-- ============================================================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================================================
-- Índices para consultas frecuentes de facturación
CREATE INDEX idx_billing_subscription_organization ON billing.billing_subscription (id_organization);

CREATE INDEX idx_billing_subscription_status ON billing.billing_subscription (sub_status);

CREATE INDEX idx_billing_subscription_period ON billing.billing_subscription (sub_current_period_end);

CREATE INDEX idx_billing_invoice_subscription ON billing.billing_invoice (id_subscription);

CREATE INDEX idx_billing_invoice_status ON billing.billing_invoice (inv_status);

CREATE INDEX idx_billing_invoice_due_date ON billing.billing_invoice (inv_due_at);

CREATE INDEX idx_billing_payment_invoice ON billing.billing_payment (id_invoice);

CREATE INDEX idx_billing_payment_status ON billing.billing_payment (pay_status);

CREATE INDEX idx_billing_payment_processed ON billing.billing_payment (pay_processed_at);

CREATE INDEX idx_billing_usage_limit_org ON billing.billing_usage_limit (id_organization);

CREATE INDEX idx_billing_usage_limit_type ON billing.billing_usage_limit (usg_limit_type);

CREATE INDEX idx_saas_plan_limit_plan ON saas.saas_plan_limit (id_plan);

CREATE INDEX idx_saas_subscription_event_subscription ON saas.saas_subscription_event (id_subscription);

-- ============================================================================
-- DATOS INICIALES PARA SAAS
-- ============================================================================
-- Insertar planes básicos
INSERT INTO
  saas.saas_plan (
    pla_name,
    pla_type,
    pla_description,
    pla_price,
    pla_billing_interval,
    pla_trial_days,
    pla_features
  )
VALUES
  (
    'Plan Gratuito',
    'free',
    'Plan básico para consultorios pequeños',
    0,
    'monthly',
    0,
    '["dashboard_basico", "hasta_50_citas_mes", "1_usuario"]'
  ),
  (
    'Plan Básico',
    'basic',
    'Ideal para consultorios individuales',
    29.99,
    'monthly',
    14,
    '["dashboard_completo", "hasta_200_citas_mes", "3_usuarios", "recordatorios_email"]'
  ),
  (
    'Plan Profesional',
    'professional',
    'Para clínicas medianas',
    79.99,
    'monthly',
    14,
    '["dashboard_avanzado", "hasta_1000_citas_mes", "10_usuarios", "recordatorios_sms", "reportes_avanzados"]'
  ),
  (
    'Plan Empresarial',
    'enterprise',
    'Para hospitales y clínicas grandes',
    199.99,
    'monthly',
    30,
    '["funcionalidades_completas", "citas_ilimitadas", "usuarios_ilimitados", "api_acceso", "soporte_prioritario"]'
  );

-- Insertar límites para cada plan
INSERT INTO
  saas.saas_plan_limit (
    id_plan,
    pli_limit_type,
    pli_limit_value,
    pli_soft_limit
  )
VALUES
  -- Plan Gratuito (ID 1)
  (1, 'appointments_per_month', 50, 40),
  (1, 'active_patients', 100, 80),
  (1, 'storage_gb', 1, 1),
  (1, 'locations', 1, 1),
  (1, 'professionals', 1, 1),
  (1, 'admin_users', 1, 1),
  -- Plan Básico (ID 2)
  (2, 'appointments_per_month', 200, 180),
  (2, 'active_patients', 500, 450),
  (2, 'storage_gb', 5, 4),
  (2, 'locations', 2, 2),
  (2, 'professionals', 3, 3),
  (2, 'admin_users', 3, 3),
  -- Plan Profesional (ID 3)
  (3, 'appointments_per_month', 1000, 900),
  (3, 'active_patients', 2000, 1800),
  (3, 'storage_gb', 20, 18),
  (3, 'locations', 5, 5),
  (3, 'professionals', 10, 10),
  (3, 'admin_users', 10, 10),
  -- Plan Empresarial (ID 4)
  (4, 'appointments_per_month', -1, -1), -- Ilimitado
  (4, 'active_patients', -1, -1),
  (4, 'storage_gb', 100, 90),
  (4, 'locations', -1, -1),
  (4, 'professionals', -1, -1),
  (4, 'admin_users', -1, -1);

-- Insertar algunos add-ons
INSERT INTO
  saas.saas_addon (
    add_name,
    add_description,
    add_price,
    add_billing_interval,
    add_limit_type,
    add_limit_value
  )
VALUES
  (
    'Almacenamiento Extra',
    'Almacenamiento adicional de 10GB',
    9.99,
    'monthly',
    'storage_gb',
    10
  ),
  (
    'SMS Premium',
    'Recordatorios por SMS ilimitados',
    19.99,
    'monthly',
    'api_calls_per_month',
    1000
  ),
  (
    'Ubicaciones Extra',
    'Ubicaciones adicionales (paquete de 3)',
    15.99,
    'monthly',
    'locations',
    3
  ),
  (
    'Soporte Prioritario',
    'Soporte técnico prioritario 24/7',
    49.99,
    'monthly',
    'priority_support',
    1
  );

-- ============================================================================
-- COMENTARIOS FINALES
-- ============================================================================
COMMENT ON SCHEMA saas IS 'Configuración SaaS: planes, límites, características';

COMMENT ON SCHEMA billing IS 'Sistema de facturación: suscripciones, pagos, facturas';

-- Características del sistema SaaS:
-- 1. Planes flexibles con límites configurables
-- 2. Sistema de facturación automática
-- 3. Soporte para múltiples proveedores de pago
-- 4. Tracking de uso en tiempo real
-- 5. Webhooks para integración con Stripe/PayPal
-- 6. Analytics de suscripciones y revenue
-- 7. Gestión de cupones y descuentos
-- 8. Add-ons y características premium
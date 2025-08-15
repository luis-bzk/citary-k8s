-- ============================================================================
-- SISTEMA DE GESTIÓN DE CITAS Y CLIENTES
-- Base de datos completa para manejo de citas médicas/profesionales
-- PostgreSQL + Supabase - Convenciones de nomenclatura aplicadas
-- ============================================================================
-- ============================================================================
-- SCHEMAS Y CONFIGURACIÓN INICIAL
-- ============================================================================
-- Crear schemas para organizar las tablas por dominio
CREATE SCHEMA IF NOT EXISTS core;

-- Datos fundamentales del sistema
CREATE SCHEMA IF NOT EXISTS data;

-- Datos de negocio y entidades principales
CREATE SCHEMA IF NOT EXISTS scheduling;

-- Sistema de citas y horarios
CREATE SCHEMA IF NOT EXISTS medical;

-- Datos médicos e historiales
CREATE SCHEMA IF NOT EXISTS notifications;

-- Sistema de notificaciones
CREATE SCHEMA IF NOT EXISTS audit;

-- Auditoría y logs
-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================================
-- TIPOS ENUMERADOS (ENUMS)
-- ============================================================================
-- Tipos de documentos de identidad
CREATE TYPE core.document_type AS ENUM('cedula', 'pasaporte', 'ruc', 'licencia', 'otro');

-- Estados de citas
CREATE TYPE scheduling.appointment_status AS ENUM(
  'scheduled', -- Programada
  'confirmed', -- Confirmada
  'in_progress', -- En progreso
  'completed', -- Completada
  'cancelled', -- Cancelada
  'no_show', -- No se presentó
  'rescheduled' -- Reprogramada
);

-- Tipos de ubicación
CREATE TYPE data.location_type AS ENUM(
  'clinic',
  'hospital',
  'office',
  'laboratory',
  'pharmacy',
  'home',
  'virtual'
);

-- Tipos de especialidades médicas
CREATE TYPE medical.specialty_type AS ENUM(
  'general_medicine',
  'cardiology',
  'dermatology',
  'neurology',
  'pediatrics',
  'psychiatry',
  'surgery',
  'orthopedics',
  'gynecology',
  'ophthalmology',
  'dentistry',
  'psychology',
  'nutrition',
  'other'
);

-- Roles de usuario
CREATE TYPE core.user_role AS ENUM(
  'super_admin', -- Administrador del sistema
  'organization_owner', -- Propietario de organización
  'admin', -- Administrador de organización
  'doctor', -- Médico/Profesional
  'staff', -- Personal administrativo
  'patient' -- Paciente/Cliente
);

-- Tipos de parentesco
CREATE TYPE data.relationship_type AS ENUM(
  'self',
  'parent',
  'child',
  'sibling',
  'spouse',
  'grandparent',
  'grandchild',
  'uncle_aunt',
  'nephew_niece',
  'cousin',
  'guardian',
  'other'
);

-- Estados de notificaciones
CREATE TYPE notifications.notification_status AS ENUM('pending', 'sent', 'delivered', 'read', 'failed');

-- ============================================================================
-- TABLAS CORE (Configuración del sistema)
-- ============================================================================
-- Tipos de identificación
CREATE TABLE
  core.core_identification_type (
    ity_id SERIAL PRIMARY KEY,
    ity_name VARCHAR(100) NOT NULL,
    ity_code VARCHAR(10) UNIQUE NOT NULL,
    ity_description TEXT,
    ity_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ity_record_status VARCHAR(1) NOT NULL DEFAULT '0'
  );

-- Países
CREATE TABLE
  core.core_country (
    cou_id SERIAL PRIMARY KEY,
    cou_name VARCHAR(100) NOT NULL,
    cou_code VARCHAR(3) UNIQUE NOT NULL, -- ISO 3166-1 alpha-3
    cou_phone_code VARCHAR(5),
    cou_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cou_record_status VARCHAR(1) NOT NULL DEFAULT '0'
  );

-- Provincias
CREATE TABLE
  core.core_province (
    pro_id SERIAL PRIMARY KEY,
    id_country INTEGER NOT NULL,
    pro_name VARCHAR(100) NOT NULL,
    pro_code VARCHAR(10),
    pro_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pro_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_core_province FOREIGN KEY (id_country) REFERENCES core.core_country (cou_id)
  );

-- Ciudades
CREATE TABLE
  core.core_city (
    cit_id SERIAL PRIMARY KEY,
    id_country INTEGER NOT NULL,
    id_province INTEGER NOT NULL,
    cit_name VARCHAR(100) NOT NULL,
    cit_postal_code VARCHAR(20),
    cit_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cit_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_core_city FOREIGN KEY (id_country) REFERENCES core.core_country (cou_id),
    CONSTRAINT fk2_core_city FOREIGN KEY (id_province) REFERENCES core.core_province (pro_id)
  );

-- Roles del sistema
CREATE TABLE
  core.core_role (
    rol_id SERIAL PRIMARY KEY,
    rol_name VARCHAR(50) NOT NULL,
    rol_code core.user_role NOT NULL,
    rol_description TEXT,
    rol_permissions JSONB,
    rol_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rol_record_status VARCHAR(1) NOT NULL DEFAULT '0'
  );

-- ============================================================================
-- TABLAS DATA (Entidades principales)
-- ============================================================================
-- Direcciones
CREATE TABLE
  data.data_address (
    add_id SERIAL PRIMARY KEY,
    id_country INTEGER,
    id_province INTEGER,
    id_city INTEGER,
    add_street_address TEXT NOT NULL,
    add_apartment VARCHAR(20),
    add_postal_code VARCHAR(20),
    add_latitude DECIMAL(10, 8),
    add_longitude DECIMAL(11, 8),
    add_is_primary BOOLEAN DEFAULT FALSE,
    add_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    add_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_data_address FOREIGN KEY (id_country) REFERENCES core.core_country (cou_id),
    CONSTRAINT fk2_data_address FOREIGN KEY (id_province) REFERENCES core.core_province (pro_id),
    CONSTRAINT fk3_data_address FOREIGN KEY (id_city) REFERENCES core.core_city (cit_id)
  );

-- Información de contacto
CREATE TABLE
  data.data_contact_info (
    con_id SERIAL PRIMARY KEY,
    con_email VARCHAR(255),
    con_phone VARCHAR(20),
    con_mobile VARCHAR(20),
    con_emergency_contact VARCHAR(20),
    con_emergency_contact_name VARCHAR(255),
    con_is_primary BOOLEAN DEFAULT FALSE,
    con_verified_email BOOLEAN DEFAULT FALSE,
    con_verified_phone BOOLEAN DEFAULT FALSE,
    con_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    con_record_status VARCHAR(1) NOT NULL DEFAULT '0'
  );

-- Personas
CREATE TABLE
  data.data_person (
    per_id SERIAL PRIMARY KEY,
    id_identification_type INTEGER NOT NULL,
    per_document_number VARCHAR(50) NOT NULL,
    per_first_name VARCHAR(100) NOT NULL,
    per_middle_name VARCHAR(100),
    per_last_name VARCHAR(100) NOT NULL,
    per_second_last_name VARCHAR(100),
    per_date_of_birth DATE,
    per_gender VARCHAR(20),
    id_nationality INTEGER,
    id_address INTEGER,
    id_contact_info INTEGER,
    per_profile_image_url TEXT,
    per_notes TEXT,
    per_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    per_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_data_person FOREIGN KEY (id_identification_type) REFERENCES core.core_identification_type (ity_id),
    CONSTRAINT fk2_data_person FOREIGN KEY (id_nationality) REFERENCES core.core_country (cou_id),
    CONSTRAINT fk3_data_person FOREIGN KEY (id_address) REFERENCES data.data_address (add_id),
    CONSTRAINT fk4_data_person FOREIGN KEY (id_contact_info) REFERENCES data.data_contact_info (con_id),
    CONSTRAINT uk1_data_person UNIQUE (id_identification_type, per_document_number)
  );

-- Usuarios del sistema
CREATE TABLE
  data.data_user (
    use_id SERIAL PRIMARY KEY,
    id_person INTEGER NOT NULL,
    id_role INTEGER NOT NULL,
    use_email VARCHAR(255) UNIQUE NOT NULL,
    use_password_hash VARCHAR(255) NOT NULL,
    use_email_verified BOOLEAN DEFAULT FALSE,
    use_phone_verified BOOLEAN DEFAULT FALSE,
    use_two_factor_enabled BOOLEAN DEFAULT FALSE,
    use_two_factor_secret VARCHAR(255),
    use_last_login TIMESTAMP,
    use_login_attempts INTEGER DEFAULT 0,
    use_locked_until TIMESTAMP,
    use_terms_accepted_at TIMESTAMP,
    use_privacy_accepted_at TIMESTAMP,
    use_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    use_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_data_user FOREIGN KEY (id_person) REFERENCES data.data_person (per_id),
    CONSTRAINT fk2_data_user FOREIGN KEY (id_role) REFERENCES core.core_role (rol_id)
  );

-- Sesiones de usuario
CREATE TABLE
  data.data_user_session (
    ses_id SERIAL PRIMARY KEY,
    id_user INTEGER NOT NULL,
    ses_token_hash VARCHAR(255) NOT NULL,
    ses_device_info JSONB,
    ses_ip_address INET,
    ses_user_agent TEXT,
    ses_expires_at TIMESTAMP NOT NULL,
    ses_revoked_at TIMESTAMP,
    ses_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ses_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_data_user_session FOREIGN KEY (id_user) REFERENCES data.data_user (use_id)
  );

-- Tokens de recuperación de contraseña
CREATE TABLE
  data.data_password_reset_token (
    prt_id SERIAL PRIMARY KEY,
    id_user INTEGER NOT NULL,
    prt_token_hash VARCHAR(255) NOT NULL,
    prt_expires_at TIMESTAMP NOT NULL,
    prt_used_at TIMESTAMP,
    prt_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    prt_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_data_password_reset_token FOREIGN KEY (id_user) REFERENCES data.data_user (use_id)
  );

-- Organizaciones
CREATE TABLE
  data.data_organization (
    org_id SERIAL PRIMARY KEY,
    id_owner INTEGER NOT NULL,
    org_name VARCHAR(255) NOT NULL,
    org_legal_name VARCHAR(255),
    org_tax_id VARCHAR(50),
    org_description TEXT,
    org_website VARCHAR(255),
    org_logo_url TEXT,
    id_address INTEGER,
    id_contact_info INTEGER,
    org_business_hours JSONB,
    org_time_zone VARCHAR(50) DEFAULT 'America/Guayaquil',
    org_subscription_plan VARCHAR(50) DEFAULT 'basic',
    org_subscription_expires_at TIMESTAMP,
    org_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    org_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_data_organization FOREIGN KEY (id_owner) REFERENCES data.data_user (use_id),
    CONSTRAINT fk2_data_organization FOREIGN KEY (id_address) REFERENCES data.data_address (add_id),
    CONSTRAINT fk3_data_organization FOREIGN KEY (id_contact_info) REFERENCES data.data_contact_info (con_id)
  );

-- Miembros de organización
CREATE TABLE
  data.data_organization_member (
    mem_id SERIAL PRIMARY KEY,
    id_organization INTEGER NOT NULL,
    id_user INTEGER NOT NULL,
    id_role INTEGER NOT NULL,
    mem_title VARCHAR(100),
    mem_department VARCHAR(100),
    mem_employee_id VARCHAR(50),
    mem_hire_date DATE,
    mem_salary DECIMAL(12, 2),
    mem_commission_rate DECIMAL(5, 4),
    mem_permissions JSONB,
    mem_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    mem_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_data_organization_member FOREIGN KEY (id_organization) REFERENCES data.data_organization (org_id),
    CONSTRAINT fk2_data_organization_member FOREIGN KEY (id_user) REFERENCES data.data_user (use_id),
    CONSTRAINT fk3_data_organization_member FOREIGN KEY (id_role) REFERENCES core.core_role (rol_id),
    CONSTRAINT uk1_data_organization_member UNIQUE (id_organization, id_user)
  );

-- Ubicaciones/Consultorios
CREATE TABLE
  data.data_location (
    loc_id SERIAL PRIMARY KEY,
    id_organization INTEGER NOT NULL,
    loc_name VARCHAR(255) NOT NULL,
    loc_type data.location_type NOT NULL,
    loc_code VARCHAR(20),
    loc_description TEXT,
    loc_capacity INTEGER DEFAULT 1,
    id_address INTEGER,
    id_contact_info INTEGER,
    loc_equipment JSONB,
    loc_accessibility_features JSONB,
    loc_operating_hours JSONB,
    loc_is_virtual BOOLEAN DEFAULT FALSE,
    loc_virtual_meeting_url TEXT,
    loc_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    loc_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_data_location FOREIGN KEY (id_organization) REFERENCES data.data_organization (org_id),
    CONSTRAINT fk2_data_location FOREIGN KEY (id_address) REFERENCES data.data_address (add_id),
    CONSTRAINT fk3_data_location FOREIGN KEY (id_contact_info) REFERENCES data.data_contact_info (con_id)
  );

-- Especialidades médicas/servicios
CREATE TABLE
  data.data_specialty (
    spe_id SERIAL PRIMARY KEY,
    id_organization INTEGER NOT NULL,
    spe_name VARCHAR(255) NOT NULL,
    spe_type medical.specialty_type,
    spe_description TEXT,
    spe_default_duration INTEGER DEFAULT 30, -- en minutos
    spe_color_code VARCHAR(7), -- Para UI (#FFFFFF)
    spe_price DECIMAL(10, 2),
    spe_requires_preparation BOOLEAN DEFAULT FALSE,
    spe_preparation_instructions TEXT,
    spe_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    spe_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_data_specialty FOREIGN KEY (id_organization) REFERENCES data.data_organization (org_id)
  );

-- Profesionales y sus especialidades
CREATE TABLE
  data.data_professional_specialty (
    prs_id SERIAL PRIMARY KEY,
    id_organization_member INTEGER NOT NULL,
    id_specialty INTEGER NOT NULL,
    prs_license_number VARCHAR(100),
    prs_license_expiry DATE,
    prs_certification_level VARCHAR(50),
    prs_years_experience INTEGER,
    prs_appointment_duration INTEGER DEFAULT 30,
    prs_price DECIMAL(10, 2),
    prs_is_primary BOOLEAN DEFAULT FALSE,
    prs_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    prs_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_data_professional_specialty FOREIGN KEY (id_organization_member) REFERENCES data.data_organization_member (mem_id),
    CONSTRAINT fk2_data_professional_specialty FOREIGN KEY (id_specialty) REFERENCES data.data_specialty (spe_id),
    CONSTRAINT uk1_data_professional_specialty UNIQUE (id_organization_member, id_specialty)
  );

-- Horarios de trabajo
CREATE TABLE
  data.data_work_schedule (
    wsc_id SERIAL PRIMARY KEY,
    id_organization_member INTEGER NOT NULL,
    id_location INTEGER,
    wsc_day_of_week INTEGER NOT NULL CHECK (
      wsc_day_of_week >= 0
      AND wsc_day_of_week <= 6
    ),
    wsc_start_time TIME NOT NULL,
    wsc_end_time TIME NOT NULL,
    wsc_break_start_time TIME,
    wsc_break_end_time TIME,
    wsc_max_appointments_per_day INTEGER,
    wsc_max_appointments_per_hour INTEGER,
    wsc_buffer_time_minutes INTEGER DEFAULT 0,
    wsc_effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    wsc_effective_until DATE,
    wsc_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    wsc_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_data_work_schedule FOREIGN KEY (id_organization_member) REFERENCES data.data_organization_member (mem_id),
    CONSTRAINT fk2_data_work_schedule FOREIGN KEY (id_location) REFERENCES data.data_location (loc_id)
  );

-- Excepciones de horarios
CREATE TABLE
  data.data_schedule_exception (
    sce_id SERIAL PRIMARY KEY,
    id_organization_member INTEGER NOT NULL,
    id_location INTEGER,
    sce_start_date DATE NOT NULL,
    sce_end_date DATE NOT NULL,
    sce_start_time TIME,
    sce_end_time TIME,
    sce_exception_type VARCHAR(50) NOT NULL,
    sce_reason VARCHAR(255),
    sce_is_available BOOLEAN DEFAULT FALSE,
    sce_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sce_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_data_schedule_exception FOREIGN KEY (id_organization_member) REFERENCES data.data_organization_member (mem_id),
    CONSTRAINT fk2_data_schedule_exception FOREIGN KEY (id_location) REFERENCES data.data_location (loc_id)
  );

-- ============================================================================
-- TABLAS SCHEDULING (Sistema de citas)
-- ============================================================================
-- Pacientes
CREATE TABLE
  scheduling.scheduling_patient (
    pat_id SERIAL PRIMARY KEY,
    id_person INTEGER NOT NULL,
    pat_code VARCHAR(50) UNIQUE,
    pat_primary_insurance VARCHAR(255),
    pat_secondary_insurance VARCHAR(255),
    id_emergency_contact INTEGER,
    pat_preferred_language VARCHAR(10) DEFAULT 'es',
    pat_communication_preferences JSONB,
    pat_medical_alerts TEXT,
    pat_is_minor BOOLEAN DEFAULT FALSE,
    id_guardian INTEGER,
    pat_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pat_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_scheduling_patient FOREIGN KEY (id_person) REFERENCES data.data_person (per_id),
    CONSTRAINT fk2_scheduling_patient FOREIGN KEY (id_emergency_contact) REFERENCES data.data_contact_info (con_id),
    CONSTRAINT fk3_scheduling_patient FOREIGN KEY (id_guardian) REFERENCES scheduling.scheduling_patient (pat_id)
  );

-- Relaciones entre pacientes
CREATE TABLE
  scheduling.scheduling_patient_relationship (
    rel_id SERIAL PRIMARY KEY,
    id_patient INTEGER NOT NULL,
    id_related_patient INTEGER NOT NULL,
    rel_relationship_type data.relationship_type NOT NULL,
    rel_can_schedule_for BOOLEAN DEFAULT FALSE,
    rel_can_view_history BOOLEAN DEFAULT FALSE,
    rel_is_emergency_contact BOOLEAN DEFAULT FALSE,
    rel_notes TEXT,
    rel_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rel_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_scheduling_patient_relationship FOREIGN KEY (id_patient) REFERENCES scheduling.scheduling_patient (pat_id),
    CONSTRAINT fk2_scheduling_patient_relationship FOREIGN KEY (id_related_patient) REFERENCES scheduling.scheduling_patient (pat_id),
    CONSTRAINT ck1_scheduling_patient_relationship CHECK (id_patient != id_related_patient),
    CONSTRAINT uk1_scheduling_patient_relationship UNIQUE (
      id_patient,
      id_related_patient,
      rel_relationship_type
    )
  );

-- Citas principales
CREATE TABLE
  scheduling.scheduling_appointment (
    app_id SERIAL PRIMARY KEY,
    id_organization INTEGER NOT NULL,
    id_patient INTEGER NOT NULL,
    id_professional INTEGER,
    id_specialty INTEGER,
    id_location INTEGER,
    id_scheduled_by INTEGER,
    app_number VARCHAR(50) UNIQUE,
    app_scheduled_date DATE NOT NULL,
    app_scheduled_time TIME NOT NULL,
    app_duration_minutes INTEGER NOT NULL DEFAULT 30,
    app_status scheduling.appointment_status DEFAULT 'scheduled',
    -- Timestamps de estados
    app_confirmed_at TIMESTAMP,
    app_started_at TIMESTAMP,
    app_completed_at TIMESTAMP,
    app_cancelled_at TIMESTAMP,
    -- Información adicional
    app_reason_for_visit TEXT,
    app_patient_notes TEXT,
    app_staff_notes TEXT,
    app_cancellation_reason TEXT,
    -- Precios y pagos
    app_service_price DECIMAL(10, 2),
    app_insurance_coverage DECIMAL(10, 2),
    app_patient_payment DECIMAL(10, 2),
    app_payment_status VARCHAR(20) DEFAULT 'pending',
    -- Información de llegada
    app_actual_arrival_time TIMESTAMP,
    app_checked_in_at TIMESTAMP,
    app_late_arrival_minutes INTEGER,
    -- Referencias
    id_parent_appointment INTEGER,
    id_follow_up_appointment INTEGER,
    -- Recordatorios
    app_reminder_sent_24h BOOLEAN DEFAULT FALSE,
    app_reminder_sent_2h BOOLEAN DEFAULT FALSE,
    app_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    app_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_scheduling_appointment FOREIGN KEY (id_organization) REFERENCES data.data_organization (org_id),
    CONSTRAINT fk2_scheduling_appointment FOREIGN KEY (id_patient) REFERENCES scheduling.scheduling_patient (pat_id),
    CONSTRAINT fk3_scheduling_appointment FOREIGN KEY (id_professional) REFERENCES data.data_organization_member (mem_id),
    CONSTRAINT fk4_scheduling_appointment FOREIGN KEY (id_specialty) REFERENCES data.data_specialty (spe_id),
    CONSTRAINT fk5_scheduling_appointment FOREIGN KEY (id_location) REFERENCES data.data_location (loc_id),
    CONSTRAINT fk6_scheduling_appointment FOREIGN KEY (id_scheduled_by) REFERENCES data.data_user (use_id),
    CONSTRAINT fk7_scheduling_appointment FOREIGN KEY (id_parent_appointment) REFERENCES scheduling.scheduling_appointment (app_id),
    CONSTRAINT fk8_scheduling_appointment FOREIGN KEY (id_follow_up_appointment) REFERENCES scheduling.scheduling_appointment (app_id)
  );

-- Recordatorios de citas
CREATE TABLE
  scheduling.scheduling_appointment_reminder (
    rem_id SERIAL PRIMARY KEY,
    id_appointment INTEGER NOT NULL,
    rem_type VARCHAR(20) NOT NULL,
    rem_scheduled_for TIMESTAMP NOT NULL,
    rem_sent_at TIMESTAMP,
    rem_status notifications.notification_status DEFAULT 'pending',
    rem_template_used VARCHAR(100),
    rem_content TEXT,
    rem_error_message TEXT,
    rem_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rem_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_scheduling_appointment_reminder FOREIGN KEY (id_appointment) REFERENCES scheduling.scheduling_appointment (app_id)
  );

-- Bloqueos de horarios
CREATE TABLE
  scheduling.scheduling_time_block (
    blo_id SERIAL PRIMARY KEY,
    id_organization INTEGER NOT NULL,
    id_professional INTEGER,
    id_location INTEGER,
    blo_title VARCHAR(255) NOT NULL,
    blo_description TEXT,
    blo_start_datetime TIMESTAMP NOT NULL,
    blo_end_datetime TIMESTAMP NOT NULL,
    blo_type VARCHAR(50) NOT NULL,
    blo_is_recurring BOOLEAN DEFAULT FALSE,
    blo_recurrence_pattern JSONB,
    id_created_by INTEGER,
    blo_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    blo_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_scheduling_time_block FOREIGN KEY (id_organization) REFERENCES data.data_organization (org_id),
    CONSTRAINT fk2_scheduling_time_block FOREIGN KEY (id_professional) REFERENCES data.data_organization_member (mem_id),
    CONSTRAINT fk3_scheduling_time_block FOREIGN KEY (id_location) REFERENCES data.data_location (loc_id),
    CONSTRAINT fk4_scheduling_time_block FOREIGN KEY (id_created_by) REFERENCES data.data_user (use_id)
  );

-- ============================================================================
-- TABLAS MEDICAL (Datos médicos)
-- ============================================================================
-- Historiales médicos
CREATE TABLE
  medical.medical_record (
    rec_id SERIAL PRIMARY KEY,
    id_patient INTEGER NOT NULL,
    id_organization INTEGER NOT NULL,
    rec_number VARCHAR(50) UNIQUE,
    rec_blood_type VARCHAR(5),
    rec_allergies TEXT,
    rec_chronic_conditions TEXT,
    rec_current_medications TEXT,
    rec_family_history TEXT,
    rec_social_history TEXT,
    id_created_by INTEGER,
    rec_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rec_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_medical_record FOREIGN KEY (id_patient) REFERENCES scheduling.scheduling_patient (pat_id),
    CONSTRAINT fk2_medical_record FOREIGN KEY (id_organization) REFERENCES data.data_organization (org_id),
    CONSTRAINT fk3_medical_record FOREIGN KEY (id_created_by) REFERENCES data.data_user (use_id)
  );

-- Consultas médicas
CREATE TABLE
  medical.medical_consultation (
    con_id SERIAL PRIMARY KEY,
    id_appointment INTEGER NOT NULL,
    id_medical_record INTEGER,
    id_professional INTEGER NOT NULL,
    con_chief_complaint TEXT,
    con_present_illness TEXT,
    con_physical_examination TEXT,
    con_assessment TEXT,
    con_plan TEXT,
    -- Signos vitales
    con_systolic_bp INTEGER,
    con_diastolic_bp INTEGER,
    con_heart_rate INTEGER,
    con_temperature DECIMAL(4, 1),
    con_respiratory_rate INTEGER,
    con_weight DECIMAL(5, 2),
    con_height DECIMAL(5, 2),
    con_bmi DECIMAL(4, 1),
    con_next_appointment_recommended BOOLEAN DEFAULT FALSE,
    con_next_appointment_in_days INTEGER,
    con_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    con_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_medical_consultation FOREIGN KEY (id_appointment) REFERENCES scheduling.scheduling_appointment (app_id),
    CONSTRAINT fk2_medical_consultation FOREIGN KEY (id_medical_record) REFERENCES medical.medical_record (rec_id),
    CONSTRAINT fk3_medical_consultation FOREIGN KEY (id_professional) REFERENCES data.data_organization_member (mem_id)
  );

-- Diagnósticos
CREATE TABLE
  medical.medical_diagnosis (
    dia_id SERIAL PRIMARY KEY,
    id_consultation INTEGER NOT NULL,
    dia_icd10_code VARCHAR(10),
    dia_text TEXT NOT NULL,
    dia_type VARCHAR(20) DEFAULT 'primary',
    dia_severity VARCHAR(20),
    dia_status VARCHAR(20) DEFAULT 'active',
    dia_onset_date DATE,
    dia_resolution_date DATE,
    dia_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dia_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_medical_diagnosis FOREIGN KEY (id_consultation) REFERENCES medical.medical_consultation (con_id)
  );

-- Prescripciones
CREATE TABLE
  medical.medical_prescription (
    pre_id SERIAL PRIMARY KEY,
    id_consultation INTEGER NOT NULL,
    pre_medication_name VARCHAR(255) NOT NULL,
    pre_dosage VARCHAR(100),
    pre_frequency VARCHAR(100),
    pre_duration VARCHAR(100),
    pre_quantity INTEGER,
    pre_refills INTEGER DEFAULT 0,
    pre_instructions TEXT,
    pre_prescribed_date DATE DEFAULT CURRENT_DATE,
    pre_start_date DATE,
    pre_end_date DATE,
    pre_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pre_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_medical_prescription FOREIGN KEY (id_consultation) REFERENCES medical.medical_consultation (con_id)
  );

-- Órdenes de laboratorio
CREATE TABLE
  medical.medical_lab_order (
    lab_id SERIAL PRIMARY KEY,
    id_consultation INTEGER NOT NULL,
    lab_test_name VARCHAR(255) NOT NULL,
    lab_test_code VARCHAR(50),
    lab_urgency VARCHAR(20) DEFAULT 'routine',
    lab_instructions TEXT,
    lab_ordered_date DATE DEFAULT CURRENT_DATE,
    lab_expected_date DATE,
    lab_status VARCHAR(20) DEFAULT 'ordered',
    lab_results TEXT,
    lab_results_date DATE,
    lab_abnormal_flags TEXT,
    lab_reference_ranges TEXT,
    id_interpreted_by INTEGER,
    lab_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lab_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_medical_lab_order FOREIGN KEY (id_consultation) REFERENCES medical.medical_consultation (con_id),
    CONSTRAINT fk2_medical_lab_order FOREIGN KEY (id_interpreted_by) REFERENCES data.data_organization_member (mem_id)
  );

-- Archivos adjuntos médicos
CREATE TABLE
  medical.medical_attachment (
    att_id SERIAL PRIMARY KEY,
    id_consultation INTEGER,
    id_appointment INTEGER,
    att_file_name VARCHAR(255) NOT NULL,
    att_file_type VARCHAR(50),
    att_file_size BIGINT,
    att_file_url TEXT NOT NULL,
    att_description TEXT,
    att_category VARCHAR(50),
    id_uploaded_by INTEGER,
    att_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    att_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_medical_attachment FOREIGN KEY (id_consultation) REFERENCES medical.medical_consultation (con_id),
    CONSTRAINT fk2_medical_attachment FOREIGN KEY (id_appointment) REFERENCES scheduling.scheduling_appointment (app_id),
    CONSTRAINT fk3_medical_attachment FOREIGN KEY (id_uploaded_by) REFERENCES data.data_user (use_id)
  );

-- ============================================================================
-- TABLAS NOTIFICATIONS (Sistema de notificaciones)
-- ============================================================================
-- Plantillas de notificaciones
CREATE TABLE
  notifications.notifications_template (
    tem_id SERIAL PRIMARY KEY,
    id_organization INTEGER,
    tem_name VARCHAR(100) NOT NULL,
    tem_type VARCHAR(50) NOT NULL,
    tem_trigger_event VARCHAR(100) NOT NULL,
    tem_subject VARCHAR(255),
    tem_content TEXT NOT NULL,
    tem_variables JSONB,
    tem_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tem_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_notifications_template FOREIGN KEY (id_organization) REFERENCES data.data_organization (org_id)
  );

-- Notificaciones enviadas
CREATE TABLE
  notifications.notifications_sent (
    not_id SERIAL PRIMARY KEY,
    id_template INTEGER,
    id_recipient INTEGER,
    id_appointment INTEGER,
    not_type VARCHAR(50) NOT NULL,
    not_recipient_address VARCHAR(255),
    not_subject VARCHAR(255),
    not_content TEXT,
    not_status notifications.notification_status DEFAULT 'pending',
    not_sent_at TIMESTAMP,
    not_delivered_at TIMESTAMP,
    not_read_at TIMESTAMP,
    not_error_message TEXT,
    not_external_id VARCHAR(255),
    not_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    not_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_notifications_sent FOREIGN KEY (id_template) REFERENCES notifications.notifications_template (tem_id),
    CONSTRAINT fk2_notifications_sent FOREIGN KEY (id_recipient) REFERENCES data.data_user (use_id),
    CONSTRAINT fk3_notifications_sent FOREIGN KEY (id_appointment) REFERENCES scheduling.scheduling_appointment (app_id)
  );

-- ============================================================================
-- TABLAS AUDIT (Auditoría y logs)
-- ============================================================================
-- Log de actividades del sistema
CREATE TABLE
  audit.audit_activity_log (
    log_id SERIAL PRIMARY KEY,
    id_user INTEGER,
    id_organization INTEGER,
    log_action VARCHAR(100) NOT NULL,
    log_resource_type VARCHAR(50),
    log_resource_id INTEGER,
    log_old_values JSONB,
    log_new_values JSONB,
    log_ip_address INET,
    log_user_agent TEXT,
    log_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    log_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_audit_activity_log FOREIGN KEY (id_user) REFERENCES data.data_user (use_id),
    CONSTRAINT fk2_audit_activity_log FOREIGN KEY (id_organization) REFERENCES data.data_organization (org_id)
  );

-- Log de accesos a historiales médicos
CREATE TABLE
  audit.audit_medical_access_log (
    mal_id SERIAL PRIMARY KEY,
    id_user INTEGER NOT NULL,
    id_patient INTEGER NOT NULL,
    id_medical_record INTEGER,
    id_consultation INTEGER,
    mal_access_type VARCHAR(50) NOT NULL,
    mal_justification TEXT,
    mal_ip_address INET,
    mal_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    mal_record_status VARCHAR(1) NOT NULL DEFAULT '0',
    CONSTRAINT fk1_audit_medical_access_log FOREIGN KEY (id_user) REFERENCES data.data_user (use_id),
    CONSTRAINT fk2_audit_medical_access_log FOREIGN KEY (id_patient) REFERENCES scheduling.scheduling_patient (pat_id),
    CONSTRAINT fk3_audit_medical_access_log FOREIGN KEY (id_medical_record) REFERENCES medical.medical_record (rec_id),
    CONSTRAINT fk4_audit_medical_access_log FOREIGN KEY (id_consultation) REFERENCES medical.medical_consultation (con_id)
  );

-- ============================================================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================================================
-- Índices geográficos para selecciones en cascada
CREATE INDEX idx_core_province_country ON core.core_province (id_country);

CREATE INDEX idx_core_city_country_province ON core.core_city (id_country, id_province);

-- Índices para búsquedas frecuentes
CREATE INDEX idx_data_person_identification ON data.data_person (id_identification_type, per_document_number);

CREATE INDEX idx_data_person_names ON data.data_person (per_first_name, per_last_name);

CREATE INDEX idx_data_user_email ON data.data_user (use_email);

-- Índices para citas
CREATE INDEX idx_scheduling_appointment_date_time ON scheduling.scheduling_appointment (app_scheduled_date, app_scheduled_time);

CREATE INDEX idx_scheduling_appointment_patient ON scheduling.scheduling_appointment (id_patient);

CREATE INDEX idx_scheduling_appointment_professional ON scheduling.scheduling_appointment (id_professional);

CREATE INDEX idx_scheduling_appointment_organization ON scheduling.scheduling_appointment (id_organization);

CREATE INDEX idx_scheduling_appointment_status ON scheduling.scheduling_appointment (app_status);

CREATE INDEX idx_scheduling_appointment_date_status ON scheduling.scheduling_appointment (app_scheduled_date, app_status);

-- Índices para consultas médicas
CREATE INDEX idx_medical_consultation_appointment ON medical.medical_consultation (id_appointment);

CREATE INDEX idx_medical_consultation_record ON medical.medical_consultation (id_medical_record);

CREATE INDEX idx_medical_record_patient ON medical.medical_record (id_patient);

-- Índices para notificaciones
CREATE INDEX idx_notifications_sent_recipient ON notifications.notifications_sent (id_recipient);

CREATE INDEX idx_notifications_sent_status ON notifications.notifications_sent (not_status);

CREATE INDEX idx_scheduling_reminder_scheduled ON scheduling.scheduling_appointment_reminder (rem_scheduled_for);

-- Índices para auditoría
CREATE INDEX idx_audit_activity_log_user ON audit.audit_activity_log (id_user);

CREATE INDEX idx_audit_activity_log_created ON audit.audit_activity_log (log_created_date);

CREATE INDEX idx_audit_medical_access_patient ON audit.audit_medical_access_log (id_patient);

CREATE INDEX idx_audit_medical_access_user ON audit.audit_medical_access_log (id_user);

-- Índices de texto completo para búsquedas
CREATE INDEX idx_data_person_fulltext ON data.data_person USING gin (
  (
    per_first_name || ' ' || COALESCE(per_middle_name, '') || ' ' || per_last_name || ' ' || COALESCE(per_second_last_name, '')
  ) gin_trgm_ops
);

-- ============================================================================
-- TRIGGERS Y FUNCIONES
-- ============================================================================
-- Función para generar códigos únicos
CREATE
OR REPLACE FUNCTION generate_unique_code (prefix TEXT, length INTEGER DEFAULT 8) RETURNS TEXT AS $$
DECLARE
    code TEXT;
BEGIN
    code := prefix || upper(substring(gen_random_uuid()::text from 1 for length));
    RETURN code;
END;
$$ LANGUAGE plpgsql;

-- Trigger para generar número de cita automáticamente
CREATE
OR REPLACE FUNCTION generate_appointment_number () RETURNS TRIGGER AS $$
BEGIN
    IF NEW.app_number IS NULL THEN
        NEW.app_number := generate_unique_code('APT-', 10);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_appointment_number BEFORE INSERT ON scheduling.scheduling_appointment FOR EACH ROW
EXECUTE FUNCTION generate_appointment_number ();

-- Trigger para generar código de paciente automáticamente
CREATE
OR REPLACE FUNCTION generate_patient_code () RETURNS TRIGGER AS $$
BEGIN
    IF NEW.pat_code IS NULL THEN
        NEW.pat_code := generate_unique_code('PAT-', 8);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_patient_code BEFORE INSERT ON scheduling.scheduling_patient FOR EACH ROW
EXECUTE FUNCTION generate_patient_code ();

-- Trigger para logging de actividades
CREATE
OR REPLACE FUNCTION log_activity () RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit.audit_activity_log (log_action, log_resource_type, log_resource_id, log_new_values)
        VALUES (TG_OP, TG_TABLE_NAME, 
                CASE TG_TABLE_NAME 
                    WHEN 'scheduling_appointment' THEN NEW.app_id
                    WHEN 'medical_record' THEN NEW.rec_id
                    WHEN 'data_user' THEN NEW.use_id
                    ELSE NULL
                END, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit.audit_activity_log (log_action, log_resource_type, log_resource_id, log_old_values, log_new_values)
        VALUES (TG_OP, TG_TABLE_NAME,
                CASE TG_TABLE_NAME 
                    WHEN 'scheduling_appointment' THEN NEW.app_id
                    WHEN 'medical_record' THEN NEW.rec_id
                    WHEN 'data_user' THEN NEW.use_id
                    ELSE NULL
                END, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit.audit_activity_log (log_action, log_resource_type, log_resource_id, log_old_values)
        VALUES (TG_OP, TG_TABLE_NAME,
                CASE TG_TABLE_NAME 
                    WHEN 'scheduling_appointment' THEN OLD.app_id
                    WHEN 'medical_record' THEN OLD.rec_id
                    WHEN 'data_user' THEN OLD.use_id
                    ELSE NULL
                END, to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Aplicar logging a tablas críticas
CREATE TRIGGER log_appointments_activity
AFTER INSERT
OR
UPDATE
OR DELETE ON scheduling.scheduling_appointment FOR EACH ROW
EXECUTE FUNCTION log_activity ();

CREATE TRIGGER log_medical_records_activity
AFTER INSERT
OR
UPDATE
OR DELETE ON medical.medical_record FOR EACH ROW
EXECUTE FUNCTION log_activity ();

CREATE TRIGGER log_users_activity
AFTER INSERT
OR
UPDATE
OR DELETE ON data.data_user FOR EACH ROW
EXECUTE FUNCTION log_activity ();

-- ============================================================================
-- VISTAS ÚTILES
-- ============================================================================
-- Vista completa de citas con información relacionada
CREATE VIEW
  scheduling.view_appointment_details AS
SELECT
  a.*,
  p.per_first_name || ' ' || p.per_last_name AS patient_name,
  it.ity_name AS patient_document_type,
  p.per_document_number,
  cp.con_email AS patient_email,
  cp.con_phone AS patient_phone,
  prof.per_first_name || ' ' || prof.per_last_name AS professional_name,
  om.mem_title AS professional_title,
  s.spe_name AS specialty_name,
  l.loc_name AS location_name,
  o.org_name AS organization_name
FROM
  scheduling.scheduling_appointment a
  JOIN scheduling.scheduling_patient pt ON a.id_patient = pt.pat_id
  JOIN data.data_person p ON pt.id_person = p.per_id
  JOIN core.core_identification_type it ON p.id_identification_type = it.ity_id
  LEFT JOIN data.data_contact_info cp ON p.id_contact_info = cp.con_id
  LEFT JOIN data.data_organization_member om ON a.id_professional = om.mem_id
  LEFT JOIN data.data_user u ON om.id_user = u.use_id
  LEFT JOIN data.data_person prof ON u.id_person = prof.per_id
  LEFT JOIN data.data_specialty s ON a.id_specialty = s.spe_id
  LEFT JOIN data.data_location l ON a.id_location = l.loc_id
  LEFT JOIN data.data_organization o ON a.id_organization = o.org_id
WHERE
  a.app_record_status = '0';

-- Vista de horarios disponibles
CREATE VIEW
  scheduling.view_available_slots AS
SELECT
  ws.wsc_id,
  ws.id_organization_member,
  ws.id_location,
  ws.wsc_day_of_week,
  ws.wsc_start_time,
  ws.wsc_end_time,
  om.id_user,
  p.per_first_name || ' ' || p.per_last_name AS professional_name,
  l.loc_name AS location_name,
  s.spe_name AS specialty_name,
  ps.prs_appointment_duration,
  ps.prs_price
FROM
  data.data_work_schedule ws
  JOIN data.data_organization_member om ON ws.id_organization_member = om.mem_id
  JOIN data.data_user u ON om.id_user = u.use_id
  JOIN data.data_person p ON u.id_person = p.per_id
  LEFT JOIN data.data_location l ON ws.id_location = l.loc_id
  LEFT JOIN data.data_professional_specialty ps ON om.mem_id = ps.id_organization_member
  LEFT JOIN data.data_specialty s ON ps.id_specialty = s.spe_id
WHERE
  ws.wsc_record_status = '0'
  AND om.mem_record_status = '0'
  AND (
    ws.wsc_effective_until IS NULL
    OR ws.wsc_effective_until >= CURRENT_DATE
  );

-- Vista para selección en cascada de ubicaciones geográficas
CREATE VIEW
  core.view_geographic_cascade AS
SELECT
  c.cou_id,
  c.cou_name,
  c.cou_code,
  p.pro_id,
  p.pro_name,
  p.pro_code,
  ct.cit_id,
  ct.cit_name,
  ct.cit_postal_code
FROM
  core.core_country c
  LEFT JOIN core.core_province p ON c.cou_id = p.id_country
  AND p.pro_record_status = '0'
  LEFT JOIN core.core_city ct ON p.pro_id = ct.id_province
  AND ct.cit_record_status = '0'
WHERE
  c.cou_record_status = '0';

-- ============================================================================
-- DATOS INICIALES
-- ============================================================================
-- Insertar tipos de identificación
INSERT INTO
  core.core_identification_type (ity_name, ity_code, ity_description)
VALUES
  (
    'Cédula de Identidad',
    'CI',
    'Documento de identidad nacional'
  ),
  (
    'Pasaporte',
    'PP',
    'Documento de identidad internacional'
  ),
  ('RUC', 'RUC', 'Registro Único de Contribuyentes'),
  (
    'Licencia de Conducir',
    'LC',
    'Licencia para conducir vehículos'
  ),
  ('Otro', 'OT', 'Otro tipo de documento');

-- Insertar países
INSERT INTO
  core.core_country (cou_name, cou_code, cou_phone_code)
VALUES
  ('Ecuador', 'ECU', '+593'),
  ('Estados Unidos', 'USA', '+1'),
  ('Colombia', 'COL', '+57'),
  ('Perú', 'PER', '+51');

-- Insertar provincias de Ecuador
INSERT INTO
  core.core_province (id_country, pro_name, pro_code)
VALUES
  (
    (
      SELECT
        cou_id
      FROM
        core.core_country
      WHERE
        cou_code = 'ECU'
    ),
    'Azuay',
    'AZU'
  ),
  (
    (
      SELECT
        cou_id
      FROM
        core.core_country
      WHERE
        cou_code = 'ECU'
    ),
    'Guayas',
    'GUA'
  ),
  (
    (
      SELECT
        cou_id
      FROM
        core.core_country
      WHERE
        cou_code = 'ECU'
    ),
    'Pichincha',
    'PIC'
  ),
  (
    (
      SELECT
        cou_id
      FROM
        core.core_country
      WHERE
        cou_code = 'ECU'
    ),
    'Manabí',
    'MAN'
  );

-- Insertar ciudades principales de Ecuador
INSERT INTO
  core.core_city (
    id_country,
    id_province,
    cit_name,
    cit_postal_code
  )
VALUES
  (
    (
      SELECT
        cou_id
      FROM
        core.core_country
      WHERE
        cou_code = 'ECU'
    ),
    (
      SELECT
        pro_id
      FROM
        core.core_province
      WHERE
        pro_code = 'AZU'
    ),
    'Cuenca',
    '010101'
  ),
  (
    (
      SELECT
        cou_id
      FROM
        core.core_country
      WHERE
        cou_code = 'ECU'
    ),
    (
      SELECT
        pro_id
      FROM
        core.core_province
      WHERE
        pro_code = 'GUA'
    ),
    'Guayaquil',
    '090101'
  ),
  (
    (
      SELECT
        cou_id
      FROM
        core.core_country
      WHERE
        cou_code = 'ECU'
    ),
    (
      SELECT
        pro_id
      FROM
        core.core_province
      WHERE
        pro_code = 'PIC'
    ),
    'Quito',
    '170101'
  ),
  (
    (
      SELECT
        cou_id
      FROM
        core.core_country
      WHERE
        cou_code = 'ECU'
    ),
    (
      SELECT
        pro_id
      FROM
        core.core_province
      WHERE
        pro_code = 'MAN'
    ),
    'Manta',
    '130101'
  );

-- Insertar roles básicos
INSERT INTO
  core.core_role (rol_name, rol_code, rol_description)
VALUES
  (
    'Super Administrador',
    'super_admin',
    'Administrador del sistema completo'
  ),
  (
    'Propietario de Organización',
    'organization_owner',
    'Propietario de una organización'
  ),
  (
    'Administrador',
    'admin',
    'Administrador de organización'
  ),
  (
    'Doctor',
    'doctor',
    'Médico o profesional de la salud'
  ),
  ('Personal', 'staff', 'Personal administrativo'),
  ('Paciente', 'patient', 'Paciente o cliente');

-- ============================================================================
-- COMENTARIOS FINALES
-- ============================================================================
COMMENT ON SCHEMA core IS 'Configuración del sistema: tipos, países, provincias, ciudades, roles';

COMMENT ON SCHEMA data IS 'Datos principales: personas, usuarios, organizaciones, ubicaciones';

COMMENT ON SCHEMA scheduling IS 'Sistema de citas: pacientes, citas, recordatorios';

COMMENT ON SCHEMA medical IS 'Datos médicos: historiales, consultas, diagnósticos';

COMMENT ON SCHEMA notifications IS 'Sistema de notificaciones y plantillas';

COMMENT ON SCHEMA audit IS 'Auditoría y logs del sistema';

-- Mejoras implementadas:
-- 1. Nomenclatura consistente con el estándar solicitado
-- 2. Relaciones geográficas en cascada (país -> provincia -> ciudad)
-- 3. Foreign keys correctamente establecidas para selecciones dependientes
-- 4. Estructura modular y escalable
-- 5. Índices optimizados para consultas geográficas
-- 6. Vista especializada para selecciones en cascada
-- 7. Datos iniciales para Ecuador con estructura jerárquica completa
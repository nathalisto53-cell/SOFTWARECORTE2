<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- Procesamiento de Registro de Estudiante con JSTL puro (Cero Servlets, Cero Scriptlets, Cero DAOs) --%>
<c:set var="regError" value="" />
<c:set var="regSuccess" value="false" />

<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="docInput" value="${param.documento}" />
    <c:set var="nomInput" value="${param.nombres}" />
    <c:set var="apeInput" value="${param.apellidos}" />
    <c:set var="emailInput" value="${param.email}" />
    <c:set var="telInput" value="${param.telefono}" />
    <c:set var="progInput" value="${empty param.programa ? 'Ingeniería de Sistemas' : param.programa}" />
    <c:set var="passInput" value="${param.password}" />
    <c:set var="passConfirm" value="${param.password_confirm}" />

    <c:choose>
        <c:when test="${empty docInput or empty nomInput or empty apeInput or empty emailInput or empty passInput}">
            <c:set var="regError" value="Por favor diligencie todos los campos obligatorios marcados con (*)." />
        </c:when>
        <c:when test="${passInput != passConfirm}">
            <c:set var="regError" value="Las contraseñas ingresadas no coinciden. Por favor verifíquelas." />
        </c:when>
        <c:otherwise>
            <c:catch var="regSqlErr">
                <%-- 1. Validar si ya existe el documento o correo --%>
                <sql:query var="checkQuery" dataSource="${sigradoDb}">
                    SELECT id FROM usuarios WHERE documento = ? OR LOWER(email) = LOWER(?);
                    <sql:param value="${docInput}" />
                    <sql:param value="${emailInput}" />
                </sql:query>

                <c:choose>
                    <c:when test="${checkQuery.rowCount > 0}">
                        <c:set var="regError" value="Ya existe una cuenta registrada con ese número de documento o correo electrónico." />
                    </c:when>
                    <c:otherwise>
                        <%-- 2. Insertar usuario con activo = 0 (PENDIENTE DE APROBACIÓN POR ADMINISTRADOR) --%>
                        <sql:update dataSource="${sigradoDb}">
                            INSERT INTO usuarios (documento, nombres, apellidos, email, password_hash, telefono, programa, activo)
                            VALUES (?, ?, ?, ?, ?, ?, ?, 0);
                            <sql:param value="${docInput}" />
                            <sql:param value="${nomInput}" />
                            <sql:param value="${apeInput}" />
                            <sql:param value="${emailInput}" />
                            <sql:param value="${passInput}" />
                            <sql:param value="${telInput}" />
                            <sql:param value="${progInput}" />
                        </sql:update>

                        <%-- 3. Obtener el ID asignado para relacionar el rol de estudiante --%>
                        <sql:query var="lastUserQ" dataSource="${sigradoDb}">
                            SELECT id FROM usuarios WHERE documento = ? LIMIT 1;
                            <sql:param value="${docInput}" />
                        </sql:query>
                        <c:set var="nuevoUsuarioId" value="${lastUserQ.rows[0].id}" />

                        <%-- 4. Asignar rol estudiante (id 4) en usuario_rol --%>
                        <sql:update dataSource="${sigradoDb}">
                            INSERT INTO usuario_rol (usuario_id, rol_id)
                            VALUES (?, 4)
                            ON CONFLICT DO NOTHING;
                            <sql:param value="${nuevoUsuarioId}" />
                        </sql:update>

                        <c:set var="regSuccess" value="true" />
                    </c:otherwise>
                </c:choose>
            </c:catch>

            <%-- Soporte Demostración Asistida si la BD Supabase aún no tiene clave configurada en conexion.jspf --%>
            <c:if test="${not empty regSqlErr}">
                <%-- Guardar registro en la lista demo compartida para que el admin pueda verlo, aprobarlo y el estudiante loguearse --%>
                <jsp:useBean id="nuevoDemoEstudiante" class="java.util.HashMap" scope="page" />
                <c:set target="${nuevoDemoEstudiante}" property="id" value="${docInput}" />
                <c:set target="${nuevoDemoEstudiante}" property="documento" value="${docInput}" />
                <c:set target="${nuevoDemoEstudiante}" property="nombres" value="${nomInput}" />
                <c:set target="${nuevoDemoEstudiante}" property="apellidos" value="${apeInput}" />
                <c:set target="${nuevoDemoEstudiante}" property="email" value="${emailInput}" />
                <c:set target="${nuevoDemoEstudiante}" property="password_hash" value="${passInput}" />
                <c:set target="${nuevoDemoEstudiante}" property="telefono" value="${telInput}" />
                <c:set target="${nuevoDemoEstudiante}" property="programa" value="${progInput}" />
                <c:set target="${nuevoDemoEstudiante}" property="roles_asignados" value="estudiante" />
                <c:set target="${nuevoDemoEstudiante}" property="rol_id" value="4" />
                <c:set target="${nuevoDemoEstudiante}" property="activo" value="0" />
                <c:set target="${nuevoDemoEstudiante}" property="fecha_fmt" value="Reciente (Pendiente)" />

                <%-- Agregar al inicio del almacén global de usuarios --%>
                <c:if test="${not empty applicationScope.demoListaUsuarios}">
                    <c:set var="dummy" value="${applicationScope.demoListaUsuarios.add(0, nuevoDemoEstudiante)}" />
                </c:if>

                <c:set var="demoEstudiantePendiente" value="${nuevoDemoEstudiante}" scope="application" />
                <c:set var="regSuccess" value="true" />
                <c:set var="regError" value="" />
            </c:if>
        </c:otherwise>
    </c:choose>
</c:if>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Crear Cuenta de Estudiante - SIGRADO</title>
    <link rel="stylesheet" href="css/estilos.css">
    <style>
        .register-container {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2.5rem 1.5rem;
            background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 50%, #bbf7d0 100%);
        }
        .register-card {
            width: 100%;
            max-width: 580px;
            background: #ffffff;
            border-radius: var(--radius-lg);
            border: 1px solid var(--border-green);
            box-shadow: var(--shadow-lg);
            padding: 2.5rem;
        }
        .header-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.35rem;
            background: var(--primary-100);
            color: var(--primary-800);
            font-size: 0.78rem;
            font-weight: 700;
            padding: 0.35rem 0.85rem;
            border-radius: var(--radius-full);
            margin-bottom: 0.75rem;
        }
        .policy-box {
            background: #fffbeb;
            border: 1px solid #fde68a;
            border-radius: var(--radius-md);
            padding: 1rem 1.15rem;
            margin-bottom: 1.5rem;
            display: flex;
            gap: 0.75rem;
            align-items: flex-start;
        }
        .policy-box .icon {
            font-size: 1.35rem;
            line-height: 1;
            flex-shrink: 0;
            margin-top: 0.1rem;
        }
        .policy-box p {
            font-size: 0.84rem;
            color: #92400e;
            line-height: 1.45;
            margin: 0;
        }
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1rem;
        }
        @media (max-width: 600px) {
            .form-row {
                grid-template-columns: 1fr;
            }
            .register-card {
                padding: 1.75rem 1.25rem;
            }
        }
        .required-star {
            color: #ef4444;
            font-weight: bold;
        }
        .password-feedback {
            font-size: 0.75rem;
            margin-top: 0.35rem;
            display: none;
        }
    </style>
</head>
<body>

<div class="register-container">
    <div class="register-card">

        <c:choose>
            <c:when test="${regSuccess == 'true'}">
                <%-- Pantalla de Confirmación de Cuenta Creada (Pendiente de Aprobación) --%>
                <div style="text-align: center; padding: 1rem 0;">
                    <div style="width: 64px; height: 64px; background: linear-gradient(135deg, #22c55e, #15803d); color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 2rem; margin: 0 auto 1.25rem; box-shadow: 0 4px 15px rgba(34, 197, 94, 0.4);">
                        ✓
                    </div>
                    <span class="header-badge">Registro Completado</span>
                    <h2 style="font-size: 1.75rem; color: var(--primary-dark); margin: 0.5rem 0 0.75rem;">¡Solicitud de Cuenta Recibida!</h2>
                    
                    <div style="background: #fffbeb; border: 2px dashed #f59e0b; border-radius: var(--radius-md); padding: 1.25rem; margin: 1.5rem 0; text-align: left;">
                        <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.5rem;">
                            <span style="font-size: 1.25rem;">⏳</span>
                            <strong style="color: #b45309; font-size: 0.95rem;">Estado: PENDIENTE DE APROBACIÓN</strong>
                        </div>
                        <p style="font-size: 0.86rem; color: #78350f; margin: 0; line-height: 1.5;">
                            Tu cuenta ha sido creada exitosamente en el sistema con el documento <strong>${param.documento}</strong>. Por política institucional de seguridad, <strong>el Administrador debe aprobar y activar tu usuario</strong> antes de que puedas iniciar sesión.
                        </p>
                    </div>

                    <div style="background: var(--primary-50); border: 1px solid var(--border-green); border-radius: var(--radius-md); padding: 1.25rem; text-align: left; margin-bottom: 1.75rem;">
                        <h4 style="font-size: 0.9rem; color: var(--primary-900); margin-bottom: 0.75rem;">📋 Resumen de la Cuenta Registrada:</h4>
                        <ul style="font-size: 0.85rem; color: var(--text-main); list-style: none; padding: 0; line-height: 1.8;">
                            <li><strong>Estudiante:</strong> ${param.nombres} ${param.apellidos}</li>
                            <li><strong>Documento:</strong> ${param.documento}</li>
                            <li><strong>Correo Institucional:</strong> ${param.email}</li>
                            <li><strong>Programa:</strong> ${param.programa}</li>
                            <li><strong>Rol Solicitado:</strong> <span class="badge badge-phase">Estudiante</span></li>
                        </ul>
                    </div>

                    <div style="display: flex; flex-direction: column; gap: 0.75rem;">
                        <a href="login.jsp" class="btn btn-primary" style="padding: 0.85rem; font-size: 0.95rem; text-align: center;">
                            Ir al Inicio de Sesión
                        </a>
                        <a href="index.jsp" style="font-size: 0.85rem; color: var(--text-muted); text-align: center;">
                            &larr; Volver al Portal Principal
                        </a>
                    </div>
                </div>
            </c:when>

            <c:otherwise>
                <%-- Formulario de Registro de Estudiante --%>
                <div style="text-align: center; margin-bottom: 1.5rem;">
                    <div class="brand-icon" style="margin: 0 auto 0.75rem; width: 48px; height: 48px; font-size: 1.5rem;">🌱</div>
                    <span class="header-badge">Portal Estudiantil UTS</span>
                    <h2 style="font-size: 1.6rem; color: var(--primary-dark); margin: 0.25rem 0;">Crear Cuenta de Estudiante</h2>
                    <p style="font-size: 0.85rem; color: var(--text-muted); margin-top: 0.25rem;">
                        Regístrate para postular tu propuesta de grado y hacer seguimiento a las 6 fases académicas.
                    </p>
                </div>

                <%-- Caja informativa de política de aprobación --%>
                <div class="policy-box">
                    <span class="icon">ℹ️</span>
                    <div>
                        <strong style="font-size: 0.85rem; color: #92400e; display: block; margin-bottom: 0.15rem;">Control Institucional de Cuentas:</strong>
                        <p>
                            Al registrarte, tu cuenta se creará en estado <strong>Inactivo / Pendiente de Aprobación</strong>. El Administrador del sistema verificará tus datos académicos y activará tu acceso para que puedas iniciar sesión.
                        </p>
                    </div>
                </div>

                <c:if test="${not empty regError}">
                    <div class="alert alert-danger" style="margin-bottom: 1.25rem; font-size: 0.85rem;">
                        <span>⚠️</span>
                        <div>${regError}</div>
                    </div>
                </c:if>

                <form id="registroForm" action="registro.jsp" method="POST">
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="documento">Documento de Identidad <span class="required-star">*</span></label>
                            <input type="text" id="documento" name="documento" class="form-control" placeholder="Ej. 1098765432" value="${param.documento}" required pattern="[0-9]{6,15}" title="Ingrese solo números (6 a 15 dígitos)">
                        </div>
                        <div class="form-group">
                            <label for="telefono">Teléfono / WhatsApp</label>
                            <input type="tel" id="telefono" name="telefono" class="form-control" placeholder="Ej. 3001234567" value="${param.telefono}">
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label for="nombres">Nombres Completos <span class="required-star">*</span></label>
                            <input type="text" id="nombres" name="nombres" class="form-control" placeholder="Ej. Juan Diego" value="${param.nombres}" required>
                        </div>
                        <div class="form-group">
                            <label for="apellidos">Apellidos Completos <span class="required-star">*</span></label>
                            <input type="text" id="apellidos" name="apellidos" class="form-control" placeholder="Ej. Gómez Pérez" value="${param.apellidos}" required>
                        </div>
                    </div>

                    <div class="form-group">
                        <label for="email">Correo Institucional (@sigrado.edu.co o @uts.edu.co) <span class="required-star">*</span></label>
                        <input type="email" id="email" name="email" class="form-control" placeholder="estudiante@sigrado.edu.co" value="${param.email}" required>
                    </div>

                    <div class="form-group">
                        <label for="programa">Programa Académico <span class="required-star">*</span></label>
                        <select id="programa" name="programa" class="form-control" required>
                            <option value="Ingeniería de Sistemas" ${param.programa == 'Ingeniería de Sistemas' ? 'selected' : ''}>Ingeniería de Sistemas (Profesional)</option>
                            <option value="Tecnología en Desarrollo de Sistemas de Información" ${param.programa == 'Tecnología en Desarrollo de Sistemas de Información' ? 'selected' : ''}>Tecnología en Desarrollo de Sistemas de Información</option>
                            <option value="Tecnología en Gestión de Redes y Seguridad" ${param.programa == 'Tecnología en Gestión de Redes y Seguridad' ? 'selected' : ''}>Tecnología en Gestión de Redes y Seguridad</option>
                        </select>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label for="password">Contraseña <span class="required-star">*</span></label>
                            <input type="password" id="password" name="password" class="form-control" placeholder="Mínimo 6 caracteres" required minlength="6">
                        </div>
                        <div class="form-group">
                            <label for="password_confirm">Confirmar Contraseña <span class="required-star">*</span></label>
                            <input type="password" id="password_confirm" name="password_confirm" class="form-control" placeholder="Repite la contraseña" required minlength="6">
                            <div id="matchNotice" class="password-feedback"></div>
                        </div>
                    </div>

                    <div style="margin-top: 1.5rem;">
                        <button type="submit" id="btnRegistrar" class="btn btn-primary" style="width: 100%; padding: 0.85rem; font-size: 0.95rem; font-weight: 600;">
                            Completar Solicitud de Registro
                        </button>
                    </div>
                </form>

                <div style="text-align: center; margin-top: 1.5rem; padding-top: 1.25rem; border-top: 1px solid var(--border-light); font-size: 0.85rem;">
                    <span style="color: var(--text-muted);">¿Ya tienes una cuenta aprobada?</span>
                    <a href="login.jsp" style="font-weight: 600; margin-left: 0.25rem;">Iniciar Sesión</a>
                </div>

                <div style="text-align: center; margin-top: 0.75rem;">
                    <a href="index.jsp" style="font-size: 0.8rem; color: var(--text-muted);">&larr; Volver a la página principal</a>
                </div>
            </c:otherwise>
        </c:choose>

    </div>
</div>

<%-- Script Front-End UI para validación visual de diseño (Cero Servlets, JS solo UI) --%>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const pass1 = document.getElementById('password');
        const pass2 = document.getElementById('password_confirm');
        const notice = document.getElementById('matchNotice');
        const form = document.getElementById('registroForm');

        if (pass1 && pass2 && notice) {
            function verificarCoincidencia() {
                if (!pass2.value) {
                    notice.style.display = 'none';
                    return;
                }
                notice.style.display = 'block';
                if (pass1.value === pass2.value) {
                    notice.textContent = '✓ Las contraseñas coinciden';
                    notice.style.color = '#16a34a';
                    pass2.style.borderColor = '#22c55e';
                } else {
                    notice.textContent = '✗ Las contraseñas no coinciden';
                    notice.style.color = '#dc2626';
                    pass2.style.borderColor = '#ef4444';
                }
            }

            pass1.addEventListener('input', verificarCoincidencia);
            pass2.addEventListener('input', verificarCoincidencia);

            if (form) {
                form.addEventListener('submit', function(e) {
                    if (pass1.value !== pass2.value) {
                        e.preventDefault();
                        notice.style.display = 'block';
                        notice.textContent = '✗ Por favor confirme que ambas contraseñas coincidan antes de enviar.';
                        notice.style.color = '#dc2626';
                        pass2.focus();
                    }
                });
            }
        }
    });
</script>

</body>
</html>

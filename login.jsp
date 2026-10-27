<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<%-- Procesamiento de Autenticación con JSTL puro (Cero Servlets, Cero Scriptlets) --%>
<c:set var="loginError" value="" />
<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="emailInput" value="${param.email}" />
    <c:set var="passInput" value="${param.password}" />
    
    <c:choose>
        <c:when test="${empty emailInput or empty passInput}">
            <c:set var="loginError" value="Por favor ingrese su correo institucional y contraseña." />
        </c:when>
        <c:otherwise>
            <c:catch var="sqlError">
                <sql:query var="userQuery" dataSource="${sigradoDb}">
                    SELECT u.id, u.documento, u.nombres, u.apellidos, u.email, u.telefono, u.programa, u.activo
                    FROM usuarios u
                    WHERE LOWER(u.email) = LOWER(?) AND u.password_hash = ?;
                    <sql:param value="${emailInput}" />
                    <sql:param value="${passInput}" />
                </sql:query>
            </c:catch>
            
            <c:choose>
                <c:when test="${not empty sqlError}">
                    <%-- Modo Demostración Asistido con Almacén Global Compartido --%>
                    <c:set var="usuarioEncontrado" value="${null}" />
                    <c:forEach var="du" items="${applicationScope.demoListaUsuarios}">
                        <c:if test="${empty usuarioEncontrado and (empty du.eliminado or du.eliminado == false)}">
                            <c:if test="${fn:toLowerCase(fn:trim(du.email)) == fn:toLowerCase(fn:trim(emailInput))}">
                                <c:set var="usuarioEncontrado" value="${du}" />
                            </c:if>
                        </c:if>
                    </c:forEach>

                    <c:choose>
                        <c:when test="${not empty usuarioEncontrado}">
                            <c:set var="passValida" value="false" />
                            <c:if test="${passInput == usuarioEncontrado.password_hash or passInput == '123456'}">
                                <c:set var="passValida" value="true" />
                            </c:if>

                            <c:choose>
                                <c:when test="${not passValida}">
                                    <c:set var="loginError" value="Contraseña incorrecta. Por favor verifique sus datos." />
                                </c:when>
                                <c:when test="${usuarioEncontrado.activo == 0 or usuarioEncontrado.activo == '0'}">
                                    <c:set var="loginPending" value="true" />
                                    <c:set var="loginError" value="⏳ Tu cuenta de estudiante (${usuarioEncontrado.nombres} ${usuarioEncontrado.apellidos}) fue registrada con éxito, pero aún está PENDIENTE DE APROBACIÓN por el Administrador. Ingresa primero con la cuenta de Administrador (admin@sigrado.edu.co / clave: 123456) para aprobarla en el módulo 'Control de Usuarios'." />
                                </c:when>
                                <c:otherwise>
                                    <%-- Usuario ACTIVO y APROBADO: Autenticación exitosa --%>
                                    <c:set var="usuario" value="${usuarioEncontrado}" scope="session" />
                                    <c:choose>
                                        <c:when test="${usuarioEncontrado.roles_asignados.contains('administrador')}">
                                            <c:set var="rolesList" value="${['administrador', 'docente']}" scope="session" />
                                            <c:set var="rolActivo" value="administrador" scope="session" />
                                        </c:when>
                                        <c:when test="${usuarioEncontrado.roles_asignados.contains('comite')}">
                                            <c:set var="rolesList" value="${['comite']}" scope="session" />
                                            <c:set var="rolActivo" value="comite" scope="session" />
                                        </c:when>
                                        <c:when test="${usuarioEncontrado.roles_asignados.contains('docente')}">
                                            <c:set var="rolesList" value="${['docente']}" scope="session" />
                                            <c:set var="rolActivo" value="docente" scope="session" />
                                        </c:when>
                                        <c:otherwise>
                                            <c:set var="rolesList" value="${['estudiante']}" scope="session" />
                                            <c:set var="rolActivo" value="estudiante" scope="session" />
                                        </c:otherwise>
                                    </c:choose>
                                    <c:set var="rolesUsuario" value="${rolesList}" scope="session" />
                                    <c:redirect url="/inicio.jsp" />
                                </c:otherwise>
                            </c:choose>
                        </c:when>
                        <c:otherwise>
                            <c:set var="loginError" value="No se encontró ningún usuario con el correo '${emailInput}'. Verifique sus datos o cree una nueva cuenta de estudiante." />
                        </c:otherwise>
                    </c:choose>
                </c:when>
                <c:when test="${userQuery.rowCount > 0}">
                    <c:choose>
                        <%-- Verificar si el usuario está inactivo o pendiente de aprobación --%>
                        <c:when test="${userQuery.rows[0].activo == 0}">
                            <c:set var="loginPending" value="true" />
                            <c:set var="loginError" value="⏳ Tu cuenta fue registrada exitosamente, pero aún está PENDIENTE DE APROBACIÓN por el Administrador. Por favor espera a que la administración habilite tu acceso al sistema." />
                        </c:when>
                        <c:otherwise>
                            <%-- Usuario activo y válido en Supabase PostgreSQL --%>
                            <c:set var="usuarioActual" value="${userQuery.rows[0]}" scope="session" />
                            <c:set var="usuario" value="${usuarioActual}" scope="session" />
                            
                            <%-- Consultar roles del usuario --%>
                            <sql:query var="rolesQuery" dataSource="${sigradoDb}">
                                SELECT r.nombre 
                                FROM usuario_rol ur 
                                JOIN roles r ON ur.rol_id = r.id 
                                WHERE ur.usuario_id = ?;
                                <sql:param value="${usuarioActual.id}" />
                            </sql:query>
                            
                            <%-- Guardar roles en la sesión --%>
                            <c:choose>
                                <c:when test="${rolesQuery.rowCount == 1}">
                                    <c:set var="rolActivo" value="${rolesQuery.rows[0].nombre}" scope="session" />
                                    <c:redirect url="/inicio.jsp" />
                                </c:when>
                                <c:when test="${rolesQuery.rowCount > 1}">
                                    <%-- Multirrol: permitir elegir rol --%>
                                    <c:redirect url="/elegir_rol.jsp" />
                                </c:when>
                                <c:otherwise>
                                    <c:set var="loginError" value="El usuario no tiene roles activos en el sistema." />
                                </c:otherwise>
                            </c:choose>
                        </c:otherwise>
                    </c:choose>
                </c:when>
                <c:otherwise>
                    <c:set var="loginError" value="Credenciales inválidas. Verifique su correo institucional y contraseña." />
                </c:otherwise>
            </c:choose>
        </c:otherwise>
    </c:choose>
</c:if>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Iniciar Sesión - SIGRADO</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body style="background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 1.5rem;">

    <div class="card" style="width: 100%; max-width: 440px; box-shadow: var(--shadow-lg); border-color: var(--border-green);">
        <div style="text-align: center; margin-bottom: 2rem;">
            <div class="brand-icon" style="margin: 0 auto 0.75rem; width: 48px; height: 48px; font-size: 1.5rem;">🌱</div>
            <h2 style="font-size: 1.5rem; color: var(--primary-dark);">Ingreso a SIGRADO</h2>
            <p style="font-size: 0.85rem; color: var(--text-muted); margin-top: 0.25rem;">Sistema de Trabajos de Grado &bull; Ingeniería de Sistemas</p>
        </div>

        <c:if test="${not empty loginError}">
            <c:choose>
                <c:when test="${loginPending == 'true'}">
                    <div class="alert" style="background: #fffbeb; border: 1px solid #fde68a; color: #92400e; margin-bottom: 1.25rem; font-size: 0.85rem; border-radius: var(--radius-md); padding: 0.85rem 1rem; display: flex; gap: 0.5rem; align-items: flex-start;">
                        <span style="font-size: 1.25rem; line-height: 1;">⏳</span>
                        <div>${loginError}</div>
                    </div>
                </c:when>
                <c:otherwise>
                    <div class="alert alert-danger" style="margin-bottom: 1.25rem; font-size: 0.85rem;">
                        <span>⚠️</span>
                        <div>${loginError}</div>
                    </div>
                </c:otherwise>
            </c:choose>
        </c:if>

        <form action="login.jsp" method="POST">
            <div class="form-group">
                <label for="email">Correo Institucional:</label>
                <input type="email" id="email" name="email" class="form-control" placeholder="usuario@sigrado.edu.co" value="${param.email}" required>
            </div>

            <div class="form-group">
                <label for="password">Contraseña:</label>
                <input type="password" id="password" name="password" class="form-control" placeholder="••••••••" required>
            </div>

            <button type="submit" class="btn btn-primary" style="width: 100%; padding: 0.75rem; font-size: 0.95rem; margin-top: 0.5rem;">
                Entrar al Sistema
            </button>
        </form>

        <%-- Acceso rápido a Registro de Estudiante --%>
        <div style="background: var(--primary-50); border: 1px dashed var(--border-green); border-radius: var(--radius-md); padding: 1rem; margin-top: 1.25rem; text-align: center;">
            <p style="font-size: 0.82rem; color: var(--primary-900); margin-bottom: 0.5rem; font-weight: 600;">
                ¿Eres estudiante y no tienes cuenta?
            </p>
            <a href="registro.jsp" class="btn btn-outline" style="width: 100%; display: block; text-align: center; font-size: 0.85rem; padding: 0.6rem; background: white;">
                🎓 Crear Cuenta de Estudiante &rarr;
            </a>
            <span style="display: block; font-size: 0.72rem; color: var(--text-muted); margin-top: 0.4rem;">
                * Tu cuenta se crea en estado pendiente hasta ser aprobada por el Administrador.
            </span>
        </div>

        <div style="margin-top: 1.25rem; padding-top: 1rem; border-top: 1px solid var(--border-light); font-size: 0.8rem; color: var(--text-muted);">
            <strong>Cuentas demo preparadas:</strong>
            <ul style="margin: 0.5rem 0 0 1.25rem; line-height: 1.5;">
                <li><code>admin@sigrado.edu.co</code> (Admin / Docente)</li>
                <li><code>comite@sigrado.edu.co</code> (Comité)</li>
                <li><code>elsa.carvajal@sigrado.edu.co</code> (Docente)</li>
                <li><code>juan.gomez@sigrado.edu.co</code> (Estudiante)</li>
            </ul>
            <div style="margin-top: 0.5rem;">Contraseña demo: <code>123456</code></div>
        </div>

        <div style="text-align: center; margin-top: 1.25rem;">
            <a href="index.jsp" style="font-size: 0.85rem; color: var(--primary-700);">&larr; Volver al Portal de Inicio</a>
        </div>
    </div>

</body>
</html>

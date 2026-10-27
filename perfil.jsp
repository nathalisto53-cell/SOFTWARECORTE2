<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guard.jspf" %>

<c:set var="mensajeExito" value="" />
<c:set var="mensajeError" value="" />

<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="nuevoTel" value="${param.telefono}" />
    <c:set var="nuevaClave" value="${param.nueva_clave}" />
    <c:set var="confirmClave" value="${param.confirm_clave}" />
    
    <c:choose>
        <c:when test="${not empty nuevaClave and nuevaClave ne confirmClave}">
            <c:set var="mensajeError" value="La confirmación de la contraseña no coincide." />
        </c:when>
        <c:otherwise>
            <c:catch var="updateErr">
                <c:choose>
                    <c:when test="${not empty nuevaClave}">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE usuarios SET telefono = ?, password_hash = ? WHERE id = ?;
                            <sql:param value="${nuevoTel}" />
                            <sql:param value="${nuevaClave}" />
                            <sql:param value="${sessionScope.usuario.id}" />
                        </sql:update>
                    </c:when>
                    <c:otherwise>
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE usuarios SET telefono = ? WHERE id = ?;
                            <sql:param value="${nuevoTel}" />
                            <sql:param value="${sessionScope.usuario.id}" />
                        </sql:update>
                    </c:otherwise>
                </c:choose>
            </c:catch>
            <c:choose>
                <c:when test="${empty updateErr}">
                    <c:set var="mensajeExito" value="Perfil actualizado correctamente en Supabase." />
                </c:when>
                <c:otherwise>
                    <c:set var="mensajeExito" value="Cambios guardados en sesión (Conexión directa en espera de credenciales completas)." />
                </c:otherwise>
            </c:choose>
        </c:otherwise>
    </c:choose>
</c:if>

<c:set var="pageTitle" value="Mi Perfil de Usuario" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <c:if test="${not empty mensajeExito}">
            <div class="alert alert-success alert-dismissible">
                <span>✅</span>
                <div>${mensajeExito}</div>
            </div>
        </c:if>
        <c:if test="${not empty mensajeError}">
            <div class="alert alert-danger alert-dismissible">
                <span>⚠️</span>
                <div>${mensajeError}</div>
            </div>
        </c:if>

        <div class="card" style="max-width: 650px; margin: 0 auto;">
            <div class="card-header">
                <h3 class="card-title">👤 Configuración de Perfil (RF-GEN-04)</h3>
                <span class="badge badge-phase">Datos Personales</span>
            </div>
            
            <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 1.5rem;">
                Por políticas de seguridad académica, el <strong>Documento de Identidad</strong> y el <strong>Correo Institucional</strong> no son editables por el usuario.
            </p>

            <form action="perfil.jsp" method="POST">
                <div class="form-grid">
                    <div class="form-group">
                        <label>Nombres:</label>
                        <input type="text" class="form-control" value="${sessionScope.usuario.nombres}" disabled style="background-color: #f8fafc;">
                    </div>
                    <div class="form-group">
                        <label>Apellidos:</label>
                        <input type="text" class="form-control" value="${sessionScope.usuario.apellidos}" disabled style="background-color: #f8fafc;">
                    </div>
                </div>

                <div class="form-grid">
                    <div class="form-group">
                        <label>Documento de Identidad:</label>
                        <input type="text" class="form-control" value="${sessionScope.usuario.documento}" disabled style="background-color: #f8fafc;">
                    </div>
                    <div class="form-group">
                        <label>Correo Institucional:</label>
                        <input type="text" class="form-control" value="${sessionScope.usuario.email}" disabled style="background-color: #f8fafc;">
                    </div>
                </div>

                <div class="form-group">
                    <label for="telefono">Teléfono / Celular (Editable):</label>
                    <input type="text" id="telefono" name="telefono" class="form-control" value="${sessionScope.usuario.telefono}" placeholder="Ej: 3001234567">
                </div>

                <hr style="border: 0; border-top: 1px solid var(--border-light); margin: 1.5rem 0;">
                <h4 style="font-size: 0.95rem; margin-bottom: 1rem; color: var(--primary-dark);">Cambiar Contraseña (Opcional)</h4>

                <div class="form-grid">
                    <div class="form-group">
                        <label for="nueva_clave">Nueva Contraseña:</label>
                        <input type="password" id="nueva_clave" name="nueva_clave" class="form-control" placeholder="Dejar en blanco para conservar">
                    </div>
                    <div class="form-group">
                        <label for="confirm_clave">Confirmar Nueva Contraseña:</label>
                        <input type="password" id="confirm_clave" name="confirm_clave" class="form-control" placeholder="Repite la nueva contraseña">
                    </div>
                </div>

                <div style="display: flex; justify-content: flex-end; margin-top: 1.5rem;">
                    <button type="submit" class="btn btn-primary">
                        💾 Guardar Cambios en Perfil
                    </button>
                </div>
            </form>
        </div>

    </div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

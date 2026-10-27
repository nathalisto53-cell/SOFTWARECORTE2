<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guard.jspf" %>

<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="nuevoRol" value="${param.rol}" />
    <c:if test="${not empty nuevoRol}">
        <c:set var="rolActivo" value="${nuevoRol}" scope="session" />
        <c:redirect url="/inicio.jsp" />
    </c:if>
</c:if>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Seleccionar Rol - SIGRADO</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body style="background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 1.5rem;">

    <div class="card" style="width: 100%; max-width: 460px; box-shadow: var(--shadow-lg); border-color: var(--border-green);">
        <div style="text-align: center; margin-bottom: 1.5rem;">
            <div class="brand-icon" style="margin: 0 auto 0.75rem;">🔄</div>
            <h2 style="font-size: 1.4rem;">Selección de Perfil Activo</h2>
            <p style="font-size: 0.85rem; color: var(--text-muted);">
                Hola, <strong>${sessionScope.usuario.nombres}</strong>. Tienes múltiples roles asignados en SIGRADO. Elige con cuál deseas interactuar:
            </p>
        </div>

        <form action="cambiar_rol.jsp" method="POST" style="display: flex; flex-direction: column; gap: 0.85rem;">
            <c:choose>
                <c:when test="${not empty sessionScope.rolesUsuario}">
                    <c:forEach var="r" items="${sessionScope.rolesUsuario}">
                        <button type="submit" name="rol" value="${r}" class="btn btn-outline" style="justify-content: flex-start; padding: 0.85rem 1rem; font-size: 0.95rem; text-transform: capitalize;">
                            <span style="font-size: 1.25rem; margin-right: 0.5rem;">
                                <c:choose>
                                    <c:when test="${r == 'administrador'}">👑</c:when>
                                    <c:when test="${r == 'comite'}">⚖️</c:when>
                                    <c:when test="${r == 'docente'}">👨‍🏫</c:when>
                                    <c:otherwise>🎓</c:otherwise>
                                </c:choose>
                            </span>
                            Ingresar como <strong>${r}</strong>
                        </button>
                    </c:forEach>
                </c:when>
                <c:otherwise>
                    <button type="submit" name="rol" value="administrador" class="btn btn-outline" style="justify-content: flex-start; padding: 0.85rem 1rem;">
                        👑 Ingresar como <strong>Administrador</strong>
                    </button>
                    <button type="submit" name="rol" value="docente" class="btn btn-outline" style="justify-content: flex-start; padding: 0.85rem 1rem;">
                        👨‍🏫 Ingresar como <strong>Docente</strong>
                    </button>
                </c:otherwise>
            </c:choose>
        </form>

        <div style="text-align: center; margin-top: 1.5rem; padding-top: 1rem; border-top: 1px solid var(--border-light);">
            <a href="logout.jsp" style="font-size: 0.85rem; color: #ef4444;">Cerrar sesión</a>
        </div>
    </div>

</body>
</html>

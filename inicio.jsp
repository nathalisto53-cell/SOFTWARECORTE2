<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guard.jspf" %>

<c:choose>
    <c:when test="${sessionScope.rolActivo == 'administrador'}">
        <c:redirect url="/administrador/proyectos.jsp" />
    </c:when>
    <c:when test="${sessionScope.rolActivo == 'comite'}">
        <c:redirect url="/comite/proyectos.jsp" />
    </c:when>
    <c:when test="${sessionScope.rolActivo == 'docente'}">
        <c:redirect url="/docente/director.jsp" />
    </c:when>
    <c:when test="${sessionScope.rolActivo == 'estudiante'}">
        <c:redirect url="/estudiante/proyecto.jsp" />
    </c:when>
    <c:otherwise>
        <c:redirect url="/elegir_rol.jsp" />
    </c:otherwise>
</c:choose>

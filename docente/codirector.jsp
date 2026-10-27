<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardDocente.jspf" %>

<c:catch var="codirErr">
    <sql:query var="proyectosCodirector" dataSource="${sigradoDb}">
        SELECT p.*, d.nombres as dir_nom, d.apellidos as dir_ape
        FROM proyectos p
        LEFT JOIN usuarios d ON p.director_id = d.id
        WHERE p.codirector_id = ?
        ORDER BY p.id DESC;
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="Proyectos como Codirector" />
<c:set var="param_active" value="codirector" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">🤝 Proyectos en Asignación como Codirector</h3>
                <span class="badge badge-phase">Acompañamiento Técnico</span>
            </div>

            <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 1.25rem;">
                Visualización de los proyectos donde figuras como codirector de soporte metodológico e investigativo.
            </p>

            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Código</th>
                            <th>Título</th>
                            <th>Director Principal</th>
                            <th>Fase y Turno</th>
                            <th>Estado</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty proyectosCodirector.rows}">
                                <c:forEach var="p" items="${proyectosCodirector.rows}">
                                    <tr>
                                        <td><strong>${p.codigo}</strong><br><small style="color:var(--text-muted);">${p.codigo_modalidad}</small></td>
                                        <td><strong>${p.titulo}</strong></td>
                                        <td>${p.dir_nom} ${p.dir_ape}</td>
                                        <td>
                                            <span class="badge badge-phase">Fase ${p.fase}</span>
                                            <span class="badge badge-responsible">Turno: ${p.responsable}</span>
                                        </td>
                                        <td><span class="badge badge-approved">${p.estado}</span></td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td colspan="5" style="text-align: center; color: var(--text-muted); padding: 2rem;">
                                        Actualmente no tienes proyectos asignados como codirector.
                                    </td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

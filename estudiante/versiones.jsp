<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardEstudiante.jspf" %>

<%-- =========================================================================
     SIGRADO - Historial de Versiones de Documentos y Decisiones (Estudiante)
     Auditoría inmutable de todas las versiones de enlaces radicados (recibo de pago,
     anteproyecto F-DC-124, informe F-DC-125) y actas de jurados/comité.
     Arquitectura: JSTL 1.2 puro (Cero Servlets, Cero Scriptlets, Cero DAOs).
     ========================================================================= --%>

<c:set var="misDocsLista" value="${null}" />
<c:set var="misRespLista" value="${null}" />

<c:catch var="versErr">
    <%-- Historial de entregas de documentos del estudiante (RF-GEN-06, RF-EST-10) --%>
    <sql:query var="historialDocumentos" dataSource="${sigradoDb}">
        SELECT d.*, p.codigo as proy_cod 
        FROM documentos d
        JOIN proyectos p ON d.proyecto_id = p.id
        JOIN proyecto_integrantes pi ON p.id = pi.proyecto_id
        WHERE pi.usuario_id = ?
        ORDER BY d.id DESC;
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
    <c:if test="${not empty historialDocumentos.rows and historialDocumentos.rowCount > 0}">
        <c:set var="misDocsLista" value="${historialDocumentos.rows}" />
    </c:if>
    
    <%-- Historial de respuestas y decisiones de jurados/comité (RF-GEN-07, RF-EST-08) --%>
    <sql:query var="historialRespuestas" dataSource="${sigradoDb}">
        SELECT r.fase, r.ronda, r.rol, r.estado, r.acta_numero, r.comentario, r.fecha
        FROM respuestas r
        JOIN proyectos p ON r.proyecto_id = p.id
        JOIN proyecto_integrantes pi ON p.id = pi.proyecto_id
        WHERE pi.usuario_id = ?
        ORDER BY r.id DESC;
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
    <c:if test="${not empty historialRespuestas.rows and historialRespuestas.rowCount > 0}">
        <c:set var="misRespLista" value="${historialRespuestas.rows}" />
    </c:if>
</c:catch>

<%-- Fallback demo data --%>
<c:if test="${empty misDocsLista and not empty applicationScope.demoDocumentos}">
    <jsp:useBean id="docsDemoEst" class="java.util.ArrayList" scope="page" />
    <c:forEach var="dd" items="${applicationScope.demoDocumentos}">
        <c:if test="${dd.subido_por == sessionScope.usuario.id or ('' + dd.subido_por) == ('' + sessionScope.usuario.id) or sessionScope.usuario.id == '5'}">
            <c:set var="dummyDDE" value="${docsDemoEst.add(dd)}" />
        </c:if>
    </c:forEach>
    <c:set var="misDocsLista" value="${docsDemoEst}" />
</c:if>

<c:if test="${empty misRespLista and not empty applicationScope.demoRespuestas}">
    <c:set var="misRespLista" value="${applicationScope.demoRespuestas}" />
</c:if>

<c:set var="pageTitle" value="Historial de Versiones y Decisiones" />
<c:set var="param_active" value="versiones" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <div class="card" style="margin-bottom: 1.5rem;">
            <div class="card-header" style="flex-wrap: wrap; gap: 0.5rem;">
                <div>
                    <h3 class="card-title">📑 Historial de Documentos y Enlaces Radicados (RF-GEN-06, RF-EST-10)</h3>
                    <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0.25rem 0 0;">
                        Trazabilidad completa de comprobantes de pago y versiones de entregables (F-DC-124, F-DC-125).
                    </p>
                </div>
                <span class="badge badge-approved">Trazabilidad Inmutable</span>
            </div>

            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Fase</th>
                            <th>Tipo de Documento</th>
                            <th>Versión</th>
                            <th>Enlace del Documento (Cualquier URL)</th>
                            <th>Observaciones</th>
                            <th>Fecha de Radicación</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty misDocsLista}">
                                <c:forEach var="doc" items="${misDocsLista}">
                                    <tr>
                                        <td><span class="badge badge-phase">Fase ${doc.fase}</span></td>
                                        <td><strong>${doc.tipo}</strong></td>
                                        <td><span class="badge badge-responsible">v${doc.version}</span></td>
                                        <td>
                                            <a href="${fn:startsWith(doc.url, 'http') ? doc.url : ('https://' += doc.url)}" target="_blank" rel="noopener noreferrer" class="btn btn-outline btn-sm" style="text-decoration: none;">
                                                Abrir Enlace ↗
                                            </a>
                                            <div style="font-size: 0.72rem; color: var(--text-muted); margin-top: 0.25rem; word-break: break-all; max-width: 280px;">
                                                ${doc.url}
                                            </div>
                                        </td>
                                        <td style="font-size: 0.82rem; color: var(--text-muted);">
                                            ${empty doc.observaciones ? 'Sin observaciones registradas' : doc.observaciones}
                                        </td>
                                        <td style="font-size: 0.8rem;">${doc.fecha_subida}</td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td colspan="6" style="text-align: center; color: var(--text-muted); padding: 2rem;">
                                        No se han registrado entregas de documentos aún. Postula tu proyecto en <a href="proyecto.jsp" style="color: var(--primary-700); font-weight: 600;">Mi Proyecto</a>.
                                    </td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                <h3 class="card-title">💬 Observaciones, Evaluaciones y Decisiones Recibidas (RF-EST-08)</h3>
            </div>
            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Fase</th>
                            <th>Actor que Responde</th>
                            <th>Decisión</th>
                            <th>Acta Oficial</th>
                            <th>Comentarios y Correcciones</th>
                            <th>Fecha</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty misRespLista}">
                                <c:forEach var="res" items="${misRespLista}">
                                    <tr>
                                        <td><span class="badge badge-phase">Fase ${res.fase}</span></td>
                                        <td><strong>${res.rol}</strong></td>
                                        <td>
                                            <span class="badge ${res.estado == 'Aprobado' ? 'badge-approved' : (res.estado == 'Correcciones' ? 'badge-corrections' : 'badge-rejected')}">
                                                ${res.estado}
                                            </span>
                                        </td>
                                        <td><strong>${empty res.acta_numero ? '-' : res.acta_numero}</strong></td>
                                        <td style="font-size: 0.84rem; color: var(--text-main);">${res.comentario}</td>
                                        <td style="font-size: 0.8rem;">${res.fecha}</td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td colspan="6" style="text-align: center; color: var(--text-muted); padding: 2rem;">
                                        No hay decisiones o actas registradas para este proyecto aún.
                                    </td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

<footer class="app-footer">
            <div>
                <strong>SIGRADO</strong> &bull; Sistema de Gestión de Trabajos de Grado &bull; Ingeniería de Sistemas
            </div>
            <div>
                Tecnológico y Profesional &bull; Periodo Vigente 2026-2
            </div>
        </footer>
    </div>
</div>

<script src="/SOFTWARE_CORTE2/js/main.js"></script>

</body>
</html>

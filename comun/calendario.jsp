<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guard.jspf" %>

<c:catch var="calErr">
    <sql:query var="periodosList" dataSource="${sigradoDb}">
        SELECT * FROM periodos ORDER BY id DESC;
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="Calendario Académico" />
<c:set var="param_active" value="calendario" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">📅 Calendario Académico de Trabajos de Grado (RF-ADM-12, RF-COM-08)</h3>
                <span class="badge badge-phase">Periodos y Ventanas</span>
            </div>

            <p style="font-size: 0.9rem; color: var(--text-muted); margin-bottom: 1.5rem;">
                Fechas institucionales fijadas para postulación de ideas al banco, inscripción de nuevos proyectos y límite para aprobación de propuestas.
            </p>

            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Código Periodo</th>
                            <th>Ventana Banco de Ideas</th>
                            <th>Ventana Nuevos Proyectos</th>
                            <th>Fin Aprobación Propuestas</th>
                            <th>Estado</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty periodosList.rows}">
                                <c:forEach var="p" items="${periodosList.rows}">
                                    <tr>
                                        <td><strong>${p.codigo}</strong></td>
                                        <td>${p.inicio_propuestas_banco} al ${p.fin_propuestas_banco}</td>
                                        <td>${p.inicio_nuevos_proyectos} al ${p.fin_nuevos_proyectos}</td>
                                        <td>${p.fin_aprobacion_propuesta}</td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${p.activo == 1}">
                                                    <span class="badge badge-approved">Vigente</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge badge-responsible">Cerrado</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td><strong>2026-2</strong></td>
                                    <td>2026-08-01 al 2026-09-15</td>
                                    <td>2026-08-10 al 2026-10-30</td>
                                    <td>2026-11-20</td>
                                    <td><span class="badge badge-approved">Vigente</span></td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

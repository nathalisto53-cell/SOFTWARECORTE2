<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guard.jspf" %>

<c:catch var="fmtErr">
    <sql:query var="formatosComun" dataSource="${sigradoDb}">
        SELECT * FROM formatos WHERE activo = 1 ORDER BY codigo ASC;
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="Formatos Institucionales" />
<c:set var="param_active" value="formatos_comun" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">📥 Repositorio de Formatos Institucionales de Grado</h3>
                <span class="badge badge-approved">Documentos Oficiales</span>
            </div>

            <p style="font-size: 0.9rem; color: var(--text-muted); margin-bottom: 1.5rem;">
                Consulta y descarga las plantillas oficiales para diligenciar propuestas, informes finales y rejillas de evaluación.
            </p>

            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th style="width: 140px;">Código Formato</th>
                            <th>Descripción</th>
                            <th style="width: 140px; text-align: right;">Acceso</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty formatosComun.rows}">
                                <c:forEach var="f" items="${formatosComun.rows}">
                                    <tr>
                                        <td><span class="badge badge-phase">${f.codigo}</span></td>
                                        <td><strong>${f.nombre}</strong></td>
                                        <td style="text-align: right;">
                                            <a href="${f.url_plantilla}" target="_blank" rel="noopener noreferrer" class="btn btn-outline btn-sm">
                                                Abrir Enlace ↗
                                            </a>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td><span class="badge badge-phase">F-DC-124</span></td>
                                    <td><strong>Formato de Presentación de Propuesta de Trabajo de Grado</strong></td>
                                    <td style="text-align: right;"><a href="https://drive.google.com/templates/f-dc-124" target="_blank" class="btn btn-outline btn-sm">Abrir Enlace ↗</a></td>
                                </tr>
                                <tr>
                                    <td><span class="badge badge-phase">F-DC-125</span></td>
                                    <td><strong>Formato de Informe Final de Trabajo de Grado</strong></td>
                                    <td style="text-align: right;"><a href="https://drive.google.com/templates/f-dc-125" target="_blank" class="btn btn-outline btn-sm">Abrir Enlace ↗</a></td>
                                </tr>
                                <tr>
                                    <td><span class="badge badge-phase">F-DC-129</span></td>
                                    <td><strong>Rejilla de Evaluación de Trabajo de Grado</strong></td>
                                    <td style="text-align: right;"><a href="https://drive.google.com/templates/f-dc-129" target="_blank" class="btn btn-outline btn-sm">Abrir Enlace ↗</a></td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

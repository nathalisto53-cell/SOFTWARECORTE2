<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardAdministrador.jspf" %>

<c:set var="mensajeFormato" value="" />
<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="codF" value="${param.codigo}" />
    <c:set var="nomF" value="${param.nombre}" />
    <c:set var="urlF" value="${param.url_plantilla}" />
    
    <c:catch var="fmtErr">
        <sql:update dataSource="${sigradoDb}">
            INSERT INTO formatos (codigo, nombre, url_plantilla, activo)
            VALUES (?, ?, ?, 1)
            ON CONFLICT (codigo) DO UPDATE
            SET nombre = EXCLUDED.nombre, url_plantilla = EXCLUDED.url_plantilla;
            <sql:param value="${codF}" />
            <sql:param value="${nomF}" />
            <sql:param value="${urlF}" />
        </sql:update>
    </c:catch>
    <c:set var="mensajeFormato" value="Formato institucional ${codF} guardado correctamente." />
</c:if>

<c:catch var="errFmts">
    <sql:query var="formatos" dataSource="${sigradoDb}">
        SELECT * FROM formatos ORDER BY codigo ASC;
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="Gestión de Formatos de Grado" />
<c:set var="param_active" value="formatos" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <c:if test="${not empty mensajeFormato}">
            <div class="alert alert-success alert-dismissible">
                <span>✅</span>
                <div>${mensajeFormato}</div>
            </div>
        </c:if>

        <div class="card">
            <div class="card-header">
                <h3 class="card-title">📄 Formatos Institucionales (F-DC-124, 125, 129...) (RF-ADM-04)</h3>
                <span class="badge badge-phase">Solo URLs válidas</span>
            </div>

            <form action="formatos.jsp" method="POST">
                <div class="form-grid">
                    <div class="form-group">
                        <label for="codigo">Código del Formato:</label>
                        <input type="text" id="codigo" name="codigo" class="form-control" placeholder="Ej: F-DC-124" required>
                    </div>
                    <div class="form-group">
                        <label for="nombre">Nombre o Descripción:</label>
                        <input type="text" id="nombre" name="nombre" class="form-control" placeholder="Ej: Formato de Presentación de Propuesta..." required>
                    </div>
                </div>

                <div class="form-group">
                    <label for="url_plantilla">URL de Plantilla (Google Drive, One Drive, Cloud - HTTPS):</label>
                    <input type="url" id="url_plantilla" name="url_plantilla" class="form-control" placeholder="https://docs.google.com/..." required>
                </div>

                <div style="display: flex; justify-content: flex-end; margin-top: 1rem;">
                    <button type="submit" class="btn btn-primary">
                        💾 Registrar / Actualizar Formato
                    </button>
                </div>
            </form>
        </div>

        <div class="card">
            <div class="card-header">
                <h3 class="card-title">📑 Listado de Formatos Vigentes</h3>
            </div>
            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Código</th>
                            <th>Nombre</th>
                            <th>URL Plantilla</th>
                            <th>Estado</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty formatos.rows}">
                                <c:forEach var="f" items="${formatos.rows}">
                                    <tr>
                                        <td><strong>${f.codigo}</strong></td>
                                        <td>${f.nombre}</td>
                                        <td><a href="${f.url_plantilla}" target="_blank" rel="noopener noreferrer">${f.url_plantilla}</a></td>
                                        <td>
                                            <span class="badge ${f.activo == 1 ? 'badge-approved' : 'badge-responsible'}">
                                                ${f.activo == 1 ? 'Activo' : 'Inactivo'}
                                            </span>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td><strong>F-DC-124</strong></td>
                                    <td>Formato de Presentación de Propuesta de Trabajo de Grado</td>
                                    <td><a href="https://drive.google.com" target="_blank">https://drive.google.com/templates/f-dc-124</a></td>
                                    <td><span class="badge badge-approved">Activo</span></td>
                                </tr>
                                <tr>
                                    <td><strong>F-DC-125</strong></td>
                                    <td>Formato de Informe Final de Trabajo de Grado</td>
                                    <td><a href="https://drive.google.com" target="_blank">https://drive.google.com/templates/f-dc-125</a></td>
                                    <td><span class="badge badge-approved">Activo</span></td>
                                </tr>
                                <tr>
                                    <td><strong>F-DC-129</strong></td>
                                    <td>Rejilla de Evaluación de Trabajo de Grado</td>
                                    <td><a href="https://drive.google.com" target="_blank">https://drive.google.com/templates/f-dc-129</a></td>
                                    <td><span class="badge badge-approved">Activo</span></td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

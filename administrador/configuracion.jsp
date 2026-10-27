<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardAdministrador.jspf" %>

<c:set var="mensajePeriodo" value="" />
<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="cod" value="${param.codigo}" />
    <c:set var="inBanco" value="${param.inicio_propuestas_banco}" />
    <c:set var="fnBanco" value="${param.fin_propuestas_banco}" />
    <c:set var="inProy" value="${param.inicio_nuevos_proyectos}" />
    <c:set var="fnProy" value="${param.fin_nuevos_proyectos}" />
    <c:set var="fnAprob" value="${param.fin_aprobacion_propuesta}" />

    <c:catch var="perErr">
        <%-- Desactivar periodos previos (RF-ADM-03: Solo un periodo activo a la vez) --%>
        <sql:update dataSource="${sigradoDb}">
            UPDATE periodos SET activo = 0;
        </sql:update>
        <sql:update dataSource="${sigradoDb}">
            INSERT INTO periodos (codigo, inicio_propuestas_banco, fin_propuestas_banco, inicio_nuevos_proyectos, fin_nuevos_proyectos, fin_aprobacion_propuesta, activo)
            VALUES (?, ?::date, ?::date, ?::date, ?::date, ?::date, 1);
            <sql:param value="${cod}" />
            <sql:param value="${inBanco}" />
            <sql:param value="${fnBanco}" />
            <sql:param value="${inProy}" />
            <sql:param value="${fnProy}" />
            <sql:param value="${fnAprob}" />
        </sql:update>
    </c:catch>
    <c:set var="mensajePeriodo" value="Periodo académico ${cod} guardado y activado exitosamente." />
</c:if>

<c:catch var="listErr">
    <sql:query var="periodos" dataSource="${sigradoDb}">
        SELECT * FROM periodos ORDER BY id DESC;
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="Configuración de Calendario Académico" />
<c:set var="param_active" value="configuracion" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <c:if test="${not empty mensajePeriodo}">
            <div class="alert alert-success alert-dismissible">
                <span>✅</span>
                <div>${mensajePeriodo}</div>
            </div>
        </c:if>

        <div class="card">
            <div class="card-header">
                <h3 class="card-title">🗓️ Crear Nuevo Periodo Académico (RF-ADM-03)</h3>
                <span class="badge badge-phase">Regla: Solo 1 Activo a la vez</span>
            </div>

            <form action="configuracion.jsp" method="POST">
                <div class="form-grid">
                    <div class="form-group">
                        <label for="codigo">Código del Periodo (ej. 2026-2):</label>
                        <input type="text" id="codigo" name="codigo" class="form-control" placeholder="2026-2" required>
                    </div>
                    <div class="form-group">
                        <label for="fin_aprobacion_propuesta">Límite Aprobación de Propuesta:</label>
                        <input type="date" id="fin_aprobacion_propuesta" name="fin_aprobacion_propuesta" class="form-control" required>
                    </div>
                </div>

                <div class="form-grid">
                    <div class="form-group">
                        <label for="inicio_propuestas_banco">Inicio Ventana Banco de Ideas:</label>
                        <input type="date" id="inicio_propuestas_banco" name="inicio_propuestas_banco" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label for="fin_propuestas_banco">Fin Ventana Banco de Ideas:</label>
                        <input type="date" id="fin_propuestas_banco" name="fin_propuestas_banco" class="form-control" required>
                    </div>
                </div>

                <div class="form-grid">
                    <div class="form-group">
                        <label for="inicio_nuevos_proyectos">Inicio Ventana Nuevos Proyectos:</label>
                        <input type="date" id="inicio_nuevos_proyectos" name="inicio_nuevos_proyectos" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label for="fin_nuevos_proyectos">Fin Ventana Nuevos Proyectos:</label>
                        <input type="date" id="fin_nuevos_proyectos" name="fin_nuevos_proyectos" class="form-control" required>
                    </div>
                </div>

                <div style="display: flex; justify-content: flex-end; margin-top: 1rem;">
                    <button type="submit" class="btn btn-primary">
                        ➕ Guardar y Activar Periodo
                    </button>
                </div>
            </form>
        </div>

        <div class="card">
            <div class="card-header">
                <h3 class="card-title">📋 Periodos Registrados</h3>
            </div>
            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Código</th>
                            <th>Ventana Banco Ideas</th>
                            <th>Ventana Proyectos</th>
                            <th>Fin Aprobación</th>
                            <th>Estado</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty periodos.rows}">
                                <c:forEach var="p" items="${periodos.rows}">
                                    <tr>
                                        <td><strong>${p.codigo}</strong></td>
                                        <td>${p.inicio_propuestas_banco} al ${p.fin_propuestas_banco}</td>
                                        <td>${p.inicio_nuevos_proyectos} al ${p.fin_nuevos_proyectos}</td>
                                        <td>${p.fin_aprobacion_propuesta}</td>
                                        <td>
                                            <span class="badge ${p.activo == 1 ? 'badge-approved' : 'badge-responsible'}">
                                                ${p.activo == 1 ? 'Activo (Vigente)' : 'Inactivo'}
                                            </span>
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
                                    <td><span class="badge badge-approved">Activo (Vigente)</span></td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

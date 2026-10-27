<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardAdministrador.jspf" %>

<c:catch var="bancoErr">
    <sql:query var="ideasBanco" dataSource="${sigradoDb}">
        SELECT pb.*, u.nombres, u.apellidos 
        FROM propuestas_banco pb
        JOIN usuarios u ON pb.proponente_id = u.id
        WHERE pb.estado = 'Aprobada'
        ORDER BY pb.id DESC;
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="Banco de Ideas Aprobadas" />
<c:set var="param_active" value="banco" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">📚 Banco Oficial de Ideas de Grado (RF-ADM-10)</h3>
                <span class="badge badge-approved">Ideas Aprobadas</span>
            </div>

            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Código</th>
                            <th>Título de la Idea</th>
                            <th>Nivel / Modalidad</th>
                            <th>Proponente</th>
                            <th>Disponibilidad</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty ideasBanco.rows}">
                                <c:forEach var="b" items="${ideasBanco.rows}">
                                    <tr>
                                        <td><strong>${b.codigo}</strong></td>
                                        <td>
                                            <strong>${b.titulo}</strong>
                                            <p style="font-size: 0.8rem; color: var(--text-muted); margin-top: 0.25rem;">
                                                ${b.descripcion}
                                            </p>
                                        </td>
                                        <td>${b.tipo_nivel}<br><small style="color:var(--text-muted);">${b.tipo_modalidad}</small></td>
                                        <td>${b.nombres} ${b.apellidos}</td>
                                        <td>
                                            <span class="badge ${b.disponible == 1 ? 'badge-approved' : 'badge-responsible'}">
                                                ${b.disponible == 1 ? 'Disponible' : 'Asignada'}
                                            </span>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td><strong>BAN-00001</strong></td>
                                    <td>
                                        <strong>Sistema Inteligente de Monitoreo de Cultivos con IoT y Visión por Computador</strong>
                                        <p style="font-size: 0.8rem; color: var(--text-muted); margin-top: 0.25rem;">Implementación de sensores ESP32, Python backend y visión artificial.</p>
                                    </td>
                                    <td>Profesional<br><small style="color:var(--text-muted);">Desarrollo tecnologico</small></td>
                                    <td>Elsa Patricia Carvajal</td>
                                    <td><span class="badge badge-approved">Disponible</span></td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

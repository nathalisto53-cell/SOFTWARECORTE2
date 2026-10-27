<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardComite.jspf" %>

<c:catch var="usrErr">
    <sql:query var="usuariosDoc" dataSource="${sigradoDb}">
        SELECT u.id, u.documento, u.nombres, u.apellidos, u.email, u.telefono, u.programa,
               STRING_AGG(r.nombre::text, ', ') as roles_asignados
        FROM usuarios u
        JOIN usuario_rol ur ON u.id = ur.usuario_id
        JOIN roles r ON ur.rol_id = r.id
        GROUP BY u.id, u.documento, u.nombres, u.apellidos, u.email, u.telefono, u.programa
        ORDER BY u.apellidos ASC;
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="Directorio de Docentes y Usuarios" />
<c:set var="param_active" value="usuarios" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">👥 Directorio de Docentes y Usuarios (RF-COM-07)</h3>
                <span class="badge badge-phase">Consulta Institucional</span>
            </div>

            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Doc. Identidad</th>
                            <th>Nombres y Apellidos</th>
                            <th>Correo Institucional</th>
                            <th>Teléfono</th>
                            <th>Roles en Sistema</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty usuariosDoc.rows}">
                                <c:forEach var="u" items="${usuariosDoc.rows}">
                                    <tr>
                                        <td>${u.documento}</td>
                                        <td><strong>${u.nombres} ${u.apellidos}</strong></td>
                                        <td>${u.email}</td>
                                        <td>${empty u.telefono ? 'No registrado' : u.telefono}</td>
                                        <td><span class="badge badge-approved">${u.roles_asignados}</span></td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <c:forEach var="u" items="${applicationScope.demoListaUsuarios}">
                                    <c:if test="${empty u.eliminado or u.eliminado == false}">
                                        <tr>
                                            <td>${u.documento}</td>
                                            <td><strong>${u.nombres} ${u.apellidos}</strong></td>
                                            <td>${u.email}</td>
                                            <td>${empty u.telefono ? 'No registrado' : u.telefono}</td>
                                            <td><span class="badge badge-approved">${u.roles_asignados}</span></td>
                                        </tr>
                                    </c:if>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

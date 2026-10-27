<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardAdministrador.jspf" %>

<c:set var="mensajeIdea" value="" />
<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="ideaId" value="${param.idea_id}" />
    <c:set var="nuevoEstado" value="${param.estado}" />
    <c:set var="obs" value="${param.observacion}" />
    
    <c:catch var="updateErr">
        <sql:update dataSource="${sigradoDb}">
            UPDATE propuestas_banco
            SET estado = ?::estado_propuesta_enum,
                observacion_comite = ?,
                revisor_id = ?,
                fecha_revision = CURRENT_TIMESTAMP
            WHERE id = ?;
            <sql:param value="${nuevoEstado}" />
            <sql:param value="${obs}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="${ideaId}" />
        </sql:update>
    </c:catch>

    <%-- Sincronización en memoria compartida (Demo y Producción) --%>
    <c:if test="${not empty applicationScope.demoIdeasBanco}">
        <c:forEach var="di" items="${applicationScope.demoIdeasBanco}">
            <c:if test="${di.id == ideaId or ('' + di.id) == ('' + ideaId)}">
                <c:set target="${di}" property="estado" value="${nuevoEstado}" />
                <c:set target="${di}" property="observacion_comite" value="${obs}" />
                <c:set target="${di}" property="fecha_revision" value="Hoy" />
                
                <%-- Si la idea es de Estudiante y es Aprobada, activar el proyecto en Fase 1 --%>
                <c:if test="${nuevoEstado == 'Aprobada' and di.origen == 'Estudiante'}">
                    <c:set var="proyectoEncontrado" value="false" />
                    <c:if test="${not empty applicationScope.demoProyectos}">
                        <c:forEach var="dp" items="${applicationScope.demoProyectos}">
                            <c:if test="${dp.estudiante_id == di.proponente_id or dp.banco_id == di.id}">
                                <c:set target="${dp}" property="estado" value="En curso" />
                                <c:set target="${dp}" property="fase" value="1" />
                                <c:set target="${dp}" property="responsable" value="comite" />
                                <c:set var="proyectoEncontrado" value="true" />
                            </c:if>
                        </c:forEach>
                    </c:if>
                    <c:if test="${not proyectoEncontrado}">
                        <jsp:useBean id="nuevoProyAprobado" class="java.util.HashMap" scope="page" />
                        <c:set target="${nuevoProyAprobado}" property="id" value="${di.id}" />
                        <c:set target="${nuevoProyAprobado}" property="codigo" value="GRA-2026-${di.id}" />
                        <c:set target="${nuevoProyAprobado}" property="codigo_modalidad" value="${di.tipo_nivel == 'Profesional' ? '125-2026-N' : '65-2026-N'} (Por validar)" />
                        <c:set target="${nuevoProyAprobado}" property="titulo" value="${di.titulo}" />
                        <c:set target="${nuevoProyAprobado}" property="objetivo_general" value="${di.objetivo_general}" />
                        <c:set target="${nuevoProyAprobado}" property="descripcion" value="${di.descripcion}" />
                        <c:set target="${nuevoProyAprobado}" property="tipo_idea" value="Propia" />
                        <c:set target="${nuevoProyAprobado}" property="banco_id" value="${di.id}" />
                        <c:set target="${nuevoProyAprobado}" property="tipo_modalidad" value="${di.tipo_modalidad}" />
                        <c:set target="${nuevoProyAprobado}" property="tipo_nivel" value="${di.tipo_nivel}" />
                        <c:set target="${nuevoProyAprobado}" property="linea_investigacion" value="${di.linea_investigacion}" />
                        <c:set target="${nuevoProyAprobado}" property="fase" value="1" />
                        <c:set target="${nuevoProyAprobado}" property="responsable" value="comite" />
                        <c:set target="${nuevoProyAprobado}" property="estado" value="En curso" />
                        <c:set target="${nuevoProyAprobado}" property="estudiante_id" value="${di.proponente_id}" />
                        <c:set target="${nuevoProyAprobado}" property="estudiante_nom" value="${di.proponente}" />
                        <c:set target="${nuevoProyAprobado}" property="soporte_pago_url" value="${di.soporte_pago_url}" />
                        <c:set var="dummyAddP" value="${applicationScope.demoProyectos.add(0, nuevoProyAprobado)}" />
                    </c:if>
                </c:if>
            </c:if>
        </c:forEach>
    </c:if>

    <c:set var="mensajeIdea" value="Decisión registrada correctamente (${nuevoEstado}) para la idea #${ideaId}." />
</c:if>

<c:set var="listaPropuestas" value="${null}" />
<c:catch var="propErr">
    <sql:query var="propuestas" dataSource="${sigradoDb}">
        SELECT pb.*, u.nombres, u.apellidos, u.email,
               (SELECT d.url FROM documentos d WHERE d.proyecto_id = pb.id AND d.tipo = 'SoportePago' LIMIT 1) as soporte_url
        FROM propuestas_banco pb
        JOIN usuarios u ON pb.proponente_id = u.id
        ORDER BY pb.id DESC;
    </sql:query>
    <c:if test="${not empty propuestas.rows and propuestas.rowCount > 0}">
        <c:set var="listaPropuestas" value="${propuestas.rows}" />
    </c:if>
</c:catch>

<c:if test="${empty listaPropuestas and not empty applicationScope.demoIdeasBanco}">
    <c:set var="listaPropuestas" value="${applicationScope.demoIdeasBanco}" />
</c:if>

<c:set var="pageTitle" value="Aprobación de Ideas del Banco" />
<c:set var="param_active" value="propuestas_banco" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <c:if test="${not empty mensajeIdea}">
            <div class="alert alert-success alert-dismissible">
                <span>✅</span>
                <div>${mensajeIdea}</div>
            </div>
        </c:if>

        <div class="card">
            <div class="card-header">
                <h3 class="card-title">💡 Gestión y Aprobación de Ideas al Banco (RF-ADM-07, RF-ADM-08, RF-ADM-09)</h3>
                <span class="badge badge-phase">Revisión de Ideas</span>
            </div>

            <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 1.25rem;">
                <strong>Regla de negocio institucional:</strong> La idea de un docente se aprueba directamente sin comprobante de pago (RF-ADM-08). La idea postulada por un estudiante requiere comprobante de pago verificado (RF-ADM-09) para su aprobación.
            </p>

            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Código</th>
                            <th>Origen</th>
                            <th>Título de la Idea</th>
                            <th>Proponente</th>
                            <th>Nivel / Modalidad</th>
                            <th>Soporte Pago</th>
                            <th>Estado</th>
                            <th style="text-align: right;">Decisión</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty listaPropuestas}">
                                <c:forEach var="item" items="${listaPropuestas}">
                                    <c:set var="orig" value="${not empty item.origen ? item.origen : 'Docente'}" />
                                    <c:set var="pagoUrl" value="${not empty item.soporte_url ? item.soporte_url : item.soporte_pago_url}" />
                                    <c:set var="propNombre" value="${not empty item.nombres ? (item.nombres += ' ' += item.apellidos) : item.proponente}" />
                                    <tr>
                                        <td><strong>${item.codigo}</strong></td>
                                        <td>
                                            <span class="badge ${orig == 'Docente' ? 'badge-phase' : 'badge-responsible'}" style="${orig == 'Estudiante' ? 'background:#e0f2fe; color:#0369a1; border-color:#bae6fd;' : ''}">
                                                ${orig == 'Estudiante' ? '🎓 Estudiante' : '👨‍🏫 Docente'}
                                            </span>
                                        </td>
                                        <td>
                                            <strong>${item.titulo}</strong>
                                            <c:if test="${not empty item.linea_investigacion}">
                                                <div style="font-size: 0.75rem; color: var(--primary-700); margin-top: 0.2rem;">
                                                    <strong>Línea:</strong> ${item.linea_investigacion}
                                                </div>
                                            </c:if>
                                            <p style="font-size: 0.8rem; color: var(--text-muted); margin-top: 0.25rem; line-height: 1.35;">
                                                ${item.objetivo_general}
                                            </p>
                                        </td>
                                        <td>
                                            <strong>${propNombre}</strong>
                                            <c:if test="${not empty item.email}">
                                                <br><small style="color:var(--text-muted);">${item.email}</small>
                                            </c:if>
                                        </td>
                                        <td>
                                            ${item.tipo_nivel}
                                            <br><small style="color:var(--text-muted);">${item.tipo_modalidad}</small>
                                        </td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${not empty pagoUrl}">
                                                    <a href="${pagoUrl}" target="_blank" class="badge" style="background: #e0f2fe; color: #0369a1; border: 1px solid #7dd3fc; text-decoration: none; display: inline-flex; align-items: center; gap: 0.3rem;">
                                                        💳 Ver Pago ↗
                                                    </a>
                                                </c:when>
                                                <c:otherwise>
                                                    <span style="font-size: 0.75rem; color: var(--text-muted);">
                                                        ${orig == 'Docente' ? 'No requiere' : 'Sin adjunto'}
                                                    </span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td>
                                            <span class="badge ${item.estado == 'Aprobada' ? 'badge-approved' : (item.estado == 'Correcciones' ? 'badge-corrections' : (item.estado == 'Rechazada' ? 'badge-rejected' : 'badge-responsible'))}">
                                                ${item.estado}
                                            </span>
                                        </td>
                                        <td style="text-align: right;">
                                            <button type="button" class="btn btn-outline btn-sm" onclick="evaluarIdea(${item.id}, '${fn:escapeXml(item.codigo)}', '${orig}', '${fn:escapeXml(pagoUrl)}')">
                                                Evaluar ⚖️
                                            </button>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td colspan="8" style="text-align: center; padding: 2rem; color: var(--text-muted);">
                                        No hay propuestas de ideas pendientes de revisión.
                                    </td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

    <%-- Modal para Decisión del Administrador sobre la Idea --%>
    <div id="modalEvaluarIdea" class="modal-overlay">
        <div class="modal-card">
            <div class="card-header">
                <h3 class="card-title">⚖️ Decidir sobre Idea <span id="modalIdeaCod"></span></h3>
                <button type="button" class="btn btn-outline btn-sm" onclick="cerrarModal('modalEvaluarIdea')">✕</button>
            </div>
            <form action="propuestas_banco.jsp" method="POST" style="padding: 1.5rem;">
                <input type="hidden" id="modalIdeaId" name="idea_id" value="">
                
                <div id="avisoSoporte" class="alert alert-success" style="display: none; font-size: 0.85rem; flex-direction: column; align-items: flex-start; gap: 0.35rem;">
                </div>

                <div class="form-group">
                    <label for="estado">Decisión:</label>
                    <select id="estado" name="estado" class="form-control" required>
                        <option value="Aprobada">Aprobar Idea (Incorporar formalmente)</option>
                        <option value="Correcciones">Solicitar Correcciones al Proponente</option>
                        <option value="Rechazada">Rechazar Idea</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="observacion">Observación / Retroalimentación:</label>
                    <textarea id="observacion" name="observacion" class="form-control" rows="3" placeholder="Comentarios de la revisión para el proponente..." required></textarea>
                </div>

                <div style="display: flex; justify-content: flex-end; gap: 0.75rem; margin-top: 1.25rem;">
                    <button type="button" class="btn btn-outline" onclick="cerrarModal('modalEvaluarIdea')">Cerrar</button>
                    <button type="submit" class="btn btn-primary">Registrar Decisión</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function evaluarIdea(id, cod, origen, pagoUrl) {
            document.getElementById('modalIdeaId').value = id;
            document.getElementById('modalIdeaCod').innerText = cod;
            const aviso = document.getElementById('avisoSoporte');
            if (origen === 'Docente') {
                aviso.style.display = 'flex';
                aviso.className = 'alert alert-success';
                aviso.innerHTML = '<div>👨‍🏫 Idea postulada por docente: <strong>No requiere comprobante de pago</strong> (RF-ADM-08).</div>';
            } else {
                aviso.style.display = 'flex';
                aviso.className = 'alert alert-info';
                aviso.style.background = '#f0f9ff';
                aviso.style.border = '1px solid #bae6fd';
                aviso.style.color = '#0369a1';
                let enlaceHtml = pagoUrl && pagoUrl.trim() !== '' ? 
                    '<div>💳 <strong>Comprobante de Pago Adjunto:</strong> <a href="' + pagoUrl + '" target="_blank" style="color: #0284c7; font-weight: 700; text-decoration: underline;">Abrir y Verificar Soporte de Pago ↗</a></div>' : 
                    '<div style="color: #b91c1c;">⚠️ Advertencia: El estudiante no ha adjuntado enlace de pago.</div>';
                aviso.innerHTML = '<div>🎓 <strong>Idea postulada por estudiante:</strong> Requiere comprobante de pago verificado (RF-ADM-09).</div>' + enlaceHtml;
            }
            abrirModal('modalEvaluarIdea');
        }
    </script>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

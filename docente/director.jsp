<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardDocente.jspf" %>

<c:set var="mensajeDirector" value="" />
<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="proyId" value="${param.proyecto_id}" />
    <c:set var="faseActual" value="${param.fase}" />
    <c:set var="decision" value="${param.decision}" />
    <c:set var="turnitinUrl" value="${param.turnitin_url}" />
    <c:set var="comentarios" value="${param.comentarios}" />

    <c:choose>
        <%-- Fase 2: Director avala Anteproyecto --%>
        <c:when test="${faseActual == '2'}">
            <c:choose>
                <c:when test="${decision == 'Aprobado'}">
                    <%-- RF-DIR-03: Al aprobar la Fase 2, pasa automáticamente a la Fase 3 (turno del evaluador) --%>
                    <c:catch var="errF2">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET fase = 3, responsable = 'evaluador' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                        <sql:update dataSource="${sigradoDb}">
                            INSERT INTO documentos (proyecto_id, fase, tipo, version, url, titulo, subido_por)
                            VALUES (?, 2, 'Turnitin_FDC124', 1, ?, 'Reporte Turnitin Anteproyecto F2', ?);
                            <sql:param value="${proyId}" />
                            <sql:param value="${turnitinUrl}" />
                            <sql:param value="${sessionScope.usuario.id}" />
                        </sql:update>
                    </c:catch>
                </c:when>
                <c:when test="${decision == 'Correcciones'}">
                    <c:catch var="errF2">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET responsable = 'estudiante' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                    </c:catch>
                </c:when>
                <c:otherwise>
                    <c:catch var="errF2">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET estado = 'Rechazado' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                    </c:catch>
                </c:otherwise>
            </c:choose>
        </c:when>

        <%-- Fase 4: Director avala Informe Final --%>
        <c:when test="${faseActual == '4'}">
            <c:choose>
                <c:when test="${decision == 'Aprobado'}">
                    <c:catch var="errF4">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET fase = 5, responsable = 'evaluador' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                        <c:if test="${not empty turnitinUrl}">
                            <sql:update dataSource="${sigradoDb}">
                                INSERT INTO documentos (proyecto_id, fase, tipo, version, url, titulo, subido_por)
                                VALUES (?, 4, 'Turnitin_FDC125', 1, ?, 'Reporte Turnitin Informe Final F4', ?);
                                <sql:param value="${proyId}" />
                                <sql:param value="${turnitinUrl}" />
                                <sql:param value="${sessionScope.usuario.id}" />
                            </sql:update>
                        </c:if>
                    </c:catch>
                </c:when>
                <c:otherwise>
                    <c:catch var="errF4">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET responsable = 'estudiante' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                    </c:catch>
                </c:otherwise>
            </c:choose>
        </c:when>
    </c:choose>

    <%-- Registro en respuestas e historial --%>
    <c:catch var="histErr">
        <sql:update dataSource="${sigradoDb}">
            INSERT INTO respuestas (proyecto_id, fase, ronda, usuario_id, rol, estado, comentario)
            VALUES (?, ?, 1, ?, 'director', ?::estado_respuesta_enum, ?);
            <sql:param value="${proyId}" />
            <sql:param value="${faseActual}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="${decision}" />
            <sql:param value="${comentarios}" />
        </sql:update>
        <sql:update dataSource="${sigradoDb}">
            INSERT INTO historial (proyecto_id, usuario_id, accion, fase, comentario)
            VALUES (?, ?, ?, ?, ?);
            <sql:param value="${proyId}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="Director Fase ${faseActual}: ${decision}" />
            <sql:param value="${faseActual}" />
            <sql:param value="${comentarios}" />
        </sql:update>
    </c:catch>

    <c:set var="mensajeDirector" value="Respuesta enviada correctamente" />
</c:if>

<c:catch var="docErr">
    <sql:query var="misProyectosDirector" dataSource="${sigradoDb}">
        SELECT p.*,
               (SELECT d.url FROM documentos d WHERE d.proyecto_id = p.id AND d.fase = p.fase ORDER BY d.id DESC LIMIT 1) as ultimo_doc_url,
               (SELECT d.tipo FROM documentos d WHERE d.proyecto_id = p.id AND d.fase = p.fase ORDER BY d.id DESC LIMIT 1) as ultimo_doc_tipo
        FROM proyectos p
        WHERE p.director_id = ?
        ORDER BY p.id DESC;
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="Proyectos como Docente Director" />
<c:set var="param_active" value="director" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <c:if test="${not empty mensajeDirector}">
            <div class="alert alert-success alert-dismissible">
                <span>✅</span>
                <div><strong>${mensajeDirector}</strong> (El turno se transfirió automáticamente al siguiente actor)</div>
            </div>
        </c:if>

        <div class="card">
            <div class="card-header">
                <h3 class="card-title">🎯 Proyectos Asignados como Director (RF-DIR-01, 02, 03, 04)</h3>
                <span class="badge badge-phase">Fases 2 y 4</span>
            </div>

            <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 1.25rem;">
                En <strong>Fase 2</strong> evalúas el anteproyecto entregado por el estudiante y adjuntas el enlace al reporte de Turnitin. Al aprobar, pasa directamente a <strong>Fase 3 (Evaluador)</strong>. En <strong>Fase 4</strong> revisas el Informe Final.
            </p>

            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Código</th>
                            <th>Título</th>
                            <th>Fase y Turno</th>
                            <th>Documento del Estudiante</th>
                            <th>Estado</th>
                            <th style="text-align: right;">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty misProyectosDirector.rows}">
                                <c:forEach var="p" items="${misProyectosDirector.rows}">
                                    <tr>
                                        <td><strong>${p.codigo}</strong><br><small style="color:var(--text-muted);">${p.codigo_modalidad}</small></td>
                                        <td><strong>${p.titulo}</strong></td>
                                        <td>
                                            <span class="badge badge-phase">Fase ${p.fase}</span>
                                            <span class="badge ${p.responsable == 'director' ? 'badge-approved' : 'badge-responsible'}">
                                                Turno: ${p.responsable}
                                            </span>
                                        </td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${not empty p.ultimo_doc_url}">
                                                    <a href="${p.ultimo_doc_url}" target="_blank" rel="noopener noreferrer" class="btn btn-outline btn-sm">
                                                        👁️ Ver (${p.ultimo_doc_tipo})
                                                    </a>
                                                </c:when>
                                                <c:otherwise>
                                                    <span style="color: var(--text-muted); font-size: 0.8rem;">En espera de entrega</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td><span class="badge badge-approved">${p.estado}</span></td>
                                        <td style="text-align: right;">
                                            <c:if test="${p.responsable == 'director' and (p.fase == 2 or p.fase == 4)}">
                                                <button type="button" class="btn btn-primary btn-sm" onclick="responderDirector(${p.id}, '${p.codigo}', ${p.fase}, '${p.ultimo_doc_url}')">
                                                    ✍️ Responder
                                                </button>
                                            </c:if>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td><strong>GRA-00001</strong></td>
                                    <td><strong>Plataforma Web de Telemetría para Cultivos Hidropónicos</strong></td>
                                    <td>
                                        <span class="badge badge-phase">Fase 2</span>
                                        <span class="badge badge-approved">Turno: director</span>
                                    </td>
                                    <td>
                                        <a href="https://drive.google.com/anteproyecto-ejemplo" target="_blank" class="btn btn-outline btn-sm">
                                            👁️ Ver (Propuesta_FDC124)
                                        </a>
                                    </td>
                                    <td><span class="badge badge-approved">En curso</span></td>
                                    <td style="text-align: right;">
                                        <button type="button" class="btn btn-primary btn-sm" onclick="responderDirector(1, 'GRA-00001', 2, 'https://drive.google.com/anteproyecto-ejemplo')">
                                            ✍️ Responder
                                        </button>
                                    </td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

    <%-- Modal de Respuesta del Director --%>
    <div id="modalDirector" class="modal-overlay">
        <div class="modal-card">
            <div class="card-header">
                <h3 class="card-title">✍️ Respuesta del Director &bull; Fase <span id="spanDirFase"></span></h3>
                <button type="button" class="btn btn-outline btn-sm" onclick="cerrarModal('modalDirector')">✕</button>
            </div>
            <form action="director.jsp" method="POST" style="padding: 1.5rem;">
                <input type="hidden" id="dirProyId" name="proyecto_id" value="">
                <input type="hidden" id="dirFase" name="fase" value="">

                <div class="alert alert-success" style="font-size: 0.85rem; margin-bottom: 1rem;">
                    Revisando: <strong id="dirProyCod"></strong> | Enlace estudiante: <a id="dirDocLink" href="#" target="_blank">Abrir Documento ↗</a>
                </div>

                <div class="form-group">
                    <label for="decisionDir">Decisión:</label>
                    <select id="decisionDir" name="decision" class="form-control" required>
                        <option value="Aprobado">Aprobado (Avanzar al siguiente turno)</option>
                        <option value="Correcciones">Correcciones (Devolver al estudiante)</option>
                        <option value="Rechazado">No aprobado / Rechazado</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="turnitin_url">URL Informe de Plagio (Turnitin - HTTPS obligatorio):</label>
                    <input type="url" id="turnitin_url" name="turnitin_url" class="form-control" placeholder="https://turnitin.com/reports/..." required>
                </div>

                <div class="form-group">
                    <label for="comentariosDir">Observaciones y Retroalimentación:</label>
                    <textarea id="comentariosDir" name="comentarios" class="form-control" rows="3" placeholder="Retroalimentación metodológica para el estudiante..." required></textarea>
                </div>

                <div style="display: flex; justify-content: flex-end; gap: 0.75rem; margin-top: 1.25rem;">
                    <button type="button" class="btn btn-outline" onclick="cerrarModal('modalDirector')">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Registrar Decisión</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function responderDirector(id, cod, fase, docUrl) {
            document.getElementById('dirProyId').value = id;
            document.getElementById('dirFase').value = fase;
            document.getElementById('dirProyCod').innerText = cod;
            document.getElementById('spanDirFase').innerText = fase;

            const docLink = document.getElementById('dirDocLink');
            if (docUrl && docUrl.length > 0) {
                docLink.href = docUrl;
                docLink.innerText = 'Abrir Documento Entregado ↗';
                docLink.style.pointerEvents = 'auto';
            } else {
                docLink.innerText = 'Sin documento cargado';
                docLink.removeAttribute('href');
            }

            abrirModal('modalDirector');
        }
    </script>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

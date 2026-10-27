<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardDocente.jspf" %>

<c:set var="mensajeEvaluador" value="" />
<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="proyId" value="${param.proyecto_id}" />
    <c:set var="faseActual" value="${param.fase}" />
    <c:set var="decision" value="${param.decision}" />
    <c:set var="comentarios" value="${param.comentarios}" />
    <c:set var="docFirmadoUrl" value="${param.doc_firmado_url}" />
    <c:set var="rejillaUrl" value="${param.rejilla_url}" />
    <c:set var="actaNum" value="${param.acta_numero}" />

    <c:choose>
        <%-- Fase 3: Evaluador responde con F-DC-124 firmada. Si aprueba, pasa a Comité --%>
        <c:when test="${faseActual == '3'}">
            <c:choose>
                <c:when test="${decision == 'Aprobado'}">
                    <c:catch var="e3Err">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET fase = 3, responsable = 'comite' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                        <sql:update dataSource="${sigradoDb}">
                            INSERT INTO documentos (proyecto_id, fase, tipo, version, url, titulo, subido_por)
                            VALUES (?, 3, 'Propuesta_FDC124_Firmada', 1, ?, 'Propuesta F-DC-124 Firmada', ?);
                            <sql:param value="${proyId}" />
                            <sql:param value="${docFirmadoUrl}" />
                            <sql:param value="${sessionScope.usuario.id}" />
                        </sql:update>
                    </c:catch>
                </c:when>
                <c:otherwise>
                    <c:catch var="e3Err">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET fase = 2, responsable = 'estudiante' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                    </c:catch>
                </c:otherwise>
            </c:choose>
        </c:when>

        <%-- Fase 5: Evaluador con F-DC-125 y Rejilla F-DC-129 --%>
        <c:when test="${faseActual == '5'}">
            <c:choose>
                <c:when test="${decision == 'Aprobado'}">
                    <c:catch var="e5Err">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET fase = 5, responsable = 'comite' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                        <sql:update dataSource="${sigradoDb}">
                            INSERT INTO documentos (proyecto_id, fase, tipo, version, url, titulo, subido_por)
                            VALUES (?, 5, 'Informe_FDC125_Firmado', 1, ?, 'Informe F-DC-125 Firmado', ?);
                            <sql:param value="${proyId}" />
                            <sql:param value="${docFirmadoUrl}" />
                            <sql:param value="${sessionScope.usuario.id}" />
                        </sql:update>
                        <sql:update dataSource="${sigradoDb}">
                            INSERT INTO documentos (proyecto_id, fase, tipo, version, url, titulo, subido_por)
                            VALUES (?, 5, 'Rejilla_FDC129', 1, ?, 'Rejilla F-DC-129 Firmada', ?);
                            <sql:param value="${proyId}" />
                            <sql:param value="${rejillaUrl}" />
                            <sql:param value="${sessionScope.usuario.id}" />
                        </sql:update>
                    </c:catch>
                </c:when>
                <c:otherwise>
                    <c:catch var="e5Err">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET fase = 4, responsable = 'estudiante' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                    </c:catch>
                </c:otherwise>
            </c:choose>
        </c:when>
    </c:choose>

    <%-- Respuestas e Historial --%>
    <c:catch var="rErr">
        <sql:update dataSource="${sigradoDb}">
            INSERT INTO respuestas (proyecto_id, fase, ronda, usuario_id, rol, estado, acta_numero, comentario)
            VALUES (?, ?, 1, ?, 'evaluador', ?::estado_respuesta_enum, ?, ?);
            <sql:param value="${proyId}" />
            <sql:param value="${faseActual}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="${decision}" />
            <sql:param value="${actaNum}" />
            <sql:param value="${comentarios}" />
        </sql:update>
        <sql:update dataSource="${sigradoDb}">
            INSERT INTO historial (proyecto_id, usuario_id, accion, fase, comentario)
            VALUES (?, ?, ?, ?, ?);
            <sql:param value="${proyId}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="Evaluador Fase ${faseActual}: ${decision}" />
            <sql:param value="${faseActual}" />
            <sql:param value="${comentarios}" />
        </sql:update>
    </c:catch>

    <c:set var="mensajeEvaluador" value="Respuesta enviada correctamente" />
</c:if>

<c:catch var="evaQueryErr">
    <sql:query var="misProyectosEvaluador" dataSource="${sigradoDb}">
        SELECT p.*,
               (SELECT d.url FROM documentos d WHERE d.proyecto_id = p.id AND d.tipo LIKE '%Turnitin%' ORDER BY d.id DESC LIMIT 1) as turnitin_doc_url,
               (SELECT d.url FROM documentos d WHERE d.proyecto_id = p.id AND (d.tipo = 'Propuesta_FDC124' OR d.tipo = 'Informe_FDC125') ORDER BY d.id DESC LIMIT 1) as propuesta_url
        FROM proyectos p
        WHERE p.evaluador_id = ?
        ORDER BY p.id DESC;
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
</c:catch>

<c:set var="pageTitle" value="Proyectos como Docente Evaluador" />
<c:set var="param_active" value="evaluador" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <c:if test="${not empty mensajeEvaluador}">
            <div class="alert alert-success alert-dismissible">
                <span>✅</span>
                <div><strong>${mensajeEvaluador}</strong> (El proyecto ha pasado a consideración del Comité Curricular)</div>
            </div>
        </c:if>

        <div class="card">
            <div class="card-header">
                <h3 class="card-title">📝 Proyectos Asignados como Evaluador (RF-EVA-01, 02, 03, 04)</h3>
                <span class="badge badge-phase">Fases 3 y 5</span>
            </div>

            <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 1.25rem;">
                En <strong>Fase 3</strong> examinas la propuesta y el Turnitin del Director, respondiendo con la <strong>URL de la propuesta firmada (F-DC-124)</strong>. En <strong>Fase 5</strong> dictaminas el informe final con <strong>F-DC-125 y Rejilla F-DC-129</strong>.
            </p>

            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Código</th>
                            <th>Título</th>
                            <th>Fase y Turno</th>
                            <th>Propuesta y Turnitin</th>
                            <th>Estado</th>
                            <th style="text-align: right;">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty misProyectosEvaluador.rows}">
                                <c:forEach var="p" items="${misProyectosEvaluador.rows}">
                                    <tr>
                                        <td><strong>${p.codigo}</strong><br><small style="color:var(--text-muted);">${p.codigo_modalidad}</small></td>
                                        <td><strong>${p.titulo}</strong></td>
                                        <td>
                                            <span class="badge badge-phase">Fase ${p.fase}</span>
                                            <span class="badge ${p.responsable == 'evaluador' ? 'badge-approved' : 'badge-responsible'}">
                                                Turno: ${p.responsable}
                                            </span>
                                        </td>
                                        <td>
                                            <c:if test="${not empty p.propuesta_url}">
                                                <a href="${p.propuesta_url}" target="_blank" class="btn btn-outline btn-sm">📄 Documento</a>
                                            </c:if>
                                            <c:if test="${not empty p.turnitin_doc_url}">
                                                <a href="${p.turnitin_doc_url}" target="_blank" class="btn btn-outline btn-sm" style="color: #2563eb;">🔍 Turnitin</a>
                                            </c:if>
                                        </td>
                                        <td><span class="badge badge-approved">${p.estado}</span></td>
                                        <td style="text-align: right;">
                                            <c:if test="${p.responsable == 'evaluador' and (p.fase == 3 or p.fase == 5)}">
                                                <button type="button" class="btn btn-primary btn-sm" onclick="responderEvaluador(${p.id}, '${p.codigo}', ${p.fase})">
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
                                        <span class="badge badge-phase">Fase 3</span>
                                        <span class="badge badge-approved">Turno: evaluador</span>
                                    </td>
                                    <td>
                                        <a href="https://drive.google.com/anteproyecto-ejemplo" target="_blank" class="btn btn-outline btn-sm">📄 Propuesta</a>
                                        <a href="https://turnitin.com/ejemplo" target="_blank" class="btn btn-outline btn-sm" style="color: #2563eb;">🔍 Turnitin</a>
                                    </td>
                                    <td><span class="badge badge-approved">En curso</span></td>
                                    <td style="text-align: right;">
                                        <button type="button" class="btn btn-primary btn-sm" onclick="responderEvaluador(1, 'GRA-00001', 3)">
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

    <%-- Modal de Evaluación --%>
    <div id="modalEvaluador" class="modal-overlay">
        <div class="modal-card">
            <div class="card-header">
                <h3 class="card-title">✍️ Dictamen del Evaluador &bull; Fase <span id="spanEvaFase"></span></h3>
                <button type="button" class="btn btn-outline btn-sm" onclick="cerrarModal('modalEvaluador')">✕</button>
            </div>
            <form action="evaluador.jsp" method="POST" style="padding: 1.5rem;">
                <input type="hidden" id="evaProyId" name="proyecto_id" value="">
                <input type="hidden" id="evaFase" name="fase" value="">

                <div class="form-group">
                    <label for="decisionEva">Decisión:</label>
                    <select id="decisionEva" name="decision" class="form-control" required>
                        <option value="Aprobado">Aprobado (Pasar al Comité)</option>
                        <option value="Correcciones">Correcciones (Devolver al estudiante)</option>
                        <option value="Rechazado">Rechazado</option>
                    </select>
                </div>

                <div class="form-group">
                    <label id="lblDocFirmado" for="doc_firmado_url">URL Documento Firmado (F-DC-124 / F-DC-125):</label>
                    <input type="url" id="doc_firmado_url" name="doc_firmado_url" class="form-control" placeholder="https://drive.google.com/..." required>
                </div>

                <div id="campoRejilla" class="form-group" style="display: none;">
                    <label for="rejilla_url">URL Rejilla de Evaluación Firmada (F-DC-129):</label>
                    <input type="url" id="rejilla_url" name="rejilla_url" class="form-control" placeholder="https://drive.google.com/rejilla-firmada">
                </div>

                <div class="form-group">
                    <label for="acta_numero_eva">Número de Acta (opcional):</label>
                    <input type="text" id="acta_numero_eva" name="acta_numero" class="form-control" placeholder="Ej: EVA-2026-10">
                </div>

                <div class="form-group">
                    <label for="comentariosEva">Observaciones del Evaluador:</label>
                    <textarea id="comentariosEva" name="comentarios" class="form-control" rows="3" placeholder="Comentarios de la evaluación técnica..." required></textarea>
                </div>

                <div style="display: flex; justify-content: flex-end; gap: 0.75rem; margin-top: 1.25rem;">
                    <button type="button" class="btn btn-outline" onclick="cerrarModal('modalEvaluador')">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Registrar Dictamen</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function responderEvaluador(id, cod, fase) {
            document.getElementById('evaProyId').value = id;
            document.getElementById('evaFase').value = fase;
            document.getElementById('spanEvaFase').innerText = fase;

            const lblDoc = document.getElementById('lblDocFirmado');
            const rejillaBox = document.getElementById('campoRejilla');
            const rejillaInput = document.getElementById('rejilla_url');

            if (fase === 5) {
                lblDoc.innerText = 'URL Informe Final Firmado (F-DC-125):';
                rejillaBox.style.display = 'block';
                rejillaInput.required = true;
            } else {
                lblDoc.innerText = 'URL Propuesta Firmada (F-DC-124):';
                rejillaBox.style.display = 'none';
                rejillaInput.required = false;
            }

            abrirModal('modalEvaluador');
        }
    </script>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

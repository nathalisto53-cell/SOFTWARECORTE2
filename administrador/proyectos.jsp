<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardAdministrador.jspf" %>

<%-- =========================================================================
     SIGRADO - Gestión Global de Proyectos de Grado (Administrador)
     - Permite al Administrador asignar Director, Evaluador y Codirector a cualquier proyecto.
     - Permite cambiar de fase, responsable en turno y código de modalidad.
     - Genera listados dinámicos de docentes directores y evaluadores elegibles.
     - Arquitectura: JSTL 1.2 puro (Cero Servlets, Cero Scriptlets, Cero DAOs).
     ========================================================================= --%>

<c:set var="mensajeAccion" value="" />
<c:set var="tipoAlerta" value="success" />

<%-- PROCESAMIENTO DE ACCIONES DEL ADMINISTRADOR (POST) --%>
<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="accion" value="${param.accion}" />

    <%-- 1. ASIGNACIÓN DE DIRECTOR, EVALUADOR Y GESTIÓN DE FASE POR EL ADMIN --%>
    <c:if test="${accion == 'asignar_proyecto'}">
        <c:set var="pId" value="${param.proyecto_id}" />
        <c:set var="dirId" value="${empty param.director_id ? null : param.director_id}" />
        <c:set var="evaId" value="${empty param.evaluador_id ? null : param.evaluador_id}" />
        <c:set var="codirId" value="${empty param.codirector_id ? null : param.codirector_id}" />
        <c:set var="nuevaFase" value="${param.fase}" />
        <c:set var="nuevoResp" value="${param.responsable}" />
        <c:set var="nuevoCodMod" value="${param.codigo_modalidad}" />
        <c:set var="obsAdmin" value="${param.observaciones}" />

        <c:catch var="asigSqlErr">
            <sql:update dataSource="${sigradoDb}">
                UPDATE proyectos 
                SET director_id = ?,
                    evaluador_id = ?,
                    codirector_id = ?,
                    fase = ?,
                    responsable = ?,
                    codigo_modalidad = ?
                WHERE id = ?;
                <sql:param value="${dirId}" />
                <sql:param value="${evaId}" />
                <sql:param value="${codirId}" />
                <sql:param value="${nuevaFase}" />
                <sql:param value="${nuevoResp}" />
                <sql:param value="${nuevoCodMod}" />
                <sql:param value="${pId}" />
            </sql:update>

            <sql:update dataSource="${sigradoDb}">
                INSERT INTO historial (proyecto_id, usuario_id, accion, fase, comentario)
                VALUES (?, ?, 'Asignación de Jurados / Actualización por Administrador', ?, ?);
                <sql:param value="${pId}" />
                <sql:param value="${sessionScope.usuario.id}" />
                <sql:param value="${nuevaFase}" />
                <sql:param value="${obsAdmin}" />
            </sql:update>
        </c:catch>

        <%-- Actualizar almacén demo compartido en memoria --%>
        <c:if test="${not empty applicationScope.demoProyectos}">
            <c:set var="nomDir" value="" />
            <c:set var="apeDir" value="" />
            <c:set var="emailDir" value="" />
            <c:set var="nomEva" value="" />
            <c:set var="apeEva" value="" />
            <c:set var="emailEva" value="" />
            <c:set var="nomCodir" value="" />

            <c:forEach var="u" items="${applicationScope.demoListaUsuarios}">
                <c:if test="${u.id == dirId or ('' + u.id) == ('' + dirId)}">
                    <c:set var="nomDir" value="${u.nombres}" />
                    <c:set var="apeDir" value="${u.apellidos}" />
                    <c:set var="emailDir" value="${u.email}" />
                </c:if>
                <c:if test="${u.id == evaId or ('' + u.id) == ('' + evaId)}">
                    <c:set var="nomEva" value="${u.nombres}" />
                    <c:set var="apeEva" value="${u.apellidos}" />
                    <c:set var="emailEva" value="${u.email}" />
                </c:if>
                <c:if test="${not empty codirId and (u.id == codirId or ('' + u.id) == ('' + codirId))}">
                    <c:set var="nomCodir" value="${u.nombres} ${u.apellidos}" />
                </c:if>
            </c:forEach>

            <c:forEach var="dp" items="${applicationScope.demoProyectos}">
                <c:if test="${dp.id == pId or ('' + dp.id) == ('' + pId)}">
                    <c:set target="${dp}" property="director_id" value="${dirId}" />
                    <c:set target="${dp}" property="dir_nom" value="${nomDir}" />
                    <c:set target="${dp}" property="dir_ape" value="${apeDir}" />
                    <c:set target="${dp}" property="dir_email" value="${emailDir}" />
                    <c:set target="${dp}" property="evaluador_id" value="${evaId}" />
                    <c:set target="${dp}" property="eva_nom" value="${nomEva}" />
                    <c:set target="${dp}" property="eva_ape" value="${apeEva}" />
                    <c:set target="${dp}" property="eva_email" value="${emailEva}" />
                    <c:set target="${dp}" property="codir_nom" value="${nomCodir}" />
                    <c:set target="${dp}" property="fase" value="${nuevaFase}" />
                    <c:set target="${dp}" property="responsable" value="${nuevoResp}" />
                    <c:if test="${not empty nuevoCodMod}">
                        <c:set target="${dp}" property="codigo_modalidad" value="${nuevoCodMod}" />
                    </c:if>
                </c:if>
            </c:forEach>

            <%-- Registrar en historial de respuestas/decisiones --%>
            <c:if test="${not empty applicationScope.demoRespuestas}">
                <jsp:useBean id="admRespBean" class="java.util.HashMap" scope="page" />
                <c:set target="${admRespBean}" property="id" value="${pId}0A" />
                <c:set target="${admRespBean}" property="proyecto_id" value="${pId}" />
                <c:set target="${admRespBean}" property="fase" value="${nuevaFase}" />
                <c:set target="${admRespBean}" property="ronda" value="1" />
                <c:set target="${admRespBean}" property="rol" value="comite" />
                <c:set target="${admRespBean}" property="estado" value="Aprobado" />
                <c:set target="${admRespBean}" property="acta_numero" value="RES-ADMIN-2026" />
                <c:set target="${admRespBean}" property="comentario" value="Asignación directa por Administrador: ${obsAdmin}" />
                <c:set target="${admRespBean}" property="fecha" value="Hoy" />
                <c:set var="dummyAR" value="${applicationScope.demoRespuestas.add(0, admRespBean)}" />
            </c:if>
        </c:if>

        <c:set var="mensajeAccion" value="✅ Asignación de Director, Evaluador y parámetros del proyecto #${pId} actualizados exitosamente." />
    </c:if>

    <%-- 2. CANCELACIÓN DE PROYECTO --%>
    <c:if test="${accion == 'cancelar'}">
        <c:set var="pId" value="${param.proyecto_id}" />
        <c:set var="motivo" value="${param.motivo_cancelacion}" />
        <c:catch var="cancelErr">
            <sql:update dataSource="${sigradoDb}">
                UPDATE proyectos SET estado = 'Cancelado' WHERE id = ?;
                <sql:param value="${pId}" />
            </sql:update>
            <sql:update dataSource="${sigradoDb}">
                INSERT INTO historial (proyecto_id, usuario_id, accion, fase, comentario)
                VALUES (?, ?, 'Cancelación de Proyecto por Administrador', 1, ?);
                <sql:param value="${pId}" />
                <sql:param value="${sessionScope.usuario.id}" />
                <sql:param value="${motivo}" />
            </sql:update>
        </c:catch>

        <c:forEach var="dp" items="${applicationScope.demoProyectos}">
            <c:if test="${dp.id == pId or ('' + dp.id) == ('' + pId)}">
                <c:set target="${dp}" property="estado" value="Cancelado" />
            </c:if>
        </c:forEach>

        <c:set var="mensajeAccion" value="🗑️ Proyecto #${pId} cancelado correctamente." />
    </c:if>
</c:if>

<%-- 1. LISTADO DE DOCENTES PARA ASIGNACIONES (DIRECTOR Y EVALUADOR) --%>
<c:set var="docentesDisponibles" value="${null}" />
<c:catch var="docErr">
    <sql:query var="docListQ" dataSource="${sigradoDb}">
        SELECT u.id, u.nombres, u.apellidos, u.email, u.documento
        FROM usuarios u
        JOIN usuario_rol ur ON u.id = ur.usuario_id
        JOIN roles r ON ur.rol_id = r.id
        WHERE (r.nombre = 'docente' OR r.nombre = 'administrador') AND u.activo = 1
        ORDER BY u.apellidos ASC;
    </sql:query>
    <c:if test="${not empty docListQ.rows and docListQ.rowCount > 0}">
        <c:set var="docentesDisponibles" value="${docListQ.rows}" />
    </c:if>
</c:catch>

<c:if test="${empty docentesDisponibles and not empty applicationScope.demoListaUsuarios}">
    <jsp:useBean id="docFiltradosAdmin" class="java.util.ArrayList" scope="page" />
    <c:forEach var="u" items="${applicationScope.demoListaUsuarios}">
        <c:if test="${(empty u.eliminado or u.eliminado == false) and (u.activo == 1 or u.activo == '1')}">
            <c:if test="${fn:contains(u.roles_asignados, 'docente') or fn:contains(u.roles_asignados, 'administrador')}">
                <c:set var="dummyADoc" value="${docFiltradosAdmin.add(u)}" />
            </c:if>
        </c:if>
    </c:forEach>
    <c:set var="docentesDisponibles" value="${docFiltradosAdmin}" />
</c:if>

<%-- 2. LISTADO DE PROYECTOS --%>
<c:set var="listaProyectos" value="${null}" />
<c:catch var="errList">
    <sql:query var="proyectosDbQ" dataSource="${sigradoDb}">
        SELECT p.*, per.codigo as periodo_cod,
               d.nombres as dir_nom, d.apellidos as dir_ape,
               e.nombres as eva_nom, e.apellidos as eva_ape,
               (SELECT d2.url FROM documentos d2 WHERE d2.proyecto_id = p.id ORDER BY d2.id DESC LIMIT 1) as ultimo_doc_url
        FROM proyectos p
        LEFT JOIN periodos per ON p.periodo_id = per.id
        LEFT JOIN usuarios d ON p.director_id = d.id
        LEFT JOIN usuarios e ON p.evaluador_id = e.id
        ORDER BY p.id DESC;
    </sql:query>
    <c:if test="${not empty proyectosDbQ.rows and proyectosDbQ.rowCount > 0}">
        <c:set var="listaProyectos" value="${proyectosDbQ.rows}" />
    </c:if>
</c:catch>

<c:if test="${empty listaProyectos}">
    <c:set var="listaProyectos" value="${applicationScope.demoProyectos}" />
</c:if>

<c:set var="pageTitle" value="Gestión Global de Proyectos" />
<c:set var="param_active" value="proyectos" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <c:if test="${not empty mensajeAccion}">
            <div class="alert alert-success" style="display: flex; gap: 0.75rem; align-items: center; margin-bottom: 1.5rem; border-radius: var(--radius-md); padding: 1rem 1.25rem;">
                <span style="font-size: 1.25rem;">✓</span>
                <div>${mensajeAccion}</div>
            </div>
        </c:if>

        <div class="card">
            <div class="card-header" style="flex-wrap: wrap; gap: 1rem;">
                <div>
                    <h3 class="card-title">📁 Control y Asignación de Proyectos de Grado (RF-ADM-06, RF-GEN-08)</h3>
                    <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0.25rem 0 0;">
                        Supervisión y control total: Asignar o cambiar Directores, Evaluadores, Fases y Códigos de Modalidad.
                    </p>
                </div>
                <span class="badge badge-phase">Visión de Administrador</span>
            </div>

            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Código / Modalidad</th>
                            <th>Título del Proyecto</th>
                            <th>Nivel / Modalidad</th>
                            <th>Fase y Turno</th>
                            <th>Estado</th>
                            <th>Director / Evaluador</th>
                            <th style="text-align: right;">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty listaProyectos}">
                                <c:forEach var="p" items="${listaProyectos}">
                                    <c:set var="enlaceDoc" value="${not empty p.ultimo_doc_url ? p.ultimo_doc_url : p.soporte_pago_url}" />
                                    <tr>
                                        <td>
                                            <strong>${p.codigo}</strong><br>
                                            <small style="color:var(--text-muted);">${empty p.codigo_modalidad ? 'Sin modalidad asignada' : p.codigo_modalidad}</small>
                                        </td>
                                        <td>
                                            <strong>${p.titulo}</strong>
                                            <c:if test="${not empty p.estudiante_nom}">
                                                <div style="font-size: 0.78rem; color: var(--text-muted); margin-top: 0.2rem;">
                                                    👤 Estudiante: <strong>${p.estudiante_nom}</strong>
                                                </div>
                                            </c:if>
                                            <c:if test="${not empty enlaceDoc}">
                                                <div style="margin-top: 0.35rem;">
                                                    <a href="${fn:startsWith(enlaceDoc, 'http') ? enlaceDoc : ('https://' += enlaceDoc)}" target="_blank" rel="noopener noreferrer" style="font-size: 0.76rem; color: var(--primary-700); text-decoration: underline;">
                                                        👁️ Ver Enlace Radicado ↗
                                                    </a>
                                                </div>
                                            </c:if>
                                        </td>
                                        <td>
                                            ${p.tipo_nivel}<br>
                                            <small style="color:var(--text-muted);">${p.tipo_modalidad}</small>
                                        </td>
                                        <td>
                                            <span class="badge badge-phase">Fase ${p.fase} de 6</span>
                                            <div style="margin-top: 0.25rem;">
                                                <span class="badge badge-responsible">Turno: ${p.responsable}</span>
                                            </div>
                                        </td>
                                        <td>
                                            <span class="badge ${p.estado == 'En curso' ? 'badge-approved' : (p.estado == 'Finalizado' ? 'badge-phase' : 'badge-rejected')}">
                                                ${p.estado}
                                            </span>
                                        </td>
                                        <td>
                                            <div style="font-size: 0.8rem; line-height: 1.45;">
                                                <div><strong>Dir:</strong> ${empty p.dir_nom ? '<span style="color:#d97706;">Por asignar</span>' : (p.dir_nom += ' ' += p.dir_ape)}</div>
                                                <div><strong>Eva:</strong> ${empty p.eva_nom ? '<span style="color:#d97706;">Por asignar</span>' : (p.eva_nom += ' ' += p.eva_ape)}</div>
                                            </div>
                                        </td>
                                        <td style="text-align: right; white-space: nowrap;">
                                            <div style="display: flex; gap: 0.4rem; justify-content: flex-end;">
                                                <%-- Botón para asignar jurados y gestionar el proyecto --%>
                                                <button type="button" class="btn btn-primary btn-sm" onclick="abrirModalAdminAsignar('${p.id}', '${fn:escapeXml(p.codigo)}', '${fn:escapeXml(p.titulo)}', '${p.fase}', '${p.responsable}', '${fn:escapeXml(p.codigo_modalidad)}', '${p.director_id}', '${p.evaluador_id}', '${p.codirector_id}', '${p.tipo_nivel}')">
                                                    🎯 Asignar / Gestionar
                                                </button>

                                                <c:if test="${p.estado == 'En curso'}">
                                                    <button type="button" class="btn btn-outline btn-sm" onclick="prepararCancelacion(${p.id}, '${p.codigo}')" style="color: #ef4444; border-color: #fca5a5;" title="Cancelar Proyecto">
                                                        ✕
                                                    </button>
                                                </c:if>
                                            </div>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td colspan="7" style="text-align: center; color: var(--text-muted); padding: 2rem;">
                                        No se encontraron proyectos de grado registrados.
                                    </td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

    <%-- =========================================================================
         MODAL ADMINISTRADOR: ASIGNACIÓN DE DIRECTOR, EVALUADOR Y CONTROL DE PROYECTO
         ========================================================================= --%>
    <div id="modalAdminAsignar" class="modal-overlay" style="display: none;">
        <div class="modal-box" style="max-width: 640px; max-height: 90vh; overflow-y: auto;">
            <div class="modal-header" style="background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);">
                <div>
                    <h3 class="card-title" style="margin: 0; color: var(--primary-900);">
                        🎯 Asignar Docentes y Parámetros del Proyecto
                    </h3>
                    <small style="color: var(--primary-700); font-weight: 600;">Facultad de Administración Institucional</small>
                </div>
                <button type="button" class="modal-close-btn" onclick="cerrarModal('modalAdminAsignar')">&times;</button>
            </div>

            <form action="proyectos.jsp" method="POST">
                <input type="hidden" name="accion" value="asignar_proyecto">
                <input type="hidden" id="adm_proy_id" name="proyecto_id" value="">

                <div class="modal-body" style="padding: 1.5rem;">
                    
                    <div style="background: var(--primary-50); border: 1px solid var(--border-green); border-radius: var(--radius-md); padding: 0.85rem 1rem; margin-bottom: 1.25rem;">
                        <span id="adm_badge_codigo" style="font-family: monospace; font-size: 0.8rem; font-weight: 700; background: var(--primary-200); color: var(--primary-900); padding: 0.15rem 0.45rem; border-radius: var(--radius-sm);">
                            GRA-XXXX
                        </span>
                        <h4 id="adm_display_titulo" style="font-size: 0.98rem; color: var(--primary-900); margin: 0.35rem 0 0; line-height: 1.35;">
                            ...
                        </h4>
                    </div>

                    <%-- LISTADOS DE DOCENTES DIRECTORES Y EVALUADORES GENERADOS DINÁMICAMENTE --%>
                    <div style="background: #ffffff; border: 1px solid var(--border-light); border-radius: var(--radius-md); padding: 1.25rem; margin-bottom: 1.25rem;">
                        <h4 style="font-size: 0.88rem; color: var(--primary-dark); text-transform: uppercase; margin: 0 0 1rem; letter-spacing: 0.5px;">
                            👨‍🏫 Asignación Oficial de Jurados
                        </h4>

                        <div class="form-grid">
                            <%-- LISTADO DIRECTOR --%>
                            <div class="form-group">
                                <label for="adm_director_id" style="color: var(--primary-900); font-weight: 700;">
                                    🎯 Docente Director de Proyecto:
                                </label>
                                <select id="adm_director_id" name="director_id" class="form-control" required>
                                    <option value="">-- Seleccionar Director --</option>
                                    <c:forEach var="doc" items="${docentesDisponibles}">
                                        <option value="${doc.id}">
                                            ${doc.apellidos}, ${doc.nombres} (${doc.email})
                                        </option>
                                    </c:forEach>
                                </select>
                            </div>

                            <%-- LISTADO EVALUADOR --%>
                            <div class="form-group">
                                <label for="adm_evaluador_id" style="color: var(--primary-900); font-weight: 700;">
                                    🔍 Docente Jurado Evaluador:
                                </label>
                                <select id="adm_evaluador_id" name="evaluador_id" class="form-control" required>
                                    <option value="">-- Seleccionar Evaluador --</option>
                                    <c:forEach var="doc" items="${docentesDisponibles}">
                                        <option value="${doc.id}">
                                            ${doc.apellidos}, ${doc.nombres} (${doc.email})
                                        </option>
                                    </c:forEach>
                                </select>
                            </div>
                        </div>

                        <%-- Codirector Opcional --%>
                        <div class="form-group" style="margin-top: 0.75rem; margin-bottom: 0;">
                            <label for="adm_codirector_id">Docente Codirector (Opcional):</label>
                            <select id="adm_codirector_id" name="codirector_id" class="form-control">
                                <option value="">-- Sin codirector asignado --</option>
                                <c:forEach var="doc" items="${docentesDisponibles}">
                                    <option value="${doc.id}">
                                        ${doc.apellidos}, ${doc.nombres} (${doc.email})
                                    </option>
                                </c:forEach>
                            </select>
                        </div>
                    </div>

                    <%-- CONTROL DE FASE, TURNO Y CÓDIGO DE MODALIDAD --%>
                    <div class="form-grid" style="margin-bottom: 1rem;">
                        <div class="form-group">
                            <label for="adm_fase">Fase del Proyecto (1 a 6):</label>
                            <select id="adm_fase" name="fase" class="form-control" required>
                                <option value="1">Fase 1: Postulación e Idea y Pago</option>
                                <option value="2">Fase 2: Elaboración de Propuesta (F-DC-124)</option>
                                <option value="3">Fase 3: Evaluación de Propuesta (Comité/Jurado)</option>
                                <option value="4">Fase 4: Desarrollo e Informe Final (F-DC-125)</option>
                                <option value="5">Fase 5: Evaluación de Informe (Rejilla F-DC-129)</option>
                                <option value="6">Fase 6: Sustentación Pública y Grado</option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label for="adm_responsable">Actor en Turno:</label>
                            <select id="adm_responsable" name="responsable" class="form-control" required>
                                <option value="estudiante">Estudiante</option>
                                <option value="director">Director</option>
                                <option value="evaluador">Evaluador</option>
                                <option value="comite">Comité Curricular</option>
                            </select>
                        </div>
                    </div>

                    <div class="form-group" style="margin-bottom: 1rem;">
                        <label for="adm_codigo_modalidad">Código de Modalidad Asignado:</label>
                        <input type="text" id="adm_codigo_modalidad" name="codigo_modalidad" class="form-control" placeholder="Ej: 125-2026-01 o 65-2026-01">
                        <small style="color: var(--text-muted); font-size: 0.76rem;">125-XXX para Profesional, 65-XXX para Tecnológico.</small>
                    </div>

                    <div class="form-group">
                        <label for="adm_observaciones">Observaciones Administrativas:</label>
                        <textarea id="adm_observaciones" name="observaciones" class="form-control" rows="2" placeholder="Motivo de la asignación o cambios de estado..."></textarea>
                    </div>

                </div>

                <div class="modal-footer" style="padding: 1rem 1.5rem; background: var(--bg-light); border-top: 1px solid var(--border-light); display: flex; justify-content: flex-end; gap: 0.75rem;">
                    <button type="button" class="btn btn-outline" onclick="cerrarModal('modalAdminAsignar')">Cancelar</button>
                    <button type="submit" class="btn btn-primary" style="padding: 0.65rem 1.5rem;">
                        💾 Guardar Asignaciones
                    </button>
                </div>
            </form>
        </div>
    </div>

    <%-- MODAL DE CONFIRMACIÓN DE CANCELACIÓN --%>
    <div id="modalCancelarProy" class="modal-overlay" style="display: none;">
        <div class="modal-box" style="max-width: 460px;">
            <div class="modal-header" style="border-bottom-color: #fee2e2;">
                <h3 style="font-size: 1.15rem; color: #b91c1c; margin: 0;">Confirmar Cancelación de Proyecto</h3>
                <button type="button" class="modal-close-btn" onclick="cerrarModal('modalCancelarProy')">&times;</button>
            </div>
            <form action="proyectos.jsp" method="POST">
                <input type="hidden" name="accion" value="cancelar">
                <input type="hidden" id="cancel_proy_id" name="proyecto_id" value="">
                
                <div class="modal-body" style="padding: 1.5rem;">
                    <p style="font-size: 0.95rem; color: var(--text-main); margin-bottom: 0.75rem;">
                        ¿Confirma la cancelación del proyecto <strong id="cancel_proy_cod" style="color: #b91c1c;">...</strong>?
                    </p>
                    <div class="form-group">
                        <label for="motivo_cancelacion">Motivo de Cancelación:</label>
                        <textarea id="motivo_cancelacion" name="motivo_cancelacion" class="form-control" rows="2" placeholder="Escriba la justificación institucional..." required></textarea>
                    </div>
                </div>

                <div class="modal-footer" style="padding: 1rem 1.5rem; background: var(--bg-light); border-top: 1px solid var(--border-light); display: flex; justify-content: flex-end; gap: 0.75rem;">
                    <button type="button" class="btn btn-outline" onclick="cerrarModal('modalCancelarProy')">Volver</button>
                    <button type="submit" class="btn btn-primary" style="background: #dc2626; border-color: #b91c1c;">
                        Confirmar Cancelación
                    </button>
                </div>
            </form>
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

<style>
    .modal-overlay {
        position: fixed;
        top: 0; left: 0; right: 0; bottom: 0;
        background: rgba(15, 23, 42, 0.6);
        backdrop-filter: blur(4px);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
        padding: 1.5rem;
    }
    .modal-box {
        background: #ffffff;
        border-radius: var(--radius-lg);
        box-shadow: var(--shadow-lg);
        width: 100%;
        overflow: hidden;
        animation: modalAppear 0.2s ease-out;
    }
    .modal-header {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid var(--border-light);
        display: flex;
        justify-content: space-between;
        align-items: center;
    }
    .modal-close-btn {
        background: transparent;
        border: none;
        font-size: 1.5rem;
        cursor: pointer;
        color: var(--text-muted);
        line-height: 1;
    }
    .modal-close-btn:hover {
        color: #dc2626;
    }
    @keyframes modalAppear {
        from { opacity: 0; transform: translateY(-15px) scale(0.98); }
        to { opacity: 1; transform: translateY(0) scale(1); }
    }
</style>

<script>
    function abrirModalAdminAsignar(id, codigo, titulo, fase, resp, codMod, dirId, evaId, codirId, nivel) {
        document.getElementById('adm_proy_id').value = id;
        document.getElementById('adm_badge_codigo').textContent = codigo;
        document.getElementById('adm_display_titulo').textContent = titulo;
        document.getElementById('adm_fase').value = fase || '1';
        document.getElementById('adm_responsable').value = resp || 'comite';

        // Autogenerar sugerencia de código si está vacío
        if (codMod && codMod.trim() !== '' && codMod !== 'null') {
            document.getElementById('adm_codigo_modalidad').value = codMod;
        } else {
            const prefijo = (nivel === 'Tecnologico') ? '65' : '125';
            document.getElementById('adm_codigo_modalidad').value = prefijo + '-2026-' + id;
        }

        if (dirId && document.getElementById('adm_director_id')) {
            document.getElementById('adm_director_id').value = dirId;
        }
        if (evaId && document.getElementById('adm_evaluador_id')) {
            document.getElementById('adm_evaluador_id').value = evaId;
        }
        if (codirId && document.getElementById('adm_codirector_id')) {
            document.getElementById('adm_codirector_id').value = codirId;
        }

        abrirModal('modalAdminAsignar');
    }

    function prepararCancelacion(id, codigo) {
        document.getElementById('cancel_proy_id').value = id;
        document.getElementById('cancel_proy_cod').textContent = codigo;
        abrirModal('modalCancelarProy');
    }
</script>

</body>
</html>

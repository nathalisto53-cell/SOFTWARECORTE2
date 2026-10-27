<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardComite.jspf" %>

<%-- =========================================================================
     SIGRADO - Decisiones del Comité Curricular (Fases 1, 3, 5 y 6)
     - Acepta la propuesta en Fase 1 y asigna Docente Director y Docente Evaluador.
     - Genera listados dinámicos de docentes para selección de Directores y Evaluadores.
     - Permite examinar cualquier enlace de comprobante de pago o entregables.
     - Arquitectura: JSTL 1.2 puro (Cero Servlets, Cero Scriptlets, Cero DAOs).
     ========================================================================= --%>

<c:set var="mensajeRespuesta" value="" />
<c:set var="tipoAlerta" value="success" />

<%-- PROCESAMIENTO DE DECISIÓN DEL COMITÉ (POST) --%>
<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="faseActual" value="${param.fase}" />
    <c:set var="proyId" value="${param.proyecto_id}" />
    <c:set var="decision" value="${param.decision}" /> <%-- Aprobado, Correcciones, Rechazado --%>
    <c:set var="actaNum" value="${param.acta_numero}" />
    <c:set var="actaFec" value="${param.acta_fecha}" />
    <c:set var="comentario" value="${param.comentario}" />

    <c:choose>
        <%-- FASE 1: Idea y Pago -> Aprobación y Asignación de Director y Evaluador --%>
        <c:when test="${faseActual == '1'}">
            <c:choose>
                <c:when test="${decision == 'Aprobado'}">
                    <c:set var="directorId" value="${param.director_id}" />
                    <c:set var="evaluadorId" value="${param.evaluador_id}" />
                    <c:set var="codirectorId" value="${empty param.codirector_id ? null : param.codirector_id}" />
                    <c:set var="tipoNivel" value="${param.tipo_nivel}" />
                    <c:set var="prefijo" value="${tipoNivel == 'Tecnologico' ? '65' : '125'}" />
                    <c:set var="codModalidad" value="${prefijo}-2026-${proyId}" />

                    <c:catch var="f1Err">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos 
                            SET codigo_modalidad = ?,
                                director_id = ?,
                                evaluador_id = ?,
                                codirector_id = ?,
                                fase = 2,
                                responsable = 'estudiante'
                            WHERE id = ?;
                            <sql:param value="${codModalidad}" />
                            <sql:param value="${directorId}" />
                            <sql:param value="${evaluadorId}" />
                            <sql:param value="${codirectorId}" />
                            <sql:param value="${proyId}" />
                        </sql:update>
                    </c:catch>

                    <%-- Actualizar almacén demo en memoria --%>
                    <c:if test="${not empty applicationScope.demoProyectos}">
                        <%-- Buscar datos de Director y Evaluador en la lista de usuarios --%>
                        <c:set var="dirNom" value="" />
                        <c:set var="dirApe" value="" />
                        <c:set var="dirEmail" value="" />
                        <c:set var="evaNom" value="" />
                        <c:set var="evaApe" value="" />
                        <c:set var="evaEmail" value="" />
                        <c:set var="codirNom" value="" />

                        <c:forEach var="u" items="${applicationScope.demoListaUsuarios}">
                            <c:if test="${u.id == directorId or ('' + u.id) == ('' + directorId)}">
                                <c:set var="dirNom" value="${u.nombres}" />
                                <c:set var="dirApe" value="${u.apellidos}" />
                                <c:set var="dirEmail" value="${u.email}" />
                            </c:if>
                            <c:if test="${u.id == evaluadorId or ('' + u.id) == ('' + evaluadorId)}">
                                <c:set var="evaNom" value="${u.nombres}" />
                                <c:set var="evaApe" value="${u.apellidos}" />
                                <c:set var="evaEmail" value="${u.email}" />
                            </c:if>
                            <c:if test="${not empty codirectorId and (u.id == codirectorId or ('' + u.id) == ('' + codirectorId))}">
                                <c:set var="codirNom" value="${u.nombres} ${u.apellidos}" />
                            </c:if>
                        </c:forEach>

                        <c:forEach var="dp" items="${applicationScope.demoProyectos}">
                            <c:if test="${dp.id == proyId or ('' + dp.id) == ('' + proyId)}">
                                <c:set target="${dp}" property="fase" value="2" />
                                <c:set target="${dp}" property="responsable" value="estudiante" />
                                <c:set target="${dp}" property="codigo_modalidad" value="${codModalidad}" />
                                <c:set target="${dp}" property="director_id" value="${directorId}" />
                                <c:set target="${dp}" property="dir_nom" value="${dirNom}" />
                                <c:set target="${dp}" property="dir_ape" value="${dirApe}" />
                                <c:set target="${dp}" property="dir_email" value="${dirEmail}" />
                                <c:set target="${dp}" property="evaluador_id" value="${evaluadorId}" />
                                <c:set target="${dp}" property="eva_nom" value="${evaNom}" />
                                <c:set target="${dp}" property="eva_ape" value="${evaApe}" />
                                <c:set target="${dp}" property="eva_email" value="${evaEmail}" />
                                <c:set target="${dp}" property="codir_nom" value="${codirNom}" />
                            </c:if>
                        </c:forEach>
                    </c:if>

                    <c:set var="mensajeRespuesta" value="✅ Propuesta Aprobada en Fase 1. Se asignó código de modalidad ${codModalidad}, se designó Director y Evaluador, y el proyecto avanzó a la Fase 2 (Turno del Estudiante para radicar F-DC-124)." />
                </c:when>
                
                <c:when test="${decision == 'Correcciones'}">
                    <c:catch var="f1Err">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET responsable = 'estudiante' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                    </c:catch>
                    <c:forEach var="dp" items="${applicationScope.demoProyectos}">
                        <c:if test="${dp.id == proyId or ('' + dp.id) == ('' + proyId)}">
                            <c:set target="${dp}" property="responsable" value="estudiante" />
                        </c:if>
                    </c:forEach>
                    <c:set var="mensajeRespuesta" value="⚠️ Solicitud devuelta con correcciones al estudiante." />
                </c:when>

                <c:otherwise>
                    <c:catch var="f1Err">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET estado = 'Rechazado' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                    </c:catch>
                    <c:forEach var="dp" items="${applicationScope.demoProyectos}">
                        <c:if test="${dp.id == proyId or ('' + dp.id) == ('' + proyId)}">
                            <c:set target="${dp}" property="estado" value="Rechazado" />
                        </c:if>
                    </c:forEach>
                    <c:set var="mensajeRespuesta" value="❌ Propuesta rechazada por el Comité." />
                    <c:set var="tipoAlerta" value="danger" />
                </c:otherwise>
            </c:choose>
        </c:when>

        <%-- FASE 3: Propuesta II (Comité) -> Pasa a Fase 4 --%>
        <c:when test="${faseActual == '3'}">
            <c:choose>
                <c:when test="${decision == 'Aprobado'}">
                    <c:catch var="f3Err">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET fase = 4, responsable = 'estudiante' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                    </c:catch>
                    <c:forEach var="dp" items="${applicationScope.demoProyectos}">
                        <c:if test="${dp.id == proyId or ('' + dp.id) == ('' + proyId)}">
                            <c:set target="${dp}" property="fase" value="4" />
                            <c:set target="${dp}" property="responsable" value="estudiante" />
                        </c:if>
                    </c:forEach>
                    <c:set var="mensajeRespuesta" value="✅ Propuesta aprobada por Comité. Proyecto avanza a Fase 4 (Desarrollo del Proyecto e Informe Final)." />
                </c:when>
                <c:otherwise>
                    <c:catch var="f3Err">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET fase = 2, responsable = 'estudiante' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                    </c:catch>
                    <c:forEach var="dp" items="${applicationScope.demoProyectos}">
                        <c:if test="${dp.id == proyId or ('' + dp.id) == ('' + proyId)}">
                            <c:set target="${dp}" property="fase" value="2" />
                            <c:set target="${dp}" property="responsable" value="estudiante" />
                        </c:if>
                    </c:forEach>
                    <c:set var="mensajeRespuesta" value="⚠️ Propuesta devuelta para correcciones en Fase 2." />
                </c:otherwise>
            </c:choose>
        </c:when>

        <%-- FASE 5: Informe II (Comité) -> Pasa a Fase 6 --%>
        <c:when test="${faseActual == '5'}">
            <c:choose>
                <c:when test="${decision == 'Aprobado'}">
                    <c:catch var="f5Err">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET fase = 6, responsable = 'comite' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                    </c:catch>
                    <c:forEach var="dp" items="${applicationScope.demoProyectos}">
                        <c:if test="${dp.id == proyId or ('' + dp.id) == ('' + proyId)}">
                            <c:set target="${dp}" property="fase" value="6" />
                            <c:set target="${dp}" property="responsable" value="comite" />
                        </c:if>
                    </c:forEach>
                    <c:set var="mensajeRespuesta" value="✅ Aval de Sustentación emitido. Proyecto avanza a Fase 6 (Sustentación Pública y Grado)." />
                </c:when>
                <c:otherwise>
                    <c:catch var="f5Err">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE proyectos SET fase = 4, responsable = 'estudiante' WHERE id = ?;
                            <sql:param value="${proyId}" />
                        </sql:update>
                    </c:catch>
                    <c:forEach var="dp" items="${applicationScope.demoProyectos}">
                        <c:if test="${dp.id == proyId or ('' + dp.id) == ('' + proyId)}">
                            <c:set target="${dp}" property="fase" value="4" />
                            <c:set target="${dp}" property="responsable" value="estudiante" />
                        </c:if>
                    </c:forEach>
                    <c:set var="mensajeRespuesta" value="⚠️ Informe final devuelto para ajustes a la Fase 4." />
                </c:otherwise>
            </c:choose>
        </c:when>

        <%-- FASE 6: Cierre y Sustentación --%>
        <c:when test="${faseActual == '6'}">
            <c:set var="fecSust" value="${param.fecha_hora_sustentacion}" />
            <c:set var="lugarSust" value="${param.lugar_sustentacion}" />
            <c:catch var="f6Err">
                <sql:update dataSource="${sigradoDb}">
                    UPDATE proyectos SET estado = 'Finalizado', responsable = 'comite' WHERE id = ?;
                    <sql:param value="${proyId}" />
                </sql:update>
                <sql:update dataSource="${sigradoDb}">
                    INSERT INTO sustentaciones (proyecto_id, fecha_hora, lugar_enlace, resultado, acta_numero, registrado_por)
                    VALUES (?, ?::timestamp, ?, ?, ?, ?)
                    ON CONFLICT (proyecto_id) DO UPDATE
                    SET resultado = EXCLUDED.resultado, acta_numero = EXCLUDED.acta_numero;
                    <sql:param value="${proyId}" />
                    <sql:param value="${fecSust}" />
                    <sql:param value="${lugarSust}" />
                    <sql:param value="${decision}" />
                    <sql:param value="${actaNum}" />
                    <sql:param value="${sessionScope.usuario.id}" />
                </sql:update>
            </c:catch>
            <c:forEach var="dp" items="${applicationScope.demoProyectos}">
                <c:if test="${dp.id == proyId or ('' + dp.id) == ('' + proyId)}">
                    <c:set target="${dp}" property="estado" value="Finalizado" />
                    <c:set target="${dp}" property="responsable" value="comite" />
                </c:if>
            </c:forEach>
            <c:set var="mensajeRespuesta" value="🎓 Sustentación y Acta de Grado registradas. Proyecto culminado exitosamente." />
        </c:when>
    </c:choose>

    <%-- Guardar registro de respuesta e historial --%>
    <c:catch var="regErr">
        <sql:update dataSource="${sigradoDb}">
            INSERT INTO respuestas (proyecto_id, fase, ronda, usuario_id, rol, estado, acta_numero, acta_fecha, comentario)
            VALUES (?, ?, 1, ?, 'comite', ?::estado_respuesta_enum, ?, ?::date, ?);
            <sql:param value="${proyId}" />
            <sql:param value="${faseActual}" />
            <sql:param value="${sessionScope.usuario.id}" />
            <sql:param value="${decision}" />
            <sql:param value="${actaNum}" />
            <sql:param value="${actaFec}" />
            <sql:param value="${comentario}" />
        </sql:update>
    </c:catch>

    <c:if test="${not empty applicationScope.demoRespuestas}">
        <jsp:useBean id="nuevaRespCom" class="java.util.HashMap" scope="page" />
        <c:set target="${nuevaRespCom}" property="id" value="${proyId}0${faseActual}" />
        <c:set target="${nuevaRespCom}" property="proyecto_id" value="${proyId}" />
        <c:set target="${nuevaRespCom}" property="fase" value="${faseActual}" />
        <c:set target="${nuevaRespCom}" property="ronda" value="1" />
        <c:set target="${nuevaRespCom}" property="rol" value="comite" />
        <c:set target="${nuevaRespCom}" property="estado" value="${decision}" />
        <c:set target="${nuevaRespCom}" property="acta_numero" value="${actaNum}" />
        <c:set target="${nuevaRespCom}" property="comentario" value="${comentario}" />
        <c:set target="${nuevaRespCom}" property="fecha" value="${actaFec}" />
        <c:set var="dummyARC" value="${applicationScope.demoRespuestas.add(0, nuevaRespCom)}" />
    </c:if>
</c:if>

<%-- 1. LISTADO DE DOCENTES DISPONIBLES (DIRECTORES Y EVALUADORES) --%>
<c:set var="docentesDisponibles" value="${null}" />
<c:catch var="docSqlErr">
    <sql:query var="docentesListDb" dataSource="${sigradoDb}">
        SELECT u.id, u.nombres, u.apellidos, u.email, u.documento
        FROM usuarios u
        JOIN usuario_rol ur ON u.id = ur.usuario_id
        JOIN roles r ON ur.rol_id = r.id
        WHERE (r.nombre = 'docente' OR r.nombre = 'administrador') AND u.activo = 1
        ORDER BY u.apellidos ASC;
    </sql:query>
    <c:if test="${not empty docentesListDb.rows and docentesListDb.rowCount > 0}">
        <c:set var="docentesDisponibles" value="${docentesListDb.rows}" />
    </c:if>
</c:catch>

<c:if test="${empty docentesDisponibles and not empty applicationScope.demoListaUsuarios}">
    <jsp:useBean id="docentesFiltrados" class="java.util.ArrayList" scope="page" />
    <c:forEach var="u" items="${applicationScope.demoListaUsuarios}">
        <c:if test="${(empty u.eliminado or u.eliminado == false) and (u.activo == 1 or u.activo == '1')}">
            <c:if test="${fn:contains(u.roles_asignados, 'docente') or fn:contains(u.roles_asignados, 'administrador')}">
                <c:set var="dummyAddDoc" value="${docentesFiltrados.add(u)}" />
            </c:if>
        </c:if>
    </c:forEach>
    <c:set var="docentesDisponibles" value="${docentesFiltrados}" />
</c:if>

<%-- 2. LISTADO DE PROYECTOS --%>
<c:set var="proyectosComiteList" value="${null}" />
<c:catch var="comErr">
    <sql:query var="proyectosComiteDb" dataSource="${sigradoDb}">
        SELECT p.*, 
               (SELECT d.url FROM documentos d WHERE d.proyecto_id = p.id AND d.fase = p.fase ORDER BY d.id DESC LIMIT 1) as ultimo_doc_url,
               (SELECT d.tipo FROM documentos d WHERE d.proyecto_id = p.id AND d.fase = p.fase ORDER BY d.id DESC LIMIT 1) as ultimo_doc_tipo,
               d.nombres as dir_nom, d.apellidos as dir_ape,
               e.nombres as eva_nom, e.apellidos as eva_ape
        FROM proyectos p
        LEFT JOIN usuarios d ON p.director_id = d.id
        LEFT JOIN usuarios e ON p.evaluador_id = e.id
        ORDER BY p.id DESC;
    </sql:query>
    <c:if test="${not empty proyectosComiteDb.rows and proyectosComiteDb.rowCount > 0}">
        <c:set var="proyectosComiteList" value="${proyectosComiteDb.rows}" />
    </c:if>
</c:catch>

<c:if test="${empty proyectosComiteList}">
    <c:set var="proyectosComiteList" value="${applicationScope.demoProyectos}" />
</c:if>

<c:set var="pageTitle" value="Panel de Decisiones del Comité" />
<c:set var="param_active" value="proyectos" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <c:if test="${not empty mensajeRespuesta}">
            <div class="alert alert-${tipoAlerta}" style="display: flex; gap: 0.75rem; align-items: center; margin-bottom: 1.5rem; border-radius: var(--radius-md); padding: 1rem 1.25rem;">
                <span style="font-size: 1.25rem;">✓</span>
                <div>${mensajeRespuesta}</div>
            </div>
        </c:if>

        <div class="card">
            <div class="card-header" style="flex-wrap: wrap; gap: 1rem;">
                <div>
                    <h3 class="card-title">⚖️ Decisiones y Asignaciones del Comité Curricular</h3>
                    <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0.25rem 0 0;">
                        Fase 1: Validación de Idea y Pago, Aprobación y Asignación de Director y Evaluador &bull; Fases 3, 5 y 6.
                    </p>
                </div>
                <span class="badge badge-phase">Comité Curricular</span>
            </div>

            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Código</th>
                            <th>Título del Proyecto</th>
                            <th>Fase y Turno</th>
                            <th>Nivel / Modalidad</th>
                            <th>Documento / Comprobante</th>
                            <th>Director / Evaluador</th>
                            <th style="text-align: right;">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty proyectosComiteList}">
                                <c:forEach var="p" items="${proyectosComiteList}">
                                    <c:set var="docUrl" value="${not empty p.ultimo_doc_url ? p.ultimo_doc_url : p.soporte_pago_url}" />
                                    <tr>
                                        <td>
                                            <strong>${p.codigo}</strong><br>
                                            <small style="color:var(--text-muted);">${empty p.codigo_modalidad ? 'Sin modalidad' : p.codigo_modalidad}</small>
                                        </td>
                                        <td>
                                            <strong>${p.titulo}</strong>
                                            <c:if test="${not empty p.estudiante_nom}">
                                                <div style="font-size: 0.78rem; color: var(--text-muted); margin-top: 0.2rem;">
                                                    👤 Estudiante: ${p.estudiante_nom}
                                                </div>
                                            </c:if>
                                        </td>
                                        <td>
                                            <span class="badge badge-phase">Fase ${p.fase} de 6</span>
                                            <div style="margin-top: 0.25rem;">
                                                <c:choose>
                                                    <c:when test="${p.responsable == 'comite'}">
                                                        <span class="badge badge-approved">Turno: Comité</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="badge badge-responsible">Turno: ${p.responsable}</span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </div>
                                        </td>
                                        <td>
                                            ${p.tipo_nivel}<br>
                                            <small style="color:var(--text-muted);">${p.tipo_modalidad}</small>
                                        </td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${not empty docUrl}">
                                                    <a href="${fn:startsWith(docUrl, 'http') ? docUrl : ('https://' += docUrl)}" target="_blank" rel="noopener noreferrer" class="btn btn-outline btn-sm" title="Abrir enlace del documento o recibo">
                                                        👁️ Ver Enlace ↗
                                                    </a>
                                                    <div style="font-size: 0.7rem; color: var(--text-muted); margin-top: 0.2rem; word-break: break-all; max-width: 180px;">
                                                        ${p.fase == 1 ? 'Soporte Pago' : 'Entregable'}
                                                    </div>
                                                </c:when>
                                                <c:otherwise>
                                                    <span style="color: var(--text-muted); font-size: 0.8rem;">Sin entregas</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td>
                                            <div style="font-size: 0.8rem; line-height: 1.4;">
                                                <div><strong>Dir:</strong> ${empty p.dir_nom ? '<span style="color:#d97706;">Por asignar</span>' : (p.dir_nom += ' ' += p.dir_ape)}</div>
                                                <div><strong>Eva:</strong> ${empty p.eva_nom ? '<span style="color:#d97706;">Por asignar</span>' : (p.eva_nom += ' ' += p.eva_ape)}</div>
                                            </div>
                                        </td>
                                        <td style="text-align: right;">
                                            <c:if test="${p.estado == 'En curso'}">
                                                <button type="button" class="btn btn-primary btn-sm" onclick="responderComite('${p.id}', '${fn:escapeXml(p.codigo)}', ${p.fase}, '${p.tipo_nivel}', '${fn:escapeXml(docUrl)}', '${p.director_id}', '${p.evaluador_id}')">
                                                    ✍️ ${p.fase == 1 ? 'Aprobar y Asignar' : 'Responder'}
                                                </button>
                                            </c:if>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td colspan="7" style="text-align: center; color: var(--text-muted); padding: 2rem;">
                                        No hay proyectos registrados en este momento.
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
         MODAL DE RESPUESTA DEL COMITÉ (RF-COM-01, 02): APROBACIÓN Y ASIGNACIONES
         ========================================================================= --%>
    <div id="modalComite" class="modal-overlay" style="display: none;">
        <div class="modal-box" style="max-width: 650px; max-height: 90vh; overflow-y: auto;">
            <div class="modal-header" style="background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);">
                <div>
                    <h3 class="card-title" style="margin: 0; color: var(--primary-900);">
                        ✍️ Decisión del Comité &bull; Fase <span id="mFaseSpan">1</span>
                    </h3>
                    <small style="color: var(--primary-700); font-weight: 600;">Revisión institucional de requisitos y asignación de docentes</small>
                </div>
                <button type="button" class="modal-close-btn" onclick="cerrarModal('modalComite')">&times;</button>
            </div>

            <form action="proyectos.jsp" method="POST">
                <input type="hidden" id="mProyId" name="proyecto_id" value="">
                <input type="hidden" id="mFase" name="fase" value="">
                <input type="hidden" id="mNivel" name="tipo_nivel" value="">

                <div class="modal-body" style="padding: 1.5rem;">
                    
                    <%-- Info y Documento Radicado --%>
                    <div class="alert" style="background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af; font-size: 0.85rem; border-radius: var(--radius-sm); padding: 0.85rem 1rem; margin-bottom: 1.25rem;">
                        Proyecto: <strong id="mProyCod">...</strong> | Enlace radicado por el estudiante: 
                        <a id="mDocLink" href="#" target="_blank" rel="noopener noreferrer" style="font-weight: 700; text-decoration: underline; color: #1d4ed8;">
                            Abrir Enlace Recibido ↗
                        </a>
                    </div>

                    <div class="form-grid">
                        <div class="form-group">
                            <label for="mDecision">Decisión del Comité Curricular (*):</label>
                            <select id="mDecision" name="decision" class="form-control" onchange="toggleCamposFase1()" required>
                                <option value="Aprobado">✅ Aprobado (Avanzar a siguiente fase)</option>
                                <option value="Correcciones">⚠️ Correcciones (Devolver al estudiante)</option>
                                <option value="Rechazado">❌ Rechazado (Finalizar proyecto)</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label for="acta_numero">Número de Acta (*):</label>
                            <input type="text" id="acta_numero" name="acta_numero" class="form-control" placeholder="Ej: ACTA-COM-2026-10" required>
                        </div>
                    </div>

                    <div class="form-group">
                        <label for="acta_fecha">Fecha de Sesión / Acta (*):</label>
                        <input type="date" id="acta_fecha" name="acta_fecha" class="form-control" required>
                    </div>

                    <%-- SECCIÓN EXCLUSIVA FASE 1: LISTADOS DE DIRECTORES Y EVALUADORES PARA SELECCIONAR --%>
                    <div id="seccionFase1Asignaciones" style="background: var(--primary-50); padding: 1.25rem; border-radius: var(--radius-md); border: 1px solid var(--border-green); margin-bottom: 1.25rem;">
                        <div style="font-weight: 700; color: var(--primary-900); font-size: 0.92rem; margin-bottom: 0.75rem; display: flex; align-items: center; gap: 0.4rem;">
                            <span>👨‍🏫</span>
                            <span>Asignación de Docente Director y Docente Evaluador (Fase 1 Aprobada)</span>
                        </div>

                        <div class="form-group" style="margin-bottom: 1rem;">
                            <label style="font-size: 0.82rem; color: var(--text-muted);">Código de Modalidad Oficial Asignado:</label>
                            <input type="text" id="mCodigoModalidadAuto" class="form-control" readonly style="background: #ffffff; font-weight: 700; color: var(--primary-800);">
                        </div>

                        <div class="form-grid">
                            <%-- LISTADO 1: DOCENTE DIRECTOR --%>
                            <div class="form-group">
                                <label for="director_id" style="color: var(--primary-900); font-weight: 700;">
                                    🎯 Seleccionar Docente Director (*):
                                </label>
                                <select id="director_id" name="director_id" class="form-control" required>
                                    <option value="">-- Seleccionar Director --</option>
                                    <c:forEach var="doc" items="${docentesDisponibles}" varStatus="status">
                                        <option value="${doc.id}">
                                            ${doc.apellidos}, ${doc.nombres} (${doc.email})
                                        </option>
                                    </c:forEach>
                                </select>
                                <small style="color: var(--text-muted); font-size: 0.75rem;">Acompañará al estudiante en Fases 2 y 4.</small>
                            </div>

                            <%-- LISTADO 2: DOCENTE EVALUADOR --%>
                            <div class="form-group">
                                <label for="evaluador_id" style="color: var(--primary-900); font-weight: 700;">
                                    🔍 Seleccionar Docente Evaluador (*):
                                </label>
                                <select id="evaluador_id" name="evaluador_id" class="form-control" required>
                                    <option value="">-- Seleccionar Evaluador --</option>
                                    <c:forEach var="doc" items="${docentesDisponibles}">
                                        <option value="${doc.id}">
                                            ${doc.apellidos}, ${doc.nombres} (${doc.email})
                                        </option>
                                    </c:forEach>
                                </select>
                                <small style="color: var(--text-muted); font-size: 0.75rem;">Evaluará propuesta en F3 e informe en F5.</small>
                            </div>
                        </div>

                        <%-- Codirector Opcional --%>
                        <div class="form-group" style="margin-top: 0.5rem; margin-bottom: 0;">
                            <label for="codirector_id">Docente Codirector (Opcional):</label>
                            <select id="codirector_id" name="codirector_id" class="form-control">
                                <option value="">-- Sin codirector asignado --</option>
                                <c:forEach var="doc" items="${docentesDisponibles}">
                                    <option value="${doc.id}">
                                        ${doc.apellidos}, ${doc.nombres} (${doc.email})
                                    </option>
                                </c:forEach>
                            </select>
                        </div>
                    </div>

                    <%-- SECCIÓN FASE 6: SUSTENTACIÓN --%>
                    <div id="seccionFase6Sustentacion" style="display: none; background: var(--primary-50); padding: 1.25rem; border-radius: var(--radius-md); border: 1px solid var(--border-green); margin-bottom: 1.25rem;">
                        <div style="font-weight: 700; color: var(--primary-900); font-size: 0.9rem; margin-bottom: 0.5rem;">
                            🎓 Programación y Acta de Sustentación (Fase 6)
                        </div>
                        <div class="form-grid">
                            <div class="form-group">
                                <label for="fecha_hora_sustentacion">Fecha y Hora de Sustentación:</label>
                                <input type="datetime-local" id="fecha_hora_sustentacion" name="fecha_hora_sustentacion" class="form-control">
                            </div>
                            <div class="form-group">
                                <label for="lugar_sustentacion">Lugar / Enlace Virtual (Meet/Teams):</label>
                                <input type="text" id="lugar_sustentacion" name="lugar_sustentacion" class="form-control" placeholder="Ej: Auditorio Bloque 3 / meet.google.com/xxx">
                            </div>
                        </div>
                    </div>

                    <div class="form-group">
                        <label for="comentario">Observaciones y Concepto del Comité (*):</label>
                        <textarea id="comentario" name="comentario" class="form-control" rows="3" placeholder="Observaciones de la aprobación o motivos de la decisión institucional..." required></textarea>
                    </div>

                </div>

                <div class="modal-footer" style="padding: 1rem 1.5rem; background: var(--bg-light); border-top: 1px solid var(--border-light); display: flex; justify-content: flex-end; gap: 0.75rem;">
                    <button type="button" class="btn btn-outline" onclick="cerrarModal('modalComite')">Cancelar</button>
                    <button type="submit" class="btn btn-primary" style="padding: 0.65rem 1.5rem;">
                        Registrar Decisión y Asignaciones
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
    function responderComite(id, codigo, fase, nivel, docUrl, currentDirId, currentEvaId) {
        document.getElementById('mProyId').value = id;
        document.getElementById('mFase').value = fase;
        document.getElementById('mNivel').value = nivel;
        document.getElementById('mProyCod').innerText = codigo;
        document.getElementById('mFaseSpan').innerText = fase;
        
        const docLink = document.getElementById('mDocLink');
        if (docUrl && docUrl.length > 0) {
            let finalUrl = docUrl;
            if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
                finalUrl = 'https://' + finalUrl;
            }
            docLink.href = finalUrl;
            docLink.innerText = 'Abrir Documento / Recibo ↗';
            docLink.style.pointerEvents = 'auto';
        } else {
            docLink.innerText = 'No registra entrega aún';
            docLink.removeAttribute('href');
        }

        const prefijo = (nivel === 'Tecnologico') ? '65' : '125';
        document.getElementById('mCodigoModalidadAuto').value = prefijo + '-2026-' + id;

        // Establecer fecha actual por defecto
        const hoy = new Date().toISOString().split('T')[0];
        document.getElementById('acta_fecha').value = hoy;
        document.getElementById('acta_numero').value = 'ACTA-COM-2026-' + (id < 10 ? '0' + id : id);

        // Si ya tiene director o evaluador asignado, precargarlo
        if (currentDirId && document.getElementById('director_id')) {
            document.getElementById('director_id').value = currentDirId;
        }
        if (currentEvaId && document.getElementById('evaluador_id')) {
            document.getElementById('evaluador_id').value = currentEvaId;
        }

        toggleCamposFase1();
        abrirModal('modalComite');
    }

    function toggleCamposFase1() {
        const fase = parseInt(document.getElementById('mFase').value, 10);
        const decision = document.getElementById('mDecision').value;
        const seccionF1 = document.getElementById('seccionFase1Asignaciones');
        const seccionF6 = document.getElementById('seccionFase6Sustentacion');

        if (fase === 1 && decision === 'Aprobado') {
            seccionF1.style.display = 'block';
            document.getElementById('director_id').required = true;
            document.getElementById('evaluador_id').required = true;
        } else {
            seccionF1.style.display = 'none';
            document.getElementById('director_id').required = false;
            document.getElementById('evaluador_id').required = false;
        }

        if (fase === 6) {
            seccionF6.style.display = 'block';
        } else {
            seccionF6.style.display = 'none';
        }
    }
</script>

</body>
</html>

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardEstudiante.jspf" %>

<%-- =========================================================================
     SIGRADO - Centro de Seguimiento Integral de las 6 Fases del Proyecto
     Visualización detallada del avance del estudiante por las 6 fases oficiales,
     turno actual, entregables requeridos, enlaces radicados y actas institucionales.
     Arquitectura: JSTL 1.2 puro (Cero Servlets, Cero Scriptlets, Cero DAOs).
     ========================================================================= --%>

<%-- Procesamiento de Subida de Entregas con Cualquier Enlace desde Seguimiento --%>
<c:set var="mensajeSeguimiento" value="" />
<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="accionSeg" value="${param.accion}" />
    
    <c:if test="${accionSeg == 'entregar_documento'}">
        <c:set var="pIdEnt" value="${param.proyecto_id}" />
        <c:set var="faseEnt" value="${param.fase}" />
        <c:set var="tipoDoc" value="${param.tipo_documento}" />
        <c:set var="urlDoc" value="${param.documento_url}" />
        <c:set var="obsDoc" value="${param.observaciones}" />

        <c:catch var="subDocErr">
            <sql:query var="vQ" dataSource="${sigradoDb}">
                SELECT COALESCE(MAX(version), 0) + 1 as prox_version 
                FROM documentos 
                WHERE proyecto_id = ? AND tipo = ?::tipo_documento_enum;
                <sql:param value="${pIdEnt}" />
                <sql:param value="${tipoDoc}" />
            </sql:query>
            <c:set var="proxVer" value="${not empty vQ.rows ? vQ.rows[0].prox_version : 1}" />

            <sql:update dataSource="${sigradoDb}">
                INSERT INTO documentos (proyecto_id, fase, tipo, version, url, observaciones, subido_por)
                VALUES (?, ?, ?::tipo_documento_enum, ?, ?, ?, ?);
                <sql:param value="${pIdEnt}" />
                <sql:param value="${faseEnt}" />
                <sql:param value="${tipoDoc}" />
                <sql:param value="${proxVer}" />
                <sql:param value="${urlDoc}" />
                <sql:param value="${obsDoc}" />
                <sql:param value="${sessionScope.usuario.id}" />
            </sql:update>

            <%-- Actualizar turno al Director si es entrega de estudiante --%>
            <sql:update dataSource="${sigradoDb}">
                UPDATE proyectos SET responsable = 'director' WHERE id = ?;
                <sql:param value="${pIdEnt}" />
            </sql:update>
        </c:catch>

        <%-- Fallback Almacén Demo --%>
        <c:if test="${not empty subDocErr and not empty applicationScope.demoDocumentos}">
            <jsp:useBean id="segDocDemo" class="java.util.HashMap" scope="page" />
            <c:set target="${segDocDemo}" property="id" value="${pIdEnt}0${faseEnt}" />
            <c:set target="${segDocDemo}" property="proyecto_id" value="${pIdEnt}" />
            <c:set target="${segDocDemo}" property="fase" value="${faseEnt}" />
            <c:set target="${segDocDemo}" property="tipo" value="${tipoDoc}" />
            <c:set target="${segDocDemo}" property="version" value="2" />
            <c:set target="${segDocDemo}" property="url" value="${urlDoc}" />
            <c:set target="${segDocDemo}" property="titulo" value="Entrega Fase ${faseEnt} (${tipoDoc})" />
            <c:set target="${segDocDemo}" property="observaciones" value="${obsDoc}" />
            <c:set target="${segDocDemo}" property="subido_por" value="${sessionScope.usuario.id}" />
            <c:set target="${segDocDemo}" property="subido_por_nombre" value="${sessionScope.usuario.nombres} ${sessionScope.usuario.apellidos}" />
            <c:set target="${segDocDemo}" property="fecha_subida" value="Hoy" />
            <c:set var="dummyAddSegDoc" value="${applicationScope.demoDocumentos.add(0, segDocDemo)}" />

            <c:forEach var="dp" items="${applicationScope.demoProyectos}">
                <c:if test="${dp.id == pIdEnt or ('' + dp.id) == ('' + pIdEnt)}">
                    <c:set target="${dp}" property="responsable" value="director" />
                </c:if>
            </c:forEach>
        </c:if>

        <c:set var="mensajeSeguimiento" value="✅ Documento radicado exitosamente con tu enlace. El turno ha pasado a tu Director de Proyecto." />
    </c:if>
</c:if>

<%-- 1. Consultar Proyecto del Estudiante --%>
<c:set var="proy" value="${null}" />

<c:catch var="proyErr">
    <sql:query var="proyQuery" dataSource="${sigradoDb}">
        SELECT p.id, p.codigo, p.titulo, p.objetivo_general, p.descripcion, p.tipo_idea,
               p.tipo_modalidad, p.tipo_nivel, p.linea_investigacion, p.codigo_modalidad,
               p.fase, p.responsable, p.estado,
               d.nombres as dir_nom, d.apellidos as dir_ape, d.email as dir_email,
               cd.nombres as codir_nom, cd.apellidos as codir_ape, cd.email as codir_email
        FROM proyectos p
        JOIN proyecto_integrantes pi ON p.id = pi.proyecto_id
        LEFT JOIN usuarios d ON p.director_id = d.id
        LEFT JOIN usuarios cd ON p.codirector_id = cd.id
        WHERE pi.usuario_id = ? AND p.estado = 'En curso'
        LIMIT 1;
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
    <c:if test="${not empty proyQuery.rows and proyQuery.rowCount > 0}">
        <c:set var="proy" value="${proyQuery.rows[0]}" />
    </c:if>
</c:catch>

<c:if test="${empty proy and not empty applicationScope.demoProyectos}">
    <c:forEach var="dp" items="${applicationScope.demoProyectos}">
        <c:if test="${empty proy and dp.estado == 'En curso'}">
            <c:if test="${dp.estudiante_id == sessionScope.usuario.id or dp.estudiante_doc == sessionScope.usuario.documento or fn:toLowerCase(fn:trim(dp.estudiante_email)) == fn:toLowerCase(fn:trim(sessionScope.usuario.email))}">
                <c:set var="proy" value="${dp}" />
            </c:if>
        </c:if>
    </c:forEach>
</c:if>

<%-- 2. Consultar Historial de Documentos y Enlaces del Proyecto --%>
<c:set var="misDocumentos" value="${null}" />
<c:if test="${not empty proy}">
    <c:catch var="docErr">
        <sql:query var="docsQ" dataSource="${sigradoDb}">
            SELECT d.*, u.nombres as sub_nom, u.apellidos as sub_ape 
            FROM documentos d
            JOIN usuarios u ON d.subido_por = u.id
            WHERE d.proyecto_id = ?
            ORDER BY d.id DESC;
            <sql:param value="${proy.id}" />
        </sql:query>
        <c:if test="${not empty docsQ.rows and docsQ.rowCount > 0}">
            <c:set var="misDocumentos" value="${docsQ.rows}" />
        </c:if>
    </c:catch>

    <c:if test="${empty misDocumentos and not empty applicationScope.demoDocumentos}">
        <jsp:useBean id="docsFiltrados" class="java.util.ArrayList" scope="page" />
        <c:forEach var="dd" items="${applicationScope.demoDocumentos}">
            <c:if test="${dd.proyecto_id == proy.id or ('' + dd.proyecto_id) == ('' + proy.id)}">
                <c:set var="dummyDF" value="${docsFiltrados.add(dd)}" />
            </c:if>
        </c:forEach>
        <c:set var="misDocumentos" value="${docsFiltrados}" />
    </c:if>
</c:if>

<%-- 3. Consultar Actas y Decisiones del Comité / Evaluadores --%>
<c:set var="misRespuestas" value="${null}" />
<c:if test="${not empty proy}">
    <c:catch var="respErr">
        <sql:query var="respQ" dataSource="${sigradoDb}">
            SELECT r.* FROM respuestas r WHERE r.proyecto_id = ? ORDER BY r.id DESC;
            <sql:param value="${proy.id}" />
        </sql:query>
        <c:if test="${not empty respQ.rows and respQ.rowCount > 0}">
            <c:set var="misRespuestas" value="${respQ.rows}" />
        </c:if>
    </c:catch>

    <c:if test="${empty misRespuestas and not empty applicationScope.demoRespuestas}">
        <jsp:useBean id="respFiltradas" class="java.util.ArrayList" scope="page" />
        <c:forEach var="dr" items="${applicationScope.demoRespuestas}">
            <c:if test="${dr.proyecto_id == proy.id or ('' + dr.proyecto_id) == ('' + proy.id)}">
                <c:set var="dummyRF" value="${respFiltradas.add(dr)}" />
            </c:if>
        </c:forEach>
        <c:set var="misRespuestas" value="${respFiltradas}" />
    </c:if>
</c:if>

<c:set var="pageTitle" value="Seguimiento de las 6 Fases" />
<c:set var="param_active" value="seguimiento" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">

        <c:if test="${not empty mensajeSeguimiento}">
            <div class="alert alert-success" style="display: flex; gap: 0.75rem; align-items: center; margin-bottom: 1.5rem; border-radius: var(--radius-md); padding: 1rem 1.25rem;">
                <span style="font-size: 1.25rem;">✓</span>
                <div>${mensajeSeguimiento}</div>
            </div>
        </c:if>

        <c:choose>
            <%-- SI EL ESTUDIANTE TIENE PROYECTO: MOSTRAR EL TABLERO COMPLETO DE LAS 6 FASES --%>
            <c:when test="${not empty proy}">
                
                <%-- Banner Principal de Estado y Fase Actual --%>
                <div class="card" style="background: linear-gradient(135deg, #ffffff 0%, #f0fdf4 100%); border-color: var(--border-green); margin-bottom: 1.5rem; padding: 1.75rem;">
                    <div style="display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 1rem;">
                        <div>
                            <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.35rem;">
                                <span class="badge badge-phase" style="font-size: 0.85rem; padding: 0.35rem 0.75rem;">
                                    Fase ${proy.fase} de 6
                                </span>
                                <span style="font-family: monospace; font-size: 0.82rem; font-weight: 700; background: var(--primary-100); color: var(--primary-800); padding: 0.25rem 0.6rem; border-radius: var(--radius-sm);">
                                    ${proy.codigo}
                                </span>
                                <c:if test="${not empty proy.codigo_modalidad}">
                                    <span style="font-family: monospace; font-size: 0.82rem; color: #475569; background: #e2e8f0; padding: 0.25rem 0.6rem; border-radius: var(--radius-sm);">
                                        Modalidad: ${proy.codigo_modalidad}
                                    </span>
                                </c:if>
                            </div>

                            <h2 style="font-size: 1.45rem; color: var(--primary-dark); margin: 0 0 0.5rem; line-height: 1.35;">
                                ${proy.titulo}
                            </h2>

                            <div style="font-size: 0.86rem; color: var(--text-muted); display: flex; gap: 1.25rem; flex-wrap: wrap;">
                                <span>🎯 Director: <strong style="color: var(--text-main);">${empty proy.dir_nom ? 'Pendiente en Fase 1' : (proy.dir_nom += ' ' += proy.dir_ape)}</strong></span>
                                <span>Modalidad: <strong style="color: var(--text-main);">${proy.tipo_modalidad}</strong></span>
                                <span>Nivel: <strong style="color: var(--text-main);">${proy.tipo_nivel}</strong></span>
                            </div>
                        </div>

                        <%-- Semáforo de Turno --%>
                        <div style="text-align: right;">
                            <span style="font-size: 0.75rem; text-transform: uppercase; font-weight: 700; color: var(--text-muted); display: block; margin-bottom: 0.35rem;">
                                Estado del Turno Académico
                            </span>
                            <c:choose>
                                <c:when test="${proy.responsable == 'estudiante'}">
                                    <span class="badge badge-approved" style="font-size: 0.92rem; padding: 0.5rem 1rem; box-shadow: 0 2px 10px rgba(34, 197, 94, 0.3);">
                                        ⚡ ¡Tu Turno! Acción Requerida
                                    </span>
                                </c:when>
                                <c:when test="${proy.responsable == 'director'}">
                                    <span class="badge badge-responsible" style="font-size: 0.92rem; padding: 0.5rem 1rem;">
                                        ⏳ En Revisión por tu Director
                                    </span>
                                </c:when>
                                <c:when test="${proy.responsable == 'evaluador'}">
                                    <span class="badge" style="background: #fef3c7; color: #92400e; border: 1px solid #fde68a; font-size: 0.92rem; padding: 0.5rem 1rem;">
                                        🔍 En Revisión por el Jurado Evaluador
                                    </span>
                                </c:when>
                                <c:otherwise>
                                    <span class="badge" style="background: #ede9fe; color: #5b21b6; border: 1px solid #ddd6fe; font-size: 0.92rem; padding: 0.5rem 1rem;">
                                        ⚖️ En Revisión por el Comité Curricular
                                    </span>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>

                    <%-- Barra de Avance Global (6 Fases) --%>
                    <div style="margin-top: 1.5rem;">
                        <div style="display: flex; justify-content: space-between; font-size: 0.8rem; font-weight: 600; color: var(--text-muted); margin-bottom: 0.4rem;">
                            <span>Progreso General en las 6 Fases</span>
                            <span>
                                <c:choose>
                                    <c:when test="${proy.fase == 1}">16% (Fase 1 de 6)</c:when>
                                    <c:when test="${proy.fase == 2}">33% (Fase 2 de 6)</c:when>
                                    <c:when test="${proy.fase == 3}">50% (Fase 3 de 6)</c:when>
                                    <c:when test="${proy.fase == 4}">66% (Fase 4 de 6)</c:when>
                                    <c:when test="${proy.fase == 5}">83% (Fase 5 de 6)</c:when>
                                    <c:otherwise>100% (Fase 6: Sustentación)</c:otherwise>
                                </c:choose>
                            </span>
                        </div>
                        <div style="width: 100%; height: 10px; background: #e2e8f0; border-radius: 999px; overflow: hidden;">
                            <div style="height: 100%; background: linear-gradient(90deg, #22c55e, #15803d); width: ${proy.fase == 1 ? '16%' : (proy.fase == 2 ? '33%' : (proy.fase == 3 ? '50%' : (proy.fase == 4 ? '66%' : (proy.fase == 5 ? '83%' : '100%'))))}; transition: width 0.5s ease;"></div>
                        </div>
                    </div>
                </div>

                <%-- DETALLE DE LAS 6 FASES INSTITUCIONALES EN COLUMNAS / TARJETAS --%>
                <h3 style="font-size: 1.2rem; color: var(--primary-dark); margin: 0 0 1rem; display: flex; align-items: center; gap: 0.5rem;">
                    <span>🗺️</span>
                    <span>Mapa Detallado de las 6 Fases del Trabajo de Grado</span>
                </h3>

                <div style="display: grid; grid-template-columns: 1fr; gap: 1.25rem; margin-bottom: 2rem;">
                    
                    <%-- FASE 1 --%>
                    <div class="card" style="border-left: 5px solid ${proy.fase > 1 ? '#22c55e' : (proy.fase == 1 ? '#f59e0b' : '#cbd5e1')}; padding: 1.25rem;">
                        <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 1rem; flex-wrap: wrap;">
                            <div>
                                <div style="display: flex; align-items: center; gap: 0.5rem;">
                                    <span style="width: 28px; height: 28px; border-radius: 50%; background: ${proy.fase > 1 ? '#22c55e' : (proy.fase == 1 ? '#f59e0b' : '#94a3b8')}; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.85rem;">
                                        ${proy.fase > 1 ? '✓' : '1'}
                                    </span>
                                    <h4 style="margin: 0; font-size: 1.05rem; color: var(--primary-dark);">
                                        Fase 1: Postulación de la Idea y Comprobante de Pago
                                    </h4>
                                    <span class="badge ${proy.fase > 1 ? 'badge-approved' : (proy.fase == 1 ? 'badge-phase' : '')}" style="font-size: 0.75rem;">
                                        ${proy.fase > 1 ? 'Completada' : (proy.fase == 1 ? 'En Curso' : 'Pendiente')}
                                    </span>
                                </div>
                                <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0.5rem 0 0.25rem; line-height: 1.45;">
                                    <strong>Objetivo:</strong> Radicación de la idea (propia o seleccionada del Banco) y verificación del soporte de pago de derechos de grado. El Comité valida los requisitos, asigna el código oficial de modalidad (125-XXX / 65-XXX) y designa al Docente Director.
                                </p>
                                <div style="font-size: 0.8rem; color: var(--text-main); margin-top: 0.4rem;">
                                    📁 <strong>Entregable requerido:</strong> Enlace al Comprobante de Pago (recibe cualquier enlace: Drive, OneDrive, etc.).
                                </div>
                            </div>
                            <div style="text-align: right; font-size: 0.8rem;">
                                <span style="color: var(--text-muted);">Responsable:</span><br>
                                <strong>Comité Curricular</strong>
                            </div>
                        </div>
                    </div>

                    <%-- FASE 2 --%>
                    <div class="card" style="border-left: 5px solid ${proy.fase > 2 ? '#22c55e' : (proy.fase == 2 ? '#f59e0b' : '#cbd5e1')}; padding: 1.25rem;">
                        <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 1rem; flex-wrap: wrap;">
                            <div>
                                <div style="display: flex; align-items: center; gap: 0.5rem;">
                                    <span style="width: 28px; height: 28px; border-radius: 50%; background: ${proy.fase > 2 ? '#22c55e' : (proy.fase == 2 ? '#f59e0b' : '#94a3b8')}; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.85rem;">
                                        ${proy.fase > 2 ? '✓' : '2'}
                                    </span>
                                    <h4 style="margin: 0; font-size: 1.05rem; color: var(--primary-dark);">
                                        Fase 2: Elaboración y Radicación de la Propuesta (F-DC-124)
                                    </h4>
                                    <span class="badge ${proy.fase > 2 ? 'badge-approved' : (proy.fase == 2 ? 'badge-phase' : '')}" style="font-size: 0.75rem;">
                                        ${proy.fase > 2 ? 'Completada' : (proy.fase == 2 ? 'En Curso' : 'Pendiente')}
                                    </span>
                                </div>
                                <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0.5rem 0 0.25rem; line-height: 1.45;">
                                    <strong>Objetivo:</strong> Redacción del documento formal de propuesta (Formato F-DC-124) con el acompañamiento del Director y reporte de porcentaje Turnitin. El Director revisa, aprueba y firma para radicar ante el Comité.
                                </p>
                                <div style="font-size: 0.8rem; color: var(--text-main); margin-top: 0.4rem;">
                                    📁 <strong>Entregable requerido:</strong> Enlace al Anteproyecto F-DC-124 y Reporte Turnitin (recibe cualquier enlace).
                                </div>
                            </div>
                            <div style="text-align: right; font-size: 0.8rem;">
                                <span style="color: var(--text-muted);">Responsables:</span><br>
                                <strong>Estudiante & Director</strong>
                            </div>
                        </div>

                        <%-- Formulario de entrega si es turno en Fase 2 --%>
                        <c:if test="${proy.fase == 2 and proy.responsable == 'estudiante'}">
                            <div style="margin-top: 1rem; padding-top: 1rem; border-top: 1px dashed var(--border-green); background: #f0fdf4; padding: 1rem; border-radius: var(--radius-sm);">
                                <strong style="font-size: 0.85rem; color: var(--primary-900); display: block; margin-bottom: 0.5rem;">
                                    📤 Entrega de Anteproyecto (F-DC-124) - Fase 2:
                                </strong>
                                <form action="seguimiento.jsp" method="POST" style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
                                    <input type="hidden" name="accion" value="entregar_documento">
                                    <input type="hidden" name="proyecto_id" value="${proy.id}">
                                    <input type="hidden" name="fase" value="2">
                                    <input type="hidden" name="tipo_documento" value="Propuesta_FDC124">
                                    <div style="flex: 2; min-width: 250px;">
                                        <input type="text" name="documento_url" class="form-control" placeholder="Pega aquí cualquier enlace de tu documento (Google Drive, OneDrive, web...)" required>
                                    </div>
                                    <div style="flex: 1; min-width: 180px;">
                                        <input type="text" name="observaciones" class="form-control" placeholder="Notas de entrega...">
                                    </div>
                                    <button type="submit" class="btn btn-primary btn-sm">Enviar al Director</button>
                                </form>
                            </div>
                        </c:if>
                    </div>

                    <%-- FASE 3 --%>
                    <div class="card" style="border-left: 5px solid ${proy.fase > 3 ? '#22c55e' : (proy.fase == 3 ? '#f59e0b' : '#cbd5e1')}; padding: 1.25rem;">
                        <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 1rem; flex-wrap: wrap;">
                            <div>
                                <div style="display: flex; align-items: center; gap: 0.5rem;">
                                    <span style="width: 28px; height: 28px; border-radius: 50%; background: ${proy.fase > 3 ? '#22c55e' : (proy.fase == 3 ? '#f59e0b' : '#94a3b8')}; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.85rem;">
                                        ${proy.fase > 3 ? '✓' : '3'}
                                    </span>
                                    <h4 style="margin: 0; font-size: 1.05rem; color: var(--primary-dark);">
                                        Fase 3: Evaluación de la Propuesta por Jurado Evaluador y Comité
                                    </h4>
                                    <span class="badge ${proy.fase > 3 ? 'badge-approved' : (proy.fase == 3 ? 'badge-phase' : '')}" style="font-size: 0.75rem;">
                                        ${proy.fase > 3 ? 'Completada' : (proy.fase == 3 ? 'En Curso' : 'Pendiente')}
                                    </span>
                                </div>
                                <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0.5rem 0 0.25rem; line-height: 1.45;">
                                    <strong>Objetivo:</strong> El Comité designa a un Docente Evaluador bajo confidencialidad (doble ciego). El Evaluador califica la propuesta (Aprobada, Con Correcciones o Rechazada). Si es aprobada, el Comité expide el <strong>Acta de Aprobación de la Propuesta</strong>.
                                </p>
                                <div style="font-size: 0.8rem; color: var(--text-main); margin-top: 0.4rem;">
                                    📁 <strong>Documento emitido:</strong> Concepto de Evaluación y Acta Oficial de Aprobación de Propuesta.
                                </div>
                            </div>
                            <div style="text-align: right; font-size: 0.8rem;">
                                <span style="color: var(--text-muted);">Responsables:</span><br>
                                <strong>Comité & Evaluador</strong>
                            </div>
                        </div>
                    </div>

                    <%-- FASE 4 --%>
                    <div class="card" style="border-left: 5px solid ${proy.fase > 4 ? '#22c55e' : (proy.fase == 4 ? '#f59e0b' : '#cbd5e1')}; padding: 1.25rem;">
                        <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 1rem; flex-wrap: wrap;">
                            <div>
                                <div style="display: flex; align-items: center; gap: 0.5rem;">
                                    <span style="width: 28px; height: 28px; border-radius: 50%; background: ${proy.fase > 4 ? '#22c55e' : (proy.fase == 4 ? '#f59e0b' : '#94a3b8')}; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.85rem;">
                                        ${proy.fase > 4 ? '✓' : '4'}
                                    </span>
                                    <h4 style="margin: 0; font-size: 1.05rem; color: var(--primary-dark);">
                                        Fase 4: Desarrollo del Proyecto e Informe Final (F-DC-125)
                                    </h4>
                                    <span class="badge ${proy.fase > 4 ? 'badge-approved' : (proy.fase == 4 ? 'badge-phase' : '')}" style="font-size: 0.75rem;">
                                        ${proy.fase > 4 ? 'Completada' : (proy.fase == 4 ? 'En Curso' : 'Pendiente')}
                                    </span>
                                </div>
                                <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0.5rem 0 0.25rem; line-height: 1.45;">
                                    <strong>Objetivo:</strong> Ejecución del desarrollo tecnológico o investigación, redacción del documento final consolidado (Formato F-DC-125) y verificación de Turnitin. El Director revisa el prototipo/software y emite el Visto Bueno firmado.
                                </p>
                                <div style="font-size: 0.8rem; color: var(--text-main); margin-top: 0.4rem;">
                                    📁 <strong>Entregable requerido:</strong> Enlace al Informe Final F-DC-125 y Reporte Turnitin (recibe cualquier enlace).
                                </div>
                            </div>
                            <div style="text-align: right; font-size: 0.8rem;">
                                <span style="color: var(--text-muted);">Responsables:</span><br>
                                <strong>Estudiante & Director</strong>
                            </div>
                        </div>

                        <%-- Formulario de entrega si es turno en Fase 4 --%>
                        <c:if test="${proy.fase == 4 and proy.responsable == 'estudiante'}">
                            <div style="margin-top: 1rem; padding-top: 1rem; border-top: 1px dashed var(--border-green); background: #f0fdf4; padding: 1rem; border-radius: var(--radius-sm);">
                                <strong style="font-size: 0.85rem; color: var(--primary-900); display: block; margin-bottom: 0.5rem;">
                                    📤 Entrega de Informe Final (F-DC-125) - Fase 4:
                                </strong>
                                <form action="seguimiento.jsp" method="POST" style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
                                    <input type="hidden" name="accion" value="entregar_documento">
                                    <input type="hidden" name="proyecto_id" value="${proy.id}">
                                    <input type="hidden" name="fase" value="4">
                                    <input type="hidden" name="tipo_documento" value="Informe_FDC125">
                                    <div style="flex: 2; min-width: 250px;">
                                        <input type="text" name="documento_url" class="form-control" placeholder="Pega aquí cualquier enlace del Informe Final (Google Drive, OneDrive, web...)" required>
                                    </div>
                                    <div style="flex: 1; min-width: 180px;">
                                        <input type="text" name="observaciones" class="form-control" placeholder="Notas de entrega...">
                                    </div>
                                    <button type="submit" class="btn btn-primary btn-sm">Enviar al Director</button>
                                </form>
                            </div>
                        </c:if>
                    </div>

                    <%-- FASE 5 --%>
                    <div class="card" style="border-left: 5px solid ${proy.fase > 5 ? '#22c55e' : (proy.fase == 5 ? '#f59e0b' : '#cbd5e1')}; padding: 1.25rem;">
                        <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 1rem; flex-wrap: wrap;">
                            <div>
                                <div style="display: flex; align-items: center; gap: 0.5rem;">
                                    <span style="width: 28px; height: 28px; border-radius: 50%; background: ${proy.fase > 5 ? '#22c55e' : (proy.fase == 5 ? '#f59e0b' : '#94a3b8')}; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.85rem;">
                                        ${proy.fase > 5 ? '✓' : '5'}
                                    </span>
                                    <h4 style="margin: 0; font-size: 1.05rem; color: var(--primary-dark);">
                                        Fase 5: Calificación de Jurado Evaluador con Rejilla (F-DC-129)
                                    </h4>
                                    <span class="badge ${proy.fase > 5 ? 'badge-approved' : (proy.fase == 5 ? 'badge-phase' : '')}" style="font-size: 0.75rem;">
                                        ${proy.fase > 5 ? 'Completada' : (proy.fase == 5 ? 'En Curso' : 'Pendiente')}
                                    </span>
                                </div>
                                <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0.5rem 0 0.25rem; line-height: 1.45;">
                                    <strong>Objetivo:</strong> El Jurado Evaluador califica en detalle el informe final diligenciando la <strong>Rejilla de Calificación F-DC-129</strong>. Si el concepto es aprobatorio, el Comité emite el <strong>Aval de Sustentación</strong>.
                                </p>
                                <div style="font-size: 0.8rem; color: var(--text-main); margin-top: 0.4rem;">
                                    📁 <strong>Documento emitido:</strong> Rejilla F-DC-129 diligenciada y Aval del Comité para programación de fecha.
                                </div>
                            </div>
                            <div style="text-align: right; font-size: 0.8rem;">
                                <span style="color: var(--text-muted);">Responsables:</span><br>
                                <strong>Jurado Evaluador & Comité</strong>
                            </div>
                        </div>
                    </div>

                    <%-- FASE 6 --%>
                    <div class="card" style="border-left: 5px solid ${proy.fase == 6 ? '#f59e0b' : (proy.estado == 'Finalizado' ? '#22c55e' : '#cbd5e1')}; padding: 1.25rem;">
                        <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 1rem; flex-wrap: wrap;">
                            <div>
                                <div style="display: flex; align-items: center; gap: 0.5rem;">
                                    <span style="width: 28px; height: 28px; border-radius: 50%; background: ${proy.estado == 'Finalizado' ? '#22c55e' : (proy.fase == 6 ? '#f59e0b' : '#94a3b8')}; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.85rem;">
                                        ${proy.estado == 'Finalizado' ? '✓' : '6'}
                                    </span>
                                    <h4 style="margin: 0; font-size: 1.05rem; color: var(--primary-dark);">
                                        Fase 6: Sustentación Pública, Acta Definitiva y Grado
                                    </h4>
                                    <span class="badge ${proy.estado == 'Finalizado' ? 'badge-approved' : (proy.fase == 6 ? 'badge-phase' : '')}" style="font-size: 0.75rem;">
                                        ${proy.estado == 'Finalizado' ? 'Grado Culminado' : (proy.fase == 6 ? 'En Curso' : 'Pendiente')}
                                    </span>
                                </div>
                                <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0.5rem 0 0.25rem; line-height: 1.45;">
                                    <strong>Objetivo:</strong> Defensa oral y pública del proyecto ante el jurado calificador. Firma del <strong>Acta de Sustentación</strong> con la calificación numérica final y expedición de requisitos de titulación.
                                </p>
                                <div style="font-size: 0.8rem; color: var(--text-main); margin-top: 0.4rem;">
                                    📁 <strong>Documento emitido:</strong> Acta de Sustentación oficial y Certificado de Aprobación de Grado.
                                </div>
                            </div>
                            <div style="text-align: right; font-size: 0.8rem;">
                                <span style="color: var(--text-muted);">Responsables:</span><br>
                                <strong>Jurados & Comité</strong>
                            </div>
                        </div>
                    </div>

                </div>

                <%-- HISTORIAL DE DOCUMENTOS Y ENLACES ENTREGADOS --%>
                <div class="card" style="margin-bottom: 1.5rem;">
                    <div class="card-header">
                        <h3 class="card-title">📑 Documentos y Enlaces Entregados en el Proyecto</h3>
                        <span class="badge badge-phase">${not empty misDocumentos ? misDocumentos.size() : 0} Enlaces</span>
                    </div>

                    <div class="table-responsive">
                        <table class="sigrado-table">
                            <thead>
                                <tr>
                                    <th>Fase</th>
                                    <th>Tipo de Documento</th>
                                    <th>Versión</th>
                                    <th>Enlace Radicado (Cualquier URL)</th>
                                    <th>Observaciones</th>
                                    <th>Fecha</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:choose>
                                    <c:when test="${not empty misDocumentos}">
                                        <c:forEach var="doc" items="${misDocumentos}">
                                            <tr>
                                                <td><span class="badge badge-phase">Fase ${doc.fase}</span></td>
                                                <td><strong>${doc.tipo}</strong></td>
                                                <td><span class="badge badge-responsible">v${doc.version}</span></td>
                                                <td>
                                                    <a href="${fn:startsWith(doc.url, 'http') ? doc.url : ('https://' += doc.url)}" target="_blank" rel="noopener noreferrer" class="btn btn-outline btn-sm" style="font-size: 0.78rem; text-decoration: none;">
                                                        Abrir Enlace ↗
                                                    </a>
                                                    <div style="font-size: 0.72rem; color: var(--text-muted); margin-top: 0.2rem; word-break: break-all; max-width: 280px;">
                                                        ${doc.url}
                                                    </div>
                                                </td>
                                                <td style="font-size: 0.82rem; color: var(--text-muted);">
                                                    ${empty doc.observaciones ? 'Sin observaciones registradas' : doc.observaciones}
                                                </td>
                                                <td style="font-size: 0.8rem;">${doc.fecha_subida}</td>
                                            </tr>
                                        </c:forEach>
                                    </c:when>
                                    <c:otherwise>
                                        <tr>
                                            <td colspan="6" style="text-align: center; color: var(--text-muted); padding: 1.5rem;">
                                                No se han registrado entregas adicionales de documentos aún.
                                            </td>
                                        </tr>
                                    </c:otherwise>
                                </c:choose>
                            </tbody>
                        </table>
                    </div>
                </div>

                <%-- HISTORIAL DE CONCEPTOS Y ACTAS EMITIDAS --%>
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">💬 Conceptos, Evaluaciones y Actas del Comité</h3>
                    </div>
                    <div class="table-responsive">
                        <table class="sigrado-table">
                            <thead>
                                <tr>
                                    <th>Fase</th>
                                    <th>Actor</th>
                                    <th>Decisión</th>
                                    <th>Acta Oficial</th>
                                    <th>Comentarios Institucionales</th>
                                    <th>Fecha</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:choose>
                                    <c:when test="${not empty misRespuestas}">
                                        <c:forEach var="resp" items="${misRespuestas}">
                                            <tr>
                                                <td><span class="badge badge-phase">Fase ${resp.fase}</span></td>
                                                <td><strong>${resp.rol}</strong></td>
                                                <td>
                                                    <span class="badge ${resp.estado == 'Aprobado' ? 'badge-approved' : (resp.estado == 'Correcciones' ? 'badge-corrections' : 'badge-rejected')}">
                                                        ${resp.estado}
                                                    </span>
                                                </td>
                                                <td><strong>${empty resp.acta_numero ? '-' : resp.acta_numero}</strong></td>
                                                <td style="font-size: 0.84rem; color: var(--text-main);">${resp.comentario}</td>
                                                <td style="font-size: 0.8rem;">${resp.fecha}</td>
                                            </tr>
                                        </c:forEach>
                                    </c:when>
                                    <c:otherwise>
                                        <tr>
                                            <td colspan="6" style="text-align: center; color: var(--text-muted); padding: 1.5rem;">
                                                Aún no se registran conceptos emitidos para este proyecto.
                                            </td>
                                        </tr>
                                    </c:otherwise>
                                </c:choose>
                            </tbody>
                        </table>
                    </div>
                </div>

            </c:when>

            <%-- CASO EN QUE EL ESTUDIANTE NO TIENE PROYECTO INSCRITO AÚN --%>
            <c:otherwise>
                <div class="card" style="text-align: center; padding: 3rem 1.5rem;">
                    <div style="font-size: 3rem; margin-bottom: 0.75rem;">🗺️</div>
                    <h3 style="font-size: 1.4rem; color: var(--primary-dark); margin: 0 0 0.5rem;">
                        Aún no tienes un Proyecto de Grado Activo
                    </h3>
                    <p style="font-size: 0.92rem; color: var(--text-muted); max-width: 600px; margin: 0 auto 1.75rem; line-height: 1.5;">
                        Para visualizar el seguimiento de las <strong>6 Fases Oficiales</strong> de SIGRADO y ver el avance de tu trabajo de grado, debes postular una idea (propia o del banco) y registrar tu comprobante de pago.
                    </p>
                    <div style="display: flex; justify-content: center; gap: 1rem; flex-wrap: wrap;">
                        <a href="banco.jsp" class="btn btn-primary" style="padding: 0.75rem 1.5rem;">
                            💡 Explorar y Seleccionar Idea del Banco
                        </a>
                        <a href="proyecto.jsp" class="btn btn-outline" style="padding: 0.75rem 1.5rem;">
                            📝 Postular Idea Propia en Fase 1
                        </a>
                    </div>
                </div>
            </c:otherwise>
        </c:choose>

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

</body>
</html>

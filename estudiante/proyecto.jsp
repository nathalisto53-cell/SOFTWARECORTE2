<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardEstudiante.jspf" %>

<%-- =========================================================================
     SIGRADO - Mi Proyecto de Grado (Estudiante)
     - Inscripción de proyecto con Idea Propia o seleccionada del Banco de Ideas.
     - Acepta CUALQUIER enlace en el comprobante de pago o al entregar documentos.
     - Seguimiento integral del flujo institucional a través de las 6 fases.
     - Arquitectura: JSTL 1.2 puro (Cero Servlets, Cero Scriptlets, Cero DAOs).
     ========================================================================= --%>

<c:set var="mensajeInscripcion" value="" />
<c:set var="tipoAlerta" value="success" />

<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="accion" value="${param.accion}" />

    <%-- 1. INSCRIPCIÓN DE PROYECTO (IDEA PROPIA O DEL BANCO) --%>
    <c:if test="${accion == 'inscribir'}">
        <c:set var="tipoIdea" value="${param.tipo_idea}" />
        <c:set var="bancoId" value="${empty param.banco_id ? null : param.banco_id}" />
        <c:set var="titulo" value="${param.titulo}" />
        <c:set var="objetivo" value="${param.objetivo_general}" />
        <c:set var="descripcion" value="${param.descripcion}" />
        <c:set var="tipoNivel" value="${param.tipo_nivel}" />
        <c:set var="tipoModalidad" value="${param.tipo_modalidad}" />
        <c:set var="linea" value="${param.linea_investigacion}" />
        <c:set var="soportePagoUrl" value="${param.soporte_pago_url}" />
        <c:set var="esPareja" value="${param.es_pareja}" />
        <c:set var="docSegundo" value="${param.segundo_integrante_doc}" />

        <c:choose>
            <%-- CASO 1: IDEA PROPIA -> QUEDA PENDIENTE DE APROBACIÓN POR EL COMITÉ / ADMINISTRADOR --%>
            <c:when test="${tipoIdea == 'Propia'}">
                <c:catch var="insPropErr">
                    <sql:update dataSource="${sigradoDb}">
                        INSERT INTO propuestas_banco (codigo, proponente_id, origen, titulo, tipo_modalidad, tipo_nivel, linea_investigacion, periodo_id, objetivo_general, descripcion, estado, disponible)
                        VALUES (CONCAT('BAN-', TO_CHAR(CURRENT_TIMESTAMP, 'MMSS')), ?, 'Estudiante', ?, ?::tipo_modalidad_enum, ?::tipo_nivel_enum, ?, 1, ?, ?, 'Pendiente', 0);
                        <sql:param value="${sessionScope.usuario.id}" />
                        <sql:param value="${titulo}" />
                        <sql:param value="${tipoModalidad}" />
                        <sql:param value="${tipoNivel}" />
                        <sql:param value="${linea}" />
                        <sql:param value="${objetivo}" />
                        <sql:param value="${descripcion}" />
                    </sql:update>
                </c:catch>

                <c:if test="${not empty applicationScope.demoIdeasBanco}">
                    <jsp:useBean id="nuevaIdeaPropiaEst" class="java.util.HashMap" scope="page" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="id" value="${fn:length(applicationScope.demoIdeasBanco) + 10}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="codigo" value="BAN-${fn:length(applicationScope.demoIdeasBanco) + 100}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="titulo" value="${titulo}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="descripcion" value="${descripcion}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="objetivo_general" value="${objetivo}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="tipo_nivel" value="${tipoNivel}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="tipo_modalidad" value="${tipoModalidad}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="linea_investigacion" value="${linea}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="proponente" value="${sessionScope.usuario.nombres} ${sessionScope.usuario.apellidos}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="proponente_id" value="${sessionScope.usuario.id}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="origen" value="Estudiante" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="estado" value="Pendiente" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="disponible" value="0" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="soporte_pago_url" value="${soportePagoUrl}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="es_pareja" value="${esPareja}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="segundo_integrante_doc" value="${docSegundo}" />
                    <c:set target="${nuevaIdeaPropiaEst}" property="fecha_fmt" value="Hoy" />
                    <c:set var="dummyAddEst" value="${applicationScope.demoIdeasBanco.add(0, nuevaIdeaPropiaEst)}" />
                </c:if>

                <c:set var="mensajeInscripcion" value="🎉 ¡Propuesta de idea propia radicada con éxito con tu comprobante de pago! Ha quedado en estado 'Pendiente de Aprobación'. Debes esperar a que el Comité Curricular o el Administrador la revise y apruebe (RF-ADM-09)." />
                <c:set var="tipoAlerta" value="success" />
            </c:when>

            <%-- CASO 2: IDEA DEL BANCO (YA APROBADA) -> ENTRA DIRECTAMENTE A FASE 1 --%>
            <c:otherwise>
                <c:catch var="insProyErr">
                    <%-- Crear Proyecto en PostgreSQL Supabase --%>
                    <sql:update dataSource="${sigradoDb}">
                        INSERT INTO proyectos (codigo, banco_id, titulo, objetivo_general, descripcion, tipo_idea, tipo_modalidad, tipo_nivel, linea_investigacion, periodo_id, fase, responsable, estado)
                        VALUES (CONCAT('GRA-', TO_CHAR(CURRENT_TIMESTAMP, 'MMSS')), ?, ?, ?, ?, ?::tipo_idea_enum, ?::tipo_modalidad_enum, ?::tipo_nivel_enum, ?, 1, 1, 'comite', 'En curso');
                        <sql:param value="${bancoId}" />
                        <sql:param value="${titulo}" />
                        <sql:param value="${objetivo}" />
                        <sql:param value="${descripcion}" />
                        <sql:param value="${tipoIdea}" />
                        <sql:param value="${tipoModalidad}" />
                        <sql:param value="${tipoNivel}" />
                        <sql:param value="${linea}" />
                    </sql:update>

                    <%-- Obtener ID del proyecto recién creado --%>
                    <sql:query var="lastIdQ" dataSource="${sigradoDb}">
                        SELECT id FROM proyectos ORDER BY id DESC LIMIT 1;
                    </sql:query>
                    <c:set var="nuevoProyId" value="${lastIdQ.rows[0].id}" />

                    <%-- Integrante 1 (Responsable) --%>
                    <sql:update dataSource="${sigradoDb}">
                        INSERT INTO proyecto_integrantes (proyecto_id, usuario_id, es_responsable)
                        VALUES (?, ?, 1);
                        <sql:param value="${nuevoProyId}" />
                        <sql:param value="${sessionScope.usuario.id}" />
                    </sql:update>

                    <%-- Integrante 2 (si aplica) --%>
                    <c:if test="${esPareja == '1' and not empty docSegundo}">
                        <sql:query var="segundoUserQ" dataSource="${sigradoDb}">
                            SELECT id FROM usuarios WHERE documento = ? LIMIT 1;
                            <sql:param value="${docSegundo}" />
                        </sql:query>
                        <c:if test="${not empty segundoUserQ.rows}">
                            <sql:update dataSource="${sigradoDb}">
                                INSERT INTO proyecto_integrantes (proyecto_id, usuario_id, es_responsable)
                                VALUES (?, ?, 0);
                                <sql:param value="${nuevoProyId}" />
                                <sql:param value="${segundoUserQ.rows[0].id}" />
                            </sql:update>
                        </c:if>
                    </c:if>

                    <%-- Guardar Soporte de Pago en documentos (RF-EST-04 - Recibe cualquier enlace) --%>
                    <sql:update dataSource="${sigradoDb}">
                        INSERT INTO documentos (proyecto_id, fase, tipo, version, url, titulo, subido_por)
                        VALUES (?, 1, 'SoportePago', 1, ?, 'Soporte Comprobante de Pago', ?);
                        <sql:param value="${nuevoProyId}" />
                        <sql:param value="${soportePagoUrl}" />
                        <sql:param value="${sessionScope.usuario.id}" />
                    </sql:update>

                    <%-- Marcar idea del banco como no disponible si vino del banco --%>
                    <c:if test="${not empty bancoId}">
                        <sql:update dataSource="${sigradoDb}">
                            UPDATE propuestas_banco SET disponible = 0 WHERE id = ?;
                            <sql:param value="${bancoId}" />
                        </sql:update>
                    </c:if>
                </c:catch>

                <%-- Fallback Almacén Demo Compartido --%>
                <c:if test="${not empty insProyErr}">
                    <jsp:useBean id="nuevoDemoProy" class="java.util.HashMap" scope="page" />
                    <c:set target="${nuevoDemoProy}" property="id" value="${sessionScope.usuario.id}" />
                    <c:set target="${nuevoDemoProy}" property="codigo" value="GRA-2026-${sessionScope.usuario.id}" />
                    <c:set target="${nuevoDemoProy}" property="codigo_modalidad" value="${tipoNivel == 'Profesional' ? '125-2026-N' : '65-2026-N'} (Por validar en Fase 1)" />
                    <c:set target="${nuevoDemoProy}" property="titulo" value="${titulo}" />
                    <c:set target="${nuevoDemoProy}" property="objetivo_general" value="${objetivo}" />
                    <c:set target="${nuevoDemoProy}" property="descripcion" value="${descripcion}" />
                    <c:set target="${nuevoDemoProy}" property="tipo_idea" value="${tipoIdea}" />
                    <c:set target="${nuevoDemoProy}" property="tipo_modalidad" value="${tipoModalidad}" />
                    <c:set target="${nuevoDemoProy}" property="tipo_nivel" value="${tipoNivel}" />
                    <c:set target="${nuevoDemoProy}" property="linea_investigacion" value="${linea}" />
                    <c:set target="${nuevoDemoProy}" property="fase" value="1" />
                    <c:set target="${nuevoDemoProy}" property="responsable" value="comite" />
                    <c:set target="${nuevoDemoProy}" property="estado" value="En curso" />
                    <c:set target="${nuevoDemoProy}" property="director_id" value="${null}" />
                    <c:set target="${nuevoDemoProy}" property="dir_nom" value="" />
                    <c:set target="${nuevoDemoProy}" property="dir_ape" value="" />
                    <c:set target="${nuevoDemoProy}" property="dir_email" value="" />
                    <c:set target="${nuevoDemoProy}" property="estudiante_id" value="${sessionScope.usuario.id}" />
                    <c:set target="${nuevoDemoProy}" property="estudiante_doc" value="${sessionScope.usuario.documento}" />
                    <c:set target="${nuevoDemoProy}" property="estudiante_nom" value="${sessionScope.usuario.nombres} ${sessionScope.usuario.apellidos}" />
                    <c:set target="${nuevoDemoProy}" property="estudiante_email" value="${sessionScope.usuario.email}" />
                    <c:set target="${nuevoDemoProy}" property="soporte_pago_url" value="${soportePagoUrl}" />
                    <c:set target="${nuevoDemoProy}" property="fecha_creacion" value="Hoy" />

                    <%-- Marcar idea como asignada si vino del banco --%>
                    <c:if test="${not empty bancoId and not empty applicationScope.demoIdeasBanco}">
                        <c:forEach var="di" items="${applicationScope.demoIdeasBanco}">
                            <c:if test="${di.id == bancoId or ('' + di.id) == ('' + bancoId)}">
                                <c:set target="${di}" property="disponible" value="0" />
                            </c:if>
                        </c:forEach>
                    </c:if>

                    <%-- Guardar comprobante de pago en documentos demo --%>
                    <jsp:useBean id="nuevoDemoPagoDoc" class="java.util.HashMap" scope="page" />
                    <c:set target="${nuevoDemoPagoDoc}" property="id" value="${sessionScope.usuario.id}01" />
                    <c:set target="${nuevoDemoPagoDoc}" property="proyecto_id" value="${sessionScope.usuario.id}" />
                    <c:set target="${nuevoDemoPagoDoc}" property="fase" value="1" />
                    <c:set target="${nuevoDemoPagoDoc}" property="tipo" value="SoportePago" />
                    <c:set target="${nuevoDemoPagoDoc}" property="version" value="1" />
                    <c:set target="${nuevoDemoPagoDoc}" property="url" value="${soportePagoUrl}" />
                    <c:set target="${nuevoDemoPagoDoc}" property="titulo" value="Comprobante de Pago Derechos de Grado" />
                    <c:set target="${nuevoDemoPagoDoc}" property="observaciones" value="Enlace de comprobante radicado por el estudiante en la inscripción." />
                    <c:set target="${nuevoDemoPagoDoc}" property="subido_por" value="${sessionScope.usuario.id}" />
                    <c:set target="${nuevoDemoPagoDoc}" property="subido_por_nombre" value="${sessionScope.usuario.nombres} ${sessionScope.usuario.apellidos}" />
                    <c:set target="${nuevoDemoPagoDoc}" property="fecha_subida" value="Hoy" />

                    <c:if test="${not empty applicationScope.demoDocumentos}">
                        <c:set var="dummyAddDoc" value="${applicationScope.demoDocumentos.add(0, nuevoDemoPagoDoc)}" />
                    </c:if>

                    <c:if test="${not empty applicationScope.demoProyectos}">
                        <c:set var="dummyAddProy" value="${applicationScope.demoProyectos.add(0, nuevoDemoProy)}" />
                    </c:if>
                </c:if>

                <c:set var="mensajeInscripcion" value="🎉 ¡Proyecto inscrito exitosamente! Tu postulación ha iniciado en la Fase 1 (Turno del Comité Curricular) para validación de requisitos y asignación de Director." />
                <c:set var="tipoAlerta" value="success" />
            </c:otherwise>
        </c:choose>
    </c:if>

    <%-- 2. ENTREGA DE ANTEPROYECTO O INFORME FINAL (FASE 2 O FASE 4) --%>
    <c:if test="${accion == 'entregar'}">
        <c:set var="pIdEnt" value="${param.proyecto_id}" />
        <c:set var="faseEnt" value="${param.fase}" />
        <c:set var="tipoDoc" value="${faseEnt == '2' ? 'Propuesta_FDC124' : 'Informe_FDC125'}" />
        <c:set var="urlEnt" value="${param.documento_url}" />
        <c:set var="obsEnt" value="${param.observaciones}" />

        <c:catch var="entErr">
            <sql:query var="versionQ" dataSource="${sigradoDb}">
                SELECT COALESCE(MAX(version), 0) + 1 as prox_version 
                FROM documentos 
                WHERE proyecto_id = ? AND tipo = ?::tipo_documento_enum;
                <sql:param value="${pIdEnt}" />
                <sql:param value="${tipoDoc}" />
            </sql:query>
            <c:set var="proxVer" value="${not empty versionQ.rows ? versionQ.rows[0].prox_version : 1}" />

            <sql:update dataSource="${sigradoDb}">
                INSERT INTO documentos (proyecto_id, fase, tipo, version, url, observaciones, subido_por)
                VALUES (?, ?, ?::tipo_documento_enum, ?, ?, ?, ?);
                <sql:param value="${pIdEnt}" />
                <sql:param value="${faseEnt}" />
                <sql:param value="${tipoDoc}" />
                <sql:param value="${proxVer}" />
                <sql:param value="${urlEnt}" />
                <sql:param value="${obsEnt}" />
                <sql:param value="${sessionScope.usuario.id}" />
            </sql:update>

            <%-- Pasar turno al Director --%>
            <sql:update dataSource="${sigradoDb}">
                UPDATE proyectos SET responsable = 'director' WHERE id = ?;
                <sql:param value="${pIdEnt}" />
            </sql:update>
        </c:catch>

        <%-- Fallback demo --%>
        <c:if test="${not empty entErr and not empty applicationScope.demoDocumentos}">
            <jsp:useBean id="entregaDemoDoc" class="java.util.HashMap" scope="page" />
            <c:set target="${entregaDemoDoc}" property="id" value="${pIdEnt}02" />
            <c:set target="${entregaDemoDoc}" property="proyecto_id" value="${pIdEnt}" />
            <c:set target="${entregaDemoDoc}" property="fase" value="${faseEnt}" />
            <c:set target="${entregaDemoDoc}" property="tipo" value="${tipoDoc}" />
            <c:set target="${entregaDemoDoc}" property="version" value="2" />
            <c:set target="${entregaDemoDoc}" property="url" value="${urlEnt}" />
            <c:set target="${entregaDemoDoc}" property="titulo" value="${faseEnt == '2' ? 'Anteproyecto F-DC-124' : 'Informe Final F-DC-125'}" />
            <c:set target="${entregaDemoDoc}" property="observaciones" value="${obsEnt}" />
            <c:set target="${entregaDemoDoc}" property="subido_por" value="${sessionScope.usuario.id}" />
            <c:set target="${entregaDemoDoc}" property="subido_por_nombre" value="${sessionScope.usuario.nombres} ${sessionScope.usuario.apellidos}" />
            <c:set target="${entregaDemoDoc}" property="fecha_subida" value="Hoy" />
            <c:set var="dummyAddEnt" value="${applicationScope.demoDocumentos.add(0, entregaDemoDoc)}" />

            <c:forEach var="dp" items="${applicationScope.demoProyectos}">
                <c:if test="${dp.id == pIdEnt or ('' + dp.id) == ('' + pIdEnt)}">
                    <c:set target="${dp}" property="responsable" value="director" />
                </c:if>
            </c:forEach>
        </c:if>

        <c:set var="mensajeInscripcion" value="📤 Entrega de versión registrada correctamente con tu enlace. El turno ha sido enviado a tu Docente Director para su revisión." />
        <c:set var="tipoAlerta" value="success" />
    </c:if>

    <%-- 3. ACTUALIZAR ENLACE DE COMPROBANTE DE PAGO EN FASE 1 --%>
    <c:if test="${accion == 'actualizar_pago'}">
        <c:set var="pIdPago" value="${param.proyecto_id}" />
        <c:set var="nuevoEnlacePago" value="${param.nuevo_soporte_pago_url}" />

        <c:catch var="actPagoErr">
            <sql:update dataSource="${sigradoDb}">
                INSERT INTO documentos (proyecto_id, fase, tipo, version, url, titulo, subido_por)
                VALUES (?, 1, 'SoportePago', 2, ?, 'Actualización de Soporte de Pago', ?);
                <sql:param value="${pIdPago}" />
                <sql:param value="${nuevoEnlacePago}" />
                <sql:param value="${sessionScope.usuario.id}" />
            </sql:update>
        </c:catch>

        <c:forEach var="dp" items="${applicationScope.demoProyectos}">
            <c:if test="${dp.id == pIdPago or ('' + dp.id) == ('' + pIdPago)}">
                <c:set target="${dp}" property="soporte_pago_url" value="${nuevoEnlacePago}" />
            </c:if>
        </c:forEach>

        <c:set var="mensajeInscripcion" value="✅ Enlace de comprobante de pago actualizado exitosamente." />
        <c:set var="tipoAlerta" value="success" />
    </c:if>
</c:if>

<%-- CONSULTAR PROYECTO DEL ESTUDIANTE --%>
<c:set var="proyActual" value="${null}" />

<c:catch var="myProyErr">
    <sql:query var="miProyectoQ" dataSource="${sigradoDb}">
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
    <c:if test="${not empty miProyectoQ.rows and miProyectoQ.rowCount > 0}">
        <c:set var="proyActual" value="${miProyectoQ.rows[0]}" />
    </c:if>
</c:catch>

<%-- Fallback demo proyectos --%>
<c:if test="${empty proyActual and not empty applicationScope.demoProyectos}">
    <c:forEach var="dp" items="${applicationScope.demoProyectos}">
        <c:if test="${empty proyActual and dp.estado == 'En curso'}">
            <c:if test="${dp.estudiante_id == sessionScope.usuario.id or dp.estudiante_doc == sessionScope.usuario.documento or fn:toLowerCase(fn:trim(dp.estudiante_email)) == fn:toLowerCase(fn:trim(sessionScope.usuario.email))}">
                <c:set var="proyActual" value="${dp}" />
            </c:if>
        </c:if>
    </c:forEach>
</c:if>

<%-- Consultar ideas del banco disponibles --%>
<c:set var="ideasDisponiblesList" value="${null}" />
<c:catch var="bancoDispErr">
    <sql:query var="ideasDisponiblesDb" dataSource="${sigradoDb}">
        SELECT * FROM propuestas_banco WHERE estado = 'Aprobada' AND disponible = 1 ORDER BY id DESC;
    </sql:query>
    <c:if test="${not empty ideasDisponiblesDb.rows}">
        <c:set var="ideasDisponiblesList" value="${ideasDisponiblesDb.rows}" />
    </c:if>
</c:catch>

<c:if test="${empty ideasDisponiblesList}">
    <c:set var="ideasDisponiblesList" value="${applicationScope.demoIdeasBanco}" />
</c:if>

<%-- Consultar si el estudiante tiene una propuesta de idea en proceso de revisión --%>
<c:set var="miPropuestaPendiente" value="${null}" />
<c:if test="${empty proyActual}">
    <c:catch var="propPendErr">
        <sql:query var="propPendDb" dataSource="${sigradoDb}">
            SELECT * FROM propuestas_banco WHERE proponente_id = ? ORDER BY id DESC LIMIT 1;
            <sql:param value="${sessionScope.usuario.id}" />
        </sql:query>
        <c:if test="${not empty propPendDb.rows and propPendDb.rowCount > 0}">
            <c:set var="miPropuestaPendiente" value="${propPendDb.rows[0]}" />
        </c:if>
    </c:catch>

    <c:if test="${empty miPropuestaPendiente and not empty applicationScope.demoIdeasBanco}">
        <c:forEach var="di" items="${applicationScope.demoIdeasBanco}">
            <c:if test="${empty miPropuestaPendiente and di.origen == 'Estudiante'}">
                <c:if test="${di.proponente_id == sessionScope.usuario.id or fn:contains(di.proponente, sessionScope.usuario.nombres) or fn:contains(di.proponente, sessionScope.usuario.apellidos)}">
                    <c:set var="miPropuestaPendiente" value="${di}" />
                </c:if>
            </c:if>
        </c:forEach>
    </c:if>
</c:if>

<%-- Si llega con parámetro banco_id desde banco.jsp --%>
<c:set var="preIdeaBanco" value="${null}" />
<c:if test="${not empty param.banco_id}">
    <c:forEach var="ib" items="${ideasDisponiblesList}">
        <c:if test="${ib.id == param.banco_id or ('' + ib.id) == ('' + param.banco_id)}">
            <c:set var="preIdeaBanco" value="${ib}" />
        </c:if>
    </c:forEach>
</c:if>

<c:set var="pageTitle" value="Mi Proyecto de Grado" />
<c:set var="param_active" value="proyecto" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">
        
        <c:if test="${not empty mensajeInscripcion}">
            <div class="alert alert-${tipoAlerta}" style="display: flex; gap: 0.75rem; align-items: center; margin-bottom: 1.5rem; border-radius: var(--radius-md); padding: 1rem 1.25rem;">
                <span style="font-size: 1.25rem;">✓</span>
                <div>${mensajeInscripcion}</div>
            </div>
        </c:if>

        <c:choose>
            <%-- CASO A: EL ESTUDIANTE YA TIENE UN PROYECTO ACTIVO --%>
            <c:when test="${not empty proyActual}">
                <c:set var="p" value="${proyActual}" />
                
                <div class="card" style="margin-bottom: 1.5rem;">
                    <div class="card-header" style="flex-wrap: wrap; gap: 1rem;">
                        <div>
                            <span style="font-size: 0.8rem; font-weight: 700; color: var(--primary-700); text-transform: uppercase; letter-spacing: 0.5px;">
                                Proyecto de Grado en Curso
                            </span>
                            <h3 class="card-title" style="margin-top: 0.25rem; font-size: 1.35rem;">🎓 ${p.titulo}</h3>
                            <div style="font-size: 0.85rem; color: var(--text-muted); margin-top: 0.35rem; display: flex; gap: 1rem; flex-wrap: wrap;">
                                <span>Radicado: <strong style="color: var(--text-main);">${p.codigo}</strong></span>
                                <span>Código Modalidad: <strong style="color: var(--text-main);">${empty p.codigo_modalidad ? 'Por asignar en Fase 1' : p.codigo_modalidad}</strong></span>
                                <span>Origen Idea: <strong style="color: var(--text-main);">${p.tipo_idea}</strong></span>
                            </div>
                        </div>
                        <div style="display: flex; gap: 0.5rem; align-items: center; flex-wrap: wrap;">
                            <span class="badge badge-phase" style="font-size: 0.9rem; padding: 0.45rem 0.85rem;">
                                Fase ${p.fase} de 6
                            </span>
                            <c:choose>
                                <c:when test="${p.responsable == 'estudiante'}">
                                    <span class="badge badge-approved" style="font-size: 0.85rem; padding: 0.45rem 0.85rem; animation: pulse 2s infinite;">
                                        ⚡ Tu Turno (Acción Requerida)
                                    </span>
                                </c:when>
                                <c:when test="${p.responsable == 'director'}">
                                    <span class="badge badge-responsible" style="font-size: 0.85rem; padding: 0.45rem 0.85rem;">
                                        ⏳ Turno: Docente Director
                                    </span>
                                </c:when>
                                <c:when test="${p.responsable == 'evaluador'}">
                                    <span class="badge" style="background: #fef3c7; color: #92400e; border: 1px solid #fde68a; font-size: 0.85rem; padding: 0.45rem 0.85rem;">
                                        🔍 Turno: Jurado Evaluador
                                    </span>
                                </c:when>
                                <c:otherwise>
                                    <span class="badge" style="background: #ede9fe; color: #5b21b6; border: 1px solid #ddd6fe; font-size: 0.85rem; padding: 0.45rem 0.85rem;">
                                        ⚖️ Turno: Comité Curricular
                                    </span>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>

                    <%-- MAPA VISUAL INTEGRAL DE LAS 6 FASES INSTITUCIONALES (RF-GEN-10) --%>
                    <div style="padding: 1.5rem; background: var(--bg-light); border-bottom: 1px solid var(--border-light);">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                            <strong style="font-size: 0.88rem; color: var(--primary-900);">
                                📍 Progreso Institucional del Proyecto (6 Fases Oficiales SIGRADO):
                            </strong>
                            <a href="seguimiento.jsp" class="btn btn-outline btn-sm" style="background: #ffffff; font-size: 0.78rem;">
                                Ver Centro de Seguimiento Detallado &rarr;
                            </a>
                        </div>

                        <div class="phase-map-container" style="margin-bottom: 0;">
                            <div class="phase-step ${p.fase >= 1 ? (p.fase == 1 ? 'active' : 'completed') : ''}">
                                <div class="phase-circle">${p.fase > 1 ? '✓' : '1'}</div>
                                <span class="phase-title">Fase 1: Idea y Pago</span>
                            </div>
                            <div class="phase-step ${p.fase >= 2 ? (p.fase == 2 ? 'active' : 'completed') : ''}">
                                <div class="phase-circle">${p.fase > 2 ? '✓' : '2'}</div>
                                <span class="phase-title">Fase 2: Propuesta (Director)</span>
                            </div>
                            <div class="phase-step ${p.fase >= 3 ? (p.fase == 3 ? 'active' : 'completed') : ''}">
                                <div class="phase-circle">${p.fase > 3 ? '✓' : '3'}</div>
                                <span class="phase-title">Fase 3: Eval. Propuesta</span>
                            </div>
                            <div class="phase-step ${p.fase >= 4 ? (p.fase == 4 ? 'active' : 'completed') : ''}">
                                <div class="phase-circle">${p.fase > 4 ? '✓' : '4'}</div>
                                <span class="phase-title">Fase 4: Informe Final</span>
                            </div>
                            <div class="phase-step ${p.fase >= 5 ? (p.fase == 5 ? 'active' : 'completed') : ''}">
                                <div class="phase-circle">${p.fase > 5 ? '✓' : '5'}</div>
                                <span class="phase-title">Fase 5: Eval. Informe</span>
                            </div>
                            <div class="phase-step ${p.fase >= 6 ? (p.fase == 6 ? 'active' : 'completed') : ''}">
                                <div class="phase-circle">${p.fase > 6 ? '✓' : '6'}</div>
                                <span class="phase-title">Fase 6: Sustentación</span>
                            </div>
                        </div>
                    </div>

                    <%-- Detalle de Docentes y Datos del Proyecto --%>
                    <div style="padding: 1.5rem;">
                        <div class="form-grid" style="margin-bottom: 1.25rem;">
                            <div style="background: #f8fafc; padding: 1rem; border-radius: var(--radius-md); border: 1px solid var(--border-light);">
                                <span style="font-size: 0.76rem; font-weight: 700; color: var(--primary-700); text-transform: uppercase;">Docente Director de Proyecto:</span>
                                <p style="margin: 0.35rem 0 0; font-size: 0.95rem; font-weight: 600; color: var(--text-main);">
                                    ${empty p.dir_nom ? '⏳ Pendiente de designación por el Comité en Fase 1' : (p.dir_nom += ' ' += p.dir_ape)}
                                </p>
                                <c:if test="${not empty p.dir_email}">
                                    <small style="color: var(--text-muted);">${p.dir_email}</small>
                                </c:if>
                            </div>
                            <div style="background: #f8fafc; padding: 1rem; border-radius: var(--radius-md); border: 1px solid var(--border-light);">
                                <span style="font-size: 0.76rem; font-weight: 700; color: var(--primary-700); text-transform: uppercase;">Docente Codirector:</span>
                                <p style="margin: 0.35rem 0 0; font-size: 0.95rem; font-weight: 600; color: var(--text-main);">
                                    ${empty p.codir_nom ? 'Sin codirector asignado' : (p.codir_nom += ' ' += p.codir_ape)}
                                </p>
                                <c:if test="${not empty p.codir_email}">
                                    <small style="color: var(--text-muted);">${p.codir_email}</small>
                                </c:if>
                            </div>
                        </div>

                        <%-- Objetivo y Descripción --%>
                        <div style="background: #ffffff; border: 1px solid var(--border-light); border-radius: var(--radius-md); padding: 1.25rem; margin-bottom: 1.25rem;">
                            <h4 style="font-size: 0.88rem; color: var(--text-muted); text-transform: uppercase; margin: 0 0 0.4rem; letter-spacing: 0.5px;">Objetivo General:</h4>
                            <p style="font-size: 0.92rem; color: var(--text-main); margin: 0 0 0.85rem; line-height: 1.5;">${p.objetivo_general}</p>
                            
                            <h4 style="font-size: 0.88rem; color: var(--text-muted); text-transform: uppercase; margin: 0 0 0.4rem; letter-spacing: 0.5px;">Modalidad y Nivel:</h4>
                            <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                                <span class="badge" style="background: #f1f5f9; color: #334155;">Nivel: ${p.tipo_nivel}</span>
                                <span class="badge" style="background: #f0fdf4; color: #166534;">Modalidad: ${p.tipo_modalidad}</span>
                                <span class="badge" style="background: #eff6ff; color: #1e40af;">Línea: ${p.linea_investigacion}</span>
                            </div>
                        </div>

                        <%-- Enlace Comprobante de Pago Registrado (Fase 1) --%>
                        <div style="background: #fffbeb; border: 1px solid #fde68a; border-radius: var(--radius-md); padding: 1rem 1.25rem; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;">
                            <div>
                                <strong style="font-size: 0.88rem; color: #92400e; display: flex; align-items: center; gap: 0.4rem;">
                                    <span>💳</span> Comprobante de Pago Registrado (Fase 1):
                                </strong>
                                <p style="margin: 0.25rem 0 0; font-size: 0.84rem; color: #78350f;">
                                    Enlace actual: 
                                    <c:choose>
                                        <c:when test="${not empty p.soporte_pago_url}">
                                            <a href="${p.soporte_pago_url}" target="_blank" rel="noopener noreferrer" style="color: #b45309; text-decoration: underline; font-weight: 600; word-break: break-all;">
                                                ${p.soporte_pago_url} ↗
                                            </a>
                                        </c:when>
                                        <c:otherwise>
                                            <span style="color: #b45309;">(Enlace radicado en la postulación inicial)</span>
                                        </c:otherwise>
                                    </c:choose>
                                </p>
                            </div>
                            <c:if test="${p.fase == 1}">
                                <button type="button" class="btn btn-outline btn-sm" style="background: #ffffff; color: #92400e; border-color: #f59e0b;" onclick="abrirModalActualizarPago('${p.id}')">
                                    🔄 Actualizar Enlace de Pago
                                </button>
                            </c:if>
                        </div>
                    </div>

                    <%-- SI ES TURNO DEL ESTUDIANTE EN FASE 2 O FASE 4: FORMULARIO DE ENTREGA CON CUALQUIER ENLACE --%>
                    <c:if test="${p.responsable == 'estudiante' and (p.fase == 2 or p.fase == 4)}">
                        <div style="margin: 0 1.5rem 1.5rem; background: #f0fdf4; border: 2px dashed var(--primary-500); border-radius: var(--radius-md); padding: 1.5rem;">
                            <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.75rem;">
                                <span style="font-size: 1.5rem;">📤</span>
                                <div>
                                    <h4 style="font-size: 1.1rem; color: var(--primary-900); margin: 0;">
                                        Entrega de Documento &bull; Fase ${p.fase}: ${p.fase == 2 ? 'Anteproyecto de Grado (F-DC-124)' : 'Informe Final Consolidado (F-DC-125)'}
                                    </h4>
                                    <small style="color: var(--primary-700); font-weight: 600;">Es tu turno. Ingresa cualquier enlace donde esté alojado tu documento.</small>
                                </div>
                            </div>

                            <form action="proyecto.jsp" method="POST">
                                <input type="hidden" name="accion" value="entregar">
                                <input type="hidden" name="proyecto_id" value="${p.id}">
                                <input type="hidden" name="fase" value="${p.fase}">

                                <div class="form-group" style="margin-bottom: 1rem;">
                                    <label for="documento_url">
                                        Enlace del Documento (${p.fase == 2 ? 'F-DC-124' : 'F-DC-125'}):
                                    </label>
                                    <%-- type="text" para recibir cualquier enlace (Drive, OneDrive, Dropbox, Web) --%>
                                    <input type="text" 
                                           id="documento_url" 
                                           name="documento_url" 
                                           class="form-control" 
                                           placeholder="Pega aquí cualquier enlace: Google Drive, OneDrive, Dropbox, web..." 
                                           required>
                                    <small style="color: var(--text-muted); font-size: 0.78rem; display: block; margin-top: 0.35rem;">
                                        📎 <strong>Recibe cualquier enlace:</strong> Asegúrate de que el archivo o carpeta compartida cuente con permisos de visualización para tu Director.
                                    </small>
                                </div>

                                <div class="form-group" style="margin-bottom: 1rem;">
                                    <label for="observaciones">Notas / Resumen de Cambios para el Director:</label>
                                    <textarea id="observaciones" name="observaciones" class="form-control" rows="2" placeholder="Detalles de la entrega, porcentaje Turnitin, aclaraciones..."></textarea>
                                </div>

                                <div style="display: flex; justify-content: flex-end;">
                                    <button type="submit" class="btn btn-primary" style="padding: 0.65rem 1.5rem;">
                                        🚀 Enviar Entrega al Director de Proyecto
                                    </button>
                                </div>
                            </form>
                        </div>
                    </c:if>
                </div>

            </c:when>

            <%-- CASO B: EL ESTUDIANTE NO TIENE PROYECTO -> ESPERA DE APROBACIÓN O FORMULARIO DE INSCRIPCIÓN --%>
            <c:otherwise>
                <c:choose>
                    <%-- CASO B.1: EL ESTUDIANTE TIENE UNA IDEA RADICADA PENDIENTE DE APROBACIÓN --%>
                    <c:when test="${not empty miPropuestaPendiente and (miPropuestaPendiente.estado == 'Pendiente' or miPropuestaPendiente.estado == 'Correcciones')}">
                        <div class="card" style="border-color: ${miPropuestaPendiente.estado == 'Correcciones' ? '#fde047' : '#93c5fd'}; box-shadow: var(--shadow-md);">
                            <div class="card-header" style="background: ${miPropuestaPendiente.estado == 'Correcciones' ? '#fefce8' : '#eff6ff'}; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 0.75rem;">
                                <div style="display: flex; align-items: center; gap: 0.65rem;">
                                    <span style="font-size: 1.5rem;">${miPropuestaPendiente.estado == 'Correcciones' ? '⚠️' : '⏳'}</span>
                                    <div>
                                        <h3 style="margin: 0; font-size: 1.15rem; color: #1e40af;">
                                            Propuesta de Idea en Proceso de Revisión Institucional
                                        </h3>
                                        <small style="color: var(--text-muted);">Código: ${miPropuestaPendiente.codigo} &bull; Proponente: Estudiante</small>
                                    </div>
                                </div>
                                <div>
                                    <c:choose>
                                        <c:when test="${miPropuestaPendiente.estado == 'Correcciones'}">
                                            <span class="badge badge-corrections" style="font-size: 0.85rem; padding: 0.35rem 0.8rem;">
                                                ⚠️ Requiere Correcciones
                                            </span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge" style="background: #dbeafe; color: #1e40af; border: 1px solid #93c5fd; font-size: 0.85rem; padding: 0.35rem 0.8rem;">
                                                ⏳ Pendiente de Aprobación
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                            </div>

                            <div style="padding: 1.5rem;">
                                <h4 style="font-size: 1.15rem; color: var(--primary-dark); margin: 0 0 0.5rem;">
                                    ${miPropuestaPendiente.titulo}
                                </h4>

                                <div style="display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 1rem;">
                                    <span class="badge" style="background: #f1f5f9; color: #334155;">🎓 Nivel: ${miPropuestaPendiente.tipo_nivel}</span>
                                    <span class="badge" style="background: #f0fdf4; color: #166534;">⚙️ Modalidad: ${miPropuestaPendiente.tipo_modalidad}</span>
                                    <c:if test="${not empty miPropuestaPendiente.linea_investigacion}">
                                        <span class="badge" style="background: #eff6ff; color: #1e40af;">🔬 Línea: ${miPropuestaPendiente.linea_investigacion}</span>
                                    </c:if>
                                </div>

                                <div style="background: #f8fafc; border-left: 3px solid var(--primary-500); padding: 0.75rem 1rem; border-radius: 0 var(--radius-sm) var(--radius-sm) 0; margin-bottom: 1.25rem;">
                                    <strong style="font-size: 0.8rem; color: #475569; text-transform: uppercase;">Objetivo General:</strong>
                                    <p style="margin: 0.25rem 0 0; font-size: 0.875rem; color: var(--text-main);">
                                        ${miPropuestaPendiente.objetivo_general}
                                    </p>
                                </div>

                                <c:set var="enlacePagoPend" value="${not empty miPropuestaPendiente.soporte_url ? miPropuestaPendiente.soporte_url : miPropuestaPendiente.soporte_pago_url}" />
                                <div style="background: #f0fdf4; border: 1px solid var(--border-green); border-radius: var(--radius-md); padding: 1rem; margin-bottom: 1.25rem; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 0.75rem;">
                                    <div style="display: flex; align-items: center; gap: 0.6rem;">
                                        <span style="font-size: 1.3rem;">💳</span>
                                        <div>
                                            <strong style="font-size: 0.85rem; color: var(--primary-900);">Comprobante de Pago Radicado:</strong>
                                            <div style="font-size: 0.8rem; color: var(--text-muted); word-break: break-all;">
                                                ${not empty enlacePagoPend ? enlacePagoPend : 'Enlace registrado'}
                                            </div>
                                        </div>
                                    </div>
                                    <c:if test="${not empty enlacePagoPend}">
                                        <a href="${enlacePagoPend}" target="_blank" class="btn btn-outline btn-sm" style="background: #ffffff; color: var(--primary-800);">
                                            Ver Comprobante ↗
                                        </a>
                                    </c:if>
                                </div>

                                <c:choose>
                                    <c:when test="${miPropuestaPendiente.estado == 'Correcciones'}">
                                        <div class="alert" style="background: #fefce8; border: 1px solid #fde047; color: #854d0e; border-radius: var(--radius-sm); margin-bottom: 1.25rem; font-size: 0.85rem;">
                                            ⚠️ <strong>Observación del Comité Curricular:</strong>
                                            <p style="margin: 0.25rem 0 0; font-weight: 600;">${miPropuestaPendiente.observacion_comite}</p>
                                        </div>
                                    </c:when>
                                    <c:otherwise>
                                        <div class="alert" style="background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af; border-radius: var(--radius-sm); margin-bottom: 1.25rem; font-size: 0.85rem;">
                                            ℹ️ <strong>Debes esperar a que sea aprobada:</strong> Tu propuesta de idea propia y comprobante de pago fueron radicados y están siendo evaluados por el Comité Curricular o el Administrador (RF-ADM-09). Tan pronto sea aprobada, se activará tu proyecto en Fase 1 y se te asignará tu Director de Proyecto.
                                        </div>
                                    </c:otherwise>
                                </c:choose>

                                <div style="display: flex; justify-content: flex-end; gap: 0.75rem;">
                                    <a href="banco.jsp" class="btn btn-outline btn-sm">
                                        💡 Ver Detalle en Banco de Ideas / Actualizar Soporte
                                    </a>
                                </div>
                            </div>
                        </div>
                    </c:when>

                    <%-- CASO B.2: NO TIENE IDEA PENDIENTE NI PROYECTO -> FORMULARIO DE INSCRIPCIÓN --%>
                    <c:otherwise>
                        <div class="card">
                    <div class="card-header" style="flex-wrap: wrap; gap: 0.75rem;">
                        <div>
                            <h3 class="card-title">📝 Inscripción de Proyecto de Grado (Fase 1 de 6)</h3>
                            <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0.25rem 0 0;">
                                Postulación inicial para verificación de requisitos por el Comité Curricular.
                            </p>
                        </div>
                        <div>
                            <a href="banco.jsp" class="btn btn-outline btn-sm" style="background: var(--primary-50); border-color: var(--border-green); color: var(--primary-800);">
                                💡 Explorar Banco de Ideas Aprobadas &rarr;
                            </a>
                        </div>
                    </div>

                    <%-- Aviso si viene con una idea seleccionada del banco --%>
                    <c:if test="${not empty preIdeaBanco}">
                        <div class="alert" style="background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); border: 1px solid var(--border-green); border-radius: var(--radius-md); padding: 1rem 1.25rem; margin-bottom: 1.5rem; display: flex; align-items: center; gap: 0.75rem;">
                            <span style="font-size: 1.5rem;">✨</span>
                            <div>
                                <strong>Has seleccionado la idea del banco: ${preIdeaBanco.codigo}</strong>
                                <p style="margin: 0.2rem 0 0; font-size: 0.85rem; color: var(--primary-900);">
                                    "${preIdeaBanco.titulo}". Los campos han sido pre-completados. Solo ingresa el enlace de tu comprobante de pago para finalizar tu inscripción.
                                </p>
                            </div>
                        </div>
                    </c:if>

                    <form action="proyecto.jsp" method="POST">
                        <input type="hidden" name="accion" value="inscribir">

                        <div class="form-grid">
                            <div class="form-group">
                                <label for="tipo_idea">Origen de la Idea:</label>
                                <select id="tipo_idea" name="tipo_idea" class="form-control" onchange="toggleBancoSelect()" required>
                                    <option value="Propia" ${not empty preIdeaBanco ? '' : 'selected'}>💡 Idea Propia formulada por el Estudiante</option>
                                    <option value="Banco" ${not empty preIdeaBanco ? 'selected' : ''}>📚 Seleccionar del Banco Oficial de Ideas</option>
                                </select>
                            </div>
                            <div id="boxBancoSelect" class="form-group" style="${not empty preIdeaBanco ? 'display:block;' : 'display:none;'}">
                                <label for="banco_id">Idea Aprobada del Banco:</label>
                                <select id="banco_id" name="banco_id" class="form-control" onchange="cargarDatosIdeaBanco(this)">
                                    <option value="">-- Selecciona una idea del banco --</option>
                                    <c:forEach var="ib" items="${ideasDisponiblesList}">
                                        <c:if test="${ib.disponible == 1 or ib.disponible == '1' or ib.id == param.banco_id}">
                                            <option value="${ib.id}" 
                                                    data-titulo="${fn:escapeXml(ib.titulo)}" 
                                                    data-nivel="${ib.tipo_nivel}" 
                                                    data-modalidad="${ib.tipo_modalidad}" 
                                                    data-linea="${fn:escapeXml(ib.linea_investigacion)}" 
                                                    data-objetivo="${fn:escapeXml(ib.objetivo_general)}" 
                                                    data-descripcion="${fn:escapeXml(ib.descripcion)}"
                                                    ${ib.id == param.banco_id ? 'selected' : ''}>
                                                ${ib.codigo} - ${ib.titulo}
                                            </option>
                                        </c:if>
                                    </c:forEach>
                                </select>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="titulo">Título Formal del Trabajo de Grado (*):</label>
                            <input type="text" id="titulo" name="titulo" class="form-control" placeholder="Título formal del trabajo de grado..." value="${not empty preIdeaBanco ? preIdeaBanco.titulo : ''}" required>
                        </div>

                        <div class="form-grid">
                            <div class="form-group">
                                <label for="tipo_nivel">Nivel de Titulación (*):</label>
                                <select id="tipo_nivel" name="tipo_nivel" class="form-control" required>
                                    <option value="Profesional" ${preIdeaBanco.tipo_nivel == 'Profesional' ? 'selected' : ''}>Profesional (Ingeniería de Sistemas - Código 125-XXX)</option>
                                    <option value="Tecnologico" ${preIdeaBanco.tipo_nivel == 'Tecnologico' ? 'selected' : ''}>Tecnológico (Tecnología en Sistemas - Código 65-XXX)</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label for="tipo_modalidad">Modalidad de Grado (*):</label>
                                <select id="tipo_modalidad" name="tipo_modalidad" class="form-control" required>
                                    <option value="Desarrollo tecnologico" ${preIdeaBanco.tipo_modalidad == 'Desarrollo tecnologico' ? 'selected' : ''}>Desarrollo tecnológico</option>
                                    <option value="Investigacion" ${preIdeaBanco.tipo_modalidad == 'Investigacion' ? 'selected' : ''}>Investigación</option>
                                    <option value="Emprendimiento" ${preIdeaBanco.tipo_modalidad == 'Emprendimiento' ? 'selected' : ''}>Emprendimiento</option>
                                    <option value="Otro" ${preIdeaBanco.tipo_modalidad == 'Otro' ? 'selected' : ''}>Otro</option>
                                </select>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="linea_investigacion">Línea de Investigación (*):</label>
                            <input type="text" id="linea_investigacion" name="linea_investigacion" class="form-control" placeholder="Ej: Inteligencia Artificial, Ciberseguridad, Ingeniería de Software" value="${not empty preIdeaBanco ? preIdeaBanco.linea_investigacion : ''}" required>
                        </div>

                        <div class="form-group">
                            <label for="objetivo_general">Objetivo General (*):</label>
                            <textarea id="objetivo_general" name="objetivo_general" class="form-control" rows="2" placeholder="Verbo en infinitivo + objeto de estudio + finalidad..." required>${not empty preIdeaBanco ? preIdeaBanco.objetivo_general : ''}</textarea>
                        </div>

                        <div class="form-group">
                            <label for="descripcion">Descripción y Alcance Preliminar:</label>
                            <textarea id="descripcion" name="descripcion" class="form-control" rows="3" placeholder="Descripción detallada de la propuesta, problemática y alcance esperado...">${not empty preIdeaBanco ? preIdeaBanco.descripcion : ''}</textarea>
                        </div>

                        <hr style="border:0; border-top: 1px solid var(--border-light); margin: 1.5rem 0;">
                        <h4 style="font-size: 0.95rem; color: var(--primary-dark); margin-bottom: 1rem;">
                            👥 Modalidad de Integrantes y Comprobante de Pago
                        </h4>

                        <div class="form-grid">
                            <div class="form-group">
                                <label for="es_pareja">Modalidad de Integrantes:</label>
                                <select id="es_pareja" name="es_pareja" class="form-control" onchange="toggleSegundoIntegrante()" required>
                                    <option value="0">Individual (1 Estudiante)</option>
                                    <option value="1">En Pareja (2 Estudiantes)</option>
                                </select>
                            </div>
                            <div id="boxSegundoIntegrante" class="form-group" style="display: none;">
                                <label for="segundo_integrante_doc">Documento del 2do Estudiante:</label>
                                <input type="text" id="segundo_integrante_doc" name="segundo_integrante_doc" class="form-control" placeholder="Número de documento de identidad del compañero">
                            </div>
                        </div>

                        <%-- CAMPO COMPROBANTE DE PAGO: RECIBE CUALQUIER ENLACE (type="text") --%>
                        <div class="form-group" style="background: #f8fafc; border: 1px solid var(--border-green); padding: 1.25rem; border-radius: var(--radius-md);">
                            <label for="soporte_pago_url" style="color: var(--primary-900); font-weight: 700;">
                                Enlace del Comprobante de Pago de Derechos de Grado (RF-EST-04 - Obligatorio) (*):
                            </label>
                            <%-- type="text" para permitir cualquier enlace sin bloqueo de regex estricto del navegador --%>
                            <input type="text" 
                                   id="soporte_pago_url" 
                                   name="soporte_pago_url" 
                                   class="form-control" 
                                   placeholder="Pega aquí cualquier enlace: Google Drive, OneDrive, Dropbox, enlace institucional o web..." 
                                   required>
                            <div style="margin-top: 0.4rem; font-size: 0.8rem; color: var(--text-muted); line-height: 1.4;">
                                📎 <strong>Acepta cualquier enlace:</strong> Puedes ingresar enlaces de Google Drive, OneDrive, Dropbox, enlaces institucionales o enlaces web. Recuerda asegurar permisos de lectura para el Comité.
                            </div>
                        </div>

                        <div style="display: flex; justify-content: flex-end; margin-top: 1.5rem;">
                            <button type="submit" class="btn btn-primary" style="padding: 0.75rem 2rem; font-size: 0.95rem;">
                                🚀 Inscribir Proyecto de Grado (Fase 1)
                            </button>
                        </div>
                    </form>
                </div>
                    </c:otherwise>
                </c:choose>
            </c:otherwise>
        </c:choose>

    </div>

    <%-- MODAL PARA ACTUALIZAR ENLACE DE PAGO --%>
    <div id="modalActualizarPago" class="modal-overlay" style="display: none;">
        <div class="modal-box" style="max-width: 500px;">
            <div class="modal-header">
                <h3 style="font-size: 1.15rem; color: var(--primary-dark); margin: 0;">Actualizar Enlace de Pago</h3>
                <button type="button" class="modal-close-btn" onclick="cerrarModal('modalActualizarPago')">&times;</button>
            </div>
            <form action="proyecto.jsp" method="POST">
                <input type="hidden" name="accion" value="actualizar_pago">
                <input type="hidden" id="pago_target_id" name="proyecto_id" value="">
                
                <div class="modal-body" style="padding: 1.5rem;">
                    <div class="form-group">
                        <label for="nuevo_soporte_pago_url">Nuevo Enlace del Comprobante de Pago:</label>
                        <input type="text" id="nuevo_soporte_pago_url" name="nuevo_soporte_pago_url" class="form-control" placeholder="Pega aquí cualquier enlace..." required>
                        <small style="color: var(--text-muted); font-size: 0.78rem; display: block; margin-top: 0.35rem;">
                            Acepta cualquier enlace: Google Drive, OneDrive, Dropbox, enlace web, etc.
                        </small>
                    </div>
                </div>

                <div class="modal-footer" style="padding: 1rem 1.5rem; background: var(--bg-light); border-top: 1px solid var(--border-light); display: flex; justify-content: flex-end; gap: 0.75rem;">
                    <button type="button" class="btn btn-outline" onclick="cerrarModal('modalActualizarPago')">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Guardar Enlace</button>
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
    @keyframes pulse {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.75; }
    }
</style>

<script>
    function toggleBancoSelect() {
        const tipo = document.getElementById('tipo_idea').value;
        const box = document.getElementById('boxBancoSelect');
        box.style.display = tipo === 'Banco' ? 'block' : 'none';
    }

    function toggleSegundoIntegrante() {
        const pareja = document.getElementById('es_pareja').value;
        const box = document.getElementById('boxSegundoIntegrante');
        box.style.display = pareja === '1' ? 'block' : 'none';
    }

    function cargarDatosIdeaBanco(selectElem) {
        const selectedOpt = selectElem.options[selectElem.selectedIndex];
        if (!selectedOpt || !selectedOpt.value) return;

        const titulo = selectedOpt.getAttribute('data-titulo') || '';
        const nivel = selectedOpt.getAttribute('data-nivel') || '';
        const modalidad = selectedOpt.getAttribute('data-modalidad') || '';
        const linea = selectedOpt.getAttribute('data-linea') || '';
        const objetivo = selectedOpt.getAttribute('data-objetivo') || '';
        const descripcion = selectedOpt.getAttribute('data-descripcion') || '';

        if (titulo) document.getElementById('titulo').value = titulo;
        if (nivel) document.getElementById('tipo_nivel').value = nivel;
        if (modalidad) document.getElementById('tipo_modalidad').value = modalidad;
        if (linea) document.getElementById('linea_investigacion').value = linea;
        if (objetivo) document.getElementById('objetivo_general').value = objetivo;
        if (descripcion) document.getElementById('descripcion').value = descripcion;
    }

    function abrirModalActualizarPago(id) {
        document.getElementById('pago_target_id').value = id;
        abrirModal('modalActualizarPago');
    }
</script>

</body>
</html>

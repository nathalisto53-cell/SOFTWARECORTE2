<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardEstudiante.jspf" %>

<%-- =========================================================================
     SIGRADO - Banco de Ideas de Grado para Estudiantes
     - Permite al estudiante explorar y seleccionar ideas aprobadas de docentes.
     - Permite al estudiante SUBIR UNA IDEA NUEVA PROPIA adjuntando su comprobante
       de pago (RF-EST-04 / RF-ADM-09), la cual queda PENDIENTE DE APROBACIÓN.
     - Seguimiento en vivo al estado de revisión institucional (Pendiente, Correcciones, Aprobada).
     - Arquitectura: JSTL 1.2 puro (Cero Servlets, Cero Scriptlets, Cero DAOs).
     ========================================================================= --%>

<c:set var="mensajeFeedback" value="" />
<c:set var="tipoAlertaFeedback" value="success" />

<%-- PROCESAR ACCIONES DEL ESTUDIANTE (POST) --%>
<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="accion" value="${param.accion}" />

    <%-- 1. SUBIR NUEVA IDEA PROPIA DEL ESTUDIANTE CON COMPROBANTE DE PAGO --%>
    <c:if test="${accion == 'postular_nueva_idea'}">
        <c:set var="tit" value="${fn:trim(param.titulo)}" />
        <c:set var="modalidad" value="${param.tipo_modalidad}" />
        <c:set var="niv" value="${param.tipo_nivel}" />
        <c:set var="linea" value="${fn:trim(param.linea_investigacion)}" />
        <c:set var="obj" value="${fn:trim(param.objetivo_general)}" />
        <c:set var="desc" value="${fn:trim(param.descripcion)}" />
        <c:set var="soportePagoUrl" value="${fn:trim(param.soporte_pago_url)}" />
        <c:set var="esPareja" value="${param.es_pareja}" />
        <c:set var="segundoDoc" value="${fn:trim(param.segundo_integrante_doc)}" />

        <c:if test="${not empty tit and not empty modalidad and not empty niv and not empty obj and not empty soportePagoUrl}">
            <c:catch var="insPropErr">
                <sql:update dataSource="${sigradoDb}">
                    INSERT INTO propuestas_banco (codigo, proponente_id, origen, titulo, tipo_modalidad, tipo_nivel, linea_investigacion, periodo_id, objetivo_general, descripcion, estado, disponible)
                    VALUES (CONCAT('BAN-', TO_CHAR(CURRENT_TIMESTAMP, 'MMSS')), ?, 'Estudiante', ?, ?::tipo_modalidad_enum, ?::tipo_nivel_enum, ?, 1, ?, ?, 'Pendiente', 0);
                    <sql:param value="${sessionScope.usuario.id}" />
                    <sql:param value="${tit}" />
                    <sql:param value="${modalidad}" />
                    <sql:param value="${niv}" />
                    <sql:param value="${linea}" />
                    <sql:param value="${obj}" />
                    <sql:param value="${desc}" />
                </sql:update>
            </c:catch>

            <%-- Sincronizar en almacén demo compartido en memoria --%>
            <c:if test="${not empty applicationScope.demoIdeasBanco}">
                <jsp:useBean id="nuevaIdeaEstBean" class="java.util.HashMap" scope="page" />
                <c:set target="${nuevaIdeaEstBean}" property="id" value="${fn:length(applicationScope.demoIdeasBanco) + 10}" />
                <c:set target="${nuevaIdeaEstBean}" property="codigo" value="BAN-${fn:length(applicationScope.demoIdeasBanco) + 100}" />
                <c:set target="${nuevaIdeaEstBean}" property="titulo" value="${tit}" />
                <c:set target="${nuevaIdeaEstBean}" property="descripcion" value="${desc}" />
                <c:set target="${nuevaIdeaEstBean}" property="objetivo_general" value="${obj}" />
                <c:set target="${nuevaIdeaEstBean}" property="tipo_nivel" value="${niv}" />
                <c:set target="${nuevaIdeaEstBean}" property="tipo_modalidad" value="${modalidad}" />
                <c:set target="${nuevaIdeaEstBean}" property="linea_investigacion" value="${linea}" />
                <c:set target="${nuevaIdeaEstBean}" property="proponente" value="${sessionScope.usuario.nombres} ${sessionScope.usuario.apellidos}" />
                <c:set target="${nuevaIdeaEstBean}" property="proponente_id" value="${sessionScope.usuario.id}" />
                <c:set target="${nuevaIdeaEstBean}" property="origen" value="Estudiante" />
                <c:set target="${nuevaIdeaEstBean}" property="estado" value="Pendiente" />
                <c:set target="${nuevaIdeaEstBean}" property="disponible" value="0" />
                <c:set target="${nuevaIdeaEstBean}" property="soporte_pago_url" value="${soportePagoUrl}" />
                <c:set target="${nuevaIdeaEstBean}" property="es_pareja" value="${esPareja}" />
                <c:set target="${nuevaIdeaEstBean}" property="segundo_integrante_doc" value="${segundoDoc}" />
                <c:set target="${nuevaIdeaEstBean}" property="fecha_fmt" value="Hoy" />
                <c:set var="dummyAddEst" value="${applicationScope.demoIdeasBanco.add(0, nuevaIdeaEstBean)}" />
            </c:if>

            <c:set var="mensajeFeedback" value="🎉 ¡Tu propuesta de idea ha sido radicada exitosamente con tu comprobante de pago! Ha quedado en estado 'Pendiente de Aprobación'. Debes esperar a que el Comité Curricular o el Administrador la revise y valide tu pago (RF-ADM-09)." />
            <c:set var="tipoAlertaFeedback" value="success" />
        </c:if>
    </c:if>

    <%-- 2. ACTUALIZAR ENLACE DE PAGO DE PROPUESTA PENDIENTE --%>
    <c:if test="${accion == 'actualizar_pago_propuesta'}">
        <c:set var="propId" value="${param.propuesta_id}" />
        <c:set var="nuevoSoporte" value="${fn:trim(param.nuevo_soporte_pago_url)}" />

        <c:if test="${not empty applicationScope.demoIdeasBanco}">
            <c:forEach var="di" items="${applicationScope.demoIdeasBanco}">
                <c:if test="${di.id == propId or ('' + di.id) == ('' + propId)}">
                    <c:set target="${di}" property="soporte_pago_url" value="${nuevoSoporte}" />
                </c:if>
            </c:forEach>
        </c:if>

        <c:set var="mensajeFeedback" value="✅ Enlace de comprobante de pago actualizado correctamente." />
        <c:set var="tipoAlertaFeedback" value="success" />
    </c:if>
</c:if>

<%-- 1. Consultar si el estudiante ya tiene un proyecto activo --%>
<c:set var="tieneProyectoActivo" value="false" />
<c:set var="miProyectoActual" value="${null}" />

<c:catch var="chkProyErr">
    <sql:query var="miProyQ" dataSource="${sigradoDb}">
        SELECT p.id, p.codigo, p.titulo, p.fase, p.estado 
        FROM proyectos p
        JOIN proyecto_integrantes pi ON p.id = pi.proyecto_id
        WHERE pi.usuario_id = ? AND p.estado = 'En curso'
        LIMIT 1;
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
    <c:if test="${not empty miProyQ.rows and miProyQ.rowCount > 0}">
        <c:set var="tieneProyectoActivo" value="true" />
        <c:set var="miProyectoActual" value="${miProyQ.rows[0]}" />
    </c:if>
</c:catch>

<c:if test="${not tieneProyectoActivo and not empty applicationScope.demoProyectos}">
    <c:forEach var="dp" items="${applicationScope.demoProyectos}">
        <c:if test="${not tieneProyectoActivo and dp.estado == 'En curso'}">
            <c:if test="${dp.estudiante_id == sessionScope.usuario.id or dp.estudiante_doc == sessionScope.usuario.documento or fn:toLowerCase(fn:trim(dp.estudiante_email)) == fn:toLowerCase(fn:trim(sessionScope.usuario.email))}">
                <c:set var="tieneProyectoActivo" value="true" />
                <c:set var="miProyectoActual" value="${dp}" />
            </c:if>
        </c:if>
    </c:forEach>
</c:if>

<%-- 2. Consultar si el estudiante tiene una propuesta de idea en proceso de revisión --%>
<c:set var="miPropuestaEstudiante" value="${null}" />
<c:catch var="chkPropErr">
    <sql:query var="miPropQ" dataSource="${sigradoDb}">
        SELECT pb.*,
               (SELECT d.url FROM documentos d WHERE d.proyecto_id = pb.id AND d.tipo = 'SoportePago' LIMIT 1) as soporte_url
        FROM propuestas_banco pb
        WHERE pb.proponente_id = ?
        ORDER BY pb.id DESC LIMIT 1;
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
    <c:if test="${not empty miPropQ.rows and miPropQ.rowCount > 0}">
        <c:set var="miPropuestaEstudiante" value="${miPropQ.rows[0]}" />
    </c:if>
</c:catch>

<c:if test="${empty miPropuestaEstudiante and not empty applicationScope.demoIdeasBanco}">
    <c:forEach var="di" items="${applicationScope.demoIdeasBanco}">
        <c:if test="${empty miPropuestaEstudiante and di.origen == 'Estudiante'}">
            <c:if test="${di.proponente_id == sessionScope.usuario.id or fn:contains(di.proponente, sessionScope.usuario.nombres) or fn:contains(di.proponente, sessionScope.usuario.apellidos)}">
                <c:set var="miPropuestaEstudiante" value="${di}" />
            </c:if>
        </c:if>
    </c:forEach>
</c:if>

<%-- 3. Consultar Ideas Aprobadas del Banco para Explorar --%>
<c:set var="listaIdeas" value="${null}" />
<c:catch var="bancoErr">
    <sql:query var="ideasBancoDb" dataSource="${sigradoDb}">
        SELECT pb.id, pb.codigo, pb.titulo, pb.tipo_nivel, pb.tipo_modalidad, pb.linea_investigacion,
               pb.objetivo_general, pb.descripcion, pb.disponible, pb.fecha_propuesta,
               u.nombres as proponente_nom, u.apellidos as proponente_ape, u.email as proponente_email
        FROM propuestas_banco pb
        JOIN usuarios u ON pb.proponente_id = u.id
        WHERE pb.estado = 'Aprobada'
        ORDER BY pb.disponible DESC, pb.id DESC;
    </sql:query>
    <c:if test="${not empty ideasBancoDb.rows and ideasBancoDb.rowCount > 0}">
        <c:set var="listaIdeas" value="${ideasBancoDb.rows}" />
    </c:if>
</c:catch>

<c:if test="${empty listaIdeas}">
    <c:set var="listaIdeas" value="${applicationScope.demoIdeasBanco}" />
</c:if>

<c:set var="pageTitle" value="Banco de Ideas de Grado" />
<c:set var="param_active" value="banco" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">

        <%-- Alerta de feedback de acciones --%>
        <c:if test="${not empty mensajeFeedback}">
            <div class="alert alert-${tipoAlertaFeedback}" style="display: flex; align-items: center; gap: 0.75rem; margin-bottom: 1.5rem;">
                <span style="font-size: 1.4rem;">${tipoAlertaFeedback == 'success' ? '✅' : 'ℹ️'}</span>
                <div>
                    <strong>Información del Sistema:</strong>
                    <div>${mensajeFeedback}</div>
                </div>
            </div>
        </c:if>

        <%-- SECCIÓN 1: ESTADO DE LA PROPUESTA POSTULADA POR EL ESTUDIANTE (SI TIENE UNA) --%>
        <c:if test="${not empty miPropuestaEstudiante and not tieneProyectoActivo}">
            <div class="card" style="margin-bottom: 2rem; border-color: ${miPropuestaEstudiante.estado == 'Aprobada' ? 'var(--border-green)' : (miPropuestaEstudiante.estado == 'Correcciones' ? '#fde047' : '#93c5fd')}; box-shadow: var(--shadow-md);">
                <div class="card-header" style="background: ${miPropuestaEstudiante.estado == 'Aprobada' ? 'linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%)' : (miPropuestaEstudiante.estado == 'Correcciones' ? '#fefce8' : '#eff6ff')}; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 0.75rem;">
                    <div style="display: flex; align-items: center; gap: 0.65rem;">
                        <span style="font-size: 1.4rem;">
                            ${miPropuestaEstudiante.estado == 'Aprobada' ? '🎉' : (miPropuestaEstudiante.estado == 'Correcciones' ? '⚠️' : '⏳')}
                        </span>
                        <div>
                            <h3 style="margin: 0; font-size: 1.15rem; color: var(--primary-dark);">
                                Mi Propuesta de Idea de Grado (${miPropuestaEstudiante.codigo})
                            </h3>
                            <small style="color: var(--text-muted);">Radicada como idea propia del estudiante</small>
                        </div>
                    </div>
                    <div>
                        <c:choose>
                            <c:when test="${miPropuestaEstudiante.estado == 'Aprobada'}">
                                <span class="badge badge-approved" style="font-size: 0.85rem; padding: 0.35rem 0.8rem;">
                                    ✓ Aprobada Oficialmente
                                </span>
                            </c:when>
                            <c:when test="${miPropuestaEstudiante.estado == 'Correcciones'}">
                                <span class="badge badge-corrections" style="font-size: 0.85rem; padding: 0.35rem 0.8rem;">
                                    ⚠️ Requiere Correcciones
                                </span>
                            </c:when>
                            <c:when test="${miPropuestaEstudiante.estado == 'Rechazada'}">
                                <span class="badge badge-rejected" style="font-size: 0.85rem; padding: 0.35rem 0.8rem;">
                                    ✕ Rechazada
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
                    <h4 style="font-size: 1.1rem; color: var(--primary-900); margin: 0 0 0.5rem;">
                        ${miPropuestaEstudiante.titulo}
                    </h4>

                    <div style="display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 1rem;">
                        <span class="badge" style="background: #f1f5f9; color: #334155;">🎓 Nivel: ${miPropuestaEstudiante.tipo_nivel}</span>
                        <span class="badge" style="background: #f0fdf4; color: #166534;">⚙️ Modalidad: ${miPropuestaEstudiante.tipo_modalidad}</span>
                        <c:if test="${not empty miPropuestaEstudiante.linea_investigacion}">
                            <span class="badge" style="background: #eff6ff; color: #1e40af;">🔬 Línea: ${miPropuestaEstudiante.linea_investigacion}</span>
                        </c:if>
                    </div>

                    <div style="background: #f8fafc; border-left: 3px solid var(--primary-500); padding: 0.75rem 1rem; border-radius: 0 var(--radius-sm) var(--radius-sm) 0; margin-bottom: 1rem;">
                        <strong style="font-size: 0.8rem; color: #475569; text-transform: uppercase;">Objetivo General:</strong>
                        <p style="margin: 0.25rem 0 0; font-size: 0.875rem; color: var(--text-main);">
                            ${miPropuestaEstudiante.objetivo_general}
                        </p>
                    </div>

                    <c:set var="enlacePagoProp" value="${not empty miPropuestaEstudiante.soporte_url ? miPropuestaEstudiante.soporte_url : miPropuestaEstudiante.soporte_pago_url}" />

                    <div style="background: #f0f9ff; border: 1px solid #bae6fd; border-radius: var(--radius-md); padding: 1rem; margin-bottom: 1.25rem; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 0.75rem;">
                        <div style="display: flex; align-items: center; gap: 0.6rem;">
                            <span style="font-size: 1.3rem;">💳</span>
                            <div>
                                <strong style="font-size: 0.85rem; color: #0369a1;">Comprobante de Pago Radicado:</strong>
                                <div style="font-size: 0.8rem; color: #0284c7; word-break: break-all;">
                                    ${not empty enlacePagoProp ? enlacePagoProp : 'No se registró enlace'}
                                </div>
                            </div>
                        </div>
                        <div style="display: flex; gap: 0.5rem;">
                            <c:if test="${not empty enlacePagoProp}">
                                <a href="${enlacePagoProp}" target="_blank" class="btn btn-outline btn-sm" style="background: #ffffff; color: #0369a1; border-color: #7dd3fc;">
                                    Ver Soporte ↗
                                </a>
                            </c:if>
                            <button type="button" class="btn btn-outline btn-sm" onclick="abrirModalActualizarPago('${miPropuestaEstudiante.id}', '${fn:escapeXml(enlacePagoProp)}')">
                                ✏️ Actualizar Enlace
                            </button>
                        </div>
                    </div>

                    <%-- Mensajes según el estado de la propuesta --%>
                    <c:choose>
                        <c:when test="${miPropuestaEstudiante.estado == 'Pendiente'}">
                            <div class="alert" style="background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af; border-radius: var(--radius-sm); margin: 0; padding: 0.9rem 1.15rem; font-size: 0.85rem;">
                                ℹ️ <strong>Debes esperar a que sea aprobada:</strong> Tu propuesta de idea y soporte de pago están en revisión por el Comité Curricular o el Administrador (RF-ADM-09). Tan pronto sea validada, se formalizará tu proyecto en Fase 1.
                            </div>
                        </c:when>
                        <c:when test="${miPropuestaEstudiante.estado == 'Correcciones'}">
                            <div class="alert" style="background: #fefce8; border: 1px solid #fde047; color: #854d0e; border-radius: var(--radius-sm); margin: 0; padding: 0.9rem 1.15rem; font-size: 0.85rem;">
                                ⚠️ <strong>Observaciones del Comité Curricular:</strong>
                                <p style="margin: 0.25rem 0 0; font-weight: 600;">
                                    ${not empty miPropuestaEstudiante.observacion_comite ? miPropuestaEstudiante.observacion_comite : 'Por favor ajusta los detalles de tu propuesta o actualiza el enlace de pago.'}
                                </p>
                            </div>
                        </c:when>
                        <c:when test="${miPropuestaEstudiante.estado == 'Aprobada'}">
                            <div class="alert alert-success" style="margin: 0; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 0.75rem;">
                                <div>
                                    <strong>🎉 ¡Tu idea ha sido aprobada!</strong>
                                    <div>Ya puedes consultar tu proyecto en curso e iniciar formalmente la Fase 1 con tu Director asignado.</div>
                                </div>
                                <a href="proyecto.jsp" class="btn btn-primary btn-sm">
                                    Ir a Mi Proyecto de Grado &rarr;
                                </a>
                            </div>
                        </c:when>
                    </c:choose>
                </div>
            </div>
        </c:if>

        <%-- SECCIÓN 2: BANNER PRINCIPAL CON OPCIONES --%>
        <div class="alert" style="background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); border: 1px solid var(--border-green); border-radius: var(--radius-md); padding: 1.25rem 1.5rem; margin-bottom: 1.5rem; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 1rem;">
            <div style="display: flex; align-items: flex-start; gap: 0.85rem; max-width: 750px;">
                <span style="font-size: 2rem; line-height: 1;">💡</span>
                <div>
                    <h3 style="margin: 0; font-size: 1.15rem; color: var(--primary-900);">
                        Banco de Ideas de Grado para Estudiantes
                    </h3>
                    <p style="margin: 0.35rem 0 0; font-size: 0.85rem; color: var(--text-main); line-height: 1.45;">
                        Tienes dos opciones para iniciar tu trabajo de grado: puedes <strong>seleccionar una idea aprobada</strong> formulada por docentes O <strong>postular tu propia idea nueva</strong> adjuntando tu comprobante de pago para que sea revisada y aprobada por el Comité Curricular.
                    </p>
                </div>
            </div>
            <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                <a href="#seccionPostularPropia" class="btn btn-primary btn-sm" onclick="mostrarSeccionFormulario()">
                    ➕ Subir Mi Propia Idea
                </a>
                <a href="#seccionExplorarBanco" class="btn btn-outline btn-sm" style="background: #ffffff;" onclick="mostrarSeccionBanco()">
                    📚 Explorar Banco de Ideas
                </a>
            </div>
        </div>

        <%-- SECCIÓN 3: FORMULARIO PARA POSTULAR NUEVA IDEA PROPIA DEL ESTUDIANTE --%>
        <div class="card" id="seccionPostularPropia" style="margin-bottom: 2rem;">
            <div class="card-header" style="background: linear-gradient(to right, #f8fafc, #ffffff); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 0.5rem;">
                <div>
                    <h3 class="card-title">➕ Postular Nueva Idea de Grado Propia</h3>
                    <p style="margin: 0.2rem 0 0; font-size: 0.8rem; color: var(--text-muted);">
                        Formula tu propuesta, adjunta tu comprobante de pago y envíala para aprobación del Comité/Administrador.
                    </p>
                </div>
                <span class="badge badge-phase">Requiere Soporte de Pago</span>
            </div>

            <form action="banco.jsp" method="POST" style="padding: 1.5rem;">
                <input type="hidden" name="accion" value="postular_nueva_idea">

                <div class="form-group">
                    <label for="titulo">Título de tu Idea de Grado: <span style="color: #dc2626;">*</span></label>
                    <input type="text" id="titulo" name="titulo" class="form-control" placeholder="Ej: Plataforma Web con Inteligencia Artificial para Detección de..." required>
                </div>

                <div class="form-grid">
                    <div class="form-group">
                        <label for="tipo_nivel">Nivel de Titulación: <span style="color: #dc2626;">*</span></label>
                        <select id="tipo_nivel" name="tipo_nivel" class="form-control" required>
                            <option value="Profesional">Profesional (Modalidad 125 - Ingeniería de Sistemas)</option>
                            <option value="Tecnologico">Tecnológico (Modalidad 65 - Tecnología en Sistemas)</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="tipo_modalidad">Modalidad de Grado: <span style="color: #dc2626;">*</span></label>
                        <select id="tipo_modalidad" name="tipo_modalidad" class="form-control" required>
                            <option value="Desarrollo tecnologico">Desarrollo tecnológico</option>
                            <option value="Investigacion">Investigación</option>
                            <option value="Emprendimiento">Emprendimiento</option>
                            <option value="Otro">Otro</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="linea_investigacion">Línea de Investigación: <span style="color: #dc2626;">*</span></label>
                        <input type="text" id="linea_investigacion" name="linea_investigacion" class="form-control" placeholder="Ej: Inteligencia Artificial, Ingeniería de Software, Ciberseguridad..." required>
                    </div>
                </div>

                <div class="form-group">
                    <label for="objetivo_general">Objetivo General: <span style="color: #dc2626;">*</span></label>
                    <textarea id="objetivo_general" name="objetivo_general" class="form-control" rows="2" placeholder="Verbo en infinitivo + finalidad + impacto de la propuesta..." required></textarea>
                </div>

                <div class="form-group">
                    <label for="descripcion">Descripción Técnica y Alcance Preliminar:</label>
                    <textarea id="descripcion" name="descripcion" class="form-control" rows="3" placeholder="Detalle técnico de la idea, problemática que resuelve y stack tecnológico sugerido..."></textarea>
                </div>

                <div class="form-grid">
                    <div class="form-group">
                        <label for="es_pareja">Modalidad de Integrantes:</label>
                        <select id="es_pareja" name="es_pareja" class="form-control" onchange="toggleSegundoDocEstudiante(this)">
                            <option value="0">Individual (1 Estudiante)</option>
                            <option value="1">En Pareja (2 Estudiantes)</option>
                        </select>
                    </div>
                    <div class="form-group" id="boxSegundoDoc" style="display: none;">
                        <label for="segundo_integrante_doc">Documento de Identidad del Compañero:</label>
                        <input type="text" id="segundo_integrante_doc" name="segundo_integrante_doc" class="form-control" placeholder="C.C. o T.I. del 2do estudiante">
                    </div>
                </div>

                <%-- CAMPO COMPROBANTE DE PAGO: OBLIGATORIO PARA ESTUDIANTES (ACEPTA CUALQUIER ENLACE) --%>
                <div class="form-group" style="background: #f0fdf4; border: 1.5px solid var(--border-green); padding: 1.25rem; border-radius: var(--radius-md); margin-top: 1rem;">
                    <label for="soporte_pago_url" style="color: var(--primary-900); font-weight: 700; display: flex; align-items: center; gap: 0.4rem;">
                        <span>💳</span> Enlace del Comprobante de Pago de Derechos de Grado (* Obligatorio): <span style="color: #dc2626;">*</span>
                    </label>
                    <input type="text" 
                           id="soporte_pago_url" 
                           name="soporte_pago_url" 
                           class="form-control" 
                           placeholder="Pega aquí cualquier enlace: Google Drive, OneDrive, Dropbox, enlace institucional o web..." 
                           required>
                    <small style="color: var(--text-muted); font-size: 0.8rem; display: block; margin-top: 0.4rem; line-height: 1.4;">
                        📎 <strong>Acepta cualquier enlace:</strong> Puedes ingresar enlaces de Google Drive, OneDrive, Dropbox, enlaces institucionales o enlaces web. Asegúrate de otorgar permisos de lectura para que el Administrador y Comité puedan verificar tu pago.
                    </small>
                </div>

                <div style="background: #fffbeb; border: 1px solid #fde68a; border-radius: var(--radius-sm); padding: 0.85rem 1rem; margin-top: 1.25rem; font-size: 0.85rem; color: #92400e; display: flex; align-items: center; gap: 0.65rem;">
                    <span>📌</span>
                    <div>
                        <strong>Regla de negocio institucional:</strong> Al postular tu idea con el pago adjunto, quedará en estado <strong>'Pendiente de Aprobación'</strong>. Deberás esperar a que el Comité Curricular o el Administrador revise y apruebe tu idea (RF-ADM-09).
                    </div>
                </div>

                <div style="display: flex; justify-content: flex-end; gap: 0.75rem; margin-top: 1.5rem;">
                    <button type="reset" class="btn btn-outline">Limpiar</button>
                    <button type="submit" class="btn btn-primary" style="padding: 0.7rem 1.75rem; font-size: 0.95rem;">
                        🚀 Radicar Idea y Enviar a Aprobación
                    </button>
                </div>
            </form>
        </div>

        <%-- SECCIÓN 4: BANCO DE IDEAS APROBADAS DISPONIBLES (FORMULADAS POR DOCENTES) --%>
        <div class="card" id="seccionExplorarBanco" style="margin-bottom: 2rem;">
            <div class="card-header" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;">
                <div>
                    <h3 class="card-title">📚 Ideas Aprobadas Disponibles en el Banco</h3>
                    <p style="margin: 0.2rem 0 0; font-size: 0.8rem; color: var(--text-muted);">
                        Propuestas formuladas por docentes e investigadores que puedes seleccionar para tu grado.
                    </p>
                </div>
                <div style="flex: 1; max-width: 380px;">
                    <input type="text" id="buscadorIdeas" class="form-control" placeholder="🔍 Buscar por código, título, docente o línea..." onkeyup="filtrarIdeas()">
                </div>
            </div>

            <div style="padding: 1.25rem;">
                <div style="display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 1.25rem;" id="tabGroup">
                    <button type="button" class="btn-filter active" onclick="filtrarNivel('todos', this)">Todas</button>
                    <button type="button" class="btn-filter" onclick="filtrarNivel('Profesional', this)">🎓 Profesional</button>
                    <button type="button" class="btn-filter" onclick="filtrarNivel('Tecnologico', this)">⚙️ Tecnológico</button>
                    <button type="button" class="btn-filter highlight" onclick="filtrarDisponibilidad('1', this)">✅ Solo Disponibles</button>
                </div>

                <%-- Tarjetas de Ideas del Banco --%>
                <div id="contenedorIdeas" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 1.25rem;">
                    <c:forEach var="idea" items="${listaIdeas}">
                        <c:set var="propNom" value="${not empty idea.proponente ? idea.proponente : (idea.proponente_nom += ' ' += idea.proponente_ape)}" />
                        <div class="card idea-card" 
                             data-id="${idea.id}"
                             data-codigo="${idea.codigo}"
                             data-titulo="${fn:escapeXml(idea.titulo)}"
                             data-nivel="${idea.tipo_nivel}"
                             data-modalidad="${idea.tipo_modalidad}"
                             data-linea="${idea.linea_investigacion}"
                             data-proponente="${fn:escapeXml(propNom)}"
                             data-disponible="${idea.disponible}"
                             data-search="${fn:toLowerCase(idea.codigo)} ${fn:toLowerCase(idea.titulo)} ${fn:toLowerCase(idea.linea_investigacion)} ${fn:toLowerCase(propNom)}"
                             style="display: flex; flex-direction: column; justify-content: space-between; border-color: ${idea.disponible == 1 ? 'var(--border-green)' : 'var(--border-light)'};">
                            
                            <div>
                                <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 0.5rem; margin-bottom: 0.75rem;">
                                    <span style="font-family: monospace; font-size: 0.78rem; font-weight: 700; background: var(--primary-100); color: var(--primary-800); padding: 0.2rem 0.55rem; border-radius: var(--radius-sm);">
                                        ${idea.codigo}
                                    </span>
                                    <c:choose>
                                        <c:when test="${idea.disponible == 1 or idea.disponible == '1'}">
                                            <span class="badge badge-approved" style="font-size: 0.75rem;">
                                                ● Disponible
                                            </span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge" style="background: #e2e8f0; color: #475569; font-size: 0.75rem;">
                                                🔒 Asignada
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </div>

                                <h4 style="font-size: 1.05rem; color: var(--primary-dark); margin: 0 0 0.5rem; line-height: 1.35;">
                                    ${idea.titulo}
                                </h4>

                                <div style="display: flex; gap: 0.4rem; flex-wrap: wrap; margin-bottom: 0.85rem;">
                                    <span class="badge" style="background: #f1f5f9; color: #334155; font-size: 0.72rem;">${idea.tipo_nivel}</span>
                                    <span class="badge" style="background: #f0fdf4; color: #166534; font-size: 0.72rem;">${idea.tipo_modalidad}</span>
                                    <c:if test="${not empty idea.linea_investigacion}">
                                        <span class="badge" style="background: #eff6ff; color: #1e40af; font-size: 0.72rem;">${idea.linea_investigacion}</span>
                                    </c:if>
                                </div>

                                <p style="font-size: 0.84rem; color: var(--text-muted); line-height: 1.45; margin-bottom: 0.85rem;">
                                    ${idea.descripcion}
                                </p>

                                <div style="background: #f8fafc; border-left: 3px solid var(--primary-500); padding: 0.65rem 0.85rem; border-radius: 0 var(--radius-sm) var(--radius-sm) 0; margin-bottom: 1rem;">
                                    <strong style="font-size: 0.76rem; color: #475569; text-transform: uppercase;">Objetivo General:</strong>
                                    <p style="font-size: 0.82rem; color: var(--text-main); margin: 0.25rem 0 0; line-height: 1.4;">
                                        ${idea.objetivo_general}
                                    </p>
                                </div>
                            </div>

                            <div style="padding-top: 0.85rem; border-top: 1px solid var(--border-light); display: flex; align-items: center; justify-content: space-between; gap: 0.5rem; flex-wrap: wrap;">
                                <div style="font-size: 0.8rem; color: var(--text-muted);">
                                    <span>👨‍🏫 Proponente:</span>
                                    <strong style="color: var(--text-main);">${propNom}</strong>
                                </div>

                                <div>
                                    <c:choose>
                                        <c:when test="${idea.disponible == 1 or idea.disponible == '1'}">
                                            <button type="button" class="btn btn-primary btn-sm" onclick="abrirModalSeleccionar('${idea.id}', '${fn:escapeXml(idea.codigo)}', '${fn:escapeXml(idea.titulo)}', '${idea.tipo_nivel}', '${idea.tipo_modalidad}', '${fn:escapeXml(idea.linea_investigacion)}', '${fn:escapeXml(propNom)}', '${fn:escapeXml(idea.objetivo_general)}')">
                                                ✨ Seleccionar esta Idea
                                            </button>
                                        </c:when>
                                        <c:otherwise>
                                            <span style="font-size: 0.8rem; color: #94a3b8; font-style: italic;">
                                                No disponible
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                            </div>

                        </div>
                    </c:forEach>
                </div>
            </div>
        </div>

    </div>

    <%-- MODAL INTERACTIVO: SELECCIONAR IDEA DEL BANCO Y ADJUNTAR PAGO --%>
    <div id="modalSeleccionarIdea" class="modal-overlay" style="display: none;">
        <div class="modal-box" style="max-width: 640px; max-height: 90vh; overflow-y: auto;">
            <div class="modal-header" style="background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); border-bottom: 1px solid var(--border-green);">
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                    <span style="font-size: 1.35rem;">✨</span>
                    <div>
                        <h3 style="font-size: 1.15rem; color: var(--primary-900); margin: 0;">Postular con Idea del Banco</h3>
                        <small style="color: var(--primary-700); font-weight: 600;">Inscripción oficial a la Fase 1 &bull; Turno Comité</small>
                    </div>
                </div>
                <button type="button" class="modal-close-btn" onclick="cerrarModal('modalSeleccionarIdea')">&times;</button>
            </div>

            <form action="proyecto.jsp" method="POST">
                <input type="hidden" name="accion" value="inscribir">
                <input type="hidden" name="tipo_idea" value="Banco">
                <input type="hidden" id="modal_banco_id" name="banco_id" value="">
                <input type="hidden" id="modal_titulo" name="titulo" value="">
                <input type="hidden" id="modal_tipo_nivel" name="tipo_nivel" value="">
                <input type="hidden" id="modal_tipo_modalidad" name="tipo_modalidad" value="">
                <input type="hidden" id="modal_linea" name="linea_investigacion" value="">
                <input type="hidden" id="modal_objetivo" name="objetivo_general" value="">
                <input type="hidden" id="modal_descripcion" name="descripcion" value="">

                <div class="modal-body" style="padding: 1.5rem;">
                    
                    <div style="background: var(--primary-50); border: 1px solid var(--border-green); border-radius: var(--radius-md); padding: 1rem 1.15rem; margin-bottom: 1.25rem;">
                        <span id="modal_badge_codigo" style="font-family: monospace; font-size: 0.75rem; font-weight: 700; background: var(--primary-200); color: var(--primary-900); padding: 0.15rem 0.45rem; border-radius: var(--radius-sm);">
                            BAN-XXXX
                        </span>
                        <h4 id="modal_display_titulo" style="font-size: 1rem; color: var(--primary-900); margin: 0.4rem 0 0.5rem; line-height: 1.35;">
                            ...
                        </h4>
                        <div style="font-size: 0.8rem; color: var(--text-muted); display: flex; gap: 1rem; flex-wrap: wrap;">
                            <span>🎓 Nivel: <strong id="modal_display_nivel" style="color: var(--text-main);">...</strong></span>
                            <span>⚙️ Modalidad: <strong id="modal_display_modalidad" style="color: var(--text-main);">...</strong></span>
                            <span>👨‍🏫 Proponente: <strong id="modal_display_proponente" style="color: var(--text-main);">...</strong></span>
                        </div>
                    </div>

                    <div class="form-grid" style="margin-bottom: 1rem;">
                        <div class="form-group">
                            <label for="modal_es_pareja">Modalidad de Estudiantes:</label>
                            <select id="modal_es_pareja" name="es_pareja" class="form-control" onchange="toggleSegundoIntegranteModal()" required>
                                <option value="0">Individual (1 Estudiante)</option>
                                <option value="1">En Pareja (2 Estudiantes)</option>
                            </select>
                        </div>
                        <div id="modalBoxSegundo" class="form-group" style="display: none;">
                            <label for="modal_segundo_doc">Documento del 2do Estudiante:</label>
                            <input type="text" id="modal_segundo_doc" name="segundo_integrante_doc" class="form-control" placeholder="C.C. o T.I. del compañero">
                        </div>
                    </div>

                    <div class="form-group" style="margin-bottom: 1.25rem;">
                        <label for="modal_soporte_pago_url">
                            Enlace del Comprobante de Pago (RF-EST-04 - Obligatorio): <span style="color: #dc2626;">*</span>
                        </label>
                        <input type="text" 
                               id="modal_soporte_pago_url" 
                               name="soporte_pago_url" 
                               class="form-control" 
                               placeholder="Pega aquí cualquier enlace: Google Drive, OneDrive, Dropbox, Web..." 
                               required>
                        <small style="color: var(--text-muted); font-size: 0.78rem; display: block; margin-top: 0.35rem;">
                            📎 Acepta cualquier enlace: Google Drive, OneDrive, Dropbox, institucional o web con permisos de lectura.
                        </small>
                    </div>

                    <div style="background: #fffbeb; border: 1px solid #fde68a; border-radius: var(--radius-sm); padding: 0.75rem 1rem; font-size: 0.8rem; color: #92400e; line-height: 1.45;">
                        📌 Al postular con esta idea, pasará a estar <strong>reservada</strong> para tu proyecto y entrará directamente a <strong>Fase 1 (Turno del Comité Curricular)</strong> para la asignación oficial de tu Director.
                    </div>

                </div>

                <div class="modal-footer" style="padding: 1rem 1.5rem; background: var(--bg-light); border-top: 1px solid var(--border-light); display: flex; justify-content: flex-end; gap: 0.75rem;">
                    <button type="button" class="btn btn-outline" onclick="cerrarModal('modalSeleccionarIdea')">Cancelar</button>
                    <button type="submit" class="btn btn-primary" style="padding: 0.65rem 1.5rem;">
                        🚀 Confirmar y Postular Proyecto
                    </button>
                </div>
            </form>
        </div>
    </div>

    <%-- MODAL PARA ACTUALIZAR ENLACE DE PAGO DE PROPUESTA PENDIENTE --%>
    <div id="modalActualizarPagoPropuesta" class="modal-overlay" style="display: none;">
        <div class="modal-box" style="max-width: 500px;">
            <div class="modal-header">
                <h3 style="font-size: 1.15rem; color: var(--primary-dark); margin: 0;">Actualizar Enlace de Pago</h3>
                <button type="button" class="modal-close-btn" onclick="cerrarModal('modalActualizarPagoPropuesta')">&times;</button>
            </div>
            <form action="banco.jsp" method="POST">
                <input type="hidden" name="accion" value="actualizar_pago_propuesta">
                <input type="hidden" id="modalActPropId" name="propuesta_id" value="">
                
                <div class="modal-body" style="padding: 1.5rem;">
                    <div class="form-group">
                        <label for="nuevo_soporte_pago_url">Nuevo Enlace del Comprobante de Pago:</label>
                        <input type="text" id="nuevo_soporte_pago_url" name="nuevo_soporte_pago_url" class="form-control" placeholder="Pega aquí cualquier enlace: Drive, OneDrive, etc." required>
                        <small style="color: var(--text-muted); font-size: 0.78rem; display: block; margin-top: 0.35rem;">
                            Acepta cualquier enlace: Google Drive, OneDrive, Dropbox, institucional o web.
                        </small>
                    </div>
                </div>

                <div class="modal-footer" style="padding: 1rem 1.5rem; background: var(--bg-light); border-top: 1px solid var(--border-light); display: flex; justify-content: flex-end; gap: 0.75rem;">
                    <button type="button" class="btn btn-outline" onclick="cerrarModal('modalActualizarPagoPropuesta')">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Guardar Enlace</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function toggleSegundoDocEstudiante(sel) {
            const box = document.getElementById('boxSegundoDoc');
            if (sel.value === '1') {
                box.style.display = 'block';
                document.getElementById('segundo_integrante_doc').required = true;
            } else {
                box.style.display = 'none';
                document.getElementById('segundo_integrante_doc').required = false;
            }
        }

        function abrirModalActualizarPago(id, enlaceActual) {
            document.getElementById('modalActPropId').value = id;
            document.getElementById('nuevo_soporte_pago_url').value = enlaceActual || '';
            abrirModal('modalActualizarPagoPropuesta');
        }

        function abrirModalSeleccionar(id, codigo, titulo, nivel, modalidad, linea, prop, obj) {
            document.getElementById('modal_banco_id').value = id;
            document.getElementById('modal_titulo').value = titulo;
            document.getElementById('modal_tipo_nivel').value = nivel;
            document.getElementById('modal_tipo_modalidad').value = modalidad;
            document.getElementById('modal_linea').value = linea;
            document.getElementById('modal_objetivo').value = obj;

            document.getElementById('modal_badge_codigo').innerText = codigo;
            document.getElementById('modal_display_titulo').innerText = titulo;
            document.getElementById('modal_display_nivel').innerText = nivel;
            document.getElementById('modal_display_modalidad').innerText = modalidad;
            document.getElementById('modal_display_proponente').innerText = prop;

            abrirModal('modalSeleccionarIdea');
        }

        function toggleSegundoIntegranteModal() {
            const sel = document.getElementById('modal_es_pareja');
            const box = document.getElementById('modalBoxSegundo');
            box.style.display = sel.value === '1' ? 'block' : 'none';
        }

        function filtrarIdeas() {
            const query = document.getElementById('buscadorIdeas').value.toLowerCase().trim();
            const cards = document.querySelectorAll('.idea-card');
            cards.forEach(card => {
                const searchData = card.getAttribute('data-search') || '';
                card.style.display = searchData.includes(query) ? '' : 'none';
            });
        }

        function filtrarNivel(nivel, btn) {
            document.querySelectorAll('#tabGroup .btn-filter').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            const cards = document.querySelectorAll('.idea-card');
            cards.forEach(card => {
                const cardNivel = card.getAttribute('data-nivel');
                card.style.display = (nivel === 'todos' || cardNivel === nivel) ? '' : 'none';
            });
        }

        function filtrarDisponibilidad(disp, btn) {
            document.querySelectorAll('#tabGroup .btn-filter').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            const cards = document.querySelectorAll('.idea-card');
            cards.forEach(card => {
                const cardDisp = card.getAttribute('data-disponible');
                card.style.display = (cardDisp === disp) ? '' : 'none';
            });
        }
    </script>

    <style>
        .btn-filter {
            background: #ffffff;
            border: 1px solid var(--border-light);
            padding: 0.45rem 0.9rem;
            border-radius: var(--radius-sm);
            font-size: 0.82rem;
            cursor: pointer;
            transition: var(--transition);
        }
        .btn-filter:hover {
            border-color: var(--primary-400);
            background: var(--primary-50);
        }
        .btn-filter.active {
            background: var(--primary-600);
            color: #ffffff;
            border-color: var(--primary-600);
            font-weight: 600;
        }
        .btn-filter.highlight {
            border-color: var(--primary-400);
            color: var(--primary-800);
        }
    </style>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

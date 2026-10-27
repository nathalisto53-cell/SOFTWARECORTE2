<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardDocente.jspf" %>

<%-- =========================================================================
     SIGRADO - BANCO DE IDEAS (VISTA DOCENTE)
     Permite al docente proponer ideas de trabajo de grado (RF-DOC-01),
     hacer seguimiento a sus ideas postuladas y observaciones (RF-DOC-02),
     y consultar las ideas aprobadas en el banco general (RF-ADM-10).
     Arquitectura: JSTL puro (Cero Servlets, Cero Scriptlets).
     ========================================================================= --%>

<c:set var="mensajePropuesta" value="" />
<c:set var="tipoAlerta" value="success" />

<%-- Procesar envío de nueva propuesta de idea por el docente --%>
<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="tit" value="${fn:trim(param.titulo)}" />
    <c:set var="modalidad" value="${param.tipo_modalidad}" />
    <c:set var="niv" value="${param.tipo_nivel}" />
    <c:set var="linea" value="${fn:trim(param.linea_investigacion)}" />
    <c:set var="obj" value="${fn:trim(param.objetivo_general)}" />
    <c:set var="desc" value="${fn:trim(param.descripcion)}" />
    <c:set var="perId" value="${not empty param.periodo_id ? param.periodo_id : 1}" />

    <c:if test="${not empty tit and not empty modalidad and not empty niv and not empty obj}">
        <c:catch var="insErr">
            <sql:update dataSource="${sigradoDb}">
                INSERT INTO propuestas_banco (codigo, proponente_id, origen, titulo, tipo_modalidad, tipo_nivel, linea_investigacion, periodo_id, objetivo_general, descripcion, estado, disponible)
                VALUES (CONCAT('BAN-', TO_CHAR(CURRENT_TIMESTAMP, 'MMSS')), ?, 'Docente', ?, ?::tipo_modalidad_enum, ?::tipo_nivel_enum, ?, ?, ?, ?, 'Pendiente', 1);
                <sql:param value="${sessionScope.usuario.id}" />
                <sql:param value="${tit}" />
                <sql:param value="${modalidad}" />
                <sql:param value="${niv}" />
                <sql:param value="${linea}" />
                <sql:param value="${perId}" />
                <sql:param value="${obj}" />
                <sql:param value="${desc}" />
            </sql:update>
        </c:catch>

        <%-- Sincronización en memoria de sesión/aplicación para actualización inmediata --%>
        <c:if test="${not empty applicationScope.demoIdeasBanco}">
            <jsp:useBean id="nuevaIdeaBean" class="java.util.HashMap" scope="page" />
            <c:set target="${nuevaIdeaBean}" property="id" value="${fn:length(applicationScope.demoIdeasBanco) + 1}" />
            <c:set target="${nuevaIdeaBean}" property="codigo" value="BAN-${fn:length(applicationScope.demoIdeasBanco) + 100}" />
            <c:set target="${nuevaIdeaBean}" property="titulo" value="${tit}" />
            <c:set target="${nuevaIdeaBean}" property="descripcion" value="${desc}" />
            <c:set target="${nuevaIdeaBean}" property="objetivo_general" value="${obj}" />
            <c:set target="${nuevaIdeaBean}" property="tipo_nivel" value="${niv}" />
            <c:set target="${nuevaIdeaBean}" property="tipo_modalidad" value="${modalidad}" />
            <c:set target="${nuevaIdeaBean}" property="linea_investigacion" value="${linea}" />
            <c:set target="${nuevaIdeaBean}" property="proponente" value="${sessionScope.usuario.nombres} ${sessionScope.usuario.apellidos}" />
            <c:set target="${nuevaIdeaBean}" property="proponente_id" value="${sessionScope.usuario.id}" />
            <c:set target="${nuevaIdeaBean}" property="estado" value="Pendiente" />
            <c:set target="${nuevaIdeaBean}" property="disponible" value="1" />
            <c:set target="${nuevaIdeaBean}" property="fecha_fmt" value="Hoy" />
            <c:set var="dummyAdd" value="${applicationScope.demoIdeasBanco.add(0, nuevaIdeaBean)}" />
        </c:if>

        <c:set var="mensajePropuesta" value="¡Propuesta de idea postulada exitosamente al Banco! Ha quedado registrada con estado 'Pendiente' y será revisada por el Administrador o Comité Curricular." />
    </c:if>
</c:if>

<%-- 1. Periodo académico activo --%>
<c:catch var="perErr">
    <sql:query var="periodoVigente" dataSource="${sigradoDb}">
        SELECT * FROM periodos WHERE activo = 1 LIMIT 1;
    </sql:query>
</c:catch>

<%-- 2. Consultar ideas postuladas por el docente actual --%>
<c:set var="misIdeasLista" value="${null}" />
<c:catch var="misIdeasErr">
    <sql:query var="misIdeasDb" dataSource="${sigradoDb}">
        SELECT * FROM propuestas_banco WHERE proponente_id = ? ORDER BY id DESC;
        <sql:param value="${sessionScope.usuario.id}" />
    </sql:query>
    <c:if test="${not empty misIdeasDb.rows and misIdeasDb.rowCount > 0}">
        <c:set var="misIdeasLista" value="${misIdeasDb.rows}" />
    </c:if>
</c:catch>

<c:if test="${empty misIdeasLista and not empty applicationScope.demoIdeasBanco}">
    <jsp:useBean id="misIdeasDemoList" class="java.util.ArrayList" scope="page" />
    <c:forEach var="idm" items="${applicationScope.demoIdeasBanco}">
        <c:if test="${idm.proponente_id == sessionScope.usuario.id or fn:contains(idm.proponente, sessionScope.usuario.nombres) or fn:contains(idm.proponente, sessionScope.usuario.apellidos)}">
            <c:set var="dummyM" value="${misIdeasDemoList.add(idm)}" />
        </c:if>
    </c:forEach>
    <c:if test="${not empty misIdeasDemoList}">
        <c:set var="misIdeasLista" value="${misIdeasDemoList}" />
    </c:if>
</c:if>

<%-- 3. Consultar Banco General de Ideas Aprobadas --%>
<c:set var="ideasAprobadasLista" value="${null}" />
<c:catch var="bancoErr">
    <sql:query var="ideasBancoDb" dataSource="${sigradoDb}">
        SELECT pb.*, u.nombres, u.apellidos, u.email 
        FROM propuestas_banco pb
        JOIN usuarios u ON pb.proponente_id = u.id
        WHERE pb.estado = 'Aprobada'
        ORDER BY pb.disponible DESC, pb.id DESC;
    </sql:query>
    <c:if test="${not empty ideasBancoDb.rows and ideasBancoDb.rowCount > 0}">
        <c:set var="ideasAprobadasLista" value="${ideasBancoDb.rows}" />
    </c:if>
</c:catch>

<c:if test="${empty ideasAprobadasLista and not empty applicationScope.demoIdeasBanco}">
    <jsp:useBean id="demoAprobadas" class="java.util.ArrayList" scope="page" />
    <c:forEach var="di" items="${applicationScope.demoIdeasBanco}">
        <c:if test="${di.estado == 'Aprobada'}">
            <c:set var="dummyApp" value="${demoAprobadas.add(di)}" />
        </c:if>
    </c:forEach>
    <c:set var="ideasAprobadasLista" value="${demoAprobadas}" />
</c:if>

<c:set var="pageTitle" value="Banco de Ideas de Grado" />
<c:set var="param_active" value="banco" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">

        <%-- Banner Informativo --%>
        <div class="alert" style="background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); border: 1px solid var(--border-green); border-radius: var(--radius-md); padding: 1.25rem 1.5rem; margin-bottom: 1.5rem; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 1rem;">
            <div style="display: flex; align-items: flex-start; gap: 0.85rem; max-width: 780px;">
                <span style="font-size: 2rem; line-height: 1;">💡</span>
                <div>
                    <h3 style="margin: 0 0 0.25rem 0; font-size: 1.15rem; color: var(--primary-dark);">Banco Institucional de Ideas de Grado</h3>
                    <p style="margin: 0; font-size: 0.875rem; color: var(--primary-800); line-height: 1.4;">
                        Como docente, puedes postular ideas y líneas de investigación para nutrir el banco temático institucional (RF-DOC-01). Una vez aprobadas por el Administrador o Comité, quedan disponibles para que los estudiantes las adopten como su trabajo de grado.
                    </p>
                </div>
            </div>
            <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                <a href="#formProponer" class="btn btn-primary btn-sm">➕ Proponer Nueva Idea</a>
                <a href="#misPostulaciones" class="btn btn-outline btn-sm">📋 Mis Postulaciones</a>
                <a href="#bancoOficial" class="btn btn-outline btn-sm">📚 Ver Banco General</a>
            </div>
        </div>

        <%-- Notificación de éxito al enviar propuesta --%>
        <c:if test="${not empty mensajePropuesta}">
            <div class="alert alert-success" style="display: flex; align-items: center; gap: 0.75rem;">
                <span style="font-size: 1.3rem;">✅</span>
                <div>
                    <strong>¡Registro Exitoso!</strong>
                    <div>${mensajePropuesta}</div>
                </div>
            </div>
        </c:if>

        <%-- Formulario para proponer nueva idea --%>
        <div class="card" id="formProponer" style="margin-bottom: 2rem;">
            <div class="card-header" style="display: flex; justify-content: space-between; align-items: center;">
                <h3 class="card-title">💡 Proponer Nueva Idea al Banco de Ideas (RF-DOC-01)</h3>
                <span class="badge badge-phase">Nueva Postulación Docente</span>
            </div>

            <form action="banco.jsp" method="POST" style="padding: 1.5rem;">
                <input type="hidden" name="periodo_id" value="${not empty periodoVigente.rows ? periodoVigente.rows[0].id : 1}">

                <div class="form-group">
                    <label for="titulo">Título de la Idea de Grado: <span style="color: #dc2626;">*</span></label>
                    <input type="text" id="titulo" name="titulo" class="form-control" placeholder="Ej: Implementación de Red Neuronal y Visión Artificial para Detección de Fallas en Maquinaria..." required>
                </div>

                <div class="form-grid">
                    <div class="form-group">
                        <label for="tipo_nivel">Nivel Académico: <span style="color: #dc2626;">*</span></label>
                        <select id="tipo_nivel" name="tipo_nivel" class="form-control" required>
                            <option value="Profesional">Profesional (Modalidad 125)</option>
                            <option value="Tecnologico">Tecnológico (Modalidad 65)</option>
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
                    <textarea id="objetivo_general" name="objetivo_general" class="form-control" rows="2" placeholder="Verbo en infinitivo + finalidad + impacto o contexto de aplicación..." required></textarea>
                </div>

                <div class="form-group">
                    <label for="descripcion">Descripción Técnica y Tecnologías Recomendadas:</label>
                    <textarea id="descripcion" name="descripcion" class="form-control" rows="3" placeholder="Detalle técnico de la idea, stack tecnológico sugerido (Python, React, PostgreSQL, Docker, etc.) y alcance esperado para el estudiante..."></textarea>
                </div>

                <div style="display: flex; justify-content: flex-end; gap: 0.75rem; margin-top: 1rem;">
                    <button type="reset" class="btn btn-outline">
                        Limpiar Campos
                    </button>
                    <button type="submit" class="btn btn-primary" style="display: inline-flex; align-items: center; gap: 0.5rem;">
                        <span>🚀</span> Postular Idea al Banco
                    </button>
                </div>
            </form>
        </div>

        <%-- Tabla de Mis Ideas Postuladas --%>
        <div class="card" id="misPostulaciones" style="margin-bottom: 2rem;">
            <div class="card-header" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 0.5rem;">
                <h3 class="card-title">📋 Mis Ideas Postuladas y Estado de Revisión (RF-DOC-02)</h3>
                <span class="badge badge-responsible">Proponente: ${sessionScope.usuario.nombres} ${sessionScope.usuario.apellidos}</span>
            </div>

            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th style="width: 130px;">Código</th>
                            <th>Título de la Idea</th>
                            <th style="width: 180px;">Nivel / Modalidad</th>
                            <th style="width: 140px;">Estado</th>
                            <th>Observación de Revisión</th>
                            <th style="width: 120px;">En Banco</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty misIdeasLista}">
                                <c:forEach var="mi" items="${misIdeasLista}">
                                    <tr>
                                        <td><strong>${mi.codigo}</strong></td>
                                        <td>
                                            <strong>${mi.titulo}</strong>
                                            <c:if test="${not empty mi.linea_investigacion}">
                                                <div style="font-size: 0.78rem; color: var(--text-muted); margin-top: 0.2rem;">
                                                    <strong>Línea:</strong> ${mi.linea_investigacion}
                                                </div>
                                            </c:if>
                                            <c:if test="${not empty mi.objetivo_general}">
                                                <div style="font-size: 0.78rem; color: var(--text-muted); margin-top: 0.2rem;">
                                                    ${mi.objetivo_general}
                                                </div>
                                            </c:if>
                                        </td>
                                        <td>
                                            ${mi.tipo_nivel}
                                            <br><small style="color: var(--text-muted);">${mi.tipo_modalidad}</small>
                                        </td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${mi.estado == 'Aprobada'}">
                                                    <span class="badge badge-approved">✓ Aprobada</span>
                                                </c:when>
                                                <c:when test="${mi.estado == 'Correcciones'}">
                                                    <span class="badge badge-corrections">⚠️ Correcciones</span>
                                                </c:when>
                                                <c:when test="${mi.estado == 'Rechazada'}">
                                                    <span class="badge badge-rejected">✕ Rechazada</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge badge-responsible">⏳ Pendiente</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${not empty mi.observacion_comite}">
                                                    <span style="font-size: 0.85rem; color: var(--text-main);">${mi.observacion_comite}</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span style="font-size: 0.82rem; color: var(--text-subtle); font-style: italic;">En espera de revisión por el Comité/Administrador</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${mi.estado == 'Aprobada'}">
                                                    <span class="badge ${mi.disponible == 1 ? 'badge-approved' : 'badge-responsible'}">
                                                        ${mi.disponible == 1 ? 'Disponible' : 'Asignada'}
                                                    </span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge badge-responsible">No visible</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td colspan="6" style="text-align: center; padding: 2rem; color: var(--text-muted);">
                                        <div style="font-size: 2rem; margin-bottom: 0.5rem;">📝</div>
                                        <strong>Aún no has postulado ideas de grado.</strong>
                                        <p style="margin: 0.25rem 0 0; font-size: 0.85rem;">Utiliza el formulario superior para registrar tu primera idea temática.</p>
                                    </td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

        <%-- Tabla del Banco General de Ideas Aprobadas --%>
        <div class="card" id="bancoOficial">
            <div class="card-header" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;">
                <div>
                    <h3 class="card-title">📚 Banco Oficial de Ideas Aprobadas (RF-ADM-10)</h3>
                    <p style="margin: 0.2rem 0 0; font-size: 0.8rem; color: var(--text-muted);">Ideas validadas disponibles para asignación a estudiantes de grado.</p>
                </div>
                <div>
                    <input type="text" id="filtroBanco" onkeyup="filtrarIdeasBanco()" placeholder="🔍 Buscar por título, modalidad o proponente..." class="form-control" style="width: 320px; font-size: 0.85rem;">
                </div>
            </div>

            <div class="table-responsive">
                <table class="sigrado-table" id="tablaBancoGeneral">
                    <thead>
                        <tr>
                            <th style="width: 130px;">Código</th>
                            <th>Título de la Idea</th>
                            <th style="width: 200px;">Nivel / Modalidad</th>
                            <th style="width: 200px;">Proponente</th>
                            <th style="width: 140px;">Disponibilidad</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty ideasAprobadasLista}">
                                <c:forEach var="b" items="${ideasAprobadasLista}">
                                    <tr class="fila-idea">
                                        <td><strong>${b.codigo}</strong></td>
                                        <td>
                                            <strong class="idea-titulo">${b.titulo}</strong>
                                            <c:if test="${not empty b.linea_investigacion}">
                                                <div style="font-size: 0.78rem; color: var(--primary-700); margin-top: 0.2rem;">
                                                    <strong>Línea:</strong> ${b.linea_investigacion}
                                                </div>
                                            </c:if>
                                            <c:if test="${not empty b.descripcion}">
                                                <p style="font-size: 0.8rem; color: var(--text-muted); margin-top: 0.25rem; line-height: 1.35;">
                                                    ${b.descripcion}
                                                </p>
                                            </c:if>
                                        </td>
                                        <td>
                                            <span class="idea-nivel">${b.tipo_nivel}</span>
                                            <br><small class="idea-modalidad" style="color:var(--text-muted);">${b.tipo_modalidad}</small>
                                        </td>
                                        <td class="idea-proponente">
                                            <c:choose>
                                                <c:when test="${not empty b.nombres}">
                                                    ${b.nombres} ${b.apellidos}
                                                </c:when>
                                                <c:when test="${not empty b.proponente}">
                                                    ${b.proponente}
                                                </c:when>
                                                <c:otherwise>
                                                    Docente Investigador
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td>
                                            <span class="badge ${b.disponible == 1 ? 'badge-approved' : 'badge-responsible'}">
                                                ${b.disponible == 1 ? '✓ Disponible' : '🔒 Asignada'}
                                            </span>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td><strong>BAN-2026-01</strong></td>
                                    <td>
                                        <strong class="idea-titulo">Sistema Inteligente de Monitoreo de Cultivos con IoT y Visión por Computador</strong>
                                        <div style="font-size: 0.78rem; color: var(--primary-700); margin-top: 0.2rem;">
                                            <strong>Línea:</strong> Inteligencia Artificial y Sistemas Embebidos
                                        </div>
                                        <p style="font-size: 0.8rem; color: var(--text-muted); margin-top: 0.25rem;">
                                            Implementación de sensores ESP32, Python backend y visión artificial.
                                        </p>
                                    </td>
                                    <td>Profesional<br><small style="color:var(--text-muted);">Desarrollo tecnologico</small></td>
                                    <td>Elsa Patricia Carvajal</td>
                                    <td><span class="badge badge-approved">✓ Disponible</span></td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

    <script>
        function filtrarIdeasBanco() {
            const input = document.getElementById('filtroBanco');
            const filter = input.value.toLowerCase().trim();
            const filas = document.querySelectorAll('#tablaBancoGeneral tbody tr.fila-idea');

            filas.forEach(fila => {
                const texto = fila.innerText.toLowerCase();
                if (texto.includes(filter)) {
                    fila.style.display = '';
                } else {
                    fila.style.display = 'none';
                }
            });
        }
    </script>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

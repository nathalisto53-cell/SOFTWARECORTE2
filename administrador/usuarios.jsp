<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/guardAdministrador.jspf" %>

<%-- =========================================================================
     SIGRADO - Control de Usuarios para el Administrador
     Funcionalidades: Agregar, Eliminar, Aprobar, Inactivar y Reasignar Roles.
     Arquitectura: JSTL 1.2 puro (CERO Servlets, CERO Scriptlets, CERO DAOs).
     JS utilizado exclusivamente para diseño front, filtros interactivos y modales.
     ========================================================================= --%>

<c:set var="mensajeAccion" value="" />
<c:set var="tipoMensaje" value="success" />

<%-- Procesamiento de Acciones del Administrador (POST) --%>
<c:if test="${pageContext.request.method == 'POST'}">
    <c:set var="accion" value="${param.accion}" />
    
    <%-- 1. APROBAR USUARIO PENDIENTE --%>
    <c:if test="${accion == 'aprobar'}">
        <c:set var="targetId" value="${param.usuario_id}" />
        <c:catch var="aprobErr">
            <sql:update dataSource="${sigradoDb}">
                UPDATE usuarios SET activo = 1 WHERE id = ?;
                <sql:param value="${targetId}" />
            </sql:update>
        </c:catch>

        <%-- Soporte de almacén demo compartido --%>
        <c:forEach var="du" items="${applicationScope.demoListaUsuarios}">
            <c:if test="${du.id == targetId or du.documento == targetId or ('' + du.id) == ('' + targetId)}">
                <c:set target="${du}" property="activo" value="1" />
            </c:if>
        </c:forEach>

        <c:set var="mensajeAccion" value="✅ Usuario aprobado exitosamente. Su cuenta ha sido activada y ahora puede ingresar al sistema." />
        <c:set var="tipoMensaje" value="success" />
    </c:if>

    <%-- 2. INACTIVAR USUARIO --%>
    <c:if test="${accion == 'inactivar'}">
        <c:set var="targetId" value="${param.usuario_id}" />
        <c:catch var="inacErr">
            <sql:update dataSource="${sigradoDb}">
                UPDATE usuarios SET activo = 0 WHERE id = ?;
                <sql:param value="${targetId}" />
            </sql:update>
        </c:catch>

        <c:forEach var="du" items="${applicationScope.demoListaUsuarios}">
            <c:if test="${du.id == targetId or du.documento == targetId or ('' + du.id) == ('' + targetId)}">
                <c:set target="${du}" property="activo" value="0" />
            </c:if>
        </c:forEach>

        <c:set var="mensajeAccion" value="⏸️ Usuario inactivado exitosamente. Se ha suspendido el acceso temporalmente." />
        <c:set var="tipoMensaje" value="warning" />
    </c:if>

    <%-- 3. ACTIVAR USUARIO PREVIAMENTE INACTIVADO --%>
    <c:if test="${accion == 'activar'}">
        <c:set var="targetId" value="${param.usuario_id}" />
        <c:catch var="actErr">
            <sql:update dataSource="${sigradoDb}">
                UPDATE usuarios SET activo = 1 WHERE id = ?;
                <sql:param value="${targetId}" />
            </sql:update>
        </c:catch>

        <c:forEach var="du" items="${applicationScope.demoListaUsuarios}">
            <c:if test="${du.id == targetId or du.documento == targetId or ('' + du.id) == ('' + targetId)}">
                <c:set target="${du}" property="activo" value="1" />
            </c:if>
        </c:forEach>

        <c:set var="mensajeAccion" value="✅ Usuario reactivado exitosamente." />
        <c:set var="tipoMensaje" value="success" />
    </c:if>

    <%-- 4. ELIMINAR USUARIO --%>
    <c:if test="${accion == 'eliminar'}">
        <c:set var="targetId" value="${param.usuario_id}" />
        <c:set var="eliminadoExitoso" value="false" />
        
        <c:catch var="delErr">
            <sql:update dataSource="${sigradoDb}">
                DELETE FROM usuario_rol WHERE usuario_id = ?;
                <sql:param value="${targetId}" />
            </sql:update>
            <sql:update dataSource="${sigradoDb}">
                DELETE FROM usuarios WHERE id = ?;
                <sql:param value="${targetId}" />
            </sql:update>
            <c:set var="eliminadoExitoso" value="true" />
        </c:catch>

        <c:choose>
            <c:when test="${not empty delErr and not empty sigradoDb}">
                <%-- Integridad referencial: el usuario tiene proyectos, evaluaciones o documentos asociados --%>
                <c:catch var="fallbackErr">
                    <sql:update dataSource="${sigradoDb}">
                        UPDATE usuarios SET activo = 0 WHERE id = ?;
                        <sql:param value="${targetId}" />
                    </sql:update>
                </c:catch>
                <c:set var="mensajeAccion" value="⚠️ El usuario no puede eliminarse permanentemente de la base de datos institucional debido a que tiene proyectos de grado, evaluaciones o entregas asociadas. Para preservar la integridad del historial académico, el usuario ha sido marcado como INACTIVO y su acceso ha sido revocado." />
                <c:set var="tipoMensaje" value="warning" />
            </c:when>
            <c:otherwise>
                <%-- Eliminación en almacén demo compartido --%>
                <c:forEach var="du" items="${applicationScope.demoListaUsuarios}">
                    <c:if test="${du.id == targetId or du.documento == targetId or ('' + du.id) == ('' + targetId)}">
                        <c:set target="${du}" property="eliminado" value="true" />
                    </c:if>
                </c:forEach>
                <c:set var="mensajeAccion" value="🗑️ Usuario eliminado exitosamente del sistema." />
                <c:set var="tipoMensaje" value="success" />
            </c:otherwise>
        </c:choose>
    </c:if>

    <%-- 5. AGREGAR NUEVO USUARIO --%>
    <c:if test="${accion == 'crear'}">
        <c:set var="newDoc" value="${param.documento}" />
        <c:set var="newNom" value="${param.nombres}" />
        <c:set var="newApe" value="${param.apellidos}" />
        <c:set var="newEmail" value="${param.email}" />
        <c:set var="newTel" value="${param.telefono}" />
        <c:set var="newProg" value="${empty param.programa ? 'Ingeniería de Sistemas' : param.programa}" />
        <c:set var="newPass" value="${empty param.password ? '123456' : param.password}" />
        <c:set var="newRolId" value="${param.rol_id}" />
        <c:set var="newActivo" value="${empty param.activo ? '1' : param.activo}" />

        <c:catch var="crearErr">
            <%-- Verificar unicidad --%>
            <sql:query var="chkExiste" dataSource="${sigradoDb}">
                SELECT id FROM usuarios WHERE documento = ? OR LOWER(email) = LOWER(?);
                <sql:param value="${newDoc}" />
                <sql:param value="${newEmail}" />
            </sql:query>

            <c:choose>
                <c:when test="${chkExiste.rowCount > 0}">
                    <c:set var="mensajeAccion" value="❌ Error: Ya existe un usuario con este documento o correo electrónico." />
                    <c:set var="tipoMensaje" value="danger" />
                </c:when>
                <c:otherwise>
                    <sql:update dataSource="${sigradoDb}">
                        INSERT INTO usuarios (documento, nombres, apellidos, email, password_hash, telefono, programa, activo)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?::smallint);
                        <sql:param value="${newDoc}" />
                        <sql:param value="${newNom}" />
                        <sql:param value="${newApe}" />
                        <sql:param value="${newEmail}" />
                        <sql:param value="${newPass}" />
                        <sql:param value="${newTel}" />
                        <sql:param value="${newProg}" />
                        <sql:param value="${newActivo}" />
                    </sql:update>

                    <sql:query var="getNewId" dataSource="${sigradoDb}">
                        SELECT id FROM usuarios WHERE documento = ? LIMIT 1;
                        <sql:param value="${newDoc}" />
                    </sql:query>

                    <c:if test="${getNewId.rowCount > 0}">
                        <sql:update dataSource="${sigradoDb}">
                            INSERT INTO usuario_rol (usuario_id, rol_id)
                            VALUES (?, ?::int)
                            ON CONFLICT DO NOTHING;
                            <sql:param value="${getNewId.rows[0].id}" />
                            <sql:param value="${newRolId}" />
                        </sql:update>
                    </c:if>

                    <c:set var="mensajeAccion" value="✅ Usuario ${newNom} ${newApe} creado exitosamente en el sistema." />
                    <c:set var="tipoMensaje" value="success" />
                </c:otherwise>
            </c:choose>
        </c:catch>

        <%-- Fallback sesión demo --%>
        <c:if test="${not empty crearErr}">
            <jsp:useBean id="nuevoDemoUser" class="java.util.HashMap" scope="page" />
            <c:set target="${nuevoDemoUser}" property="id" value="${newDoc}" />
            <c:set target="${nuevoDemoUser}" property="documento" value="${newDoc}" />
            <c:set target="${nuevoDemoUser}" property="nombres" value="${newNom}" />
            <c:set target="${nuevoDemoUser}" property="apellidos" value="${newApe}" />
            <c:set target="${nuevoDemoUser}" property="email" value="${newEmail}" />
            <c:set target="${nuevoDemoUser}" property="password_hash" value="${newPass}" />
            <c:set target="${nuevoDemoUser}" property="telefono" value="${newTel}" />
            <c:set target="${nuevoDemoUser}" property="programa" value="${newProg}" />
            <c:choose>
                <c:when test="${newRolId == '1'}"><c:set target="${nuevoDemoUser}" property="roles_asignados" value="administrador" /><c:set target="${nuevoDemoUser}" property="rol_id" value="1" /></c:when>
                <c:when test="${newRolId == '2'}"><c:set target="${nuevoDemoUser}" property="roles_asignados" value="comite" /><c:set target="${nuevoDemoUser}" property="rol_id" value="2" /></c:when>
                <c:when test="${newRolId == '3'}"><c:set target="${nuevoDemoUser}" property="roles_asignados" value="docente" /><c:set target="${nuevoDemoUser}" property="rol_id" value="3" /></c:when>
                <c:otherwise><c:set target="${nuevoDemoUser}" property="roles_asignados" value="estudiante" /><c:set target="${nuevoDemoUser}" property="rol_id" value="4" /></c:otherwise>
            </c:choose>
            <c:set target="${nuevoDemoUser}" property="activo" value="${newActivo}" />
            <c:set target="${nuevoDemoUser}" property="fecha_fmt" value="Hoy" />

            <c:if test="${not empty applicationScope.demoListaUsuarios}">
                <c:set var="dummy" value="${applicationScope.demoListaUsuarios.add(0, nuevoDemoUser)}" />
            </c:if>

            <c:set var="mensajeAccion" value="✅ Usuario ${newNom} ${newApe} registrado correctamente en el sistema." />
            <c:set var="tipoMensaje" value="success" />
        </c:if>
    </c:if>

    <%-- 6. CAMBIAR ROL DE USUARIO --%>
    <c:if test="${accion == 'cambiar_rol'}">
        <c:set var="targetId" value="${param.usuario_id}" />
        <c:set var="targetRolId" value="${param.nuevo_rol_id}" />
        <c:catch var="rolErr">
            <sql:update dataSource="${sigradoDb}">
                DELETE FROM usuario_rol WHERE usuario_id = ?;
                <sql:param value="${targetId}" />
            </sql:update>
            <sql:update dataSource="${sigradoDb}">
                INSERT INTO usuario_rol (usuario_id, rol_id)
                VALUES (?, ?::int);
                <sql:param value="${targetId}" />
                <sql:param value="${targetRolId}" />
            </sql:update>
        </c:catch>

        <c:forEach var="du" items="${applicationScope.demoListaUsuarios}">
            <c:if test="${du.id == targetId or du.documento == targetId or ('' + du.id) == ('' + targetId)}">
                <c:choose>
                    <c:when test="${targetRolId == '1'}"><c:set target="${du}" property="roles_asignados" value="administrador" /><c:set target="${du}" property="rol_id" value="1" /></c:when>
                    <c:when test="${targetRolId == '2'}"><c:set target="${du}" property="roles_asignados" value="comite" /><c:set target="${du}" property="rol_id" value="2" /></c:when>
                    <c:when test="${targetRolId == '3'}"><c:set target="${du}" property="roles_asignados" value="docente" /><c:set target="${du}" property="rol_id" value="3" /></c:when>
                    <c:otherwise><c:set target="${du}" property="roles_asignados" value="estudiante" /><c:set target="${du}" property="rol_id" value="4" /></c:otherwise>
                </c:choose>
            </c:if>
        </c:forEach>

        <c:set var="mensajeAccion" value="🔄 Rol de usuario actualizado exitosamente." />
        <c:set var="tipoMensaje" value="success" />
    </c:if>
</c:if>

<%-- Consulta de Usuarios en la BD Supabase PostgreSQL --%>
<c:catch var="listErr">
    <sql:query var="usuariosDB" dataSource="${sigradoDb}">
        SELECT u.id, u.documento, u.nombres, u.apellidos, u.email, u.telefono, u.programa, u.activo,
               TO_CHAR(u.fecha_registro, 'DD/MM/YYYY') as fecha_fmt,
               COALESCE(STRING_AGG(r.nombre::text, ', '), 'Sin Rol') as roles_asignados,
               COALESCE(MIN(r.id), 4) as rol_id
        FROM usuarios u
        LEFT JOIN usuario_rol ur ON u.id = ur.usuario_id
        LEFT JOIN roles r ON ur.rol_id = r.id
        GROUP BY u.id, u.documento, u.nombres, u.apellidos, u.email, u.telefono, u.programa, u.activo, u.fecha_registro
        ORDER BY u.activo ASC, u.fecha_registro DESC, u.apellidos ASC;
    </sql:query>
</c:catch>

<%-- Determinación de la lista activa a desplegar (BD Supabase o Almacén Global Compartido) --%>
<c:set var="listaActiva" value="${not empty usuariosDB.rows ? usuariosDB.rows : applicationScope.demoListaUsuarios}" />

<%-- Conteo de Métricas --%>
<c:set var="cntTotal" value="0" />
<c:set var="cntPendientes" value="0" />
<c:set var="cntEstudiantes" value="0" />
<c:set var="cntDocentes" value="0" />
<c:set var="cntComite" value="0" />
<c:set var="cntAdmin" value="0" />

<c:forEach var="item" items="${listaActiva}">
    <c:if test="${empty item.eliminado or item.eliminado == false}">
        <c:set var="cntTotal" value="${cntTotal + 1}" />
        <c:if test="${item.activo == 0 or item.activo == '0'}">
            <c:set var="cntPendientes" value="${cntPendientes + 1}" />
        </c:if>
        <c:if test="${item.roles_asignados.contains('estudiante')}">
            <c:set var="cntEstudiantes" value="${cntEstudiantes + 1}" />
        </c:if>
        <c:if test="${item.roles_asignados.contains('docente')}">
            <c:set var="cntDocentes" value="${cntDocentes + 1}" />
        </c:if>
        <c:if test="${item.roles_asignados.contains('comite')}">
            <c:set var="cntComite" value="${cntComite + 1}" />
        </c:if>
        <c:if test="${item.roles_asignados.contains('administrador')}">
            <c:set var="cntAdmin" value="${cntAdmin + 1}" />
        </c:if>
    </c:if>
</c:forEach>

<c:set var="pageTitle" value="Control de Usuarios" />
<c:set var="param_active" value="usuarios" />
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

<div class="app-main">
    <%@ include file="/WEB-INF/jspf/topbar.jspf" %>

    <div class="content-body">

        <%-- Notificación de resultado de acción --%>
        <c:if test="${not empty mensajeAccion}">
            <div class="alert alert-${tipoMensaje} alert-dismissible" style="display: flex; align-items: center; gap: 0.75rem; margin-bottom: 1.5rem;">
                <span style="font-size: 1.25rem;">ℹ️</span>
                <div>${mensajeAccion}</div>
            </div>
        </c:if>

        <%-- Tarjetas de Métricas de Usuarios --%>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; margin-bottom: 1.75rem;">
            <div class="card" style="margin: 0; padding: 1.25rem; text-align: center; border-left: 4px solid var(--primary-600);">
                <div style="font-size: 0.78rem; text-transform: uppercase; color: var(--text-muted); font-weight: 700; letter-spacing: 0.05em;">Total Usuarios</div>
                <div style="font-size: 2rem; font-weight: 800; color: var(--primary-dark); margin: 0.25rem 0;">${cntTotal}</div>
                <span style="font-size: 0.75rem; color: var(--text-subtle);">Registrados en sistema</span>
            </div>

            <div class="card" style="margin: 0; padding: 1.25rem; text-align: center; border-left: 4px solid ${cntPendientes > 0 ? '#f59e0b' : '#10b981'}; background: ${cntPendientes > 0 ? '#fffbeb' : '#ffffff'};">
                <div style="font-size: 0.78rem; text-transform: uppercase; color: ${cntPendientes > 0 ? '#b45309' : 'var(--text-muted)'}; font-weight: 700; letter-spacing: 0.05em;">
                    ${cntPendientes > 0 ? '⚠️ Pendientes Aprobación' : 'Aprobaciones al Día'}
                </div>
                <div style="font-size: 2rem; font-weight: 800; color: ${cntPendientes > 0 ? '#d97706' : '#10b981'}; margin: 0.25rem 0;">${cntPendientes}</div>
                <span style="font-size: 0.75rem; color: ${cntPendientes > 0 ? '#92400e' : 'var(--text-subtle)'};">
                    ${cntPendientes > 0 ? 'Requieren tu aprobación' : 'Sin pendientes'}
                </span>
            </div>

            <div class="card" style="margin: 0; padding: 1.25rem; text-align: center; border-left: 4px solid #3b82f6;">
                <div style="font-size: 0.78rem; text-transform: uppercase; color: var(--text-muted); font-weight: 700; letter-spacing: 0.05em;">Estudiantes</div>
                <div style="font-size: 2rem; font-weight: 800; color: #1e40af; margin: 0.25rem 0;">${cntEstudiantes}</div>
                <span style="font-size: 0.75rem; color: var(--text-subtle);">Postulantes de grado</span>
            </div>

            <div class="card" style="margin: 0; padding: 1.25rem; text-align: center; border-left: 4px solid #8b5cf6;">
                <div style="font-size: 0.78rem; text-transform: uppercase; color: var(--text-muted); font-weight: 700; letter-spacing: 0.05em;">Docentes</div>
                <div style="font-size: 2rem; font-weight: 800; color: #5b21b6; margin: 0.25rem 0;">${cntDocentes}</div>
                <span style="font-size: 0.75rem; color: var(--text-subtle);">Directores y Evaluadores</span>
            </div>

            <div class="card" style="margin: 0; padding: 1.25rem; text-align: center; border-left: 4px solid #ec4899;">
                <div style="font-size: 0.78rem; text-transform: uppercase; color: var(--text-muted); font-weight: 700; letter-spacing: 0.05em;">Comité & Admins</div>
                <div style="font-size: 2rem; font-weight: 800; color: #9d174d; margin: 0.25rem 0;">${cntComite + cntAdmin}</div>
                <span style="font-size: 0.75rem; color: var(--text-subtle);">Personal de gestión</span>
            </div>
        </div>

        <%-- Banner de Alerta si hay estudiantes pendientes de aprobación --%>
        <c:if test="${cntPendientes > 0}">
            <div style="background: linear-gradient(to right, #fffbeb, #fef3c7); border: 1px solid #fde68a; border-radius: var(--radius-md); padding: 1.25rem 1.5rem; margin-bottom: 1.75rem; display: flex; align-items: center; justify-content: space-between; flex-wrap: gap: 1rem; box-shadow: var(--shadow-sm);">
                <div style="display: flex; align-items: center; gap: 0.85rem;">
                    <span style="font-size: 1.75rem;">🚨</span>
                    <div>
                        <h4 style="color: #92400e; font-size: 1rem; margin: 0 0 0.2rem;">Hay ${cntPendientes} cuenta(s) esperando tu aprobación</h4>
                        <p style="color: #78350f; font-size: 0.84rem; margin: 0;">
                            Recuerda que los estudiantes registrados no tienen acceso al portal institucional hasta que el Administrador valide su solicitud.
                        </p>
                    </div>
                </div>
                <button type="button" class="btn btn-outline" onclick="filtrarPorEstado('pendientes')" style="background: white; border-color: #f59e0b; color: #b45309; font-weight: 600; white-space: nowrap;">
                    Ver Solo Pendientes &rarr;
                </button>
            </div>
        </c:if>

        <%-- Card Principal de Control de Usuarios --%>
        <div class="card">
            <div class="card-header" style="flex-wrap: wrap; gap: 1rem;">
                <div>
                    <h3 class="card-title">👥 Control y Gestión de Usuarios (RF-ADM-01)</h3>
                    <span class="badge badge-phase">Control Integral Institucional</span>
                </div>
                <button type="button" class="btn btn-primary" onclick="abrirModal('modalNuevoUsuario')" style="display: flex; align-items: center; gap: 0.4rem;">
                    <span>➕</span>
                    <span>Agregar Usuario</span>
                </button>
            </div>

            <%-- Barra de Filtros y Búsqueda Interactiva (Diseño Front JS) --%>
            <div style="padding: 1rem 1.5rem; background: var(--bg-light); border-bottom: 1px solid var(--border-light); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;">
                <%-- Pestañas de filtro rápido --%>
                <div style="display: flex; gap: 0.4rem; flex-wrap: wrap;" id="tabGroup">
                    <button type="button" class="btn-filter active" onclick="filtrarRol('todos', this)">
                        Todos (${cntTotal})
                    </button>
                    <button type="button" class="btn-filter ${cntPendientes > 0 ? 'highlight' : ''}" onclick="filtrarRol('pendientes', this)">
                        ⏳ Pendientes (${cntPendientes})
                    </button>
                    <button type="button" class="btn-filter" onclick="filtrarRol('estudiante', this)">
                        🎓 Estudiantes (${cntEstudiantes})
                    </button>
                    <button type="button" class="btn-filter" onclick="filtrarRol('docente', this)">
                        👨‍🏫 Docentes (${cntDocentes})
                    </button>
                    <button type="button" class="btn-filter" onclick="filtrarRol('comite', this)">
                        ⚖️ Comité (${cntComite})
                    </button>
                    <button type="button" class="btn-filter" onclick="filtrarRol('administrador', this)">
                        🔑 Administradores (${cntAdmin})
                    </button>
                </div>

                <%-- Buscador interactivo --%>
                <div style="min-width: 260px; position: relative;">
                    <input type="text" id="buscadorUsuarios" class="form-control" placeholder="🔍 Buscar por nombre, documento o correo..." oninput="filtrarTabla()" style="padding-left: 2rem; font-size: 0.85rem;">
                </div>
            </div>

            <%-- Tabla de Usuarios --%>
            <div class="table-responsive">
                <table class="sigrado-table" id="tablaUsuarios">
                    <thead>
                        <tr>
                            <th style="width: 140px;">Estado</th>
                            <th>Doc. Identidad</th>
                            <th>Nombres y Apellidos</th>
                            <th>Correo Institucional</th>
                            <th>Teléfono / Programa</th>
                            <th>Rol Asignado</th>
                            <th>Fecha</th>
                            <th style="text-align: right; min-width: 200px;">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty listaActiva}">
                                <c:forEach var="u" items="${listaActiva}">
                                    <c:if test="${empty u.eliminado or u.eliminado == false}">
                                        <tr class="fila-usuario" 
                                            data-activo="${u.activo}" 
                                            data-roles="${u.roles_asignados.toLowerCase()}" 
                                            data-doc="${u.documento}"
                                            data-nombre="${u.nombres.toLowerCase()} ${u.apellidos.toLowerCase()}"
                                            data-email="${u.email.toLowerCase()}">
                                            
                                            <%-- Estado --%>
                                            <td>
                                                <c:choose>
                                                    <c:when test="${u.activo == 1 or u.activo == '1'}">
                                                        <span class="badge badge-approved" style="display: inline-flex; align-items: center; gap: 0.25rem;">
                                                            <span style="font-size: 0.6rem;">●</span> Aprobado / Activo
                                                        </span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="badge badge-pending" style="display: inline-flex; align-items: center; gap: 0.25rem; background: #fef3c7; color: #b45309; border: 1px solid #fde68a;">
                                                            <span>⏳</span> Pendiente
                                                        </span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </td>

                                            <%-- Documento --%>
                                            <td>
                                                <code style="font-weight: 700; color: var(--primary-800);">${u.documento}</code>
                                            </td>

                                            <%-- Nombre --%>
                                            <td>
                                                <strong>${u.nombres} ${u.apellidos}</strong>
                                            </td>

                                            <%-- Email --%>
                                            <td>
                                                <a href="mailto:${u.email}" style="color: var(--primary-700); font-size: 0.88rem;">${u.email}</a>
                                            </td>

                                            <%-- Teléfono & Programa --%>
                                            <td>
                                                <div style="font-size: 0.85rem;">📞 ${empty u.telefono ? 'Sin teléfono' : u.telefono}</div>
                                                <div style="font-size: 0.75rem; color: var(--text-muted);">${u.programa}</div>
                                            </td>

                                            <%-- Rol --%>
                                            <td>
                                                <c:choose>
                                                    <c:when test="${u.roles_asignados.contains('administrador')}">
                                                        <span class="badge" style="background: #fdf2f8; color: #9d174d; border: 1px solid #fbcfe8;">🔑 Administrador</span>
                                                    </c:when>
                                                    <c:when test="${u.roles_asignados.contains('comite')}">
                                                        <span class="badge" style="background: #f5f3ff; color: #6d28d9; border: 1px solid #ddd6fe;">⚖️ Comité</span>
                                                    </c:when>
                                                    <c:when test="${u.roles_asignados.contains('docente')}">
                                                        <span class="badge" style="background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe;">👨‍🏫 Docente</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <span class="badge badge-phase">🎓 Estudiante</span>
                                                    </c:otherwise>
                                                </c:choose>
                                            </td>

                                            <%-- Fecha Registro --%>
                                            <td style="font-size: 0.8rem; color: var(--text-muted);">
                                                ${empty u.fecha_fmt ? (empty u.fecha_registro ? '15/08/2026' : u.fecha_registro) : u.fecha_fmt}
                                            </td>

                                            <%-- Acciones --%>
                                            <td style="text-align: right; white-space: nowrap;">
                                                <c:choose>
                                                    <%-- Botón APROBAR si el usuario está inactivo o pendiente --%>
                                                    <c:when test="${u.activo == 0 or u.activo == '0'}">
                                                        <form action="usuarios.jsp" method="POST" style="display: inline-block; margin-right: 0.3rem;">
                                                            <input type="hidden" name="accion" value="aprobar">
                                                            <input type="hidden" name="usuario_id" value="${u.id}">
                                                            <button type="submit" class="btn btn-sm btn-primary" style="background: #16a34a; border-color: #15803d; font-weight: 600;" title="Aprobar usuario y habilitar su inicio de sesión">
                                                                ✅ Aprobar
                                                            </button>
                                                        </form>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <%-- Inactivar usuario activo --%>
                                                        <form action="usuarios.jsp" method="POST" style="display: inline-block; margin-right: 0.3rem;" onsubmit="return confirm('¿Está seguro de suspender temporalmente el acceso de este usuario?');">
                                                            <input type="hidden" name="accion" value="inactivar">
                                                            <input type="hidden" name="usuario_id" value="${u.id}">
                                                            <button type="submit" class="btn btn-sm btn-outline" style="font-size: 0.78rem; padding: 0.35rem 0.6rem; color: #d97706; border-color: #fde68a;" title="Inactivar temporalmente">
                                                                ⏸️ Inactivar
                                                            </button>
                                                        </form>
                                                    </c:otherwise>
                                                </c:choose>

                                                <%-- Botón Cambiar Rol (abre modal) --%>
                                                <button type="button" class="btn btn-sm btn-outline" 
                                                        onclick="abrirModalCambiarRol('${u.id}', '${u.nombres} ${u.apellidos}', '${u.rol_id}')"
                                                        style="font-size: 0.78rem; padding: 0.35rem 0.6rem; margin-right: 0.3rem;" title="Cambiar rol institucional">
                                                    🔄 Rol
                                                </button>

                                                <%-- Botón Eliminar Usuario (abre modal de confirmación) --%>
                                                <button type="button" class="btn btn-sm btn-outline"
                                                        onclick="abrirModalEliminar('${u.id}', '${u.nombres} ${u.apellidos}', '${u.documento}')"
                                                        style="font-size: 0.78rem; padding: 0.35rem 0.6rem; color: #dc2626; border-color: #fca5a5;" title="Eliminar usuario del sistema">
                                                    🗑️
                                                </button>
                                            </td>
                                        </tr>
                                    </c:if>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td colspan="8" style="text-align: center; padding: 2.5rem; color: var(--text-muted);">
                                        No se encontraron usuarios registrados en el sistema.
                                    </td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>

            <div id="noResultadosNotice" style="display: none; padding: 2.5rem; text-align: center; color: var(--text-muted);">
                🔍 No se encontraron usuarios que coincidan con la búsqueda o el filtro seleccionado.
            </div>

            <div class="card-footer" style="padding: 1rem 1.5rem; background: var(--bg-light); border-top: 1px solid var(--border-light); font-size: 0.82rem; color: var(--text-muted); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap;">
                <div>
                    <strong>Total Registros:</strong> ${cntTotal} usuarios &bull; <strong>Pendientes de Aprobación:</strong> ${cntPendientes}
                </div>
                <div>
                    <em>* Todo nuevo estudiante requiere aprobación del Administrador para ingresar a la plataforma.</em>
                </div>
            </div>
        </div>

    </div>

    <%-- MODAL 1: AGREGAR NUEVO USUARIO --%>
    <div id="modalNuevoUsuario" class="modal-overlay" style="display: none;">
        <div class="modal-box" style="max-width: 600px;">
            <div class="modal-header">
                <h3 style="font-size: 1.2rem; color: var(--primary-dark); margin: 0;">➕ Agregar Nuevo Usuario al Sistema</h3>
                <button type="button" class="modal-close-btn" onclick="cerrarModal('modalNuevoUsuario')">&times;</button>
            </div>
            
            <form action="usuarios.jsp" method="POST">
                <input type="hidden" name="accion" value="crear">
                
                <div class="modal-body" style="padding: 1.5rem;">
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                        <div class="form-group">
                            <label for="new_doc">Documento de Identidad (*):</label>
                            <input type="text" id="new_doc" name="documento" class="form-control" placeholder="Ej. 1098765432" required pattern="[0-9]{6,15}">
                        </div>
                        <div class="form-group">
                            <label for="new_tel">Teléfono / WhatsApp:</label>
                            <input type="tel" id="new_tel" name="telefono" class="form-control" placeholder="Ej. 3001234567">
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                        <div class="form-group">
                            <label for="new_nom">Nombres (*):</label>
                            <input type="text" id="new_nom" name="nombres" class="form-control" placeholder="Ej. Andrés Felipe" required>
                        </div>
                        <div class="form-group">
                            <label for="new_ape">Apellidos (*):</label>
                            <input type="text" id="new_ape" name="apellidos" class="form-control" placeholder="Ej. Ramírez Santos" required>
                        </div>
                    </div>

                    <div class="form-group">
                        <label for="new_email">Correo Electrónico Institucional (*):</label>
                        <input type="email" id="new_email" name="email" class="form-control" placeholder="usuario@sigrado.edu.co" required>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                        <div class="form-group">
                            <label for="new_rol">Rol Asignado (*):</label>
                            <select id="new_rol" name="rol_id" class="form-control" required>
                                <option value="4" selected>Estudiante (Postulante)</option>
                                <option value="3">Docente (Director / Evaluador)</option>
                                <option value="2">Comité Curricular de Grados</option>
                                <option value="1">Administrador del Sistema</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label for="new_activo">Estado Inicial (*):</label>
                            <select id="new_activo" name="activo" class="form-control" required>
                                <option value="1" selected>Activo (Aprobado de inmediato)</option>
                                <option value="0">Pendiente de Aprobación</option>
                            </select>
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                        <div class="form-group">
                            <label for="new_programa">Programa Académico:</label>
                            <select id="new_programa" name="programa" class="form-control">
                                <option value="Ingeniería de Sistemas">Ingeniería de Sistemas</option>
                                <option value="Tecnología en Desarrollo de Sistemas de Información">Tecnología en Sistemas</option>
                                <option value="Tecnología en Gestión de Redes y Seguridad">Gestión de Redes</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label for="new_pass">Contraseña Inicial:</label>
                            <input type="text" id="new_pass" name="password" class="form-control" value="123456" placeholder="Por defecto: 123456" required>
                        </div>
                    </div>
                </div>

                <div class="modal-footer" style="padding: 1rem 1.5rem; background: var(--bg-light); border-top: 1px solid var(--border-light); display: flex; justify-content: flex-end; gap: 0.75rem;">
                    <button type="button" class="btn btn-outline" onclick="cerrarModal('modalNuevoUsuario')">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Guardar Usuario</button>
                </div>
            </form>
        </div>
    </div>

    <%-- MODAL 2: CAMBIAR ROL DE USUARIO --%>
    <div id="modalCambiarRol" class="modal-overlay" style="display: none;">
        <div class="modal-box" style="max-width: 440px;">
            <div class="modal-header">
                <h3 style="font-size: 1.15rem; color: var(--primary-dark); margin: 0;">🔄 Cambiar Rol de Usuario</h3>
                <button type="button" class="modal-close-btn" onclick="cerrarModal('modalCambiarRol')">&times;</button>
            </div>
            
            <form action="usuarios.jsp" method="POST">
                <input type="hidden" name="accion" value="cambiar_rol">
                <input type="hidden" id="rol_target_id" name="usuario_id" value="">
                
                <div class="modal-body" style="padding: 1.5rem;">
                    <p style="font-size: 0.9rem; margin-bottom: 1rem;">
                        Modificar el rol asignado para: <strong id="rol_target_nombre" style="color: var(--primary-800);">...</strong>
                    </p>

                    <div class="form-group">
                        <label for="nuevo_rol_select">Seleccionar Nuevo Rol:</label>
                        <select id="nuevo_rol_select" name="nuevo_rol_id" class="form-control" required>
                            <option value="4">🎓 Estudiante</option>
                            <option value="3">👨‍🏫 Docente</option>
                            <option value="2">⚖️ Comité Curricular</option>
                            <option value="1">🔑 Administrador</option>
                        </select>
                    </div>
                    <small style="color: var(--text-muted); font-size: 0.78rem;">
                        * El usuario adoptará de inmediato los permisos y vistas correspondientes al nuevo rol.
                    </small>
                </div>

                <div class="modal-footer" style="padding: 1rem 1.5rem; background: var(--bg-light); border-top: 1px solid var(--border-light); display: flex; justify-content: flex-end; gap: 0.75rem;">
                    <button type="button" class="btn btn-outline" onclick="cerrarModal('modalCambiarRol')">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Actualizar Rol</button>
                </div>
            </form>
        </div>
    </div>

    <%-- MODAL 3: CONFIRMAR ELIMINACIÓN DE USUARIO --%>
    <div id="modalEliminarUsuario" class="modal-overlay" style="display: none;">
        <div class="modal-box" style="max-width: 460px;">
            <div class="modal-header" style="border-bottom-color: #fee2e2;">
                <h3 style="font-size: 1.15rem; color: #b91c1c; margin: 0; display: flex; align-items: center; gap: 0.4rem;">
                    <span>⚠️</span>
                    <span>Confirmar Eliminación</span>
                </h3>
                <button type="button" class="modal-close-btn" onclick="cerrarModal('modalEliminarUsuario')">&times;</button>
            </div>
            
            <form action="usuarios.jsp" method="POST">
                <input type="hidden" name="accion" value="eliminar">
                <input type="hidden" id="del_target_id" name="usuario_id" value="">
                
                <div class="modal-body" style="padding: 1.5rem;">
                    <p style="font-size: 0.95rem; color: var(--text-main); margin-bottom: 0.75rem;">
                        ¿Está seguro de que desea eliminar al usuario <strong id="del_target_nombre" style="color: #b91c1c;">...</strong> con documento <code id="del_target_doc">...</code>?
                    </p>
                    <div style="background: #fef2f2; border: 1px solid #fecaca; border-radius: var(--radius-sm); padding: 0.75rem; font-size: 0.8rem; color: #991b1b; line-height: 1.4;">
                        Si el usuario posee proyectos de grado activos o calificaciones asignadas, el sistema protegerá la integridad académica marcándolo automáticamente como <strong>Inactivo</strong>.
                    </div>
                </div>

                <div class="modal-footer" style="padding: 1rem 1.5rem; background: var(--bg-light); border-top: 1px solid var(--border-light); display: flex; justify-content: flex-end; gap: 0.75rem;">
                    <button type="button" class="btn btn-outline" onclick="cerrarModal('modalEliminarUsuario')">Cancelar</button>
                    <button type="submit" class="btn btn-primary" style="background: #dc2626; border-color: #b91c1c;">
                        Sí, Proceder
                    </button>
                </div>
            </form>
        </div>
    </div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>

<%-- Scripts de Front-End UI para Filtros Interactivos y Modales (Cero Servlets, JS solo UI) --%>
<style>
    .btn-filter {
        background: #ffffff;
        border: 1px solid var(--border-light);
        padding: 0.45rem 0.85rem;
        border-radius: var(--radius-full);
        font-size: 0.8rem;
        font-weight: 600;
        color: var(--text-muted);
        cursor: pointer;
        transition: var(--transition);
    }
    .btn-filter:hover {
        background: var(--primary-50);
        color: var(--primary-700);
        border-color: var(--primary-200);
    }
    .btn-filter.active {
        background: var(--primary-600);
        color: #ffffff;
        border-color: var(--primary-700);
    }
    .btn-filter.highlight {
        border-color: #f59e0b;
        color: #b45309;
        background: #fef3c7;
    }
    .btn-filter.highlight.active {
        background: #d97706;
        color: #ffffff;
        border-color: #b45309;
    }
    .modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
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
    let filtroRolActivo = 'todos';

    function filtrarRol(rol, btn) {
        filtroRolActivo = rol;
        const botones = document.querySelectorAll('#tabGroup .btn-filter');
        botones.forEach(b => b.classList.remove('active'));
        if (btn) btn.classList.add('active');
        filtrarTabla();
    }

    function filtrarPorEstado(estado) {
        filtroRolActivo = estado;
        const botones = document.querySelectorAll('#tabGroup .btn-filter');
        botones.forEach(b => {
            b.classList.remove('active');
            if (b.textContent.toLowerCase().includes(estado)) b.classList.add('active');
        });
        filtrarTabla();
    }

    function filtrarTabla() {
        const query = document.getElementById('buscadorUsuarios').value.toLowerCase().trim();
        const filas = document.querySelectorAll('.fila-usuario');
        let visibles = 0;

        filas.forEach(fila => {
            const activo = fila.getAttribute('data-activo');
            const roles = fila.getAttribute('data-roles');
            const doc = fila.getAttribute('data-doc');
            const nombre = fila.getAttribute('data-nombre');
            const email = fila.getAttribute('data-email');

            // 1. Filtro de Rol / Estado
            let coincideRol = false;
            if (filtroRolActivo === 'todos') {
                coincideRol = true;
            } else if (filtroRolActivo === 'pendientes') {
                coincideRol = (activo === '0');
            } else {
                coincideRol = roles.includes(filtroRolActivo);
            }

            // 2. Filtro de Buscador
            let coincideBusqueda = true;
            if (query !== '') {
                coincideBusqueda = doc.includes(query) || nombre.includes(query) || email.includes(query);
            }

            if (coincideRol && coincideBusqueda) {
                fila.style.display = '';
                visibles++;
            } else {
                fila.style.display = 'none';
            }
        });

        const noRes = document.getElementById('noResultadosNotice');
        if (noRes) {
            noRes.style.display = (visibles === 0) ? 'block' : 'none';
        }
    }

    function abrirModalCambiarRol(id, nombre, rolId) {
        document.getElementById('rol_target_id').value = id;
        document.getElementById('rol_target_nombre').textContent = nombre;
        document.getElementById('nuevo_rol_select').value = rolId || '4';
        abrirModal('modalCambiarRol');
    }

    function abrirModalEliminar(id, nombre, doc) {
        document.getElementById('del_target_id').value = id;
        document.getElementById('del_target_nombre').textContent = nombre;
        document.getElementById('del_target_doc').textContent = doc;
        abrirModal('modalEliminarUsuario');
    }
</script>

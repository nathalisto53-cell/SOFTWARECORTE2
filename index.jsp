<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>

<c:catch var="dbErr">
    <sql:query var="periodoActivo" dataSource="${sigradoDb}">
        SELECT * FROM periodos WHERE activo = 1 LIMIT 1;
    </sql:query>
    <sql:query var="formatosList" dataSource="${sigradoDb}">
        SELECT * FROM formatos WHERE activo = 1 ORDER BY codigo ASC;
    </sql:query>
</c:catch>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SIGRADO - Sistema de Gestión de Trabajos de Grado</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body style="background: linear-gradient(180deg, #f0fdf4 0%, #ffffff 350px);">

    <header style="padding: 1.5rem 3rem; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-light); background: rgba(255,255,255,0.85); backdrop-filter: blur(8px);">
        <div style="display: flex; align-items: center; gap: 0.85rem;">
            <div class="brand-icon">🌱</div>
            <div>
                <h1 style="font-size: 1.35rem; margin: 0; color: var(--primary-dark);">SIGRADO</h1>
                <span style="font-size: 0.8rem; color: var(--text-muted); font-weight: 500;">Ingeniería de Sistemas</span>
            </div>
        </div>
        <div style="display: flex; gap: 0.75rem; align-items: center;">
            <c:choose>
                <c:when test="${not empty sessionScope.usuario}">
                    <a href="inicio.jsp" class="btn btn-primary">Ir a mi Panel (${sessionScope.usuario.nombres})</a>
                </c:when>
                <c:otherwise>
                    <a href="registro.jsp" class="btn btn-outline" style="font-size: 0.9rem;">Crear Cuenta</a>
                    <a href="login.jsp" class="btn btn-primary" style="font-size: 0.9rem;">Iniciar Sesión</a>
                </c:otherwise>
            </c:choose>
        </div>
    </header>

    <main style="max-width: 1200px; margin: 0 auto; padding: 3rem 1.5rem;">
        
        <div style="text-align: center; max-width: 800px; margin: 0 auto 3.5rem;">
            <span class="badge badge-phase" style="padding: 0.4rem 1rem; font-size: 0.85rem; margin-bottom: 1rem;">
                Periodo Académico ${not empty periodoActivo.rows ? periodoActivo.rows[0].codigo : '2026-2'}
            </span>
            <h2 style="font-size: 2.75rem; color: var(--primary-dark); margin: 0.75rem 0 1rem; line-height: 1.2;">
                Gestión Integral del Ciclo de Trabajos de Grado
            </h2>
            <p style="font-size: 1.15rem; color: var(--text-muted); line-height: 1.6;">
                Plataforma oficial para la postulación, seguimiento en 6 fases, entregas de documentos y sustentación para los niveles Tecnológico y Profesional.
            </p>
            <div style="margin-top: 2rem; display: flex; justify-content: center; gap: 1rem; flex-wrap: wrap;">
                <a href="login.jsp" class="btn btn-primary" style="padding: 0.8rem 2rem; font-size: 1rem;">Ingresar al Sistema</a>
                <a href="registro.jsp" class="btn btn-outline" style="padding: 0.8rem 2rem; font-size: 1rem; background: var(--primary-50); border-color: var(--primary-500); color: var(--primary-800);">🎓 Crear Cuenta de Estudiante</a>
                <a href="#formatos" class="btn btn-outline" style="padding: 0.8rem 2rem; font-size: 1rem;">Descargar Formatos</a>
            </div>
        </div>

        <%-- Flujo de las 6 Fases (RF-GEN-01) --%>
        <div class="card" style="box-shadow: var(--shadow-lg); border-color: var(--border-green);">
            <div class="card-header">
                <h3 class="card-title">📌 El Flujo de Trabajo en 6 Fases</h3>
                <span class="badge badge-responsible">Trazabilidad Total</span>
            </div>
            
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 1rem; text-align: center;">
                <div style="padding: 1rem; background: var(--primary-50); border-radius: var(--radius-md); border: 1px solid var(--border-green);">
                    <div style="font-size: 1.5rem; margin-bottom: 0.35rem;">1️⃣</div>
                    <strong style="color: var(--primary-900); font-size: 0.9rem;">Idea y Pago</strong>
                    <p style="font-size: 0.78rem; color: var(--text-muted); margin-top: 0.3rem;">Postulación de idea y soporte de pago. Decide Comité.</p>
                </div>
                <div style="padding: 1rem; background: var(--primary-50); border-radius: var(--radius-md); border: 1px solid var(--border-green);">
                    <div style="font-size: 1.5rem; margin-bottom: 0.35rem;">2️⃣</div>
                    <strong style="color: var(--primary-900); font-size: 0.9rem;">Propuesta I</strong>
                    <p style="font-size: 0.78rem; color: var(--text-muted); margin-top: 0.3rem;">Entrega de Anteproyecto y Turnitin por Director.</p>
                </div>
                <div style="padding: 1rem; background: var(--primary-50); border-radius: var(--radius-md); border: 1px solid var(--border-green);">
                    <div style="font-size: 1.5rem; margin-bottom: 0.35rem;">3️⃣</div>
                    <strong style="color: var(--primary-900); font-size: 0.9rem;">Propuesta II</strong>
                    <p style="font-size: 0.78rem; color: var(--text-muted); margin-top: 0.3rem;">Evaluador con F-DC-124 firmado y Comité.</p>
                </div>
                <div style="padding: 1rem; background: var(--primary-50); border-radius: var(--radius-md); border: 1px solid var(--border-green);">
                    <div style="font-size: 1.5rem; margin-bottom: 0.35rem;">4️⃣</div>
                    <strong style="color: var(--primary-900); font-size: 0.9rem;">Informe I</strong>
                    <p style="font-size: 0.78rem; color: var(--text-muted); margin-top: 0.3rem;">Desarrollo del informe final y aval del Director.</p>
                </div>
                <div style="padding: 1rem; background: var(--primary-50); border-radius: var(--radius-md); border: 1px solid var(--border-green);">
                    <div style="font-size: 1.5rem; margin-bottom: 0.35rem;">5️⃣</div>
                    <strong style="color: var(--primary-900); font-size: 0.9rem;">Informe II</strong>
                    <p style="font-size: 0.78rem; color: var(--text-muted); margin-top: 0.3rem;">Evaluador con F-DC-125 y Rejilla F-DC-129.</p>
                </div>
                <div style="padding: 1rem; background: var(--primary-50); border-radius: var(--radius-md); border: 1px solid var(--border-green);">
                    <div style="font-size: 1.5rem; margin-bottom: 0.35rem;">6️⃣</div>
                    <strong style="color: var(--primary-900); font-size: 0.9rem;">Cierre</strong>
                    <p style="font-size: 0.78rem; color: var(--text-muted); margin-top: 0.3rem;">Sustentación pública y acta de grado definitiva.</p>
                </div>
            </div>
        </div>

        <%-- Formatos Institucionales (RF-ADM-04 / RF-GEN-01) --%>
        <div id="formatos" class="card" style="margin-top: 2rem;">
            <div class="card-header">
                <h3 class="card-title">📄 Formatos Institucionales Oficiales</h3>
                <span class="badge badge-approved">Plantillas Vigentes</span>
            </div>
            
            <div class="table-responsive">
                <table class="sigrado-table">
                    <thead>
                        <tr>
                            <th>Código</th>
                            <th>Nombre del Formato</th>
                            <th style="text-align: right;">Acceso</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${not empty formatosList.rows}">
                                <c:forEach var="f" items="${formatosList.rows}">
                                    <tr>
                                        <td><strong><span class="badge badge-phase">${f.codigo}</span></strong></td>
                                        <td>${f.nombre}</td>
                                        <td style="text-align: right;">
                                            <a href="${f.url_plantilla}" target="_blank" rel="noopener noreferrer" class="btn btn-outline btn-sm">
                                                Abrir Enlace ↗
                                            </a>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <tr>
                                    <td><span class="badge badge-phase">F-DC-124</span></td>
                                    <td>Formato de Presentación de Propuesta de Trabajo de Grado</td>
                                    <td style="text-align: right;"><a href="https://drive.google.com" target="_blank" class="btn btn-outline btn-sm">Abrir Enlace ↗</a></td>
                                </tr>
                                <tr>
                                    <td><span class="badge badge-phase">F-DC-125</span></td>
                                    <td>Formato de Informe Final de Trabajo de Grado</td>
                                    <td style="text-align: right;"><a href="https://drive.google.com" target="_blank" class="btn btn-outline btn-sm">Abrir Enlace ↗</a></td>
                                </tr>
                                <tr>
                                    <td><span class="badge badge-phase">F-DC-129</span></td>
                                    <td>Rejilla de Evaluación de Trabajo de Grado</td>
                                    <td style="text-align: right;"><a href="https://drive.google.com" target="_blank" class="btn btn-outline btn-sm">Abrir Enlace ↗</a></td>
                                </tr>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>

    </main>

    <footer style="margin-top: auto; padding: 2rem; text-align: center; font-size: 0.85rem; color: var(--text-muted); border-top: 1px solid var(--border-light); background: #ffffff;">
        &copy; 2026 SIGRADO &bull; Ingeniería de Sistemas &bull; Formatos F-DC-124 / 125 / 129
    </footer>

</body>
</html>

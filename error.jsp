<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Error - SIGRADO</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body style="background: linear-gradient(135deg, #f0fdf4 0%, #ffffff 100%); display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 2rem;">
    <div class="card" style="max-width: 500px; text-align: center; border-color: var(--border-green);">
        <div style="font-size: 3rem; margin-bottom: 0.5rem;">🛡️</div>
        <h2 style="color: var(--primary-dark); font-size: 1.6rem; margin-bottom: 0.5rem;">Acceso no autorizado o recurso no encontrado</h2>
        <p style="color: var(--text-muted); font-size: 0.95rem; margin-bottom: 1.5rem;">
            No tienes los permisos requeridos para acceder a este módulo con tu rol activo actual o la sesión ha expirado.
        </p>
        <div style="display: flex; justify-content: center; gap: 1rem;">
            <a href="inicio.jsp" class="btn btn-primary">Ir al Inicio</a>
            <a href="cambiar_rol.jsp" class="btn btn-outline">Cambiar de Perfil</a>
        </div>
    </div>
</body>
</html>

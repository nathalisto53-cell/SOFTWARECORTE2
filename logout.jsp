<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<fmt:requestEncoding value="UTF-8" />
<%-- SIGRADO - Cierre de Sesión con JSTL puro (Cero Servlets, Cero Scriptlets) --%>
<c:remove var="usuario" scope="session" />
<c:remove var="rolActivo" scope="session" />
<c:remove var="rolesUsuario" scope="session" />
<c:redirect url="/login.jsp" />

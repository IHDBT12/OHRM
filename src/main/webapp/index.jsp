<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.io.File" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="static ohrm.util.JspUtils.*" %>
<%
    request.setCharacterEncoding("UTF-8");

    String url = "jdbc:mariadb://localhost:3306/ohrm_db";
    String dbUser = "root";
    String dbPassword = "1234";
    int studentId = 20240001;
    String activeMenu = "home";

    String name = "";
    String memberDefaultImage = "assets/img/member/member.png";
    String memberCandidateImage = "assets/img/member/" + studentId + ".png";
    String memberCandidatePath = application.getRealPath(memberCandidateImage);
    String memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists()
        ? memberCandidateImage
        : memberDefaultImage;

    try {
        Class.forName("org.mariadb.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword);
             PreparedStatement pstmt = conn.prepareStatement("SELECT name FROM members WHERE student_id = ?")) {
            pstmt.setInt(1, studentId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    name = text(rs, "name");
                }
            }
        }
    } catch (Exception e) {
        name = "";
    }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>오케스트라 회원 관리 시스템</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="assets/css/common.css">
    <link rel="stylesheet" href="assets/css/home.css">
</head>
<body>
<div class="app-shell">
    <%@ include file="/WEB-INF/fragments/sidebar.jspf" %>

    <main class="main">
        <%@ include file="/WEB-INF/fragments/topbar.jspf" %>

        <section class="content ready-page">
            <h1>준비중</h1>
        </section>
    </main>
</div>
</body>
</html>

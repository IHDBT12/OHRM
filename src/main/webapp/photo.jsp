<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.io.File" %>
<%@ page import="static ohrm.util.JspUtils.*" %>
<%
    request.setCharacterEncoding("UTF-8");

    String url = "jdbc:mariadb://localhost:3306/ohrm_db";
    String dbUser = "root";
    String dbPassword = "1234";
    int studentId = 20240001;
    String activeMenu = "photo";

    int photoId = 0;
    try {
        photoId = Integer.parseInt(request.getParameter("id"));
    } catch (Exception e) {
        photoId = 0;
    }

    String name = "";
    String instrument = "";
    String memberImageUrl = "";
    String title = "";
    String date = "";
    String errorMessage = "";
    List<String> imageUrls = new ArrayList<>();

    try {
        Class.forName("org.mariadb.jdbc.Driver");

        try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword)) {
            try (PreparedStatement pstmt = conn.prepareStatement(
                "SELECT name, instrument FROM members WHERE student_id = ?"
            )) {
                pstmt.setInt(1, studentId);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        name = text(rs, "name");
                        instrument = text(rs, "instrument");
                    }
                }
            }

            try (PreparedStatement pstmt = conn.prepareStatement(
                "SELECT event_name, event_at, image_url FROM photo_albums WHERE photo_id = ?"
            )) {
                pstmt.setInt(1, photoId);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        title = text(rs, "event_name");
                        date = dateText(rs, "event_at");
                        String coverImageUrl = text(rs, "image_url");
                        if (!coverImageUrl.isEmpty()) {
                            imageUrls.add(coverImageUrl);
                        }
                    }
                }
            }

            try (PreparedStatement pstmt = conn.prepareStatement(
                "SELECT image_url FROM photo_album_images WHERE photo_id = ? ORDER BY image_id"
            )) {
                pstmt.setInt(1, photoId);
                try (ResultSet rs = pstmt.executeQuery()) {
                    imageUrls.clear();
                    while (rs.next()) {
                        imageUrls.add(text(rs, "image_url"));
                    }
                }
            }
        }
    } catch (ClassNotFoundException e) {
        errorMessage = "MariaDB JDBC 드라이버를 찾을 수 없습니다.";
    } catch (SQLException e) {
        errorMessage = "DB 조회 중 오류가 발생했습니다: " + e.getMessage();
    }

    String memberDefaultImage = "assets/img/member/member.png";
    String memberCandidateImage = "assets/img/member/" + studentId + ".png";
    String memberCandidatePath = application.getRealPath(memberCandidateImage);
    memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists()
        ? memberCandidateImage
        : memberDefaultImage;
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>오케스트라 회원 관리 시스템</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="assets/css/common.css">
    <link rel="stylesheet" href="assets/css/photo_album.css">
</head>
<body>
<div class="app-shell">
    <%@ include file="/WEB-INF/fragments/sidebar.jspf" %>

    <main class="main">
        <%@ include file="/WEB-INF/fragments/topbar.jspf" %>

        <section class="content">
            <% if (!errorMessage.isEmpty() && request.getParameter("debug") != null) { %>
                <div class="error"><%= html(errorMessage) %></div>
            <% } %>

            <div class="page-head">
                <div>
                    <h1><%= title.isEmpty() ? "사진을 찾을 수 없습니다" : html(title) %></h1>
                    <p><%= html(date) %></p>
                    <div class="accent-line"></div>
                </div>
                <div class="page-actions">
                    <a class="btn" href="photo_album.jsp">목록으로</a>
                    <% if (!title.isEmpty()) { %>
                        <form action="photo-delete" method="post" onsubmit="return confirm('이 사진 게시글을 삭제할까요?');">
                            <input type="hidden" name="photoId" value="<%= photoId %>">
                            <button class="btn danger" type="submit">삭제</button>
                        </form>
                    <% } %>
                </div>
            </div>

            <section class="card photo-detail">
                <% if (imageUrls.isEmpty()) { %>
                    <p>존재하지 않는 사진 게시글입니다.</p>
                <% } %>
                <% for (String imageUrl : imageUrls) { %>
                    <img src="<%= html(imageUrl) %>" alt="<%= html(title) %>">
                <% } %>
            </section>
        </section>
    </main>
</div>
</body>
</html>

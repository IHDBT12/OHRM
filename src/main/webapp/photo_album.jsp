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

    String selectedYear = request.getParameter("year");
    if (selectedYear == null || !selectedYear.matches("\\d{4}")) {
        selectedYear = "";
    }

    String name = "";
    String instrument = "";
    String memberImageUrl = "";
    String errorMessage = "";
    List<String> years = new ArrayList<>();
    List<String[]> photos = new ArrayList<>();

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
                "SELECT DISTINCT YEAR(event_at) AS event_year FROM photo_albums ORDER BY event_year DESC"
            );
                ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    years.add(String.valueOf(rs.getInt("event_year")));
                }
            }

            String photoSql = "SELECT photo_id, event_name, event_at, image_url FROM photo_albums";
            if (!selectedYear.isEmpty()) {
                photoSql += " WHERE YEAR(event_at) = ?";
            }
            photoSql += " ORDER BY event_at DESC, photo_id DESC";

            try (PreparedStatement pstmt = conn.prepareStatement(photoSql)) {
                if (!selectedYear.isEmpty()) {
                    pstmt.setInt(1, Integer.parseInt(selectedYear));
                }

                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        photos.add(new String[] {
                            String.valueOf(rs.getInt("photo_id")),
                            text(rs, "event_name"),
                            dateText(rs, "event_at"),
                            text(rs, "image_url")
                        });
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
                    <h1>사진첩</h1>
                    <p>행사 사진을 확인하고 새 사진을 업로드할 수 있습니다.</p>
                    <div class="accent-line"></div>
                </div>
                <a class="btn primary" href="#uploadModal">사진 업로드</a>
            </div>

            <section class="card">
                <form class="photo-toolbar" method="get" action="photo_album.jsp">
                    <select class="control" name="year" onchange="this.form.submit()">
                        <option value="">전체</option>
                        <% for (String year : years) { %>
                            <option value="<%= html(year) %>" <%= year.equals(selectedYear) ? "selected" : "" %>><%= html(year) %>년</option>
                        <% } %>
                    </select>
                </form>

                <div class="photo-list">
                    <% if (photos.isEmpty()) { %>
                        <p class="empty">등록된 사진 게시글이 없습니다.</p>
                    <% } %>
                    <% for (String[] photo : photos) { %>
                        <article class="photo-card">
                            <a href="photo.jsp?id=<%= html(photo[0]) %>">
                                <img src="<%= html(photo[3]) %>" alt="<%= html(photo[1]) %>">
                            </a>
                            <div class="photo-title"><%= html(photo[1]) %></div>
                            <div class="photo-date"><%= html(photo[2]) %></div>
                        </article>
                    <% } %>
                </div>
            </section>
        </section>
    </main>
</div>

<div class="modal" id="uploadModal">
    <div class="modal-box">
        <h2>사진 업로드</h2>
        <form class="modal-form" action="photo-upload" method="post" enctype="multipart/form-data">
            <label>
                사진
                <input class="control" type="file" name="photoImages" accept="image/*" multiple required>
            </label>
            <label>
                제목
                <input class="control" type="text" name="eventName" maxlength="20" required>
            </label>
            <label>
                날짜
                <input class="control" type="date" name="eventDate" required>
            </label>
            <div class="modal-actions">
                <a class="btn" href="#">취소</a>
                <button class="btn primary" type="submit">업로드</button>
            </div>
        </form>
    </div>
</div>
</body>
</html>

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.io.File" %>
<%@ page import="java.util.LinkedHashMap" %>
<%@ page import="java.util.Map" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%@ page import="static ohrm.util.JspUtils.*" %>
<%
    request.setCharacterEncoding("UTF-8");

    String url = "jdbc:mariadb://localhost:3306/ohrm_db";
    String dbUser = "root";
    String dbPassword = "1234";
    Integer sessionStudentId = AuthUtils.currentStudentId(request);
    if (sessionStudentId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int studentId = sessionStudentId;
    String activeMenu = "profile";

    String name = "";
    String cohort = "";
    String major = "";
    String phone = "";
    String enrolledText = "";
    String email = "";
    String joinedAt = "";
    String bio = "";
    String instrument = "";
    String memberImageUrl = "";
    String errorMessage = "";
    Map<String, String> instMap = new LinkedHashMap<>();
    instMap.put("violin", "바이올린");
    instMap.put("viola", "비올라");
    instMap.put("cello", "첼로");
    instMap.put("contrabass", "콘트라베이스");
    instMap.put("flute", "플루트");
    instMap.put("oboe", "오보에");
    instMap.put("clarinet", "클라리넷");
    instMap.put("horn", "호른");
    instMap.put("trumpet", "트럼펫");
    instMap.put("trombone", "트롬본");
    instMap.put("percussion", "타악기");
    instMap.put("etc", "기타(악기 없음)");

    try {
        Class.forName("org.mariadb.jdbc.Driver");

        try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword)) {
            try (PreparedStatement pstmt = conn.prepareStatement(
                "SELECT * FROM members WHERE student_id = ?"
            )) {
                pstmt.setInt(1, studentId);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        name = text(rs, "name");
                        cohort = text(rs, "cohort");
                        major = text(rs, "major");
                        phone = text(rs, "phone");
                        enrolledText = rs.getBoolean("is_enrolled") ? "재학" : "휴학";
                        email = text(rs, "email");
                        bio = text(rs, "bio");
                        instrument = text(rs, "instrument");
                        joinedAt = dateText(rs, "joined_at");
                    }
                }
            }
        }
    } catch (ClassNotFoundException e) {
        errorMessage = "MariaDB JDBC 드라이버를 찾을 수 없습니다. WEB-INF/lib 폴더에 JAR 파일을 넣어주세요.";
    } catch (SQLException e) {
        errorMessage = "DB 연결 또는 조회 중 오류가 발생했습니다: " + e.getMessage();
    }

    if (name.isEmpty()) {
        name = "";
        cohort = "";
        major = "";
        phone = "";
        enrolledText = "";
        email = "";
        joinedAt = "";
        bio = "";
        instrument = "";
    }

    String memberDefaultImage = "assets/img/member/member.png";
    String memberCandidateImage = "assets/img/member/" + studentId + ".png";
    String memberCandidatePath = application.getRealPath(memberCandidateImage);
    memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists()
        ? memberCandidateImage
        : memberDefaultImage;

    String instrumentText = instMap.containsKey(instrument) ? instMap.get(instrument) : instrument;
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>오케스트라 회원 관리 시스템</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="assets/css/common.css">
    <link rel="stylesheet" href="assets/css/profile.css">
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
                    <h1>내 프로필</h1>
                    <p>내 정보를 확인할 수 있습니다.</p>
                    <div class="accent-line"></div>
                </div>
                <a class="btn primary" href="profile_modify.jsp"><i class="bi"></i>프로필 수정</a>
            </div>

            <div class="grid">
                <section class="card card-pad">
                    <h2 class="card-title">프로필 사진</h2>
                    <div class="profile-photo">
                        <div class="avatar">
                            <img src="<%= html(memberImageUrl) %>" alt="프로필 사진">
                        </div>
                    </div>
                </section>

                <section class="card card-pad">
                    <h2 class="card-title">기본 정보</h2>
                    <div class="form-grid">
                        <div class="field">
                            <label>이름</label>
                            <div class="control"><%= html(name) %></div>
                        </div>
                        <div class="field">
                            <label>악기</label>
                            <div class="control"><%= html(instrumentText) %></div>
                        </div>
                        <div class="field">
                            <label>기수</label>
                            <div class="control"><%= html(cohort) %></div>
                        </div>
                        <div class="field">
                            <label>학과</label>
                            <div class="control"><%= html(major) %></div>
                        </div>
                        <div class="field">
                            <label>전화번호</label>
                            <div class="control"><%= html(phone) %></div>
                        </div>
                        <div class="field">
                            <label>재학 여부</label>
                            <div class="control"><%= html(enrolledText) %></div>
                        </div>
                    </div>
                </section>

                <section class="card card-pad">
                    <h2 class="card-title">내 소개</h2>
                    <div class="control bio-box"><%= html(bio) %></div>
                </section>

                <section class="card card-pad account-card">
                    <h2 class="card-title">계정 정보</h2>
                    <div class="account-row">
                        <span>학번</span>
                        <span><%= studentId %></span>
                        <span></span>
                    </div>
                    <div class="account-row">
                        <span>비밀번호</span>
                        <span>****</span>
                        <span></span>
                    </div>
                    <div class="account-row">
                        <span>이메일</span>
                        <span><%= html(email) %></span>
                        <span></span>
                    </div>
                    <div class="account-row">
                        <span>가입일</span>
                        <span><%= html(joinedAt) %></span>
                        <span></span>
                    </div>
                </section>
            </div>
        </section>
    </main>
</div>
</body>
</html>


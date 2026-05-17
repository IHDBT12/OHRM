<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.io.File" %>
<%@ page import="static ohrm.util.JspUtils.*" %>
<%
    request.setCharacterEncoding("UTF-8");

    String url = "jdbc:mariadb://localhost:3306/ohrm_db";
    String dbUser = "root";
    String dbPassword = "1234";
    int studentId = 20240001;
    String activeMenu = "profile";

    String name = "";
    String instrument = "";
    String major = "";
    String phone = "";
    String enrolledText = "";
    String email = "";
    String birthDate = "";
    String joinedAt = "";
    String passwordHash = "";
    String bio = "";
    String memberImageUrl = "";
    String instrumentImageUrl = "";
    String errorMessage = "";
    String saveMessage = "";

    String[] instrumentInfo = new String[3];

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
                        instrument = text(rs, "instrument");
                        major = text(rs, "major");
                        phone = text(rs, "phone");
                        enrolledText = rs.getBoolean("is_enrolled") ? "재학" : "휴학/졸업";
                        email = text(rs, "email");
                        passwordHash = text(rs, "password_hash");
                        bio = text(rs, "bio");
                        birthDate = dateText(rs, "birth_date");
                        joinedAt = dateText(rs, "joined_at");
                    }
                }
            }

            try (PreparedStatement pstmt = conn.prepareStatement(
                "SELECT asset_id, instrument_name, owner_type " +
                "FROM club_instruments WHERE student_id = ? ORDER BY asset_id LIMIT 1"
            )) {
                pstmt.setInt(1, studentId);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        instrumentInfo = new String[] {
                            String.valueOf(rs.getInt("asset_id")),
                            text(rs, "instrument_name"),
                            text(rs, "owner_type")
                        };
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
        instrument = "";
        major = "";
        phone = "";
        enrolledText = "";
        email = "";
        birthDate = "";
        joinedAt = "";
        passwordHash = "";
        bio = "";
        instrumentInfo = new String[] {
            " ", " ", " "
        };
    }

    String formError = request.getParameter("error");
    if ("birth".equals(formError)) {
        saveMessage = "생년월일은 yyyy.MM.dd 형식으로 입력해주세요. 예: 2003.05.20";
    } else if ("phone".equals(formError)) {
        saveMessage = "전화번호는 010-1234-5678 형식으로 입력해주세요.";
    }

    String memberDefaultImage = "assets/img/member/member.png";
    String memberCandidateImage = "assets/img/member/" + studentId + ".png";
    String memberCandidatePath = application.getRealPath(memberCandidateImage);
    memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists()
        ? memberCandidateImage
        : memberDefaultImage;

    String instrumentDefaultImage = "assets/img/instrument/instrument.png";
    String instrumentCandidateImage = "assets/img/instrument/" + instrumentInfo[0].trim() + ".png";
    String instrumentCandidatePath = application.getRealPath(instrumentCandidateImage);
    instrumentImageUrl = instrumentInfo[0].trim().isEmpty()
        || instrumentCandidatePath == null
        || !new File(instrumentCandidatePath).exists()
        ? instrumentDefaultImage
        : instrumentCandidateImage;
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
            <% if (!saveMessage.isEmpty()) { %>
                <div class="error"><%= html(saveMessage) %></div>
            <% } %>

            <form action="profile-update" method="post" enctype="multipart/form-data">
                <div class="page-head">
                    <div>
                        <h1>내 프로필 수정</h1>
                        <p>사진, 생년월일, 학과, 전화번호, 소개를 수정할 수 있습니다.</p>
                        <div class="accent-line"></div>
                    </div>
                    <button class="btn primary" type="submit">저장</button>
                </div>
            <div class="grid">
                <section class="card card-pad">
                    <h2 class="card-title">프로필 사진</h2>
                    <div class="profile-photo">
                        <div class="avatar">
                            <img src="<%= html(memberImageUrl) %>" alt="프로필 사진">
                        </div>
                        <input class="control" type="file" name="profileImage" accept="image/png">
                        <div class="help-text">
                            PNG 파일만 가능
                        </div>
                    </div>
                </section>

                <section class="card card-pad">
                    <h2 class="card-title">기본 정보</h2>
                    <div class="form-grid">
                        <div class="field">
                            <label>이름 (변경 불가)</label>
                            <div class="control readonly-control"><%= html(name) %></div>
                        </div>
                        <div class="field">
                            <label>생년월일</label>
                            <input class="control" type="text" name="birthDate" value="<%= html(birthDate) %>"
                                   pattern="\d{4}\.\d{2}\.\d{2}" placeholder="2003.05.20" required>
                        </div>
                        <div class="field">
                            <label>학과</label>
                            <input class="control" type="text" name="major" value="<%= html(major) %>" maxlength="30" required>
                        </div>
                        <div class="field">
                            <label>전화번호</label>
                            <input class="control" type="text" name="phone" value="<%= html(phone) %>"
                                   pattern="010-\d{4}-\d{4}" placeholder="010-1234-5678" required>
                        </div>
                        <div class="field">
                            <label>악기</label>
                            <div class="control readonly-control"><%= html(instrument) %></div>
                        </div>
                        <div class="field">
                            <label>재학 여부</label>
                            <div class="control readonly-control"><%= html(enrolledText) %></div>
                        </div>
                    </div>
                </section>

                <section class="card card-pad">
                    <h2 class="card-title">내 소개</h2>
                    <textarea class="control bio-box" name="bio" maxlength="200"><%= html(bio) %></textarea>
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
                        <span><%= html(passwordHash) %></span>
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
                    <button class="btn danger" type="button" style="width: 100%; margin-top: 18px;">회원 탈퇴</button>
                </section>

                <section class="card card-pad instrument-card">
                    <h2 class="card-title">악기</h2>
                    <div class="instrument-layout">
                        <img class="instrument-image" src="<%= html(instrumentImageUrl) %>" alt="악기 사진">
                        <div>
                            <div class="info-row"><span>악기명</span><strong><%= html(instrumentInfo[1]) %></strong></div>
                            <div class="info-row"><span>관리번호</span><strong><%= html(instrumentInfo[0]) %></strong></div>
                            <div class="info-row"><span>소유자</span><strong><%= html(instrumentInfo[2]) %></strong></div>
                            <button class="btn" type="button" style="width: 100%; margin-top: 16px;">악기 정보 수정</button>
                        </div>
                    </div>
                </section>

            </div>
            </form>
        </section>
    </main>
</div>
</body>
</html>



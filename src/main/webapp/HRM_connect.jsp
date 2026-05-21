<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="static ohrm.util.JspUtils.*" %>
<%@ page import="java.io.File" %>
<%@ page import="ohrm.util.AuthUtils" %>

<%

    request.setCharacterEncoding("UTF-8");

    String url = "jdbc:mariadb://localhost:3306/ohrm_db";
    String dbUser = "root";
    String dbPassword = "1234";
    String activeMenu = "members"; // 현재 활성화된 메뉴 설정
    
    Integer sessionStudentId = AuthUtils.currentStudentId(request);
    if (sessionStudentId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int studentId = sessionStudentId;

    String name = "";
    String memberDefaultImage = "assets/img/member/member.png";
    String memberCandidateImage = "assets/img/member/" + studentId + ".png";
    String memberCandidatePath = application.getRealPath(memberCandidateImage);
    String memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists()
        ? memberCandidateImage
        : memberDefaultImage;

    String errorMessage = "";

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
        errorMessage = "DB 조회 중 오류가 발생했습니다: " + e.getMessage();
    }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>오케스트라 회원 관리 시스템 - 인원 소개</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="assets/css/common.css">
    <%-- 인원 소개 전용 스타일이 있다면 추가, 없으면 프로필과 유사한 그리드 적용 --%>
    <link rel="stylesheet" href="assets/css/profile.css"> 
    <style>
        /* 인원 소개 페이지 전용 추가 스타일 */
        .instrument-group {
            margin-bottom: 24px;
        }
        .member-list {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 12px;
            margin-top: 12px;
        }
        .member-item {
            padding: 12px;
            background-color: var(--card-bg, #ffffff);
            border-radius: 6px;
            border: 1px solid #e2e8f0;
        }
        .member-name {
            font-weight: bold;
            font-size: 1.05rem;
        }
        .member-major {
            font-size: 0.85rem;
            color: #64748b;
            margin-top: 4px;
        }
    </style>
</head>
<body>
<div class="app-shell">
    <%@ include file="/WEB-INF/fragments/sidebar.jspf" %>

    <main class="main">
        <%@ include file="/WEB-INF/fragments/topbar.jspf" %>

        <section class="content">
            <div class="page-head">
                <div>
                    <h1>인원 소개</h1>
                    <p>오케스트라 단원들을 악기별로 확인할 수 있습니다.</p>
                    <div class="accent-line"></div>
                </div>
            </div>

            <div class="grid" style="grid-template-columns: 1fr; gap: 20px;">
                <%
                    try {
                        Class.forName("org.mariadb.jdbc.Driver");

                        try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword)) {
                            
                            // 1. 악기별 인원 수 조회
                            String groupSql =
                                "SELECT COALESCE(ci.instrument_name, '악기 미선택') AS instrument_name, COUNT(*) AS cnt " +
                                "FROM members m " +
                                "LEFT JOIN club_instruments ci ON m.instrument_asset_id = ci.asset_id " +
                                "GROUP BY ci.instrument_name " +
                                "ORDER BY ci.instrument_name ASC";
                            
                            try (PreparedStatement pthreadGroup = conn.prepareStatement(groupSql);
                                 ResultSet rsGroup = pthreadGroup.executeQuery()) {

                                while (rsGroup.next()) {
                                    String instrument = text(rsGroup, "instrument_name");
                                    int count = rsGroup.getInt("cnt");
                %>
                                    <section class="card card-pad instrument-group">
                                        <h2 class="card-title">
                                            <i class="bi bi-music-note-beamed"></i> <%= html(instrument) %> (<%= count %>명)
                                        </h2>
                                        
                                        <div class="member-list">
                                        <%
                                            // 2. 해당 악기의 멤버 상세 조회 (SQL Injection 방지를 위해 PreparedStatement 사용)
                                            String memberSql =
                                                "SELECT m.name, m.major " +
                                                "FROM members m " +
                                                "LEFT JOIN club_instruments ci ON m.instrument_asset_id = ci.asset_id " +
                                                "WHERE COALESCE(ci.instrument_name, '악기 미선택') = ? " +
                                                "ORDER BY m.name ASC";
                                            try (PreparedStatement pstmtMember = conn.prepareStatement(memberSql)) {
                                                pstmtMember.setString(1, instrument);
                                                try (ResultSet rsMember = pstmtMember.executeQuery()) {
                                                    while (rsMember.next()) {
                                                        name = text(rsMember, "name");
                                                        String major = text(rsMember, "major");
                                        %>
                                                        <div class="member-item">
                                                            <div class="member-name"><%= html(name) %></div>
                                                            <div class="member-major"><%= html(major) %></div>
                                                        </div>
                                        <%
                                                    }
                                                }
                                            }
                                        %>
                                        </div>
                                    </section>
                <%
                                }
                            }
                        }
                    } catch (ClassNotFoundException e) {
                        errorMessage = "MariaDB JDBC 드라이버를 찾을 수 없습니다.";
                    } catch (SQLException e) {
                        errorMessage = "DB 조회 중 오류가 발생했습니다: " + e.getMessage();
                    }

                    if (!errorMessage.isEmpty()) {
                %>
                        <div class="error"><%= html(errorMessage) %></div>
                <%
                    }
                %>
            </div>
        </section>
    </main>
</div>
</body>
</html>

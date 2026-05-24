<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.File" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%@ page import="static ohrm.util.JspUtils.*" %>

<%
    request.setCharacterEncoding("UTF-8");

    Integer sessionStudentId = AuthUtils.currentStudentId(request);
    if (sessionStudentId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String url = "jdbc:mariadb://localhost:3306/ohrm_db";
    String dbUser = "root";
    String dbPassword = "1234";

    int currentStudentId = sessionStudentId;
    String activeMenu = "attendance";

    String viewMode = request.getParameter("view");
    boolean groupView = "group".equals(viewMode);

    String name = "";
    String memberDefaultImage = "assets/img/member/member.png";
    String memberCandidateImage = "assets/img/member/" + currentStudentId + ".png";
    String memberCandidatePath = application.getRealPath(memberCandidateImage);
    String memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists()
        ? memberCandidateImage
        : memberDefaultImage;

    String errorMessage = "";
    String successMessage = "";

    try {
        Class.forName("org.mariadb.jdbc.Driver");

        try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword);
             PreparedStatement pstmt = conn.prepareStatement("SELECT name FROM members WHERE student_id = ?")) {

            pstmt.setInt(1, currentStudentId);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    name = text(rs, "name");
                }
            }
        }
    } catch (Exception e) {
        errorMessage = "DB 조회 중 오류가 발생했습니다: " + e.getMessage();
    }

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");

        if (action == null) {
            action = "insert";
        }

        try {
            Class.forName("org.mariadb.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword)) {

                if ("insert".equals(action)) {
                    String concertName = request.getParameter("concert_name");
                    String attendanceDate = request.getParameter("attendance_date");
                    String attendanceTime = request.getParameter("attendance_time");
                    String status = request.getParameter("is_present");
                    String note = request.getParameter("note");

                    int attendanceYear = Integer.parseInt(attendanceDate.substring(0, 4));

                    String sql = "INSERT INTO concert_attendance "
                               + "(student_id, concert_name, attendance_date, attendance_time, attendance_year, is_present, note) "
                               + "VALUES (?, ?, ?, ?, ?, ?, ?)";

                    try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                        pstmt.setInt(1, currentStudentId);
                        pstmt.setString(2, concertName);
                        pstmt.setString(3, attendanceDate);
                        pstmt.setString(4, attendanceTime);
                        pstmt.setInt(5, attendanceYear);
                        pstmt.setString(6, status);
                        pstmt.setString(7, note);
                        pstmt.executeUpdate();
                    }

                    successMessage = "출석 정보가 등록되었습니다.";
                }

                else if ("update".equals(action)) {
                    String attendanceId = request.getParameter("attendance_id");
                    String concertName = request.getParameter("concert_name");
                    String attendanceDate = request.getParameter("attendance_date");
                    String attendanceTime = request.getParameter("attendance_time");
                    String status = request.getParameter("is_present");
                    String note = request.getParameter("note");

                    int attendanceYear = Integer.parseInt(attendanceDate.substring(0, 4));

                    String sql = "UPDATE concert_attendance "
                               + "SET concert_name = ?, attendance_date = ?, attendance_time = ?, attendance_year = ?, is_present = ?, note = ? "
                               + "WHERE attendance_id = ? AND student_id = ?";

                    try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                        pstmt.setString(1, concertName);
                        pstmt.setString(2, attendanceDate);
                        pstmt.setString(3, attendanceTime);
                        pstmt.setInt(4, attendanceYear);
                        pstmt.setString(5, status);
                        pstmt.setString(6, note);
                        pstmt.setInt(7, Integer.parseInt(attendanceId));
                        pstmt.setInt(8, currentStudentId);
                        pstmt.executeUpdate();
                    }

                    successMessage = "출석 정보가 수정되었습니다.";
                }

                else if ("delete".equals(action)) {
                    String attendanceId = request.getParameter("attendance_id");

                    String sql = "DELETE FROM concert_attendance "
                               + "WHERE attendance_id = ? AND student_id = ?";

                    try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                        pstmt.setInt(1, Integer.parseInt(attendanceId));
                        pstmt.setInt(2, currentStudentId);
                        pstmt.executeUpdate();
                    }

                    successMessage = "출석 정보가 삭제되었습니다.";
                }
            }
        } catch (Exception e) {
            errorMessage = "처리 중 오류가 발생했습니다: " + e.getMessage();
        }
    }

    List<String[]> attendanceList = new ArrayList<>();

    int presentCount = 0;
    int lateCount = 0;
    int absentCount = 0;

    try {
        Class.forName("org.mariadb.jdbc.Driver");

        try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword)) {
            String sql = "SELECT attendance_id, student_id, concert_name, attendance_date, attendance_time, attendance_year, is_present, note "
                       + "FROM concert_attendance "
                       + "WHERE student_id = ? ";

            if (groupView) {
                sql += "ORDER BY concert_name ASC, attendance_date DESC, attendance_time DESC, attendance_id DESC";
            } else {
                sql += "ORDER BY attendance_date DESC, attendance_time DESC, attendance_id DESC";
            }

            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setInt(1, currentStudentId);

                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        String status = rs.getString("is_present");

                        if ("출석".equals(status)) {
                            presentCount++;
                        } else if ("지각".equals(status)) {
                            lateCount++;
                        } else {
                            absentCount++;
                        }

                        String timeText = "";
                        Time attendanceTime = rs.getTime("attendance_time");
                        if (attendanceTime != null) {
                            timeText = attendanceTime.toString().substring(0, 5);
                        }

                        attendanceList.add(new String[] {
                            String.valueOf(rs.getInt("attendance_id")),
                            String.valueOf(rs.getInt("student_id")),
                            rs.getString("concert_name"),
                            String.valueOf(rs.getDate("attendance_date")),
                            timeText,
                            String.valueOf(rs.getInt("attendance_year")),
                            status,
                            rs.getString("note") == null ? "" : rs.getString("note")
                        });
                    }
                }
            }
        }
    } catch (Exception e) {
        errorMessage = "조회 중 오류가 발생했습니다: " + e.getMessage();
    }

    int totalCount = presentCount + lateCount + absentCount;
    int attendanceRate = totalCount == 0 ? 0 : Math.round((presentCount * 100.0f) / totalCount);
%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>오케스트라 회원 관리 시스템-출결</title>

<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<link rel="stylesheet" href="assets/css/common.css">

<style>
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    font-family: 'Pretendard', 'Noto Sans KR', sans-serif;
}

body {
    background: #f5f7fb;
    color: #111827;
}

.app-shell .main {
    padding: 0;
    max-width: none;
    min-width: 0;
}

.content {
    background: #f5f7fb;
    width: 100%;
    overflow-x: hidden;
}

.attendance-wrap {
    width: 100%;
    max-width: 1400px;
    margin: 0 auto;
    padding: 40px 24px;
}

h1 {
    color: #001f3f;
    font-size: 36px;
    margin-bottom: 8px;
}

.sub {
    color: #666;
    margin-bottom: 28px;
}

.summary-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 18px;
    margin-bottom: 24px;
}

.summary-card,
.card {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 18px;
    padding: 24px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.04);
}

.summary-card {
    text-align: center;
}

.summary-card h3 {
    font-size: 15px;
    margin-bottom: 12px;
}

.num {
    font-size: 34px;
    font-weight: bold;
}

.present {
    color: #16a34a;
}

.late {
    color: #d97706;
}

.absent {
    color: #dc2626;
}

.rate {
    color: #001f3f;
}

.form-card {
    margin-bottom: 24px;
}

.input-form {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: 12px;
    margin-top: 16px;
}

.input-form input,
.input-form select {
    width: 100%;
    padding: 11px;
    border: 1px solid #d1d5db;
    border-radius: 8px;
}

.input-form button {
    width: 100%;
    border: none;
    background: #001f3f;
    color: white;
    border-radius: 8px;
    font-weight: bold;
    cursor: pointer;
    min-height: 43px;
}

.message {
    margin-bottom: 16px;
    font-weight: bold;
}

.success {
    color: #16a34a;
}

.error {
    color: #dc2626;
}

.table-card {
    overflow: hidden;
}

table {
    width: 100%;
    border-collapse: collapse;
    table-layout: fixed;
}

th {
    background: #f3f4f6;
}

th,
td {
    padding: 14px 10px;
    border-bottom: 1px solid #eee;
    text-align: center;
    font-size: 14px;
    word-break: keep-all;
    overflow-wrap: break-word;
}

.status {
    display: inline-block;
    padding: 6px 12px;
    border-radius: 20px;
    font-weight: bold;
}

.status.present {
    background: #dcfce7;
    color: #16a34a;
}

.status.late {
    background: #fef3c7;
    color: #d97706;
}

.status.absent {
    background: #fee2e2;
    color: #dc2626;
}

.row-edit {
    display: none;
}

.action-box {
    display: flex;
    gap: 6px;
    justify-content: center;
    align-items: center;
    flex-wrap: wrap;
}

.btn-small {
    padding: 7px 10px;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-weight: bold;
    white-space: nowrap;
}

.btn-update {
    background: #001f3f;
    color: white;
}

.btn-delete {
    background: #dc2626;
    color: white;
}

.btn-cancel {
    background: #6b7280;
    color: white;
}

.group-btn {
    display: inline-block;
    margin-top: 6px;
    padding: 5px 9px;
    background: #e58b00;
    color: white;
    border-radius: 6px;
    font-size: 12px;
    text-decoration: none;
    font-weight: bold;
}

.group-btn:hover {
    background: #c87500;
}

.normal-btn {
    display: inline-block;
    margin-top: 6px;
    padding: 5px 9px;
    background: #6b7280;
    color: white;
    border-radius: 6px;
    font-size: 12px;
    text-decoration: none;
    font-weight: bold;
}

.edit-form {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
    gap: 8px;
    align-items: center;
}

.edit-input {
    width: 100%;
    padding: 8px;
    border: 1px solid #d1d5db;
    border-radius: 6px;
}

@media (max-width: 900px) {
    .attendance-wrap {
        padding: 24px 14px;
    }

    h1 {
        font-size: 28px;
    }

    .sub {
        font-size: 14px;
    }

    .summary-card,
    .card {
        padding: 18px;
    }

    .num {
        font-size: 24px;
    }

    th,
    td {
        font-size: 12px;
        padding: 10px 6px;
    }

    .status {
        padding: 5px 8px;
        font-size: 12px;
    }

    .btn-small {
        padding: 6px 8px;
        font-size: 12px;
    }
}

.table-top {
    display: flex;
    justify-content: flex-end;
    margin-bottom: 14px;
}

.group-btn {
    display: inline-block;
    padding: 8px 16px;
    background: #e58b00;
    color: white;
    border-radius: 8px;
    font-size: 14px;
    text-decoration: none;
    font-weight: bold;
}

.group-btn:hover {
    background: #c87500;
}

.normal-btn {
    display: inline-block;
    padding: 8px 16px;
    background: #6b7280;
    color: white;
    border-radius: 8px;
    font-size: 14px;
    text-decoration: none;
    font-weight: bold;
}

</style>
</head>

<body>

<div class="app-shell">
    <%@ include file="/WEB-INF/fragments/sidebar.jspf" %>

    <main class="main">
        <%@ include file="/WEB-INF/fragments/topbar.jspf" %>

        <section class="content">
            <div class="attendance-wrap">

                <h1>내 출결 현황</h1>
                <p class="sub"><%= name %>님의 연주회 및 합주 출결 현황을 확인할 수 있습니다.</p>

                <% if (!successMessage.isEmpty()) { %>
                    <div class="message success"><%= successMessage %></div>
                <% } %>

                <% if (!errorMessage.isEmpty()) { %>
                    <div class="message error"><%= errorMessage %></div>
                <% } %>

                <section class="summary-grid">
                    <div class="summary-card">
                        <h3>출석</h3>
                        <div class="num present"><%= presentCount %>회</div>
                    </div>

                    <div class="summary-card">
                        <h3>지각</h3>
                        <div class="num late"><%= lateCount %>회</div>
                    </div>

                    <div class="summary-card">
                        <h3>결석</h3>
                        <div class="num absent"><%= absentCount %>회</div>
                    </div>

                    <div class="summary-card">
                        <h3>출석률</h3>
                        <div class="num rate"><%= attendanceRate %>%</div>
                    </div>
                </section>

                <section class="card form-card">
                    <h3>내 출석 등록</h3>

                    <form class="input-form" method="post" action="attendance.jsp">
                        <input type="hidden" name="action" value="insert">

                        <select name="concert_name" required>
                            <option value="">연주회명/합주명 선택</option>
                            <option value="신입생환영회">신입생환영회</option>
                            <option value="창립제">창립제</option>
                            <option value="정기연주회">정기연주회</option>
                            <option value="향상연주회">향상연주회</option>
                        </select>

                        <input type="date" name="attendance_date" required>
                        <input type="time" name="attendance_time" required>

                        <select name="is_present">
                            <option value="출석">출석</option>
                            <option value="지각">지각</option>
                            <option value="결석">결석</option>
                        </select>

                        <input type="text" name="note" placeholder="비고" maxlength="100">

                        <button type="submit">등록</button>
                    </form>
                </section>

                <section class="card table-card">

    				<div class="table-top">
        				<% if (groupView) { %>
            				<a href="attendance.jsp" class="normal-btn">기본보기</a>
        				<% } else { %>
            				<a href="attendance.jsp?view=group" class="group-btn">모아보기</a>
        				<% } %>
    				</div>

    				<table>
                        <thead>
                            <tr>
                                <th>날짜</th>
                                <th>행사명</th>
                                <th>시간</th>
                                <th>상태</th>
                                <th>비고</th>
                                <th>관리</th>
                            </tr>
                        </thead>

                        <tbody>
                        <% if (attendanceList.isEmpty()) { %>
                            <tr>
                                <td colspan="6">등록된 출석 정보가 없습니다.</td>
                            </tr>
                        <% } %>

                        <% for (String[] item : attendanceList) {
                            String rowId = item[0];
                            String concertName = item[2];
                            String dateOnly = item[3];
                            String timeOnly = item[4];
                            String status = item[6];
                            String note = item[7];
                        %>

                            <tr id="view-row-<%= rowId %>">
                                <td><%= dateOnly %></td>
                                <td><%= concertName %></td>
                                <td><%= timeOnly %></td>
                                <td>
                                    <span class="status <%= status.equals("출석") ? "present" : status.equals("지각") ? "late" : "absent" %>">
                                        <%= status %>
                                    </span>
                                </td>
                                <td><%= note %></td>
                                <td>
                                    <div class="action-box">
                                        <button type="button" class="btn-small btn-update" onclick="showEdit('<%= rowId %>')">수정</button>

                                        <form method="post" action="attendance.jsp" onsubmit="return confirm('정말 삭제하시겠습니까?');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="attendance_id" value="<%= rowId %>">
                                            <button class="btn-small btn-delete" type="submit">삭제</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>

                            <tr id="edit-row-<%= rowId %>" class="row-edit">
                                <td colspan="6">
                                    <form class="edit-form" method="post" action="attendance.jsp">
                                        <input type="hidden" name="action" value="update">
                                        <input type="hidden" name="attendance_id" value="<%= rowId %>">

                                        <input class="edit-input" type="date" name="attendance_date" value="<%= dateOnly %>" required>

                                        <select class="edit-input" name="concert_name" required>
                                            <option value="신입생환영회" <%= "신입생환영회".equals(concertName) ? "selected" : "" %>>신입생환영회</option>
                                            <option value="창립제" <%= "창립제".equals(concertName) ? "selected" : "" %>>창립제</option>
                                            <option value="정기연주회" <%= "정기연주회".equals(concertName) ? "selected" : "" %>>정기연주회</option>
                                            <option value="향상연주회" <%= "향상연주회".equals(concertName) ? "selected" : "" %>>향상연주회</option>
                                        </select>

                                        <input class="edit-input" type="time" name="attendance_time" value="<%= timeOnly %>" required>

                                        <select class="edit-input" name="is_present">
                                            <option value="출석" <%= "출석".equals(status) ? "selected" : "" %>>출석</option>
                                            <option value="지각" <%= "지각".equals(status) ? "selected" : "" %>>지각</option>
                                            <option value="결석" <%= "결석".equals(status) ? "selected" : "" %>>결석</option>
                                        </select>

                                        <input class="edit-input" type="text" name="note" value="<%= note %>" maxlength="100">

                                        <div class="action-box">
                                            <button class="btn-small btn-update" type="submit">저장</button>
                                            <button class="btn-small btn-cancel" type="button" onclick="hideEdit('<%= rowId %>')">취소</button>
                                        </div>
                                    </form>
                                </td>
                            </tr>

                        <% } %>
                        </tbody>
                    </table>
                </section>

            </div>
        </section>
    </main>
</div>

<script>
function showEdit(id) {
    document.getElementById("view-row-" + id).style.display = "none";
    document.getElementById("edit-row-" + id).style.display = "table-row";
}

function hideEdit(id) {
    document.getElementById("view-row-" + id).style.display = "table-row";
    document.getElementById("edit-row-" + id).style.display = "none";
}
</script>

</body>
</html>
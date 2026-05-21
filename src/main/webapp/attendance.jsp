<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>

<%
    request.setCharacterEncoding("UTF-8");

    String url = "jdbc:mariadb://localhost:3306/ohrm_db";
    String dbUser = "root";
    String dbPassword = "1234";

    String errorMessage = "";
    String successMessage = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");

        if (action == null) {
            action = "insert";
        }

        try {
            Class.forName("org.mariadb.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword)) {

                if ("insert".equals(action)) {
                    String studentId = request.getParameter("student_id");
                    String concertName = request.getParameter("concert_name");
                    String attendanceDate = request.getParameter("attendance_date");
                    String status = request.getParameter("is_present");
                    String note = request.getParameter("note");

                    String sql = "INSERT INTO concert_attendance "
                               + "(student_id, concert_name, attendance_date, is_present, note) "
                               + "VALUES (?, ?, ?, ?, ?)";

                    try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                        pstmt.setInt(1, Integer.parseInt(studentId));
                        pstmt.setString(2, concertName);
                        pstmt.setString(3, attendanceDate.replace("T", " ") + ":00");
                        pstmt.setString(4, status);
                        pstmt.setString(5, note);
                        pstmt.executeUpdate();
                    }

                    successMessage = "출석 정보가 등록되었습니다.";
                }

                else if ("update".equals(action)) {
                    String attendanceId = request.getParameter("attendance_id");
                    String studentId = request.getParameter("student_id");
                    String concertName = request.getParameter("concert_name");
                    String attendanceDate = request.getParameter("attendance_date");
                    String status = request.getParameter("is_present");
                    String note = request.getParameter("note");

                    String sql = "UPDATE concert_attendance "
                               + "SET student_id = ?, concert_name = ?, attendance_date = ?, is_present = ?, note = ? "
                               + "WHERE attendance_id = ?";

                    try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                        pstmt.setInt(1, Integer.parseInt(studentId));
                        pstmt.setString(2, concertName);
                        pstmt.setString(3, attendanceDate.replace("T", " ") + ":00");
                        pstmt.setString(4, status);
                        pstmt.setString(5, note);
                        pstmt.setInt(6, Integer.parseInt(attendanceId));
                        pstmt.executeUpdate();
                    }

                    successMessage = "출석 정보가 수정되었습니다.";
                }

                else if ("delete".equals(action)) {
                    String attendanceId = request.getParameter("attendance_id");

                    String sql = "DELETE FROM concert_attendance WHERE attendance_id = ?";

                    try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                        pstmt.setInt(1, Integer.parseInt(attendanceId));
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
            String sql = "SELECT attendance_id, student_id, concert_name, attendance_date, is_present, note "
                       + "FROM concert_attendance "
                       + "ORDER BY attendance_date DESC, attendance_id DESC";

            try (PreparedStatement pstmt = conn.prepareStatement(sql);
                 ResultSet rs = pstmt.executeQuery()) {

                while (rs.next()) {
                    String status = rs.getString("is_present");

                    if ("출석".equals(status)) {
                        presentCount++;
                    } else if ("지각".equals(status)) {
                        lateCount++;
                    } else {
                        absentCount++;
                    }

                    attendanceList.add(new String[] {
                        String.valueOf(rs.getInt("attendance_id")),
                        String.valueOf(rs.getInt("student_id")),
                        rs.getString("concert_name"),
                        String.valueOf(rs.getTimestamp("attendance_date")),
                        status,
                        rs.getString("note") == null ? "" : rs.getString("note")
                    });
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

.layout {
    display: flex;
    min-height: 100vh;
}

.sidebar {
    width: 220px;
    background: #001f3f;
    color: white;
    padding: 24px;
}

.logo {
    color: #f0a023;
    font-size: 23px;
    font-weight: bold;
    line-height: 1.5;
    margin-bottom: 40px;
}

.menu div {
    padding: 14px;
    margin-bottom: 10px;
    border-radius: 10px;
}

.menu .active {
    background: #e59b22;
    font-weight: bold;
}

.main {
    flex: 1;
    padding: 40px;
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
    grid-template-columns: repeat(4, 1fr);
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
    grid-template-columns: repeat(5, 1fr) 90px;
    gap: 12px;
    margin-top: 16px;
}

.input-form input,
.input-form select {
    padding: 11px;
    border: 1px solid #d1d5db;
    border-radius: 8px;
}

.input-form button {
    border: none;
    background: #001f3f;
    color: white;
    border-radius: 8px;
    font-weight: bold;
    cursor: pointer;
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

table {
    width: 100%;
    border-collapse: collapse;
}

th {
    background: #f3f4f6;
}

th,
td {
    padding: 15px;
    border-bottom: 1px solid #eee;
    text-align: center;
    font-size: 14px;
}

.status {
    padding: 6px 14px;
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
    gap: 8px;
    justify-content: center;
    align-items: center;
}

.btn-small {
    padding: 7px 12px;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-weight: bold;
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

.edit-form {
    display: grid;
    grid-template-columns: 1fr 1.7fr 2fr 1fr 2fr 1.2fr;
    gap: 8px;
    align-items: center;
}

.edit-input {
    width: 100%;
    padding: 8px;
    border: 1px solid #d1d5db;
    border-radius: 6px;
}
</style>
</head>

<body>

<div class="layout">

    <aside class="sidebar">
        <div class="logo">
            𝄞 오케스트라<br>
            Member System
        </div>

        <div class="menu">
            <div>홈</div>
            <div>인원 소개</div>
            <div>캘린더</div>
            <div>연습 기록</div>
            <div class="active">출결</div>
            <div>사진첩</div>
            <div>내 프로필</div>
        </div>
    </aside>

    <main class="main">

        <h1>출결 현황</h1>
        <p class="sub">연주회 및 합주 출결 현황을 확인할 수 있습니다.</p>

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
            <h3>출석 등록</h3>

            <form class="input-form" method="post" action="attendance.jsp">
                <input type="hidden" name="action" value="insert">

                <input type="number" name="student_id" placeholder="학번" required>
                <input type="text" name="concert_name" placeholder="연주회명/합주명" maxlength="50" required>
                <input type="datetime-local" name="attendance_date" required>

                <select name="is_present">
                    <option value="출석">출석</option>
                    <option value="지각">지각</option>
                    <option value="결석">결석</option>
                </select>

                <input type="text" name="note" placeholder="비고" maxlength="100">

                <button type="submit">등록</button>
            </form>
        </section>

        <section class="card">
            <table>
                <thead>
                    <tr>
                        <th>학번</th>
                        <th>날짜</th>
                        <th>행사명</th>
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

                    String dateForInput = item[3].replace(" ", "T");
                    if (dateForInput.length() >= 16) {
                        dateForInput = dateForInput.substring(0, 16);
                    }
                %>

                    <tr id="view-row-<%= rowId %>">
                        <td><%= item[1] %></td>
                        <td><%= item[3] %></td>
                        <td><%= item[2] %></td>
                        <td>
                            <span class="status <%= item[4].equals("출석") ? "present" : item[4].equals("지각") ? "late" : "absent" %>">
                                <%= item[4] %>
                            </span>
                        </td>
                        <td><%= item[5] %></td>
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

                                <input class="edit-input" type="number" name="student_id" value="<%= item[1] %>" required>
                                <input class="edit-input" type="datetime-local" name="attendance_date" value="<%= dateForInput %>" required>
                                <input class="edit-input" type="text" name="concert_name" value="<%= item[2] %>" maxlength="50" required>

                                <select class="edit-input" name="is_present">
                                    <option value="출석" <%= "출석".equals(item[4]) ? "selected" : "" %>>출석</option>
                                    <option value="지각" <%= "지각".equals(item[4]) ? "selected" : "" %>>지각</option>
                                    <option value="결석" <%= "결석".equals(item[4]) ? "selected" : "" %>>결석</option>
                                </select>

                                <input class="edit-input" type="text" name="note" value="<%= item[5] %>" maxlength="100">

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
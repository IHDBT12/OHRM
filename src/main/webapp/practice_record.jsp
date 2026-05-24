<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.File" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%@ page import="static ohrm.util.JspUtils.*" %>

<%!
    public String js(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\n", "\\n")
                    .replace("\r", "");
    }
%>

<%
    request.setCharacterEncoding("UTF-8");

    Integer sessionStudentId = AuthUtils.currentStudentId(request);
    if (sessionStudentId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int studentId = sessionStudentId;
    String activeMenu = "practice";

    String url = "jdbc:mariadb://localhost:3306/ohrm_db";
    String dbUser = "root";
    String dbPassword = "1234";

    String name = "";
    String errorMessage = "";
    String successMessage = "";

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
        errorMessage = "회원 정보 조회 중 오류가 발생했습니다: " + e.getMessage();
    }

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");

        try {
            Class.forName("org.mariadb.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword)) {

                if ("insert".equals(action)) {
                    String practiceDate = request.getParameter("practice_date");
                    String instrument = request.getParameter("instrument");
                    int hour = Integer.parseInt(request.getParameter("hour"));
                    int minute = Integer.parseInt(request.getParameter("minute"));
                    String memo = request.getParameter("memo");

                    int totalMinutes = hour * 60 + minute;

                    if (totalMinutes <= 0) {
                        errorMessage = "0시간 0분은 기록할 수 없습니다.";
                    } else {
                        String sql = "INSERT INTO practice_records "
                                   + "(student_id, practice_date, instrument, practice_minutes, memo) "
                                   + "VALUES (?, ?, ?, ?, ?)";

                        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                            pstmt.setInt(1, studentId);
                            pstmt.setString(2, practiceDate);
                            pstmt.setString(3, instrument);
                            pstmt.setInt(4, totalMinutes);
                            pstmt.setString(5, memo);
                            pstmt.executeUpdate();
                        }

                        successMessage = "연습 기록이 저장되었습니다.";
                    }
                }

                else if ("update".equals(action)) {
                    int recordId = Integer.parseInt(request.getParameter("record_id"));
                    String practiceDate = request.getParameter("practice_date");
                    String instrument = request.getParameter("instrument");
                    int hour = Integer.parseInt(request.getParameter("hour"));
                    int minute = Integer.parseInt(request.getParameter("minute"));
                    String memo = request.getParameter("memo");

                    int totalMinutes = hour * 60 + minute;

                    if (totalMinutes <= 0) {
                        errorMessage = "0시간 0분은 기록할 수 없습니다.";
                    } else {
                        String sql = "UPDATE practice_records "
                                   + "SET practice_date = ?, instrument = ?, practice_minutes = ?, memo = ? "
                                   + "WHERE record_id = ? AND student_id = ?";

                        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                            pstmt.setString(1, practiceDate);
                            pstmt.setString(2, instrument);
                            pstmt.setInt(3, totalMinutes);
                            pstmt.setString(4, memo);
                            pstmt.setInt(5, recordId);
                            pstmt.setInt(6, studentId);
                            pstmt.executeUpdate();
                        }

                        successMessage = "연습 기록이 수정되었습니다.";
                    }
                }

                else if ("delete".equals(action)) {
                    int recordId = Integer.parseInt(request.getParameter("record_id"));

                    String sql = "DELETE FROM practice_records "
                               + "WHERE record_id = ? AND student_id = ?";

                    try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                        pstmt.setInt(1, recordId);
                        pstmt.setInt(2, studentId);
                        pstmt.executeUpdate();
                    }

                    successMessage = "연습 기록이 삭제되었습니다.";
                }
            }
        } catch (Exception e) {
            errorMessage = "처리 중 오류가 발생했습니다: " + e.getMessage();
        }
    }

    List<String[]> records = new ArrayList<>();

    try {
        Class.forName("org.mariadb.jdbc.Driver");

        try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword)) {
            String sql = "SELECT record_id, practice_date, instrument, practice_minutes, memo "
                       + "FROM practice_records "
                       + "WHERE student_id = ? "
                       + "ORDER BY practice_date DESC, record_id DESC";

            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setInt(1, studentId);

                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        records.add(new String[] {
                            String.valueOf(rs.getInt("record_id")),
                            String.valueOf(rs.getDate("practice_date")),
                            rs.getString("instrument"),
                            String.valueOf(rs.getInt("practice_minutes")),
                            rs.getString("memo") == null ? "" : rs.getString("memo")
                        });
                    }
                }
            }
        }
    } catch (Exception e) {
        errorMessage = "연습 기록 조회 중 오류가 발생했습니다: " + e.getMessage();
    }
%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>연습기록</title>

<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<link rel="stylesheet" href="assets/css/common.css">

<style>
* {
    box-sizing: border-box;
    font-family: Arial, sans-serif;
}

body {
    margin: 0;
    background: #f5f7fb;
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

.practice-wrap {
    width: 100%;
    max-width: none;
    margin: 0;
    padding: 40px 24px;
}

h1 {
    color: #001f3f;
    margin-bottom: 8px;
}

.sub {
    color: #666;
    margin-bottom: 28px;
}

.card,
.summary-box {
    width: 100%;
    max-width: 100%;
    background: white;
    border: 1px solid #ddd;
    border-radius: 16px;
    padding: 24px;
    margin-bottom: 24px;
    overflow: hidden;
}

.form-row {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 14px;
    align-items: end;
}

label {
    display: block;
    font-weight: bold;
    margin-bottom: 8px;
}

input,
select {
    width: 100%;
    padding: 11px;
    border: 1px solid #ccc;
    border-radius: 8px;
}

button {
    padding: 12px;
    border: none;
    border-radius: 8px;
    background: #e58b00;
    color: white;
    font-weight: bold;
    cursor: pointer;
}

.cancel-btn {
    background: #6c757d;
    display: none;
    margin-top: 8px;
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

.content-grid {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 260px;
    gap: 20px;
    width: 100%;
}

.heatmap-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.heatmap-area {
    display: flex;
    gap: 12px;
    margin-top: 24px;
    overflow-x: auto;
    overflow-y: hidden;
    max-width: 100%;
    padding-bottom: 10px;
}

.week-labels {
    display: grid;
    grid-template-rows: repeat(7, 16px);
    gap: 5px;
    margin-top: 28px;
    font-size: 12px;
    flex-shrink: 0;
}

.months-wrap {
    display: grid;
    grid-template-columns: repeat(12, max-content);
    gap: 16px;
    width: max-content;
    min-width: max-content;
}

.month-title {
    text-align: center;
    font-weight: bold;
    font-size: 13px;
    margin-bottom: 8px;
}

.month-grid {
    display: grid;
    grid-template-rows: repeat(7, 16px);
    grid-auto-flow: column;
    gap: 5px;
}

.cell {
    width: 16px;
    height: 16px;
    border-radius: 3px;
    border: 1px solid rgba(0,0,0,0.08);
    background: #ebedf0;
}

.empty {
    background: transparent;
    border: none;
}

.first-day {
    border: 2px solid black;
}

.level-0 { background: #ebedf0; }
.level-1 { background: #cdeccd; }
.level-2 { background: #63c96b; }
.level-3 { background: #087f32; }

.legend {
    display: flex;
    justify-content: flex-end;
    gap: 14px;
    margin-top: 20px;
    font-size: 13px;
    flex-wrap: wrap;
}

.legend-item {
    display: flex;
    align-items: center;
    gap: 5px;
}

.summary-box h3 {
    margin-top: 0;
    color: #001f3f;
}

.summary-number {
    font-size: 34px;
    font-weight: bold;
}

.record-table {
    width: 100%;
    border-collapse: collapse;
    table-layout: fixed;
}

.record-table th,
.record-table td {
    padding: 12px;
    border-bottom: 1px solid #ddd;
    text-align: center;
    word-break: keep-all;
    overflow-wrap: break-word;
}

.record-table th {
    background: #f1f3f8;
}

.record-table td.memo {
    text-align: left;
}

.action-box {
    display: flex;
    gap: 6px;
    justify-content: center;
    flex-wrap: wrap;
}

.action-btn {
    padding: 7px 10px;
    border-radius: 6px;
    font-size: 13px;
}

.edit-btn {
    background: #1f7aec;
}

.delete-btn {
    background: #dc3545;
}

.save-edit-btn {
    background: #001f3f;
}

.empty-record {
    text-align: center;
    color: #777;
    padding: 20px;
}

.row-edit {
    display: none;
}

.edit-form {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
    gap: 8px;
}

@media (max-width: 1100px) {
    .content-grid {
        grid-template-columns: 1fr;
    }

    .practice-wrap {
        padding: 24px 14px;
    }
}

@media (max-width: 700px) {
    .record-table,
    .record-table thead,
    .record-table tbody,
    .record-table tr,
    .record-table th,
    .record-table td {
        display: block;
        width: 100%;
    }

    .record-table thead {
        display: none;
    }

    .record-table tr {
        border: 1px solid #ddd;
        border-radius: 14px;
        padding: 12px;
        margin-bottom: 14px;
    }

    .record-table td {
        border-bottom: none;
        text-align: left;
        padding: 8px 4px;
    }

    .record-table td::before {
        display: inline-block;
        width: 80px;
        font-weight: bold;
        color: #666;
    }

    .record-table td:nth-child(1)::before { content: "날짜"; }
    .record-table td:nth-child(2)::before { content: "악기"; }
    .record-table td:nth-child(3)::before { content: "시간"; }
    .record-table td:nth-child(4)::before { content: "메모"; }
    .record-table td:nth-child(5)::before { content: "작업"; }

    .action-box {
        justify-content: flex-start;
    }
}
</style>
</head>

<body>

<div class="app-shell">
    <%@ include file="/WEB-INF/fragments/sidebar.jspf" %>

    <main class="main">
        <%@ include file="/WEB-INF/fragments/topbar.jspf" %>

        <section class="content">
            <div class="practice-wrap">

                <h1>내 연습 기록</h1>
                <p class="sub"><%= name %>님의 연습 기록을 조회하고 수정할 수 있습니다.</p>

                <% if (!successMessage.isEmpty()) { %>
                    <div class="message success"><%= successMessage %></div>
                <% } %>

                <% if (!errorMessage.isEmpty()) { %>
                    <div class="message error"><%= errorMessage %></div>
                <% } %>

                <section class="card">
                    <h2>연습 기록 입력</h2>

                    <form class="form-row" method="post" action="practice_record.jsp">
                        <input type="hidden" name="action" value="insert">

                        <div>
                            <label>날짜</label>
                            <input type="date" name="practice_date" id="dateInput" required>
                        </div>

                        <div>
                            <label>악기</label>
                            <input type="text" name="instrument" placeholder="악기 입력" maxlength="50" required>
                        </div>

                        <div>
                            <label>시간</label>
                            <select name="hour" id="hourInput"></select>
                        </div>

                        <div>
                            <label>분</label>
                            <select name="minute" id="minuteInput"></select>
                        </div>

                        <div>
                            <label>메모</label>
                            <input type="text" name="memo" placeholder="메모 입력" maxlength="100">
                        </div>

                        <div>
                            <button type="submit">저장하기</button>
                        </div>
                    </form>
                </section>

                <div class="content-grid">

                    <section class="card">
                        <div class="heatmap-header">
                            <h2 id="heatmapTitle">연습 현황</h2>
                        </div>

                        <div class="heatmap-area">
                            <div class="week-labels">
                                <div>월</div>
                                <div>화</div>
                                <div>수</div>
                                <div>목</div>
                                <div>금</div>
                                <div>토</div>
                                <div>일</div>
                            </div>

                            <div id="heatmap" class="months-wrap"></div>
                        </div>

                        <div class="legend">
                            <div class="legend-item"><div class="cell level-0"></div>0</div>
                            <div class="legend-item"><div class="cell level-1"></div>~ 1h</div>
                            <div class="legend-item"><div class="cell level-2"></div>1h ~ 3h</div>
                            <div class="legend-item"><div class="cell level-3"></div>3h ~</div>
                        </div>
                    </section>

                    <aside>
                        <div class="summary-box">
                            <h3>이번 달 총 연습 시간</h3>
                            <div class="summary-number" id="monthTotal">0시간</div>
                            <p id="monthText"></p>
                        </div>

                        <div class="summary-box">
                            <h3>연속 기록</h3>
                            <div class="summary-number" id="streakText">0일</div>
                        </div>
                    </aside>

                </div>

                <section class="card">
                    <h2>최근 연습 기록</h2>

                    <table class="record-table">
                        <thead>
                            <tr>
                                <th>날짜</th>
                                <th>악기</th>
                                <th>연습 시간</th>
                                <th>메모</th>
                                <th>작업</th>
                            </tr>
                        </thead>

                        <tbody>
                        <% if (records.isEmpty()) { %>
                            <tr>
                                <td colspan="5" class="empty-record">최근 연습 기록이 없습니다.</td>
                            </tr>
                        <% } %>

                        <% for (String[] record : records) {
                            String recordId = record[0];
                            int minutes = Integer.parseInt(record[3]);
                            int hour = minutes / 60;
                            int minute = minutes % 60;
                        %>
                            <tr id="view-row-<%= recordId %>">
                                <td><%= record[1] %></td>
                                <td><%= record[2] %></td>
                                <td><%= hour %>시간 <%= minute %>분</td>
                                <td class="memo"><%= record[4].isEmpty() ? "-" : record[4] %></td>
                                <td>
                                    <div class="action-box">
                                        <button type="button" class="action-btn edit-btn" onclick="showEdit('<%= recordId %>')">수정</button>

                                        <form method="post" action="practice_record.jsp" onsubmit="return confirm('해당 연습 기록을 삭제하시겠습니까?');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="record_id" value="<%= recordId %>">
                                            <button type="submit" class="action-btn delete-btn">삭제</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>

                            <tr id="edit-row-<%= recordId %>" class="row-edit">
                                <td colspan="5">
                                    <form class="edit-form" method="post" action="practice_record.jsp">
                                        <input type="hidden" name="action" value="update">
                                        <input type="hidden" name="record_id" value="<%= recordId %>">

                                        <input type="date" name="practice_date" value="<%= record[1] %>" required>
                                        <input type="text" name="instrument" value="<%= record[2] %>" maxlength="50" required>

                                        <select name="hour">
                                            <% for (int h = 0; h <= 8; h++) { %>
                                                <option value="<%= h %>" <%= h == hour ? "selected" : "" %>><%= h %></option>
                                            <% } %>
                                        </select>

                                        <select name="minute">
                                            <% for (int m = 0; m <= 59; m++) { %>
                                                <option value="<%= m %>" <%= m == minute ? "selected" : "" %>><%= m %></option>
                                            <% } %>
                                        </select>

                                        <input type="text" name="memo" value="<%= record[4] %>" maxlength="100">

                                        <div class="action-box">
                                            <button type="submit" class="action-btn save-edit-btn">저장</button>
                                            <button type="button" class="action-btn cancel-btn" style="display:inline-block;" onclick="hideEdit('<%= recordId %>')">취소</button>
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
const YEAR = new Date().getFullYear();

const records = [
<% for (int i = 0; i < records.size(); i++) {
    String[] r = records.get(i);
%>
    {
        id: <%= r[0] %>,
        date: "<%= js(r[1]) %>",
        instrument: "<%= js(r[2]) %>",
        minutes: <%= r[3] %>,
        memo: "<%= js(r[4]) %>"
    }<%= i < records.size() - 1 ? "," : "" %>
<% } %>
];

const today = new Date();
const todayKey = makeDateKey(today);

document.getElementById("dateInput").value = todayKey;
document.getElementById("heatmapTitle").textContent = "연습 현황 " + YEAR + "년";

function makeDateKey(date) {
    return date.getFullYear() + "-" +
        String(date.getMonth() + 1).padStart(2, "0") + "-" +
        String(date.getDate()).padStart(2, "0");
}

function initializeTimeSelect() {
    const hourSelect = document.getElementById("hourInput");
    const minuteSelect = document.getElementById("minuteInput");

    for (let h = 0; h <= 8; h++) {
        const option = document.createElement("option");
        option.value = h;
        option.textContent = h;
        hourSelect.appendChild(option);
    }

    for (let m = 0; m <= 59; m++) {
        const option = document.createElement("option");
        option.value = m;
        option.textContent = m;
        minuteSelect.appendChild(option);
    }
}

function getPracticeDataByDate() {
    const data = {};

    records.forEach(record => {
        if (!data[record.date]) {
            data[record.date] = 0;
        }

        data[record.date] += record.minutes;
    });

    return data;
}

function getLevel(minutes) {
    if (!minutes || minutes === 0) return "level-0";
    if (minutes > 0 && minutes < 60) return "level-1";
    if (minutes >= 60 && minutes < 180) return "level-2";
    return "level-3";
}

function getMondayIndex(date) {
    const day = date.getDay();
    return day === 0 ? 6 : day - 1;
}

function renderHeatmap() {
    const practiceData = getPracticeDataByDate();
    const heatmap = document.getElementById("heatmap");
    heatmap.innerHTML = "";

    for (let month = 0; month < 12; month++) {
        const monthBox = document.createElement("div");
        monthBox.className = "month";

        const title = document.createElement("div");
        title.className = "month-title";
        title.textContent = (month + 1) + "월";

        const grid = document.createElement("div");
        grid.className = "month-grid";

        const firstDate = new Date(YEAR, month, 1);
        const firstDayIndex = getMondayIndex(firstDate);
        const lastDay = new Date(YEAR, month + 1, 0).getDate();

        for (let i = 0; i < firstDayIndex; i++) {
            const empty = document.createElement("div");
            empty.className = "cell empty";
            grid.appendChild(empty);
        }

        for (let day = 1; day <= lastDay; day++) {
            const dateKey =
                YEAR + "-" +
                String(month + 1).padStart(2, "0") + "-" +
                String(day).padStart(2, "0");

            const minutes = practiceData[dateKey] || 0;

            const cell = document.createElement("div");
            cell.className = "cell " + getLevel(minutes);

            if (day === 1) {
                cell.classList.add("first-day");
            }

            cell.title = dateKey + " / " + formatTime(minutes);
            grid.appendChild(cell);
        }

        monthBox.appendChild(title);
        monthBox.appendChild(grid);
        heatmap.appendChild(monthBox);
    }
}

function formatTime(minutes) {
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;

    if (h > 0 && m > 0) return h + "시간 " + m + "분";
    if (h > 0) return h + "시간";
    return m + "분";
}

function renderMonthTotal() {
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;

    let total = 0;

    records.forEach(record => {
        const parts = record.date.split("-").map(Number);
        const recordYear = parts[0];
        const recordMonth = parts[1];

        if (recordYear === currentYear && recordMonth === currentMonth) {
            total += record.minutes;
        }
    });

    document.getElementById("monthTotal").textContent = formatTime(total);
    document.getElementById("monthText").textContent =
        currentYear + "년 " + currentMonth + "월 기준";
}

function renderStreak() {
    const practiceData = getPracticeDataByDate();

    const practicedDates = Object.keys(practiceData)
        .filter(dateKey => practiceData[dateKey] > 0)
        .sort((a, b) => new Date(b) - new Date(a));

    if (practicedDates.length === 0) {
        document.getElementById("streakText").textContent = "0일";
        return;
    }

    let streak = 1;
    let checkDate = new Date(practicedDates[0]);

    while (true) {
        checkDate.setDate(checkDate.getDate() - 1);

        const prevDateKey = makeDateKey(checkDate);

        if (practiceData[prevDateKey] && practiceData[prevDateKey] > 0) {
            streak++;
        } else {
            break;
        }
    }

    document.getElementById("streakText").textContent = streak + "일";
}

function showEdit(id) {
    document.getElementById("view-row-" + id).style.display = "none";
    document.getElementById("edit-row-" + id).style.display = "table-row";
}

function hideEdit(id) {
    document.getElementById("view-row-" + id).style.display = "table-row";
    document.getElementById("edit-row-" + id).style.display = "none";
}

initializeTimeSelect();
renderHeatmap();
renderMonthTotal();
renderStreak();
</script>

</body>
</html>
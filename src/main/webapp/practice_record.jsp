<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>연습기록</title>

<style>
* {
    box-sizing: border-box;
    font-family: Arial, sans-serif;
}

body {
    margin: 0;
    background: #f5f7fb;
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
    flex-shrink: 0;
}

.logo {
    color: #f0a12b;
    font-size: 22px;
    font-weight: bold;
    margin-bottom: 40px;
}

.menu div {
    padding: 14px;
    margin-bottom: 10px;
    border-radius: 10px;
}

.menu .active {
    background: #e59b22;
}

.main {
    flex: 1;
    padding: 32px;
    max-width: calc(100vw - 220px);
}

h1 {
    color: #001f3f;
}

.card, .summary-box {
    background: white;
    border: 1px solid #ddd;
    border-radius: 16px;
    padding: 24px;
    margin-bottom: 24px;
}

.form-row {
    display: grid;
    grid-template-columns: 170px 160px 90px 90px 1fr 120px;
    gap: 14px;
    align-items: end;
}

label {
    display: block;
    font-weight: bold;
    margin-bottom: 8px;
}

input, select {
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
}

.content-grid {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 260px;
    gap: 20px;
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
}

.record-table th,
.record-table td {
    padding: 12px;
    border-bottom: 1px solid #ddd;
    text-align: center;
}

.record-table th {
    background: #f1f3f8;
}

.record-table td.memo {
    text-align: left;
}

.action-btn {
    padding: 7px 10px;
    margin: 2px;
    border-radius: 6px;
    font-size: 13px;
}

.edit-btn {
    background: #1f7aec;
}

.delete-btn {
    background: #dc3545;
}

.empty-record {
    text-align: center;
    color: #777;
    padding: 20px;
}

@media (max-width: 1100px) {
    .layout {
        flex-direction: column;
    }

    .sidebar {
        width: 100%;
    }

    .main {
        max-width: 100vw;
        padding: 20px;
    }

    .content-grid {
        grid-template-columns: 1fr;
    }

    .form-row {
        grid-template-columns: 1fr 1fr;
    }
}

@media (max-width: 600px) {
    .form-row {
        grid-template-columns: 1fr;
    }
}
</style>
</head>

<body>

<div class="layout">

    <aside class="sidebar">
        <div class="logo">오케스트라<br>Member System</div>

        <div class="menu">
            <div>홈</div>
            <div>인원 소개</div>
            <div>캘린더</div>
            <div class="active">연습 기록</div>
            <div>출결</div>
            <div>사진첩</div>
            <div>내 프로필</div>
        </div>
    </aside>

    <main class="main">

        <h1>연습 기록</h1>

        <section class="card">
            <h2>연습 기록 입력</h2>

            <div class="form-row">
                <div>
                    <label>날짜</label>
                    <input type="date" id="dateInput">
                </div>

                <div>
                    <label>악기</label>
                    <input type="text" id="instrumentInput" placeholder="악기 입력">
                </div>

                <div>
					<label>시간</label>
					<select id="hourInput"></select>
				</div>
				<div>
					<label>분</label>
					<select id="minuteInput"></select>
                </div>

                <div>
                    <label>메모</label>
                    <input type="text" id="memoInput" placeholder="메모 입력">
                </div>

                <div>
                    <button id="saveBtn" onclick="savePractice()">저장하기</button>
                    <button id="cancelBtn" class="cancel-btn" onclick="cancelEdit()">취소</button>
                </div>
            </div>
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
                <tbody id="recordList"></tbody>
            </table>
        </section>

    </main>

</div>

<script>
const YEAR = new Date().getFullYear();
let records = JSON.parse(localStorage.getItem("practiceRecords")) || [];
let editId = null;

const today = new Date();
const todayKey = makeDateKey(today);

document.getElementById("dateInput").value = todayKey;
document.getElementById("heatmapTitle").textContent = "연습 현황 " + YEAR + "년";

function makeDateKey(date) {
    return date.getFullYear() + "-" +
        String(date.getMonth() + 1).padStart(2, "0") + "-" +
        String(date.getDate()).padStart(2, "0");
}

function saveToStorage() {
    localStorage.setItem("practiceRecords", JSON.stringify(records));
}

function savePractice() {
    const date = document.getElementById("dateInput").value;
    const instrument = document.getElementById("instrumentInput").value.trim();
    const hour = Number(document.getElementById("hourInput").value);
    const minute = Number(document.getElementById("minuteInput").value);
    const memo = document.getElementById("memoInput").value.trim();

    const totalMinutes = hour * 60 + minute;

    if (!date) {
        alert("날짜를 입력해주세요.");
        return;
    }

    if (!instrument) {
        alert("악기를 입력해주세요.");
        return;
    }

    if (totalMinutes === 0) {
        alert("0시간 0분은 기록할 수 없습니다.");
        return;
    }

    if (editId !== null) {
        const target = records.find(record => record.id === editId);

        if (target) {
            target.date = date;
            target.instrument = instrument;
            target.minutes = totalMinutes;
            target.memo = memo;
        }

        editId = null;
        document.getElementById("saveBtn").textContent = "저장하기";
        document.getElementById("cancelBtn").style.display = "none";
    } else {
        records.push({
            id: Date.now(),
            date: date,
            instrument: instrument,
            minutes: totalMinutes,
            memo: memo
        });
    }

    saveToStorage();
    resetForm();
    renderAll();
}

function resetForm() {
    document.getElementById("dateInput").value = todayKey;
    document.getElementById("instrumentInput").value = "";
    document.getElementById("hourInput").value = "0";
    document.getElementById("minuteInput").value = "0";
    document.getElementById("memoInput").value = "";
}

function cancelEdit() {
    editId = null;
    resetForm();
    document.getElementById("saveBtn").textContent = "저장하기";
    document.getElementById("cancelBtn").style.display = "none";
}

function editRecord(id) {
    const record = records.find(item => item.id === id);

    if (!record) return;

    editId = id;

    document.getElementById("dateInput").value = record.date;
    document.getElementById("instrumentInput").value = record.instrument;
    document.getElementById("hourInput").value = String(Math.floor(record.minutes / 60));
    document.getElementById("minuteInput").value = String(record.minutes % 60);
    document.getElementById("memoInput").value = record.memo;

    document.getElementById("saveBtn").textContent = "수정하기";
    document.getElementById("cancelBtn").style.display = "block";
}

function deleteRecord(id) {
    if (!confirm("해당 연습 기록을 삭제하시겠습니까?")) return;

    records = records.filter(record => record.id !== id);
    saveToStorage();
    renderAll();
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
        const [recordYear, recordMonth] = record.date.split("-").map(Number);

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

function renderRecords() {
    const recordList = document.getElementById("recordList");
    recordList.innerHTML = "";

    if (records.length === 0) {
        recordList.innerHTML =
            "<tr><td colspan='5' class='empty-record'>최근 연습 기록이 없습니다.</td></tr>";
        return;
    }

    const sortedRecords = [...records].sort((a, b) => {
        return new Date(b.date) - new Date(a.date);
    });

    sortedRecords.forEach(record => {
        const tr = document.createElement("tr");

        tr.innerHTML =
            "<td>" + record.date + "</td>" +
            "<td>" + record.instrument + "</td>" +
            "<td>" + formatTime(record.minutes) + "</td>" +
            "<td class='memo'>" + (record.memo || "-") + "</td>" +
            "<td>" +
                "<button class='action-btn edit-btn' onclick='editRecord(" + record.id + ")'>수정</button>" +
                "<button class='action-btn delete-btn' onclick='deleteRecord(" + record.id + ")'>삭제</button>" +
            "</td>";

        recordList.appendChild(tr);
    });
}

function initializeTimeSelect() {
    const hourSelect = document.getElementById("hourInput");
    const minuteSelect = document.getElementById("minuteInput");

    hourSelect.innerHTML = "";
    minuteSelect.innerHTML = "";

    // 0 ~ 8시간
    for (let h = 0; h <= 8; h++) {
        const option = document.createElement("option");
        option.value = h;
        option.textContent = h;
        hourSelect.appendChild(option);
    }

    // 0 ~ 59분
    for (let m = 0; m <= 59; m++) {
        const option = document.createElement("option");
        option.value = m;
        option.textContent = m;
        minuteSelect.appendChild(option);
    }
}

initializeTimeSelect();

function renderAll() {
    renderHeatmap();
    renderMonthTotal();
    renderStreak();
    renderRecords();
}

renderAll();
</script>
</body>
</html>
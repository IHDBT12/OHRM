<!DOCTYPE html>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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
    padding: 40px;
}

h1 {
    color: #001f3f;
}

.card {
    background: white;
    border: 1px solid #ddd;
    border-radius: 16px;
    padding: 24px;
    margin-bottom: 24px;
}

.form-row {
    display: grid;
    grid-template-columns: 180px 160px 100px 100px 1fr 120px;
    gap: 16px;
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

.content-grid {
    display: grid;
    grid-template-columns: 1fr 260px;
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
    align-items: flex-start;
}

.week-labels {
    display: grid;
    grid-template-rows: repeat(7, 16px);
    gap: 5px;
    margin-top: 28px;
    font-size: 12px;
}

.month {
    margin-right: 14px;
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

.summary-box {
    background: white;
    border: 1px solid #ddd;
    border-radius: 16px;
    padding: 24px;
    margin-bottom: 20px;
}

.summary-box h3 {
    margin-top: 0;
    color: #001f3f;
}

.summary-number {
    font-size: 36px;
    font-weight: bold;
}
</style>
</head>

<body>

<div class="layout">

    <aside class="sidebar">
        <div class="logo">𝄞 오케스트라<br>Member System</div>

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
        <p>연습 시간을 입력하면 해당 날짜의 잔디가 채워집니다.</p>

        <section class="card">
            <h2>연습 기록 입력</h2>

            <div class="form-row">
                <div>
                    <label>날짜</label>
                    <input type="date" id="dateInput">
                </div>

                <div>
                    <label>악기</label>
                    <select id="instrumentInput">
                        <option>바이올린</option>
                        <option>비올라</option>
                        <option>첼로</option>
                        <option>플루트</option>
                        <option>클라리넷</option>
                    </select>
                </div>

                <div>
                    <label>시간</label>
                    <select id="hourInput">
                        <option value="0">0</option>
                        <option value="1">1</option>
                        <option value="2">2</option>
                        <option value="3">3</option>
                        <option value="4">4</option>
                        <option value="5">5</option>
                    </select>
                </div>

                <div>
                    <label>분</label>
                    <select id="minuteInput">
                        <option value="0">0</option>
                        <option value="10">10</option>
                        <option value="20">20</option>
                        <option value="30">30</option>
                        <option value="40">40</option>
                        <option value="50">50</option>
                    </select>
                </div>

                <div>
                    <label>메모</label>
                    <input type="text" id="memoInput" placeholder="메모 입력">
                </div>

                <button onclick="savePractice()">저장하기</button>
            </div>
        </section>

        <div class="content-grid">

            <section class="card">
                <div class="heatmap-header">
                    <h2>연습 현황 2026년</h2>
                    <strong>0 / ~1h / 1h~3h / 3h~</strong>
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

    </main>

</div>

<script>
const YEAR = 2026;

let practiceData = {};

document.getElementById("dateInput").value = "2026-05-21";

function savePractice() {
    const date = document.getElementById("dateInput").value;
    const hour = Number(document.getElementById("hourInput").value);
    const minute = Number(document.getElementById("minuteInput").value);

    const totalMinutes = hour * 60 + minute;

    if (totalMinutes === 0) {
        alert("0시간 0분은 기록할 수 없습니다.");
        return;
    }

    practiceData[date] = totalMinutes;

    renderHeatmap();
    renderMonthTotal();
    renderStreak();
}

function getLevel(minutes) {
    if (!minutes || minutes === 0) return "level-0";
    if (minutes <= 60) return "level-1";
    if (minutes <= 180) return "level-2";
    return "level-3";
}

function getMondayIndex(date) {
    const day = date.getDay();
    return day === 0 ? 6 : day - 1;
}

function renderHeatmap() {
    const heatmap = document.getElementById("heatmap");
    heatmap.innerHTML = "";

    for (let month = 0; month < 12; month++) {
        const monthBox = document.createElement("div");
        monthBox.className = "month";

        const title = document.createElement("div");
        title.className = "month-title";
        title.textContent = '${month + 1}월';

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

            cell.title = '${dateKey} / ${minutes}분';

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

    if (h > 0 && m > 0) return '${h}시간 ${m}분';
    if (h > 0) return '${h}시간';
    return '${m}분';
}

function renderMonthTotal() {
    const now = new Date();
    const currentMonth = now.getMonth() + 1;

    let total = 0;

    Object.keys(practiceData).forEach(date => {
        const parts = date.split("-");
        const year = Number(parts[0]);
        const month = Number(parts[1]);

        if (year === YEAR && month === currentMonth) {
            total += practiceData[date];
        }
    });

    document.getElementById("monthTotal").textContent = formatTime(total);
    document.getElementById("monthText").textContent = '${YEAR}년 ${currentMonth}월 기준';
}

function renderStreak() {
    let streak = 0;
    let checkDate = new Date();

    while (true) {
        const dateKey =
            checkDate.getFullYear() + "-" +
            String(checkDate.getMonth() + 1).padStart(2, "0") + "-" +
            String(checkDate.getDate()).padStart(2, "0");

        if (practiceData[dateKey] && practiceData[dateKey] > 0) {
            streak++;
            checkDate.setDate(checkDate.getDate() - 1);
        } else {
            break;
        }
    }

    document.getElementById("streakText").textContent = '${streak}일';
}

renderHeatmap();
renderMonthTotal();
renderStreak();
</script>

</body>
</html>

<!DOCTYPE html>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>오케스트라 회원 관리 시스템 - 출결</title>

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
    cursor: pointer;
}

.menu div:hover {
    background: #0b3768;
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

.summary-card {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 18px;
    padding: 24px;
    text-align: center;
    box-shadow: 0 4px 12px rgba(0,0,0,0.04);
}

.summary-card h3 {
    font-size: 15px;
    margin-bottom: 12px;
}

.summary-card .num {
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

.card {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 18px;
    padding: 24px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.04);
}

.filter-box {
    display: flex;
    gap: 12px;
    margin-bottom: 24px;
}

.filter-btn {
    padding: 11px 26px;
    border-radius: 8px;
    border: 1px solid #d1d5db;
    background: white;
    cursor: pointer;
    font-weight: bold;
}

.filter-btn.active {
    background: #001f3f;
    color: white;
}

table {
    width: 100%;
    border-collapse: collapse;
}

th {
    background: #f3f4f6;
    color: #333;
    font-size: 14px;
}

th, td {
    padding: 15px;
    border-bottom: 1px solid #eee;
    text-align: center;
    font-size: 14px;
}

.status {
    padding: 6px 14px;
    border-radius: 20px;
    font-weight: bold;
    font-size: 13px;
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

.pagination {
    display: flex;
    justify-content: center;
    gap: 10px;
    margin-top: 24px;
}

.pagination button {
    width: 34px;
    height: 34px;
    border: 1px solid #d1d5db;
    background: white;
    border-radius: 8px;
    cursor: pointer;
}

.pagination .active {
    background: #001f3f;
    color: white;
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
        <p class="sub">나의 출결 현황을 확인할 수 있습니다.</p>

        <section class="summary-grid">

            <div class="summary-card">
                <h3>출석</h3>
                <div class="num present" id="presentCount">12회</div>
            </div>

            <div class="summary-card">
                <h3>지각</h3>
                <div class="num late" id="lateCount">2회</div>
            </div>

            <div class="summary-card">
                <h3>결석</h3>
                <div class="num absent" id="absentCount">1회</div>
            </div>

            <div class="summary-card">
                <h3>출석률</h3>
                <div class="num rate" id="attendanceRate">92%</div>
            </div>

        </section>

        <section class="card">

            <div class="filter-box">
                <button class="filter-btn active" onclick="filterAttendance('all', this)">전체</button>
                <button class="filter-btn" onclick="filterAttendance('정기 연습', this)">정기 연습</button>
                <button class="filter-btn" onclick="filterAttendance('연주회', this)">연주회</button>
                <button class="filter-btn" onclick="filterAttendance('행사', this)">행사</button>
                <button class="filter-btn" onclick="filterAttendance('파트 연습', this)">파트 연습</button>
            </div>

            <table>
                <thead>
                    <tr>
                        <th>날짜</th>
                        <th>행사명</th>
                        <th>구분</th>
                        <th>상태</th>
                        <th>비고</th>
                    </tr>
                </thead>

                <tbody id="attendanceTable"></tbody>
            </table>

            <div class="pagination">
                <button>&lt;</button>
                <button class="active">1</button>
                <button>2</button>
                <button>3</button>
                <button>&gt;</button>
            </div>

        </section>

    </main>

</div>

<script>
const attendanceList = [
    {
        date: "2026.05.21",
        eventName: "정기 연습",
        type: "정기 연습",
        status: "출석",
        note: "-"
    },
    {
        date: "2026.05.19",
        eventName: "비브라토 연습",
        type: "파트 연습",
        status: "출석",
        note: "-"
    },
    {
        date: "2026.05.18",
        eventName: "오케스트라 합주 연습",
        type: "정기 연습",
        status: "지각",
        note: "10분 지각"
    },
    {
        date: "2026.05.12",
        eventName: "정기 연습",
        type: "정기 연습",
        status: "결석",
        note: "개인 사정"
    },
    {
        date: "2026.05.07",
        eventName: "파트 합주",
        type: "파트 연습",
        status: "출석",
        note: "-"
    },
    {
        date: "2026.05.03",
        eventName: "봄 정기연주회",
        type: "연주회",
        status: "출석",
        note: "-"
    }
];

function renderTable(list) {
    const tbody = document.getElementById("attendanceTable");
    tbody.innerHTML = "";

    list.forEach(item => {
        const tr = document.createElement("tr");

        let statusClass = "";

        if (item.status === "출석") {
            statusClass = "present";
        } else if (item.status === "지각") {
            statusClass = "late";
        } else if (item.status === "결석") {
            statusClass = "absent";
        }

        tr.innerHTML = `
            <td>${item.date}</td>
            <td>${item.eventName}</td>
            <td>${item.type}</td>
            <td>
                <span class="status ${statusClass}">
                    ${item.status}
                </span>
            </td>
            <td>${item.note}</td>
        `;

        tbody.appendChild(tr);
    });
}

function filterAttendance(type, button) {
    const buttons = document.querySelectorAll(".filter-btn");

    buttons.forEach(btn => {
        btn.classList.remove("active");
    });

    button.classList.add("active");

    if (type === "all") {
        renderTable(attendanceList);
        return;
    }

    const filteredList = attendanceList.filter(item => item.type === type);
    renderTable(filteredList);
}

function renderSummary() {
    const present = attendanceList.filter(item => item.status === "출석").length;
    const late = attendanceList.filter(item => item.status === "지각").length;
    const absent = attendanceList.filter(item => item.status === "결석").length;

    const total = present + late + absent;
    const rate = total === 0 ? 0 : Math.round((present / total) * 100);

    document.getElementById("presentCount").innerText = present + "회";
    document.getElementById("lateCount").innerText = late + "회";
    document.getElementById("absentCount").innerText = absent + "회";
    document.getElementById("attendanceRate").innerText = rate + "%";
}

renderTable(attendanceList);
renderSummary();
</script>

</body>
</html>
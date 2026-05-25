<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="java.io.File" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%@ page import="static ohrm.util.JspUtils.*" %>
<%
  request.setCharacterEncoding("UTF-8");

  // 1. 보안 세션 검증 (로그인한 유저만 접근 가능)
  Integer sessionStudentId = AuthUtils.currentStudentId(request);
  if (sessionStudentId == null) {
    response.sendRedirect("login.jsp");
    return;
  }

  int studentId = sessionStudentId;
  String activeMenu = "calendar"; // 사이드바 활성 메뉴 매칭
  String name = "";
  String memberDefaultImage = "assets/img/member/member.png";
  String memberCandidateImage = "assets/img/member/" + studentId + ".png";
  String memberCandidatePath = application.getRealPath(memberCandidateImage);
  String memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists()
      ? memberCandidateImage
      : memberDefaultImage;

  // 단원 이름 정보 조회
  try {
    Class.forName("org.mariadb.jdbc.Driver");
    try (Connection profileConn = DriverManager.getConnection("jdbc:mariadb://localhost:3306/ohrm_db", "root", "1234");
         PreparedStatement profilePs = profileConn.prepareStatement("SELECT name FROM members WHERE student_id = ?")) {
      profilePs.setInt(1, studentId);
      try (ResultSet profileRs = profilePs.executeQuery()) {
        if (profileRs.next()) {
          name = text(profileRs, "name");
        }
      }
    }
  } catch (Exception e) {
    name = "";
  }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
  <link rel="stylesheet" href="assets/css/common.css">
  <title>오케스트라 회원 관리 시스템 - 캘린더</title>
  <style>
    body { font-family: 'Pretendard', sans-serif; background: #f5f7fb; color: #111827; }
    .content { padding: 30px; }
    
    /* 레이아웃 제어용 래퍼 추가 */
    .controls-wrapper {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
    }
    .controls { display: flex; align-items: center; gap: 15px; }
    .controls a { text-decoration: none; color: #001f3f; font-weight: bold; font-size: 16px; }
    
    /* 개인 달력 이동 버튼 스타일 */
    .btn-my-calendar {
        padding: 8px 14px;
        background: #fff;
        color: #001f3f;
        border: 1px solid #001f3f;
        border-radius: 6px;
        text-decoration: none;
        font-size: 14px;
        font-weight: bold;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        transition: all 0.2s ease;
    }
    .btn-my-calendar:hover {
        background: #001f3f;
        color: #fff;
    }
    
    /* 달력 본체 스타일 규격화 */
    table.calendar { border-collapse: collapse; width: 100%; background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.04); }
    table.calendar th, table.calendar td { border: 1px solid #e5e7eb; width: 14.28%; vertical-align: top; height: 115px; padding: 8px; }
    table.calendar th { background: #f8fafc; color: #475569; height: 40px; font-size: 14px; text-align: center; font-weight: 600; }
    
    .date-num { font-weight: bold; margin-bottom: 6px; display: block; color: #1e293b; }
    
    /* 카테고리별 일정 컴포넌트 배색 */
    .event { display: block; margin: 3px 0; padding: 4px 6px; border-radius: 4px; color: #0f172a; font-size: 12px; font-weight: 500; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .cat-concert { background: #fee2e2; color: #dc2626; border-left: 3px solid #dc2626; }   /* 연주회 */
    .cat-practice { background: #e0f2fe; color: #0369a1; border-left: 3px solid #0369a1; }  /* 합주 */
    .cat-room { background: #dcfce7; color: #15803d; border-left: 3px solid #15803d; }       /* 파트연습 */
    .cat-other { background: #f1f5f9; color: #475569; border-left: 3px solid #475569; }     /* 기타 */
    
    .legend { margin-top: 16px; display: flex; gap: 10px; }
    .legend span { display: inline-block; padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: bold; }
    
    .modal-overlay { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.4); z-index: 999; }
    
    /* 모달 내부 입력 폼 스타일 요소 공용화 */
    .modal-input { width: 100%; padding: 6px 8px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 14px; box-sizing: border-box; font-family: inherit; }
  </style>
</head>
<body>
<div class="app-shell">
  <%@ include file="/WEB-INF/fragments/sidebar.jspf" %>
  <main class="main">
    <%@ include file="/WEB-INF/fragments/topbar.jspf" %>
    <section class="content">
      
      <div class="page-head" style="margin-bottom: 25px;">
        <h2 style="font-size: 28px; color: #001f3f; margin-bottom: 5px;"><i class="bi bi-calendar-week"></i> 동아리 일정</h2>
      </div>

      <div style="margin-bottom: 20px; padding: 20px; border: 1px solid #e2e8f0; background: white; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.02);">
        <h3 style="margin-top: 0; font-size: 16px; color: #001f3f; margin-bottom: 12px;"><i class="bi bi-calendar-plus"></i> 새 일정 추가</h3>
        <form action="add_schedule_action.jsp" method="post" style="display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
          <label>날짜: <input type="date" name="event_date" required style="padding: 6px; border: 1px solid #cbd5e1; border-radius: 6px;"></label>
          <label>시간: <input type="time" name="event_time" required style="padding: 6px; border: 1px solid #cbd5e1; border-radius: 6px;"></label>
          <label>제목: <input type="text" name="title" required placeholder="일정 제목" style="padding: 6px; border: 1px solid #cbd5e1; border-radius: 6px; width:160px;"></label>
          <label>카테고리:
            <select name="category" style="padding: 6px; border: 1px solid #cbd5e1; border-radius: 6px;">
              <option value="연주회">연주회</option>
              <option value="합주">합주</option>
              <option value="파트연습">파트연습</option>
              <option value="기타 행사">기타 행사</option>
            </select>
          </label>
          <label style="width: 100%; display: flex; align-items: center; gap: 8px;">
            세부사항: <input type="text" name="details" placeholder="상세 내용을 적어주세요" style="padding: 6px; border: 1px solid #cbd5e1; border-radius: 6px; flex: 1;">
          </label>
          <button type="submit" style="padding: 8px 18px; background: #001f3f; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold;">추가하기</button>
        </form>
      </div>

      <%
        // 주소창 파라미터 제어
        String sy = request.getParameter("year");
        String sm = request.getParameter("month");
        Calendar cal = Calendar.getInstance();
        int year = (sy != null) ? Integer.parseInt(sy) : cal.get(Calendar.YEAR);
        int month = (sm != null) ? Integer.parseInt(sm) - 1 : cal.get(Calendar.MONTH);

        Calendar prev = (Calendar) cal.clone();
        prev.set(year, month, 1);
        prev.add(Calendar.MONTH, -1);
        Calendar next = (Calendar) cal.clone();
        next.set(year, month, 1);
        next.add(Calendar.MONTH, 1);

        int displayYear = year;
        int displayMonth = month;
        Calendar display = Calendar.getInstance();
        display.set(displayYear, displayMonth, 1);
        int firstDayOfWeek = display.get(Calendar.DAY_OF_WEEK);
        int daysInMonth = display.getActualMaximum(Calendar.DAY_OF_MONTH);

        String url = "jdbc:mariadb://localhost:3306/ohrm_db";
        String dbUser = "root";
        String dbPass = "1234";

        Map<Integer, List<Map<String,String>>> events = new HashMap<>();

        try {
          Class.forName("org.mariadb.jdbc.Driver");
          try (Connection conn = DriverManager.getConnection(url, dbUser, dbPass)) {
            Calendar startCal = (Calendar) display.clone();
            startCal.set(Calendar.DAY_OF_MONTH, 1);
            Calendar endCal = (Calendar) display.clone();
            endCal.set(Calendar.DAY_OF_MONTH, daysInMonth);

            java.sql.Date startDate = new java.sql.Date(startCal.getTimeInMillis());
            java.sql.Date endDate = new java.sql.Date(endCal.getTimeInMillis());

            String sql = "SELECT id, title, event_date, event_time, details, category FROM schedule WHERE event_date BETWEEN ? AND ? ORDER BY event_time ASC";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
              ps.setDate(1, startDate);
              ps.setDate(2, endDate);
              try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                  java.sql.Date d = rs.getDate("event_date");
                  Calendar tmp = Calendar.getInstance();
                  tmp.setTime(d);
                  int day = tmp.get(Calendar.DAY_OF_MONTH);
                  
                  Map<String,String> ev = new HashMap<>();
                  ev.put("id", String.valueOf(rs.getInt("id")));
                  ev.put("title", rs.getString("title"));
                  ev.put("category", rs.getString("category"));
                  ev.put("date", d.toString());
                  
                  String tStr = rs.getString("event_time");
                  ev.put("time", (tStr != null && tStr.length() >= 5) ? tStr.substring(0, 5) : tStr);
                  
                  String detailsStr = rs.getString("details");
                  ev.put("details", detailsStr != null ? detailsStr : "내용 없음");
                  
                  events.computeIfAbsent(day, k -> new ArrayList<>()).add(ev);
                }
              }
            }
          }
        } catch (Exception e) {
          out.println("<div style='color:red; font-weight:bold; margin-bottom:15px;'>DB 오류: " + html(e.getMessage()) + "</div>");
        }
      %>

      <div class="controls-wrapper">
        <div class="controls">
          <a href="?year=<%= prev.get(Calendar.YEAR) %>&month=<%= prev.get(Calendar.MONTH)+1 %>"><i class="bi bi-chevron-left"></i> 이전 달</a>
          <strong style="font-size: 22px; color: #001f3f;"><%= displayYear %>년 <%= (displayMonth+1) %>월</strong>
          <a href="?year=<%= next.get(Calendar.YEAR) %>&month=<%= next.get(Calendar.MONTH)+1 %>">다음 달 <i class="bi bi-chevron-right"></i></a>
        </div>
        
        <div>
          <a href="my_calendar.jsp?year=<%= displayYear %>&month=<%= displayMonth + 1 %>" class="btn-my-calendar">
            <i class="bi bi-calendar3-user"></i> 나의 달력 보기
          </a>
        </div>
      </div>

      <table class="calendar">
        <thead>
          <tr>
            <th style="color: #dc2626;">일</th><th>월</th><th>화</th><th>수</th><th>목</th><th>금</th><th style="color: #0369a1;">토</th>
          </tr>
        </thead>
        <tbody>
        <%
          // 디자인 레이아웃 깨짐을 100% 방어하는 단일 수치 기반 그리드 루프 구현
          int dayCounter = 1;
          int totalCells = ((daysInMonth + firstDayOfWeek - 1) <= 35) ? 35 : 42; 

          for (int cell = 1; cell <= totalCells; cell++) {
            if (cell % 7 == 1) {
              out.println("<tr>");
            }

            out.println("<td>");
            if (cell >= firstDayOfWeek && dayCounter <= daysInMonth) {
              out.println("<span class='date-num'>" + dayCounter + "</span>");
              List<Map<String,String>> list = events.get(dayCounter);
              if (list != null) {
                for (Map<String,String> ev : list) {
                  String cat = ev.get("category");
                  String cls = "cat-other";
                  if ("연주회".equals(cat)) cls = "cat-concert";
                  else if ("합주".equals(cat)) cls = "cat-practice";
                  else if ("파트연습".equals(cat)) cls = "cat-room";
                  
                  String safeTitle = ev.get("title").replace("'", "&#39;");
                  String safeDetails = ev.get("details").replace("\"", "&quot;").replace("'", "&#39;");
                  
                  // 데이터 매핑 시 id와 category 데이터 속성 명시적 추가 조치
                  out.println("<span class='event " + cls + "' style='cursor:pointer;' " +
                              "data-id='" + ev.get("id") + "' " +
                              "data-category='" + html(cat) + "' " +
                              "data-title='" + html(safeTitle) + "' " +
                              "data-date='" + html(ev.get("date")) + "' " +
                              "data-time='" + html(ev.get("time")) + "' " +
                              "data-details='" + html(safeDetails) + "'>" +
                              "[" + html(ev.get("time")) + "] " + html(safeTitle) + "</span>");
                }
              }
              dayCounter++;
            }
            out.println("</td>");

            if (cell % 7 == 0) {
              out.println("</tr>");
            }
          }
        %>
        </tbody>
      </table>

      <div class="legend">
        <span class="cat-concert">연주회</span>
        <span class="cat-practice">합주</span>
        <span class="cat-room">파트연습</span>
        <span class="cat-other">기타 행사</span>
      </div>

    </section>
  </main>
</div>

<div id="modalOverlay" class="modal-overlay" onclick="closeModal()"></div>
<div id="eventModal" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); background:#fff; padding:25px; border:1px solid #e2e8f0; box-shadow:0 10px 25px rgba(0,0,0,0.15); z-index:1000; border-radius:12px; width:380px;">
  
  <form id="scheduleModalForm" method="post">
    <input type="hidden" name="id" id="formId">

    <div id="viewTitleArea"><h3 id="modalTitle" style="margin-top:0; border-bottom:2px solid #001f3f; padding-bottom:10px; color:#001f3f;"></h3></div>
    <div id="editTitleArea" style="display:none; margin-bottom:12px;">
      <label style="font-size:13px; font-weight:bold; display:block; margin-bottom:4px;">일정 제목</label>
      <input type="text" name="title" id="formTitle" class="modal-input" required>
    </div>

    <p style="margin:12px 0; font-size:14px;">
      <strong><i class="bi bi-tag"></i> 구분:</strong> 
      <span id="modalCategory" style="color:#475569;"></span>
      <select name="category" id="formCategory" class="modal-input" style="display:none; margin-top:4px;" required>
        <option value="연주회">연주회</option>
        <option value="합주">합주</option>
        <option value="파트연습">파트연습</option>
        <option value="기타 행사">기타 행사</option>
      </select>
    </p>

    <p style="margin:12px 0; font-size:14px;">
      <strong><i class="bi bi-calendar-event"></i> 일자:</strong> 
      <span id="modalDate" style="color:#475569;"></span>
      <input type="date" name="event_date" id="formDate" class="modal-input" style="display:none; margin-top:4px;" required>
    </p>

    <p style="margin:12px 0; font-size:14px;">
      <strong><i class="bi bi-clock"></i> 시간:</strong> 
      <span id="modalTime" style="color:#475569;"></span>
      <input type="time" name="event_time" id="formTime" class="modal-input" style="display:none; margin-top:4px;" required>
    </p>

    <p style="margin:12px 0; font-size:14px;"><strong><i class="bi bi-info-circle"></i> 세부사항:</strong></p>
    <div id="modalDetails" style="background:#f8fafc; padding:12px; border:1px solid #e2e8f0; border-radius:6px; min-height:60px; font-size:14px; white-space:pre-wrap; color:#334155;"></div>
    <textarea name="details" id="formDetails" class="modal-input" style="display:none; min-height:60px; resize:vertical; margin-top:4px;"></textarea>

    <div style="text-align:right; margin-top:25px; display:flex; justify-content:space-between; align-items:center;">
      <div style="display:flex; gap:6px;">
        <button type="button" id="btnEditTrigger" onclick="switchEditMode()" style="padding:6px 12px; background:#001f3f; color:#fff; border:none; border-radius:6px; cursor:pointer; font-weight:bold; font-size:13px;"><i class="bi bi-pencil"></i> 수정</button>
        <button type="button" id="btnDeleteTrigger" onclick="executeDelete()" style="padding:6px 12px; background:#dc2626; color:#fff; border:none; border-radius:6px; cursor:pointer; font-weight:bold; font-size:13px;"><i class="bi bi-trash"></i> 삭제</button>
        
        <button type="button" id="btnSubmitUpdate" onclick="executeUpdate()" style="padding:6px 12px; background:#15803d; color:#fff; border:none; border-radius:6px; cursor:pointer; font-weight:bold; font-size:13px; display:none;"><i class="bi bi-check-lg"></i> 저장</button>
      </div>
      <div>
        <button type="button" onclick="closeModal()" style="padding:8px 18px; background:#475569; color:#fff; border:none; border-radius:6px; cursor:pointer; font-weight:bold; font-size:13px;">닫기</button>
      </div>
    </div>
  </form>
</div>

<script>
  // 이벤트 등록 배지 클릭 이벤트 맵핑 스크립트
  document.querySelectorAll('.event').forEach(function(el){
    el.addEventListener('click', function(){
      resetModalState(); // 모달 오픈 전 항상 보기 모드로 복원 초기화
      
      var id = this.getAttribute('data-id');
      var category = this.getAttribute('data-category');
      var title = this.getAttribute('data-title');
      var date = this.getAttribute('data-date');
      var time = this.getAttribute('data-time');
      var details = this.getAttribute('data-details');
      
      // 모달 DOM 노드 엘리먼트에 데이터 주입
      document.getElementById('formId').value = id;
      
      document.getElementById('modalTitle').textContent = title;
      document.getElementById('formTitle').value = title;
      
      document.getElementById('modalCategory').textContent = category;
      document.getElementById('formCategory').value = category;
      
      document.getElementById('modalDate').textContent = date;
      document.getElementById('formDate').value = date;
      
      document.getElementById('modalTime').textContent = time;
      document.getElementById('formTime').value = time;
      
      document.getElementById('modalDetails').textContent = details;
      document.getElementById('formDetails').value = details;
      
      document.getElementById('modalOverlay').style.display = 'block';
      document.getElementById('eventModal').style.display = 'block';
    });
  });

  // 조회화면 -> 편집 입력 폼 모드로 동적 전환
  function switchEditMode() {
    document.getElementById('viewTitleArea').style.display = 'none';
    document.getElementById('editTitleArea').style.display = 'block';
    
    document.getElementById('modalCategory').style.display = 'none';
    document.getElementById('formCategory').style.display = 'block';
    
    document.getElementById('modalDate').style.display = 'none';
    document.getElementById('formDate').style.display = 'block';
    
    document.getElementById('modalTime').style.display = 'none';
    document.getElementById('formTime').style.display = 'block';
    
    document.getElementById('modalDetails').style.display = 'none';
    document.getElementById('formDetails').style.display = 'block';
    
    document.getElementById('btnEditTrigger').style.display = 'none';
    document.getElementById('btnDeleteTrigger').style.display = 'none';
    document.getElementById('btnSubmitUpdate').style.display = 'inline-block';
  }

  // 데이터 수정 처리 액션 라우팅 트리거
  function executeUpdate() {
    var form = document.getElementById('scheduleModalForm');
    form.action = 'update_schedule_action.jsp';
    form.submit();
  }

  // 데이터 삭제 처리 액션 경고창 검증 및 라우팅 트리거
  function executeDelete() {
    if (confirm('해당 일정을 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없으며 전 단원 달력에서 제거됩니다.')) {
      var form = document.getElementById('scheduleModalForm');
      form.action = 'delete_schedule_action.jsp';
      form.submit();
    }
  }

  // 모달 컴포넌트 내부 기본 출력 뷰 모드로 상태 초기화 복원
  function resetModalState() {
    document.getElementById('viewTitleArea').style.display = 'block';
    document.getElementById('editTitleArea').style.display = 'none';
    
    document.getElementById('modalCategory').style.display = 'inline';
    document.getElementById('formCategory').style.display = 'none';
    
    document.getElementById('modalDate').style.display = 'inline';
    document.getElementById('formDate').style.display = 'none';
    
    document.getElementById('modalTime').style.display = 'inline';
    document.getElementById('formTime').style.display = 'none';
    
    document.getElementById('modalDetails').style.display = 'block';
    document.getElementById('formDetails').style.display = 'none';
    
    document.getElementById('btnEditTrigger').style.display = 'inline-block';
    document.getElementById('btnDeleteTrigger').style.display = 'inline-block';
    document.getElementById('btnSubmitUpdate').style.display = 'none';
  }

  function closeModal() {
    document.getElementById('modalOverlay').style.display = 'none';
    document.getElementById('eventModal').style.display = 'none';
  }
</script>

</body>
</html>
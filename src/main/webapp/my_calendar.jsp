<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="java.io.File" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%@ page import="static ohrm.util.JspUtils.*" %>
<%
  request.setCharacterEncoding("UTF-8");

  // 1. 세션 검증
  Integer sessionStudentId = AuthUtils.currentStudentId(request);
  if (sessionStudentId == null) { 
    response.sendRedirect("login.jsp"); 
    return; 
  }

  int studentId = sessionStudentId;
  String activeMenu = "calendar";
  
  String name = "";
  String memberDefaultImage = "assets/img/member/member.png";
  String memberCandidateImage = "assets/img/member/" + studentId + ".png";
  String memberCandidatePath = application.getRealPath(memberCandidateImage);
  String memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists()
      ? memberCandidateImage
      : memberDefaultImage;

  // 단원 이름 조회
  try {
    Class.forName("org.mariadb.jdbc.Driver");
    try (Connection conn = DriverManager.getConnection("jdbc:mariadb://localhost:3306/ohrm_db", "root", "1234");
         PreparedStatement ps = conn.prepareStatement("SELECT name FROM members WHERE student_id = ?")) {
      ps.setInt(1, studentId);
      try (ResultSet rs = ps.executeQuery()) { 
        if (rs.next()) { name = text(rs, "name"); }
      }
    }
  } catch (Exception e) { 
    name = "단원"; 
  }

  // 보기 모드 파라미터 처리
  String mode = request.getParameter("mode");
  if (mode == null) mode = "mine"; 
  boolean isAllMode = "all".equals(mode);
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
  <link rel="stylesheet" href="assets/css/common.css">
  <title>나의 출결 & 일정 달력</title>
  <style>
    body { font-family: 'Pretendard', sans-serif; background: #f5f7fb; color: #111827; }
    .content { padding: 30px; }
    .controls-wrapper { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
    .controls { display: flex; align-items: center; gap: 15px; }
    .controls a { text-decoration: none; color: #001f3f; font-weight: bold; font-size: 15px; }
    
    table.calendar { border-collapse: collapse; width: 100%; background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.04); }
    table.calendar th, table.calendar td { border: 1px solid #e5e7eb; width: 14.28%; vertical-align: top; height: 125px; padding: 6px; }
    table.calendar th { background: #f8fafc; color: #475569; height: 40px; font-size: 14px; text-align: center; font-weight: 600; }
    
    .date-num { font-weight: bold; margin-bottom: 6px; display: block; color: #1e293b; }
    
    .cal-item { display: block; margin: 3px 0; padding: 4px 6px; border-radius: 4px; font-size: 11px; font-weight: bold; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; cursor: pointer; transition: opacity 0.15s ease; }
    .cal-item:hover { opacity: 0.8; }
    
    .status-present { background: #dcfce7; color: #16a34a; border-left: 3px solid #16a34a; }
    .status-late { background: #fef3c7; color: #d97706; border-left: 3px solid #d97706; }
    .status-absent { background: #fee2e2; color: #dc2626; border-left: 3px solid #dc2626; }
    .status-personal { background: #f3e8ff; color: #7e22ce; border-left: 3px solid #7e22ce; }
    .status-club { background: #e0f2fe; color: #0369a1; border-left: 3px solid #0369a1; }

    .btn-toggle-mode { padding: 8px 14px; background: #fff; color: #4f46e5; border: 1px solid #4f46e5; border-radius: 6px; text-decoration: none; font-size: 13px; font-weight: bold; display: inline-flex; align-items: center; gap: 6px; }
    .btn-toggle-mode.active { background: #4f46e5; color: #fff; }
    .btn-switch { padding: 8px 14px; background: #001f3f; color: #fff; border-radius: 6px; text-decoration: none; font-size: 13px; font-weight: bold; display: inline-flex; align-items: center; gap: 6px; }

    .modal-overlay { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.4); z-index: 999; }
    .custom-modal { display: none; position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); background: #fff; padding: 25px; border: 1px solid #e2e8f0; box-shadow: 0 10px 25px rgba(0,0,0,0.15); z-index: 1000; border-radius: 12px; width: 400px; }
    .modal-input { width: 100%; padding: 6px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 14px; box-sizing: border-box; }
  </style>
</head>
<body>
<div class="app-shell">
  <%@ include file="/WEB-INF/fragments/sidebar.jspf" %>
  <main class="main">
    <%@ include file="/WEB-INF/fragments/topbar.jspf" %>
    <section class="content">
      
      <div class="page-head" style="margin-bottom: 20px;">
        <h2 style="font-size: 26px; color: #001f3f; margin-bottom: 5px;"><i class="bi bi-calendar3-user"></i> 나의 일정</h2>
      </div>

      <div style="background: white; padding: 20px; border-radius: 12px; margin-bottom: 20px; border: 1px solid #e5e7eb; box-shadow: 0 4px 12px rgba(0,0,0,0.02);">
        <h4 style="margin-top:0; color:#7e22ce; margin-bottom: 12px;"><i class="bi bi-pencil-square"></i> 개인 일정 메모 추가</h4>
        <form action="add_personal_action.jsp" method="post" style="display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
          <label>날짜: <input type="date" name="event_date" required style="padding: 6px; border-radius: 6px; border: 1px solid #cbd5e1;"></label>
          <label>시간: <input type="time" name="event_time" required style="padding: 6px; border-radius: 6px; border: 1px solid #cbd5e1;"></label>
          <label style="flex: 1; min-width: 200px;">일정명: <input type="text" name="title" placeholder="스케줄 제목 입력" required style="padding: 6px; border-radius: 6px; border: 1px solid #cbd5e1; width: 90%;"></label>
          
          <label style="width: 100%; display: flex; align-items: center; gap: 8px; margin-top: 5px;">
            세부사항: <input type="text" name="details" placeholder="연습 장소, 준비물 등 상세 내용을 적어주세요" style="padding: 6px; border-radius: 6px; border: 1px solid #cbd5e1; flex: 1;">
          </label>
          <div style="width: 100%; text-align: right; margin-top: 5px;">
            <button type="submit" style="padding: 8px 18px; background: #7e22ce; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold;">메모하기</button>
          </div>
        </form>
      </div>

      <%
        String sy = request.getParameter("year");
        String sm = request.getParameter("month");
        Calendar cal = Calendar.getInstance();
        int year = (sy != null) ? Integer.parseInt(sy) : cal.get(Calendar.YEAR);
        int month = (sm != null) ? Integer.parseInt(sm) - 1 : cal.get(Calendar.MONTH);

        Calendar display = Calendar.getInstance(); 
        display.set(year, month, 1);
        int firstDay = display.get(Calendar.DAY_OF_WEEK);
        int days = display.getActualMaximum(Calendar.DAY_OF_MONTH);

        Calendar prevCal = (Calendar) display.clone(); prevCal.add(Calendar.MONTH, -1);
        int prevYear = prevCal.get(Calendar.YEAR); int prevMonth = prevCal.get(Calendar.MONTH) + 1;

        Calendar nextCal = (Calendar) display.clone(); nextCal.add(Calendar.MONTH, 1);
        int nextYear = nextCal.get(Calendar.YEAR); int nextMonth = nextCal.get(Calendar.MONTH) + 1;

        Map<Integer, List<Map<String,String>>> dayEvents = new HashMap<>();

        try (Connection conn = DriverManager.getConnection("jdbc:mariadb://localhost:3306/ohrm_db", "root", "1234")) {
          
          // 1. 공식 내 출결 내역 조회
          String sql1 = "SELECT concert_name, attendance_date, attendance_time, is_present, note FROM concert_attendance WHERE student_id = ? AND MONTH(attendance_date) = ? AND YEAR(attendance_date) = ?";
          try (PreparedStatement ps = conn.prepareStatement(sql1)) {
            ps.setInt(1, studentId); ps.setInt(2, month + 1); ps.setInt(3, year);
            try (ResultSet rs = ps.executeQuery()) {
              while (rs.next()) {
                Map<String,String> m = new HashMap<>();
                m.put("id", "0");
                m.put("type", "공식 출결");
                m.put("title", rs.getString("concert_name"));
                m.put("status", rs.getString("is_present"));
                m.put("date", rs.getDate("attendance_date").toString());
                String tStr = rs.getString("attendance_time");
                m.put("time", (tStr != null && tStr.length() >= 5) ? tStr.substring(0,5) : "");
                String nStr = rs.getString("note");
                m.put("details", nStr != null ? nStr : "비고 없음");
                
                Calendar t = Calendar.getInstance(); t.setTime(rs.getDate("attendance_date"));
                dayEvents.computeIfAbsent(t.get(Calendar.DAY_OF_MONTH), k -> new ArrayList<>()).add(m);
              }
            }
          }
          
          // 2. 내 개인 메모(일정) 조회
          String sql2 = "SELECT id, title, event_date, event_time, details FROM personal_schedules WHERE student_id = ? AND MONTH(event_date) = ? AND YEAR(event_date) = ?";
          try (PreparedStatement ps = conn.prepareStatement(sql2)) {
            ps.setInt(1, studentId); ps.setInt(2, month + 1); ps.setInt(3, year);
            try (ResultSet rs = ps.executeQuery()) {
              while (rs.next()) {
                Map<String,String> m = new HashMap<>();
                m.put("id", String.valueOf(rs.getInt("id")));
                m.put("type", "개인 메모");
                m.put("title", rs.getString("title"));
                m.put("status", "메모");
                m.put("date", rs.getDate("event_date").toString());
                String tStr = rs.getString("event_time");
                m.put("time", (tStr != null && tStr.length() >= 5) ? tStr.substring(0,5) : "");
                String dStr = rs.getString("details");
                m.put("details", dStr != null ? dStr : "");
                
                Calendar t = Calendar.getInstance(); t.setTime(rs.getDate("event_date"));
                dayEvents.computeIfAbsent(t.get(Calendar.DAY_OF_MONTH), k -> new ArrayList<>()).add(m);
              }
            }
          }

          // 3. 조건부 동아리 전체 일정 조회
          if (isAllMode) {
            String sql3 = "SELECT title, event_date, event_time, category, details FROM schedule WHERE MONTH(event_date) = ? AND YEAR(event_date) = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql3)) {
              ps.setInt(1, month + 1); ps.setInt(2, year);
              try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                  Map<String,String> m = new HashMap<>();
                  m.put("id", "0");
                  m.put("type", "동아리 공통");
                  m.put("title", rs.getString("title"));
                  m.put("status", rs.getString("category"));
                  m.put("date", rs.getDate("event_date").toString());
                  String tStr = rs.getString("event_time");
                  m.put("time", (tStr != null && tStr.length() >= 5) ? tStr.substring(0,5) : "");
                  String dStr = rs.getString("details");
                  m.put("details", dStr != null ? dStr : "상세 내용 없음");
                  
                  Calendar t = Calendar.getInstance(); t.setTime(rs.getDate("event_date"));
                  dayEvents.computeIfAbsent(t.get(Calendar.DAY_OF_MONTH), k -> new ArrayList<>()).add(m);
                }
              }
            }
          }
        } catch (Exception e) { }
      %>

      <div class="controls-wrapper">
        <div class="controls">
          <a href="?year=<%= prevYear %>&month=<%= prevMonth %>&mode=<%= mode %>"><i class="bi bi-chevron-left"></i> 이전 달</a>
          <strong style="font-size: 22px; color: #001f3f;"><%= year %>년 <%= month+1 %>월</strong>
          <a href="?year=<%= nextYear %>&month=<%= nextMonth %>&mode=<%= mode %>">다음 달 <i class="bi bi-chevron-right"></i></a>
        </div>
        
        <div style="display: flex; gap: 8px;">
          <% if (isAllMode) { %>
            <a href="?year=<%= year %>&month=<%= month+1 %>&mode=mine" class="btn-toggle-mode active"><i class="bi bi-eye-slash"></i> 동아리 일정 숨기기</a>
          <% } else { %>
            <a href="?year=<%= year %>&month=<%= month+1 %>&mode=all" class="btn-toggle-mode"><i class="bi bi-eye"></i> 동아리 일정 같이 보기</a>
          <% } %>
          <a href="Calendar_page.jsp?year=<%= year %>&month=<%= month+1 %>" class="btn-switch"><i class="bi bi-calendar-week"></i> 동아리 달력 보기</a>
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
          int dayCnt = 1;
          for (int i = 0; i < 6; i++) {
            out.print("<tr>");
            for (int j = 1; j <= 7; j++) {
              int cellIdx = i * 7 + j;
              out.print("<td>");
              if (cellIdx >= firstDay && dayCnt <= days) {
                out.print("<span class='date-num'>" + dayCnt + "</span>");
                
                List<Map<String,String>> list = dayEvents.get(dayCnt);
                if (list != null) {
                  for (Map<String,String> ev : list) {
                    String type = ev.get("type");
                    String cls = ""; String prefix = "";
                    
                    if ("공식 출결".equals(type)) {
                      prefix = "[" + ev.get("status") + "] ";
                      if (ev.get("status").equals("출석")) cls = "status-present";
                      else if (ev.get("status").equals("지각")) cls = "status-late";
                      else cls = "status-absent";
                    } else if ("개인 메모".equals(type)) {
                      prefix = "[메모] "; cls = "status-personal";
                    } else if ("동아리 공통".equals(type)) {
                      prefix = "[" + ev.get("status") + "] "; cls = "status-club";
                    }
                    
                    String safeTitle = ev.get("title").replace("'", "&#39;");
                    String safeDetails = ev.get("details").replace("\"", "&quot;").replace("'", "&#39;");
                    
                    out.print("<div class='cal-item " + cls + "' " +
                              "data-id='" + ev.get("id") + "' " +
                              "data-type='" + html(type) + "' " +
                              "data-title='" + html(safeTitle) + "' " +
                              "data-date='" + html(ev.get("date")) + "' " +
                              "data-time='" + html(ev.get("time")) + "' " +
                              "data-details='" + html(safeDetails) + "'>" + 
                              prefix + html(ev.get("title")) + "</div>");
                  }
                }
                dayCnt++;
              }
              out.print("</td>");
            }
            out.print("</tr>");
            if (dayCnt > days) break;
          }
        %>
        </tbody>
      </table>
    </section>
  </main>
</div>

<div id="modalOverlay" class="modal-overlay" onclick="closeModal()"></div>
<div id="eventModal" class="custom-modal">
  <form id="updateForm" method="post">
    <input type="hidden" name="id" id="formId">
    
    <span id="modalTypeBadge" style="display:inline-block; font-size:11px; font-weight:bold; padding:3px 8px; border-radius:15px; margin-bottom:8px;"></span>
    
    <div id="viewTitleArea"><h3 id="modalTitle" style="margin-top:0; border-bottom:2px solid #001f3f; padding-bottom:10px; color:#001f3f; font-size:18px;"></h3></div>
    <div id="editTitleArea" style="display:none; margin-bottom:12px;">
      <label style="font-size:13px; font-weight:bold;">일정 제목:</label>
      <input type="text" name="title" id="formTitle" class="modal-input" required>
    </div>

    <p style="margin:10px 0; font-size:14px;">
      <strong><i class="bi bi-calendar-event"></i> 일자:</strong> 
      <span id="modalDate" style="color:#475569;"></span>
      <input type="date" name="event_date" id="formDate" class="modal-input" style="display:none; margin-top:4px;" required>
    </p>
    
    <p style="margin:10px 0; font-size:14px;">
      <strong><i class="bi bi-clock"></i> 시간:</strong> 
      <span id="modalTime" style="color:#475569;"></span>
      <input type="time" name="event_time" id="formTime" class="modal-input" style="display:none; margin-top:4px;" required>
    </p>
    
    <p style="margin:10px 0; font-size:14px;"><strong><i class="bi bi-info-circle"></i> 세부사항:</strong></p>
    <div id="modalDetails" style="background:#f8fafc; padding:12px; border:1px solid #e2e8f0; border-radius:6px; min-height:60px; font-size:13px; white-space:pre-wrap; color:#334155; line-height: 1.4;"></div>
    <textarea name="details" id="formDetails" class="modal-input" style="display:none; min-height:60px; resize:vertical;"></textarea>
    
    <div style="text-align:right; margin-top:25px; display:flex; justify-content:space-between; align-items:center;">
      <div id="authorActionButtons" style="display:none; gap:6px;">
        <button type="button" id="btnEditTrigger" onclick="switchEditMode()" style="padding:6px 12px; background:#7e22ce; color:#fff; border:none; border-radius:6px; cursor:pointer; font-weight:bold; font-size:12px;"><i class="bi bi-pencil"></i> 수정</button>
        <button type="button" id="btnDeleteTrigger" onclick="executeDelete()" style="padding:6px 12px; background:#dc2626; color:#fff; border:none; border-radius:6px; cursor:pointer; font-weight:bold; font-size:12px;"><i class="bi bi-trash"></i> 삭제</button>
        
        <button type="button" id="btnSubmitUpdate" onclick="executeUpdate()" style="padding:6px 12px; background:#16a34a; color:#fff; border:none; border-radius:6px; cursor:pointer; font-weight:bold; font-size:12px; display:none;"><i class="bi bi-check-lg"></i> 저장</button>
      </div>
      <div style="margin-left: auto;">
        <button type="button" onclick="closeModal()" style="padding:8px 18px; background:#475569; color:#fff; border:none; border-radius:6px; cursor:pointer; font-weight:bold; font-size:13px;">닫기</button>
      </div>
    </div>
  </form>
</div>

<script>
  document.querySelectorAll('.cal-item').forEach(function(el){
    el.addEventListener('click', function(){
      resetModalState();
      
      var id = this.getAttribute('data-id');
      var type = this.getAttribute('data-type');
      var title = this.getAttribute('data-title');
      var date = this.getAttribute('data-date');
      var time = this.getAttribute('data-time');
      var details = this.getAttribute('data-details');
      
      var badge = document.getElementById('modalTypeBadge');
      badge.textContent = type;
      
      if(type === '공식 출결') {
          badge.style.background = '#dcfce7'; badge.style.color = '#16a34a';
          document.getElementById('authorActionButtons').style.display = 'none';
      } else if(type === '개인 메모') {
          badge.style.background = '#f3e8ff'; badge.style.color = '#7e22ce';
          // 본인 메모일 때만 제어 패널 블록 통째로 노출
          document.getElementById('authorActionButtons').style.display = 'flex'; 
      } else {
          badge.style.background = '#e0f2fe'; badge.style.color = '#0369a1';
          document.getElementById('authorActionButtons').style.display = 'none';
      }

      document.getElementById('formId').value = id;
      document.getElementById('modalTitle').textContent = title;
      document.getElementById('formTitle').value = title;
      
      document.getElementById('modalDate').textContent = date;
      document.getElementById('formDate').value = date;
      
      document.getElementById('modalTime').textContent = time ? time : "시간 미지정";
      document.getElementById('formTime').value = time;
      
      document.getElementById('modalDetails').textContent = details ? details : "내용 없음";
      document.getElementById('formDetails').value = details;
      
      document.getElementById('modalOverlay').style.display = 'block';
      document.getElementById('eventModal').style.display = 'block';
    });
  });

  // 수정 인터페이스 폼 전환
  function switchEditMode() {
    document.getElementById('viewTitleArea').style.display = 'none';
    document.getElementById('editTitleArea').style.display = 'block';
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

  // 수정 서브밋 트리거 함수
  function executeUpdate() {
      var form = document.getElementById('updateForm');
      form.action = 'update_personal_action.jsp';
      form.submit();
  }

  // [신규] 삭제 서브밋 트리거 및 확인창 검증 함수
  function executeDelete() {
      if(confirm('이 개인 일정을 정말 삭제하시겠습니까? 데이터는 복구되지 않습니다.')) {
          var form = document.getElementById('updateForm');
          form.action = 'delete_personal_action.jsp';
          form.submit();
      }
  }

  function resetModalState() {
    document.getElementById('viewTitleArea').style.display = 'block';
    document.getElementById('editTitleArea').style.display = 'none';
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
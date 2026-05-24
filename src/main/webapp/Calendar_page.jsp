<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
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

  int studentId = sessionStudentId;
  String activeMenu = "calendar";
  String name = "";
  String memberDefaultImage = "assets/img/member/member.png";
  String memberCandidateImage = "assets/img/member/" + studentId + ".png";
  String memberCandidatePath = application.getRealPath(memberCandidateImage);
  String memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists()
      ? memberCandidateImage
      : memberDefaultImage;

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
<html>
<head>
  <meta charset="UTF-8">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
  <link rel="stylesheet" href="assets/css/common.css">
  <title>캘린더</title>
  <style>
    body { font-family: Arial, sans-serif; }
    .controls { margin-bottom: 10px; }
    .controls a { margin-right: 10px; text-decoration: none; color: #007acc; }
    table.calendar { border-collapse: collapse; width: 100%; }
    table.calendar th, table.calendar td { border: 1px solid #ddd; width: 14%; vertical-align: top; height: 110px; padding: 6px; }
    table.calendar th { background:#f5f5f5; }
    .date-num { font-weight: bold; margin-bottom: 6px; display:block; }
    .event { display:block; margin:2px 0; padding:4px; border-radius:4px; color:#111; font-size:12px; }
    .cat-concert { background:#FFA500; }   /* 연주회 */
    .cat-practice { background:#ADD8E6; }   /* 정기 연습 */
    .cat-room { background:#90EE90; }       /* 동아리방 사용 */
    .cat-other { background:#D3D3D3; }      /* 기타 */
    .legend { margin-top:12px; }
    .legend span { display:inline-block; margin-right:12px; padding:4px 8px; border-radius:4px; color:#111; }
  </style>
</head>
<body>
<div class="app-shell">
  <%@ include file="/WEB-INF/fragments/sidebar.jspf" %>
  <main class="main">
    <%@ include file="/WEB-INF/fragments/topbar.jspf" %>
    <section class="content">
      <h2>캘린더</h2>

      <div style="margin-bottom: 20px; padding: 15px; border: 1px solid #ddd; background: #f9f9f9; border-radius: 5px;">
        <h3 style="margin-top: 0; font-size: 16px;">새 일정 추가</h3>
        <form action="add_schedule_action.jsp" method="post" style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
          <label>날짜: <input type="date" name="event_date" required style="padding: 4px;"></label>
          <label>시간: <input type="time" name="event_time" required style="padding: 4px;"></label>
          <label>제목: <input type="text" name="title" required placeholder="일정 제목" style="padding: 4px; width:150px;"></label>
          <label>카테고리:
            <select name="category" style="padding: 4px;">
              <option value="연주회">연주회</option>
              <option value="정기 연습">정기 연습</option>
              <option value="동아리방 사용">동아리방 사용</option>
              <option value="기타 행사">기타 행사</option>
            </select>
          </label>
          <label style="width: 100%;">
            세부사항: <input type="text" name="details" placeholder="상세 내용을 적어주세요" style="padding: 4px; width: 60%;">
          </label>
          <button type="submit" style="padding: 6px 15px; background: #007acc; color: white; border: none; border-radius: 4px; cursor: pointer;">추가하기</button>
        </form>
      </div>
      <%
        // 파라미터로 year, month 받기. 없으면 현재 월 사용
        String sy = request.getParameter("year");
        String sm = request.getParameter("month");
        Calendar cal = Calendar.getInstance();
        int year = (sy != null) ? Integer.parseInt(sy) : cal.get(Calendar.YEAR);
        int month = (sm != null) ? Integer.parseInt(sm) - 1 : cal.get(Calendar.MONTH); // 0-based

        // 이전/다음 월 계산
        Calendar prev = (Calendar) cal.clone();
        prev.set(year, month, 1);
        prev.add(Calendar.MONTH, -1);
        Calendar next = (Calendar) cal.clone();
        next.set(year, month, 1);
        next.add(Calendar.MONTH, 1);

        int displayYear = year;
        int displayMonth = month; // 0-based
        Calendar display = Calendar.getInstance();
        display.set(displayYear, displayMonth, 1);
        int firstDayOfWeek = display.get(Calendar.DAY_OF_WEEK); // 1=Sun
        int daysInMonth = display.getActualMaximum(Calendar.DAY_OF_MONTH);

        // DB 연결 정보
        String url = "jdbc:mariadb://localhost:3306/ohrm_db";
        String dbUser = "root";
        String dbPass = "1234";

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        // 일정 맵: day -> List of maps
        Map<Integer, List<Map<String,String>>> events = new HashMap<>();

        try {
          Class.forName("org.mariadb.jdbc.Driver");
          conn = DriverManager.getConnection(url, dbUser, dbPass);

          Calendar startCal = (Calendar) display.clone();
          startCal.set(Calendar.DAY_OF_MONTH, 1);
          Calendar endCal = (Calendar) display.clone();
          endCal.set(Calendar.DAY_OF_MONTH, daysInMonth);

          java.sql.Date startDate = new java.sql.Date(startCal.getTimeInMillis());
          java.sql.Date endDate = new java.sql.Date(endCal.getTimeInMillis());

          // 시간순 정렬(ORDER BY event_time ASC) 적용
          String sql = "SELECT id, title, event_date, event_time, details, category FROM schedule WHERE event_date BETWEEN ? AND ? ORDER BY event_time ASC";
          ps = conn.prepareStatement(sql);
          ps.setDate(1, startDate);
          ps.setDate(2, endDate);
          rs = ps.executeQuery();

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
            ev.put("time", rs.getString("event_time").substring(0, 5)); // HH:mm 형식으로 자르기
            
            String detailsStr = rs.getString("details");
            ev.put("details", detailsStr != null ? detailsStr : "내용 없음");
            
            events.computeIfAbsent(day, k -> new ArrayList<>()).add(ev);
          }
        } catch (Exception e) {
          out.println("<p style='color:red;'>DB 오류: " + e.getMessage() + "</p>");
        } finally {
          if (rs != null) try { rs.close(); } catch(Exception ignored) {}
          if (ps != null) try { ps.close(); } catch(Exception ignored) {}
          if (conn != null) try { conn.close(); } catch(Exception ignored) {}
        }
      %>

      <div class="controls">
        <a href="?year=<%= prev.get(Calendar.YEAR) %>&month=<%= prev.get(Calendar.MONTH)+1 %>">&laquo; 이전</a>
        <strong><%= (displayYear) %>년 <%= (displayMonth+1) %>월</strong>
        <a href="?year=<%= next.get(Calendar.YEAR) %>&month=<%= next.get(Calendar.MONTH)+1 %>">다음 &raquo;</a>
      </div>

      <table class="calendar">
        <tr>
          <th>일</th><th>월</th><th>화</th><th>수</th><th>목</th><th>금</th><th>토</th>
        </tr>
        <%
          int dayCounter = 1;
          out.println("<tr>");
          // 첫 주 빈칸
          for (int i = 1; i < firstDayOfWeek; i++) {
            out.println("<td></td>");
          }
          for (int i = firstDayOfWeek; i <= 7; i++) {
            out.println("<td>");
            if (dayCounter <= daysInMonth) {
              out.println("<span class='date-num'>" + dayCounter + "</span>");
              List<Map<String,String>> list = events.get(dayCounter);
              if (list != null) {
                for (Map<String,String> ev : list) {
                  String cat = ev.get("category");
                  String cls = "cat-other";
                  if ("연주회".equals(cat)) cls = "cat-concert";
                  else if ("정기 연습".equals(cat)) cls = "cat-practice";
                  else if ("동아리방 사용".equals(cat)) cls = "cat-room";
                  
                  // 따옴표로 인한 HTML 깨짐 방지
                  String safeTitle = ev.get("title").replace("'", "&#39;");
                  String safeDetails = ev.get("details").replace("\"", "&quot;").replace("'", "&#39;");
                  
                  out.println("<span class='event " + cls + "' style='cursor:pointer;' " +
                              "data-title='" + safeTitle + "' " +
                              "data-date='" + ev.get("date") + "' " +
                              "data-time='" + ev.get("time") + "' " +
                              "data-details='" + safeDetails + "'>" +
                              "[" + ev.get("time") + "] " + safeTitle + "</span>");
                }
              }
              dayCounter++;
            }
            out.println("</td>");
          }
          out.println("</tr>");

          while (dayCounter <= daysInMonth) {
            out.println("<tr>");
            for (int i = 1; i <= 7; i++) {
              out.println("<td>");
              if (dayCounter <= daysInMonth) {
                out.println("<span class='date-num'>" + dayCounter + "</span>");
                List<Map<String,String>> list = events.get(dayCounter);
                if (list != null) {
                  for (Map<String,String> ev : list) {
                    String cat = ev.get("category");
                    String cls = "cat-other";
                    if ("연주회".equals(cat)) cls = "cat-concert";
                    else if ("정기 연습".equals(cat)) cls = "cat-practice";
                    else if ("동아리방 사용".equals(cat)) cls = "cat-room";
                    
                    String safeTitle = ev.get("title").replace("'", "&#39;");
                    String safeDetails = ev.get("details").replace("\"", "&quot;").replace("'", "&#39;");
                    
                    out.println("<span class='event " + cls + "' style='cursor:pointer;' " +
                                "data-title='" + safeTitle + "' " +
                                "data-date='" + ev.get("date") + "' " +
                                "data-time='" + ev.get("time") + "' " +
                                "data-details='" + safeDetails + "'>" +
                                "[" + ev.get("time") + "] " + safeTitle + "</span>");
                  }
                }
                dayCounter++;
              }
              out.println("</td>");
            }
            out.println("</tr>");
          }
        %>
      </table>

      <div class="legend">
        <span style="background:#FFA500;">연주회</span>
        <span style="background:#ADD8E6;">정기 연습</span>
        <span style="background:#90EE90;">동아리방 사용</span>
        <span style="background:#D3D3D3;">기타 행사</span>
      </div>

    </section>
  </main>
</div>

<div id="eventModal" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%, -50%); background:#fff; padding:25px; border:1px solid #ccc; box-shadow:0 4px 15px rgba(0,0,0,0.2); z-index:1000; border-radius:8px; width:350px;">
  <h3 id="modalTitle" style="margin-top:0; border-bottom:2px solid #007acc; padding-bottom:10px;"></h3>
  <p style="margin:8px 0;"><strong>일자:</strong> <span id="modalDate"></span></p>
  <p style="margin:8px 0;"><strong>시간:</strong> <span id="modalTime"></span></p>
  <p style="margin:8px 0;"><strong>세부사항:</strong></p>
  <div id="modalDetails" style="background:#f1f1f1; padding:12px; border-radius:4px; min-height:60px; font-size:14px; white-space:pre-wrap;"></div>
  <div style="text-align:right; margin-top:15px;">
    <button onclick="document.getElementById('eventModal').style.display='none'" style="padding:6px 15px; background:#555; color:#fff; border:none; border-radius:4px; cursor:pointer;">닫기</button>
  </div>
</div>

<script>
  // 달력의 일정을 클릭했을 때 모달창에 정보 세팅 및 표시
  document.querySelectorAll('.event').forEach(function(el){
    el.addEventListener('click', function(){
      document.getElementById('modalTitle').textContent = this.getAttribute('data-title');
      document.getElementById('modalDate').textContent = this.getAttribute('data-date');
      document.getElementById('modalTime').textContent = this.getAttribute('data-time');
      document.getElementById('modalDetails').textContent = this.getAttribute('data-details');
      
      document.getElementById('eventModal').style.display = 'block';
    });
  });
</script>

</body>
</html>
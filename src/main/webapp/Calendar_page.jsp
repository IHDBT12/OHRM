<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>캘린더</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
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
  <h2>캘린더</h2>

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

    // DB 연결 정보 (환경에 맞게 수정)
    String url = "jdbc:mariadb://localhost:3306/orchestra_db";
    String dbUser = "root";
    String dbPass = "1234";

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    // 일정 맵: day -> List of maps(title, category)
    Map<Integer, List<Map<String,String>>> events = new HashMap<>();

    try {
      Class.forName("org.mariadb.jdbc.Driver");
      conn = DriverManager.getConnection(url, dbUser, dbPass);

      // 해당 월의 시작일과 종료일 계산
      Calendar startCal = (Calendar) display.clone();
      startCal.set(Calendar.DAY_OF_MONTH, 1);
      Calendar endCal = (Calendar) display.clone();
      endCal.set(Calendar.DAY_OF_MONTH, daysInMonth);

      java.sql.Date startDate = new java.sql.Date(startCal.getTimeInMillis());
      java.sql.Date endDate = new java.sql.Date(endCal.getTimeInMillis());

      String sql = "SELECT id, title, event_date, category FROM schedule WHERE event_date BETWEEN ? AND ?";
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
              out.println("<span class='event " + cls + "' data-id='" + ev.get("id") + "'>" + ev.get("title") + "</span>");
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
                out.println("<span class='event " + cls + "' data-id='" + ev.get("id") + "'>" + ev.get("title") + "</span>");
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

  <script>
    // 간단한 이벤트 클릭 처리: 클릭하면 alert로 제목 표시 (원하면 모달/상세페이지로 확장)
    document.querySelectorAll('.event').forEach(function(el){
      el.addEventListener('click', function(){
        var title = this.textContent;
        alert("일정: " + title);
        // 확장: AJAX로 상세 정보 불러오기 또는 상세 페이지로 이동
      });
    });
  </script>
</body>
</html>

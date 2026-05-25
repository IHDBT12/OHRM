<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
  // 권한 체크
  String userRole = (String) session.getAttribute("user_role");
  if (!"ADMIN".equals(userRole)) {
%>
    <script>
      alert("접근 권한이 없습니다. 관리자만 이용 가능합니다.");
      location.href = "index.jsp";
    </script>
<%
    return;
  }

  // 단원 강제 삭제 요청 처리
  String deleteIdStr = request.getParameter("delete_student_id");
  if (deleteIdStr != null) {
    try {
      Class.forName("org.mariadb.jdbc.Driver");
      String url = "jdbc:mariadb://localhost:3306/ohrm_db";
      try (Connection conn = DriverManager.getConnection(url, "root", "1234")) {
        String deleteSql = "DELETE FROM members WHERE student_id = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(deleteSql)) {
          pstmt.setInt(1, Integer.parseInt(deleteIdStr));
          pstmt.executeUpdate();
        }
      }
%>
      <script>
        alert("해당 단원이 성공적으로 삭제 처리되었습니다.");
        location.href = "admin_member_management.jsp";
      </script>
<%
      return;
    } catch (Exception e) {
      out.println("<script>alert('삭제 실패: " + e.getMessage() + "');</script>");
    }
  }
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>오케스트라 관리자 - 단원 관리</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
  <style>
    body { font-family: sans-serif; padding: 20px; background: #f9fafb; }
    .admin-box { background: #fff; max-width: 900px; margin: 0 auto; padding: 30px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); position: relative; }
    h2 { color: #1e3a8a; border-bottom: 2px solid #e5e7eb; padding-bottom: 10px; margin-top: 15px; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #e5e7eb; }
    th { background-color: #f3f4f6; }
    .btn-danger { background: #dc2626; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer; }
    .badge { background: #1e3a8a; color: white; padding: 2px 6px; border-radius: 4px; font-size: 12px; }
    
    .back-to-home {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        background-color: #f3f4f6;
        color: #4b5563;
        padding: 8px 16px;
        font-size: 14px;
        font-weight: 600;
        text-decoration: none;
        border-radius: 6px;
        border: 1px solid #e5e7eb;
        transition: all 0.2s ease;
    }
    .back-to-home:hover {
        background-color: #e5e7eb;
        color: #1f2937;
        box-shadow: 0 2px 4px rgba(0,0,0,0.05);
    }
  </style>
</head>
<body>

<div class="admin-box">
  
  <a href="index.jsp" class="back-to-home">
    <i class="bi bi-arrow-left"></i> 오케스트라 홈으로 돌아가기
  </a>

  <h2>🛡️ 오케스트라 단원 명단 관리 (관리자 모드)</h2>
  <p>시스템에 등록된 전체 단원 목록입니다.</p>

  <table>
    <thead>
      <tr>
        <th>학번</th>
        <th>이름</th>
        <th>기수</th>
        <th>연락처</th>
        <th>악기</th>
        <th>등급</th>
        <th>관리</th>
      </tr>
    </thead>
    <tbody>
    <%
      try {
        Class.forName("org.mariadb.jdbc.Driver");
        String url = "jdbc:mariadb://localhost:3306/ohrm_db";
        try (Connection conn = DriverManager.getConnection(url, "root", "1234");
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT student_id, name, cohort, phone, instrument, role FROM members ORDER BY cohort DESC, student_id ASC")) {
          
          while(rs.next()) {
            int sid = rs.getInt("student_id");
            String name = rs.getString("name");
            int cohort = rs.getInt("cohort");
            String phone = rs.getString("phone");
            String instrument = rs.getString("instrument");
            String role = rs.getString("role");
    %>
            <tr>
              <td><%= sid %></td>
              <td><%= name %></td>
              <td><%= cohort %>기</td>
              <td><%= phone %></td>
              <td><%= instrument %></td>
              <td><%= "ADMIN".equals(role) ? "<span class='badge'>관리자</span>" : "일반단원" %></td>
              <td>
                <% if(!"ADMIN".equals(role)) { %>
                  <form action="admin_member_management.jsp" method="post" onsubmit="return confirm('<%= name %> 단원을 정말 강제 탈퇴시키겠습니까?');" style="margin:0;">
                    <input type="hidden" name="delete_student_id" value="<%= sid %>">
                    <button type="submit" class="btn-danger">삭제</button>
                  </form>
                <% } else { %> - <% } %>
              </td>
            </tr>
    <%
          }
        }
      } catch(Exception e) {
        out.println("<tr><td colspan='7'>오류: " + e.getMessage() + "</td></tr>");
      }
    %>
    </tbody>
  </table>
</div>

</body>
</html>
<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
  request.setCharacterEncoding("UTF-8");

  // 권한 체크 (세션 확인)
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

  String url = "jdbc:mariadb://localhost:3306/ohrm_db";
  String dbUser = "root";
  String dbPassword = "1234";

  // [트랜잭션 적용] 단원 강제 삭제 요청 처리
  String deleteIdStr = request.getParameter("delete_student_id");
  if (deleteIdStr != null) {
    Connection conn = null;
    try {
      Class.forName("org.mariadb.jdbc.Driver");
      conn = DriverManager.getConnection(url, dbUser, dbPassword);
      
      // 수동 커밋 모드로 전환하여 트랜잭션(Transaction)을 시작합니다.
      conn.setAutoCommit(false);

      int targetStudentId = Integer.parseInt(deleteIdStr);

      // [연관 데이터 처리] 탈퇴할 단원이 등록한 사진첩 앨범 데이터 처리
      // 외래키(FK) 제약조건으로 인한 에러를 막기 위해 uploader_student_id를 NULL('미상')로 업데이트
      String updateAlbumsSql = "UPDATE photo_albums SET uploader_student_id = NULL WHERE uploader_student_id = ?";
      try (PreparedStatement pstmt1 = conn.prepareStatement(updateAlbumsSql)) {
        pstmt1.setInt(1, targetStudentId);
        pstmt1.executeUpdate();
      }

      // [연관 데이터 처리] 만약 단원과 연결된 다른 매핑 테이블(출석, 회비 등)이 있다면 여기에 추가 쿼리를 작성

      // [메인 데이터 처리] 최종적으로 members 테이블에서 해당 단원을 삭제
      String deleteMemberSql = "DELETE FROM members WHERE student_id = ?";
      try (PreparedStatement pstmt2 = conn.prepareStatement(deleteMemberSql)) {
        pstmt2.setInt(1, targetStudentId);
        pstmt2.executeUpdate();
      }

      // 모든 연관 쿼리가 단 하나도 실패하지 않고 성공했을 때만 최종 Commit
      
      conn.commit();

%>
      <script>
        alert("해당 단원 정보 및 연관 데이터가 트랜잭션 안에서 안전하게 삭제/정리 처리되었습니다.");
        location.href = "admin_member_management.jsp";
      </script>
<%
      return;
    } catch (Exception e) {
    	
      // 실행 도중 에러가 발생하면 수행했던 모든 작업을 취소하고 초기 상태로 되돌립니다.
      
      if (conn != null) {
        try { 
          conn.rollback(); 
        } catch (SQLException ex) {
          ex.printStackTrace();
        }
      }
      out.println("<script>alert('삭제 작업 실패 (데이터가 안전하게 롤백되었습니다): " + e.getMessage() + "'); history.back();</script>");
      return;
    } finally {
      // 자원 반납 및 연결 종료
      if (conn != null) {
        try { conn.close(); } catch (SQLException ex) {}
      }
    }
  }

  // 등급 및 권한 변경 요청 처리 (ADMIN ↔ USER)
  String toggleIdStr = request.getParameter("toggle_student_id");
  String targetRole = request.getParameter("target_role");
  if (toggleIdStr != null && targetRole != null) {
    try {
      Class.forName("org.mariadb.jdbc.Driver");
      try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword)) {
        String updateRoleSql = "UPDATE members SET role = ? WHERE student_id = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(updateRoleSql)) {
          pstmt.setString(1, targetRole);
          pstmt.setInt(2, Integer.parseInt(toggleIdStr));
          pstmt.executeUpdate();
        }
      }
%>
      <script>
        alert("단원의 권한 등급이 성공적으로 변경되었습니다.");
        location.href = "admin_member_management.jsp";
      </script>
<%
      return;
    } catch (Exception e) {
      out.println("<script>alert('권한 변경 실패: " + e.getMessage() + "');</script>");
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
    .admin-box { background: #fff; max-width: 950px; margin: 0 auto; padding: 30px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); position: relative; }
    h2 { color: #1e3a8a; border-bottom: 2px solid #e5e7eb; padding-bottom: 10px; margin-top: 15px; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #e5e7eb; vertical-align: middle; }
    th { background-color: #f3f4f6; }
    
    .btn-custom {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 4px;
        font-size: 13px;
        font-weight: 600;
        padding: 6px 12px;
        border-radius: 6px;
        border: 1px solid transparent;
        cursor: pointer;
        text-decoration: none;
        transition: all 0.2s ease;
    }
    .btn-custom.btn-danger {
        background: #fff5f5;
        color: #dc2626;
        border-color: #ffe3e3;
    }
    .btn-custom.btn-danger:hover {
        background: #dc2626;
        color: white;
    }
    .btn-custom.btn-assign {
        background: #eff6ff;
        color: #2563eb;
        border-color: #dbeafe;
    }
    .btn-custom.btn-assign:hover {
        background: #2563eb;
        color: white;
    }
    .btn-custom.btn-demote {
        background: #fdf2f8;
        color: #db2777;
        border-color: #fce7f3;
    }
    .btn-custom.btn-demote:hover {
        background: #db2777;
        color: white;
    }

    .badge { background: #1e3a8a; color: white; padding: 3px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
    
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
  <p>시스템에 등록된 전체 단원 목록입니다. 등급을 관리자 권한으로 변경하거나 회수를 진행할 수 있습니다.</p>

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
        try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword);
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT student_id, name, cohort, phone, instrument, role FROM members ORDER BY cohort DESC, student_id ASC")) {
          
          while(rs.next()) {
            int sid = rs.getInt("student_id");
            String name = rs.getString("name");
            int cohort = rs.getInt("cohort");
            String phone = rs.getString("phone");
            String instrument = rs.getString("instrument");
            String role = rs.getString("role");
            boolean isAdmin = "ADMIN".equals(role);
    %>
            <tr>
              <td><%= sid %></td>
              <td><strong><%= name %></strong></td>
              <td><%= cohort %>기</td>
              <td><%= phone %></td>
              <td><%= instrument %></td>
              <td><%= isAdmin ? "<span class='badge'><i class='bi bi-shield-fill-check me-1'></i>관리자</span>" : "일반단원" %></td>
              <td>
                <div style="display: flex; gap: 6px; align-items: center; flex-wrap: nowrap;">
                  <% if (!isAdmin) { %>
                    <form action="admin_member_management.jsp" method="post" onsubmit="return confirm('<%= name %> 단원에게 관리자 권한을 부여하시겠습니까?');" style="margin:0; display: inline-block;">
                      <input type="hidden" name="toggle_student_id" value="<%= sid %>">
                      <input type="hidden" name="target_role" value="ADMIN">
                      <button type="submit" class="btn-custom btn-assign"><i class="bi bi-shield-plus"></i> 권한 부여</button>
                    </form>
                  <% } else { %>
                    <form action="admin_member_management.jsp" method="post" onsubmit="return confirm('<%= name %> 관리자의 권한을 회수하여 일반단원으로 변경하시겠습니까?');" style="margin:0; display: inline-block;">
                      <input type="hidden" name="toggle_student_id" value="<%= sid %>">
                      <input type="hidden" name="target_role" value="MEMBER">
                      <button type="submit" class="btn-custom btn-demote"><i class="bi bi-shield-minus"></i> 권한 회수</button>
                    </form>
                  <% } %>

                  <% if(!isAdmin) { %>
                    <form action="admin_member_management.jsp" method="post" onsubmit="return confirm('<%= name %> 단원을 정말 강제 탈퇴시키겠습니까?\n(탈퇴 시 해당 단원이 작성한 사진첩의 작성자 정보는 자동으로 미상 처리됩니다.)');" style="margin:0; display: inline-block;">
                      <input type="hidden" name="delete_student_id" value="<%= sid %>">
                      <button type="submit" class="btn-custom btn-danger"><i class="bi bi-trash3"></i> 삭제</button>
                    </form>
                  <% } %>
                </div>
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
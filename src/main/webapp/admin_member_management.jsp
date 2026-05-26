<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
  request.setCharacterEncoding("UTF-8");

  // 페이지 접근 권한 체크 (MASTER 또는 ADMIN만 진입 가능)
  String userRole = (String) session.getAttribute("user_role");
  if (userRole != null) {
    userRole = userRole.trim().toUpperCase(); 
  }

  if (!"MASTER".equals(userRole) && !"ADMIN".equals(userRole)) {
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

  // 단원 강제 삭제 요청 처리 (트랜잭션 보장)
  String deleteIdStr = request.getParameter("delete_student_id");
  if (deleteIdStr != null) {
    Connection conn = null;
    try {
      Class.forName("org.mariadb.jdbc.Driver");
      conn = DriverManager.getConnection(url, dbUser, dbPassword);
      
      int targetStudentId = Integer.parseInt(deleteIdStr);

      // [백엔드 이중 보안] 삭제 대상의 실제 DB 권한을 먼저 조회하여 검증
      String checkTargetRoleSql = "SELECT role FROM members WHERE student_id = ?";
      String targetDbRole = "";
      try (PreparedStatement pstmtCheck = conn.prepareStatement(checkTargetRoleSql)) {
          pstmtCheck.setInt(1, targetStudentId);
          try (ResultSet rsCheck = pstmtCheck.executeQuery()) {
              if (rsCheck.next()) {
                  targetDbRole = rsCheck.getString("role");
                  if (targetDbRole != null) targetDbRole = targetDbRole.trim().toUpperCase();
              }
          }
      }

      // ADMIN 끼리 삭제를 시도하거나, MASTER를 삭제하려는 경우 백엔드에서 즉시 차단
      if ("ADMIN".equals(userRole) && "ADMIN".equals(targetDbRole)) {
%>
        <script>
          alert("권한 오류: 관리자(ADMIN)는 다른 관리자를 강제 탈퇴시킬 수 없습니다.");
          location.href = "admin_member_management.jsp";
        </script>
<%
        return;
      }
      if ("MASTER".equals(targetDbRole)) {
%>
        <script>
          alert("권한 오류: 최고 권한자(MASTER)는 탈퇴 처리할 수 없습니다.");
          location.href = "admin_member_management.jsp";
        </script>
<%
        return;
      }

      // 수동 커밋 모드로 전환하여 트랜잭션(Transaction) 시작
      conn.setAutoCommit(false);

      String updateAlbumsSql = "UPDATE photo_albums SET uploader_student_id = NULL WHERE uploader_student_id = ?";
      try (PreparedStatement pstmt1 = conn.prepareStatement(updateAlbumsSql)) {
        pstmt1.setInt(1, targetStudentId);
        pstmt1.executeUpdate();
      }

      String deleteMemberSql = "DELETE FROM members WHERE student_id = ?";
      try (PreparedStatement pstmt2 = conn.prepareStatement(deleteMemberSql)) {
        pstmt2.setInt(1, targetStudentId);
        pstmt2.executeUpdate();
      }

      conn.commit();

%>
      <script>
        alert("해당 단원 정보 및 연관 데이터가 안전하게 삭제/정리 처리되었습니다.");
        location.href = "admin_member_management.jsp";
      </script>
<%
      return;
    } catch (Exception e) {
      if (conn != null) {
        try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
      }
      out.println("<script>alert('삭제 작업 실패: " + e.getMessage() + "'); history.back();</script>");
      return;
    } finally {
      if (conn != null) {
        try { conn.close(); } catch (SQLException ex) {}
      }
    }
  }

  // [MASTER] 등급 및 권한 변경 요청 처리 (ADMIN ↔ USER)
  String toggleIdStr = request.getParameter("toggle_student_id");
  String targetRole = request.getParameter("target_role"); 
  if (toggleIdStr != null && targetRole != null) {
    
    if (!"MASTER".equals(userRole)) {
%>
      <script>
        alert("권한 변경 실패: 등급 수정 기능은 최고 권한자(MASTER)에게만 허용됩니다.");
        location.href = "admin_member_management.jsp";
      </script>
<%
      return;
    }

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
    .btn-custom.btn-danger { background: #fff5f5; color: #dc2626; border-color: #ffe3e3; }
    .btn-custom.btn-danger:hover { background: #dc2626; color: white; }
    .btn-custom.btn-assign { background: #eff6ff; color: #2563eb; border-color: #dbeafe; }
    .btn-custom.btn-assign:hover { background: #2563eb; color: white; }
    .btn-custom.btn-demote { background: #fdf2f8; color: #db2777; border-color: #fce7f3; }
    .btn-custom.btn-demote:hover { background: #db2777; color: white; }

    .badge { padding: 3px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; color: white; }
    .badge.badge-master { background: #d97706; } 
    .badge.badge-admin { background: #1e3a8a; }  
    
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
  <p>시스템에 등록된 전체 단원 목록입니다. <strong>등급 변경 및 회수 제어는 오직 최고 관리자(MASTER)만 가능합니다.</strong></p>

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
             ResultSet rs = stmt.executeQuery("SELECT student_id, name, cohort, phone, instrument, role FROM members ORDER BY CASE role WHEN 'MASTER' THEN 1 WHEN 'ADMIN' THEN 2 ELSE 3 END, cohort DESC, student_id ASC")) {
          
          while(rs.next()) {
            int sid = rs.getInt("student_id");
            String name = rs.getString("name");
            int cohort = rs.getInt("cohort");
            String phone = rs.getString("phone");
            String instrument = rs.getString("instrument");
            
            String dbRole = rs.getString("role");
            if (dbRole != null) {
                dbRole = dbRole.trim().toUpperCase();
            }
            
            boolean isTargetMaster = "MASTER".equals(dbRole);
            boolean isTargetAdmin = "ADMIN".equals(dbRole);
    %>
            <tr>
              <td><%= sid %></td>
              <td><strong><%= name %></strong></td>
              <td><%= cohort %>기</td>
              <td><%= phone %></td>
              <td><%= instrument %></td>
              <td>
                <% if (isTargetMaster) { %>
                  <span class="badge badge-master"><i class="bi bi-crown-fill me-1"></i>최고권한자</span>
                <% } else if (isTargetAdmin) { %>
                  <span class="badge badge-admin"><i class="bi bi-shield-fill-check me-1"></i>관리자</span>
                <% } else { %>
                  일반단원
                <% } %>
              </td>
              <td>
                <div style="display: flex; gap: 6px; align-items: center; flex-wrap: nowrap;">
                  
                  <% if ("MASTER".equals(userRole)) { %>
                    <% if (!isTargetMaster && !isTargetAdmin) { %>
                      <form action="admin_member_management.jsp" method="post" onsubmit="return confirm('<%= name %> 단원에게 관리자 권한을 부여하시겠습니까?');" style="margin:0; display: inline-block;">
                        <input type="hidden" name="toggle_student_id" value="<%= sid %>">
                        <input type="hidden" name="target_role" value="ADMIN">
                        <button type="submit" class="btn-custom btn-assign"><i class="bi bi-shield-plus"></i> 권한 부여</button>
                      </form>
                    <% } else if (isTargetAdmin) { %>
                      <form action="admin_member_management.jsp" method="post" onsubmit="return confirm('<%= name %> 관리자의 권한을 회수하여 일반단원으로 변경하시겠습니까?');" style="margin:0; display: inline-block;">
                        <input type="hidden" name="toggle_student_id" value="<%= sid %>">
                        <input type="hidden" name="target_role" value="USER">
                        <button type="submit" class="btn-custom btn-demote"><i class="bi bi-shield-minus"></i> 권한 회수</button>
                      </form>
                    <% } %>
                  <% } %>

                  <%-- [프론트엔드 제어] 
                       1. 대상이 MASTER인 경우 누구든 삭제 불가
                       2. 로그인한 세션이 ADMIN인데 대상도 ADMIN인 경우 삭제 버튼을 숨김 --%>
                  <% 
                    boolean canDelete = true;
                    if (isTargetMaster) {
                        canDelete = false; // 마스터는 불가능
                    } else if ("ADMIN".equals(userRole) && isTargetAdmin) {
                        canDelete = false; // ADMIN 끼리는 삭제 불가능
                    }
                    
                    if (canDelete) { 
                  %>
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
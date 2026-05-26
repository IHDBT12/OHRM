<%@ page contentType="text/html; charset=UTF-8" language="java" pageEncoding="UTF-8"%>
<%@ page import="java.io.File"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.sql.DriverManager"%>
<%@ page import="java.sql.PreparedStatement"%>
<%@ page import="java.sql.ResultSet"%>
<%@ page import="ohrm.util.AuthUtils"%>
<%@ page import="static ohrm.util.JspUtils.*"%>
<%
request.setCharacterEncoding("UTF-8");

String url = "jdbc:mariadb://localhost:3306/ohrm_db";
String dbUser = "root";
String dbPassword = "1234";

Integer sessionStudentId = AuthUtils.currentStudentId(request);
if (sessionStudentId == null) {
   response.sendRedirect("login.jsp");
   return;
}

int studentId = sessionStudentId;
String activeMenu = "home";

// 프로필 사진 적용
String memberDefaultImage = "assets/img/member/member.png";
String memberCandidateImage = "assets/img/member/" + studentId + ".png";
String memberCandidatePath = application.getRealPath(memberCandidateImage);
String memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists() ? memberCandidateImage
      : memberDefaultImage;

String name = "";
int totalMembers = 0;
int upcomingSchedules = 0;

try {
   Class.forName("org.mariadb.jdbc.Driver");
   try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword)) {
      
      // 1. 사용자 이름 조회
      try (PreparedStatement pstmt = conn.prepareStatement("SELECT name FROM members WHERE student_id = ?")) {
         pstmt.setInt(1, studentId);
         try (ResultSet rs = pstmt.executeQuery()) {
            if (rs.next()) {
               name = text(rs, "name");
            }
         }
      }
      
      // 2. [통계] 총 동아리원 수 조회
      try (PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM members");
          ResultSet rs = pstmt.executeQuery()) {
         if (rs.next()) totalMembers = rs.getInt(1);
      }
      
      // 3. [통계] 다가오는 연습/행사 일정 수 조회 (현재 날짜 이후)
      try (PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM schedule WHERE event_date >= CURDATE()");
          ResultSet rs = pstmt.executeQuery()) {
         if (rs.next()) upcomingSchedules = rs.getInt(1);
      }
      
   }
} catch (Exception e) {
   e.printStackTrace();
}
%>
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>오케스트라 단원 관리 시스템</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<link rel="stylesheet" href="assets/css/common.css">
<link rel="stylesheet" href="assets/css/home.css">
</head>
<body>
   <div class="app-shell">
      <%@ include file="/WEB-INF/fragments/sidebar.jspf"%>

      <main class="main">
         <%@ include file="/WEB-INF/fragments/topbar.jspf"%>

         <section class="content container-fluid py-4">
            <div class="mb-4">
               <h2 class="fw-bold">안녕하세요, <span style="color: #d97706 !important;"><%= name %></span> 님!</h2>
               <p class="text-muted">오케스트라 동아리 단원 관리 프로그램에 접속하신 것을 환영합니다.</p>
            </div>

            <div class="row g-3 mb-4">
               <div class="col-12 col-sm-6 col-md-6">
                  <div class="card border-0 shadow-sm p-3">
                     <div class="d-flex align-items-center">
                        <div class="badge bg-primary-subtle text-primary p-3 fs-4 rounded-3 me-3">
                           <i class="bi bi-people-fill"></i>
                        </div>
                        <div>
                           <h6 class="text-muted mb-1">총 동아리원</h6>
                           <h3 class="fw-bold mb-0"><%= totalMembers %> 명</h3>
                        </div>
                     </div>
                  </div>
               </div>

               <div class="col-12 col-sm-6 col-md-6">
                  <div class="card border-0 shadow-sm p-3">
                     <div class="d-flex align-items-center">
                        <div class="badge bg-success-subtle text-success p-3 fs-4 rounded-3 me-3">
                           <i class="bi bi-calendar-event-fill"></i>
                        </div>
                        <div>
                           <h6 class="text-muted mb-1">다가오는 일정</h6>
                           <h3 class="fw-bold mb-0"><%= upcomingSchedules %> 건</h3>
                        </div>
                     </div>
                  </div>
               </div>
            </div>

            <div class="card border-0 shadow-sm p-4">
               <h5>📢 시스템 안내</h5>
               <p class="mb-0 text-secondary">좌측 메뉴를 통해 단원 정보 관리, 악기 대여 현황, 연습 기록 및 출석 체크를 진행할 수 있습니다.</p>
            </div>
         </section>
      </main>
   </div>
</body>
</html>
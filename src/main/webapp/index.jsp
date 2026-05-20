<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.File"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.sql.DriverManager"%>
<%@ page import="java.sql.PreparedStatement"%>
<%@ page import="java.sql.ResultSet"%>
<%@ page import="ohrm.util.AuthUtils"%>
<%@ page import="static ohrm.util.JspUtils.*"%>
<%
request.setCharacterEncoding("UTF-8");

// DB 접속 정보
String url = "jdbc:mariadb://localhost:3306/ohrm_db";
String dbUser = "root";
String dbPassword = "1234";
// 세션 검증
Integer sessionStudentId = AuthUtils.currentStudentId(request);
if (sessionStudentId == null) {
	response.sendRedirect("login.jsp");
	return;
}

// 세션 정보 저장
int studentId = sessionStudentId;
// 사이드바에서 쓰일 변수
String activeMenu = "home";

// 프로필 사진 적용
String memberDefaultImage = "assets/img/member/member.png";
String memberCandidateImage = "assets/img/member/" + studentId + ".png";
String memberCandidatePath = application.getRealPath(memberCandidateImage);
String memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists() ? memberCandidateImage
		: memberDefaultImage;

String name = "";
try {
	Class.forName("org.mariadb.jdbc.Driver");
	try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword);
	// SQL문 저장, SQL 인젝션 방지
	PreparedStatement pstmt = conn.prepareStatement("SELECT name FROM members WHERE student_id = ?")) {
		// 첫번째 ?에 채우기
		pstmt.setInt(1, studentId);
		// SQL문 실행해서 이름 값 가져오기
		try (ResultSet rs = pstmt.executeQuery()) {
			if (rs.next()) {
				name = text(rs, "name");
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
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>오케스트라 회원 관리 시스템</title>
<link rel="stylesheet"
	href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<link rel="stylesheet" href="assets/css/common.css">
<link rel="stylesheet" href="assets/css/home.css">
</head>
<body>
	<div class="app-shell">
		<%@ include file="/WEB-INF/fragments/sidebar.jspf"%>

		<main class="main">
			<%@ include file="/WEB-INF/fragments/topbar.jspf"%>

			<section class="content ready-page">
				<h1>오케스트라 동아리 인원 관리프로그램입니다.</h1>
			</section>
		</main>
	</div>
</body>
</html>

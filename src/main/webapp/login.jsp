<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%@ page import="static ohrm.util.JspUtils.*" %>
<%
  request.setCharacterEncoding("UTF-8");

  if (AuthUtils.currentStudentId(request) != null) {
    response.sendRedirect("index.jsp");
    return;
  }

  String errorParam = request.getParameter("error");
  String sessionError = (String) session.getAttribute("loginError");
  session.removeAttribute("loginError");

  String errorMsg = null;
  if (errorParam != null) {
    errorMsg = "학번 또는 비밀번호를 확인해주세요.";
  } else if (sessionError != null) {
    errorMsg = sessionError;
  }

  // 기존에 입력했던 학번이 있다면 가져와서 남겨둠 (사용자 편의성)
  String studentIdStr = request.getParameter("studentId");
  if (studentIdStr == null) {
    studentIdStr = request.getParameter("student_id");
  }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
  <title>오케스트라 시스템 - 로그인</title>
  <style>
    body { font-family: 'Pretendard', sans-serif; background: #f5f7fb; color: #111827; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
    .login-container { background: #fff; width: 420px; padding: 40px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); border: 1px solid #e5e7eb; box-sizing: border-box; }
    .logo-area { text-align: center; margin-bottom: 30px; }
    .logo-area h2 { color: #001f3f; margin: 0; font-size: 24px; font-weight: bold; }
    .logo-area p { color: #64748b; margin: 5px 0 0 0; font-size: 14px; }
    
    .form-group { margin-bottom: 20px; }
    .form-group label { display: block; font-size: 14px; font-weight: 600; color: #374151; margin-bottom: 6px; }
    .form-input { width: 100%; padding: 10px 12px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 14px; box-sizing: border-box; font-family: inherit; transition: border 0.2s ease; }
    .form-input:focus { outline: none; border-color: #001f3f; }
    
    .btn-submit { width: 100%; padding: 12px; background: #001f3f; color: #fff; border: none; border-radius: 8px; font-size: 16px; font-weight: bold; cursor: pointer; transition: background 0.2s ease; margin-top: 10px; }
    .btn-submit:hover { background: #002f5f; }
    
    /* 에러 메시지 박스 스타일 */
    .msg-box { padding: 12px; border-radius: 8px; font-size: 13px; font-weight: 500; margin-bottom: 20px; text-align: center; }
    .msg-error { background: #fee2e2; color: #dc2626; border: 1px solid #fca5a5; }
    
    .link-area { text-align: center; margin-top: 20px; font-size: 14px; color: #64748b; }
    .link-area a { color: #001f3f; text-decoration: none; font-weight: bold; }
    .link-area a:hover { text-decoration: underline; }
  </style>
</head>
<body>

<div class="login-container">
  <div class="logo-area">
    <h2><i class="bi bi-shield-lock"></i> 단원 로그인</h2>
    <p>오케스트라 단원 통합 관리 시스템</p>
  </div>

  <%-- 에러 발생 시 출력되는 경고 메시지 박스 --%>
  <% if (errorMsg != null) { %>
    <div class="msg-box msg-error">
      <i class="bi bi-exclamation-triangle"></i> <%= html(errorMsg) %>
    </div>
  <% } %>

  <form action="login" method="post">
    
    <div class="form-group">
      <label for="studentId">학번 (ID)</label>
      <input type="number" name="studentId" id="studentId" class="form-input" required placeholder="학번을 입력하세요" value="<%= studentIdStr != null ? html(studentIdStr) : "" %>">
    </div>

    <div class="form-group">
      <label for="password">비밀번호</label>
      <input type="password" name="password" id="password" class="form-input" required placeholder="비밀번호를 입력하세요">
    </div>

    <button type="submit" class="btn-submit">로그인하기</button>
  </form>

  <div class="link-area">
    아직 단원으로 등록되지 않으셨나요? <a href="signup.jsp">신입 단원 가입</a>
  </div>
</div>

</body>
</html>
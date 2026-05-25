<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%@ page import="static ohrm.util.JspUtils.*" %>
<%
  request.setCharacterEncoding("UTF-8");

  if (AuthUtils.currentStudentId(request) != null) {
    response.sendRedirect("index.jsp");
    return;
  }

  Map<String, String> instrumentMap = new LinkedHashMap<>();
  instrumentMap.put("violin", "바이올린");
  instrumentMap.put("viola", "비올라");
  instrumentMap.put("cello", "첼로");
  instrumentMap.put("contrabass", "콘트라베이스");
  instrumentMap.put("flute", "플루트");
  instrumentMap.put("oboe", "오보에");
  instrumentMap.put("clarinet", "클라리넷");
  instrumentMap.put("horn", "호른");
  instrumentMap.put("trumpet", "트럼펫");
  instrumentMap.put("trombone", "트롬본");
  instrumentMap.put("percussion", "타악기");
  instrumentMap.put("etc", "기타");

  String error = request.getParameter("error");
  String errorMsg = null;
  if ("duplicate".equals(error)) {
    errorMsg = "이미 등록된 학번입니다.";
  } else if ("empty".equals(error)) {
    errorMsg = "필수 항목을 모두 입력해주세요.";
  } else if ("password".equals(error)) {
    errorMsg = "비밀번호와 비밀번호 확인이 일치하지 않습니다.";
  } else if ("invalid".equals(error)) {
    errorMsg = "입력값을 다시 확인해주세요.";
  } else if (error != null) {
    errorMsg = "회원가입 중 오류가 발생했습니다.";
  }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
  <title>오케스트라 회원 관리 시스템 - 회원가입</title>
  <style>
    body { font-family: 'Pretendard', Arial, sans-serif; background: #f5f7fb; color: #111827; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; padding: 24px; box-sizing: border-box; }
    .signup-container { background: #fff; width: 430px; padding: 36px; border-radius: 14px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); border: 1px solid #e5e7eb; box-sizing: border-box; }
    .logo-area { text-align: center; margin-bottom: 28px; }
    .logo-area h2 { color: #001f3f; margin: 0; font-size: 24px; }
    .logo-area p { color: #64748b; margin: 6px 0 0; font-size: 14px; }
    .form-group { margin-bottom: 16px; }
    .form-group label { display: block; font-size: 14px; font-weight: 600; color: #374151; margin-bottom: 6px; }
    .form-input { width: 100%; padding: 10px 12px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 14px; box-sizing: border-box; font-family: inherit; }
    .form-input:focus { outline: none; border-color: #001f3f; }
    .btn-submit { width: 100%; padding: 12px; background: #001f3f; color: #fff; border: 0; border-radius: 8px; font-size: 16px; font-weight: 700; cursor: pointer; margin-top: 8px; }
    .btn-submit:hover { background: #002f5f; }
    .msg-box { padding: 12px; border-radius: 8px; font-size: 13px; font-weight: 500; margin-bottom: 18px; text-align: center; background: #fee2e2; color: #dc2626; border: 1px solid #fca5a5; }
    .error-text { color: #dc2626; font-size: 12px; margin-top: 5px; display: none; }
    .link-area { text-align: center; margin-top: 18px; font-size: 14px; color: #64748b; }
    .link-area a { color: #001f3f; text-decoration: none; font-weight: 700; }
  </style>
</head>
<body>

<div class="signup-container">
  <div class="logo-area">
    <h2><i class="bi bi-person-plus"></i> 신입 단원 가입</h2>
    <p>오케스트라 회원 관리 시스템</p>
  </div>

  <% if (errorMsg != null) { %>
    <div class="msg-box"><i class="bi bi-exclamation-triangle"></i> <%= html(errorMsg) %></div>
  <% } %>

  <form action="signup" method="post" onsubmit="return validateForm();">
    <div class="form-group">
      <label for="studentId">학번</label>
      <input type="number" name="studentId" id="studentId" class="form-input" required placeholder="학번을 입력하세요">
    </div>

    <div class="form-group">
      <label for="name">이름</label>
      <input type="text" name="name" id="name" class="form-input" required placeholder="이름을 입력하세요">
    </div>

    <div class="form-group">
      <label for="password">비밀번호</label>
      <input type="password" name="password" id="password" class="form-input" required placeholder="비밀번호를 입력하세요" oninput="checkPasswordMatch();">
    </div>

    <div class="form-group">
      <label for="passwordConfirm">비밀번호 확인</label>
      <input type="password" name="passwordConfirm" id="passwordConfirm" class="form-input" required placeholder="비밀번호를 다시 입력하세요" oninput="checkPasswordMatch();">
      <div id="passwordError" class="error-text"><i class="bi bi-x-circle"></i> 비밀번호가 일치하지 않습니다.</div>
    </div>

    <div class="form-group">
      <label for="email">이메일</label>
      <input type="email" name="email" id="email" class="form-input" required placeholder="orchestra@example.com">
    </div>

    <div class="form-group">
      <label for="cohort">기수</label>
      <input type="number" name="cohort" id="cohort" class="form-input" required min="1" placeholder="예: 24">
    </div>

    <div class="form-group">
      <label for="isEnrolled">재학 여부</label>
      <select name="isEnrolled" id="isEnrolled" class="form-input" required>
        <option value="true">재학</option>
        <option value="false">휴학</option>
      </select>
    </div>

    <div class="form-group">
      <label for="instrument">악기</label>
      <select name="instrument" id="instrument" class="form-input">
        <%
          for (Map.Entry<String, String> entry : instrumentMap.entrySet()) {
        %>
          <option value="<%= html(entry.getKey()) %>"><%= html(entry.getValue()) %></option>
        <%
          }
        %>
      </select>
    </div>

    <button type="submit" class="btn-submit">회원가입</button>
  </form>

  <div class="link-area">
    이미 계정이 있나요? <a href="login.jsp">로그인하기</a>
  </div>
</div>

<script>
  function checkPasswordMatch() {
    const password = document.getElementById("password").value;
    const confirm = document.getElementById("passwordConfirm").value;
    document.getElementById("passwordError").style.display =
      confirm && password !== confirm ? "block" : "none";
  }

  function validateForm() {
    const password = document.getElementById("password").value;
    const confirm = document.getElementById("passwordConfirm").value;
    if (password !== confirm) {
      alert("비밀번호가 일치하지 않습니다.");
      document.getElementById("passwordConfirm").focus();
      return false;
    }
    return true;
  }
</script>

</body>
</html>

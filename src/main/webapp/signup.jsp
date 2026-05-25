<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="java.io.File" %>
<%@ page import="static ohrm.util.JspUtils.*" %>
<%
  request.setCharacterEncoding("UTF-8");

  // 회원가입 폼 입력 데이터 처리를 위한 변수 선언
  String studentIdStr = request.getParameter("student_id");
  String name = request.getParameter("name");
  String phone = request.getParameter("phone");
  String email = request.getParameter("email");
  String password = request.getParameter("password");
  String passwordConfirm = request.getParameter("password_confirm"); // 비밀번호 확인 변수
  String selectedInstrument = request.getParameter("instrument");

  // 악기 파트 정의용 표준 맵 (💡 clarinet2 제거)
  Map<String, String> instMap = new LinkedHashMap<>();
  instMap.put("violin", "바이올린");
  instMap.put("viola", "비올라");
  instMap.put("cello", "첼로");
  instMap.put("contrabass", "콘트라베이스");
  instMap.put("flute", "플루트");
  instMap.put("oboe", "오보에");
  instMap.put("clarinet", "클라리넷");
  instMap.put("horn", "호른");
  instMap.put("trumpet", "트럼펫");
  instMap.put("trombone", "트롬본");
  instMap.put("percussion", "타악기");
  instMap.put("etc", "기타(악기 없음)");

  String errorMsg = null;
  String successMsg = null;

  // POST 요청일 때 (회원가입 버튼 클릭 시) DB 인서트 처리
  if ("POST".equalsIgnoreCase(request.getMethod()) && studentIdStr != null) {
    try {
      int studentId = Integer.parseInt(studentIdStr);
      
      // [서버 측 검증] 비밀번호와 비밀번호 확인 값이 일치하는지 체크
      if (password == null || !password.equals(passwordConfirm)) {
        errorMsg = "비밀번호와 비밀번호 확인 값이 일치하지 않습니다.";
      }

      // 악기 선택 안했거나 빈 값이면 기본적으로 'etc' 처리
      if (selectedInstrument == null || selectedInstrument.trim().isEmpty()) {
        selectedInstrument = "etc";
      }

      if (errorMsg == null) {
        Class.forName("org.mariadb.jdbc.Driver");
        String url = "jdbc:mariadb://localhost:3306/ohrm_db";
        
        try (Connection conn = DriverManager.getConnection(url, "root", "1234")) {
          // 중복 학번 검사
          String checkSql = "SELECT student_id FROM members WHERE student_id = ?";
          try (PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
            checkPs.setInt(1, studentId);
            try (ResultSet checkRs = checkPs.executeQuery()) {
              if (checkRs.next()) {
                errorMsg = "이미 등록된 학번입니다. 다른 학번을 입력하거나 관리자에게 문의하세요.";
              }
            }
          }

          // 중복이 없을 때 최종 회원 등록 실행
          if (errorMsg == null) {
            String insertSql = "INSERT INTO members (student_id, name, phone, email, password_hash, instrument) VALUES (?, ?, ?, ?, ?, ?)";
            try (PreparedStatement insertPs = conn.prepareStatement(insertSql)) {
              insertPs.setInt(1, studentId);
              insertPs.setString(2, name);
              insertPs.setString(3, phone);
              insertPs.setString(4, email);
              insertPs.setString(5, password); 
              insertPs.setString(6, selectedInstrument);
              insertPs.executeUpdate();
              
              successMsg = "회원가입이 완료되었습니다! 로그인 페이지로 이동합니다.";
            }
          }
        }
      }
    } catch (Exception e) {
      errorMsg = "가입 처리 중 데이터베이스 오류가 발생했습니다: " + e.getMessage();
    }
  }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
  <title>오케스트라 시스템 - 회원가입</title>
  <style>
    body { font-family: 'Pretendard', sans-serif; background: #f5f7fb; color: #111827; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
    .signup-container { background: #fff; width: 420px; padding: 40px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); border: 1px solid #e5e7eb; box-sizing: border-box; }
    .logo-area { text-align: center; margin-bottom: 30px; }
    .logo-area h2 { color: #001f3f; margin: 0; font-size: 24px; font-weight: bold; }
    .logo-area p { color: #64748b; margin: 5px 0 0 0; font-size: 14px; }
    
    .form-group { margin-bottom: 20px; }
    .form-group label { display: block; font-size: 14px; font-weight: 600; color: #374151; margin-bottom: 6px; }
    .form-input { width: 100%; padding: 10px 12px; border: 1px solid #cbd5e1; border-radius: 8px; font-size: 14px; box-sizing: border-box; font-family: inherit; transition: border 0.2s ease; }
    .form-input:focus { outline: none; border-color: #001f3f; }
    
    .error-text { color: #dc2626; font-size: 12px; margin-top: 4px; display: none; }
    
    .btn-submit { width: 100%; padding: 12px; background: #001f3f; color: #fff; border: none; border-radius: 8px; font-size: 16px; font-weight: bold; cursor: pointer; transition: background 0.2s ease; margin-top: 10px; }
    .btn-submit:hover { background: #002f5f; }
    
    .msg-box { padding: 12px; border-radius: 8px; font-size: 13px; font-weight: 500; margin-bottom: 20px; text-align: center; }
    .msg-error { background: #fee2e2; color: #dc2626; border: 1px solid #fca5a5; }
    .msg-success { background: #dcfce7; color: #15803d; border: 1px solid #86efac; }
    
    .link-area { text-align: center; margin-top: 20px; font-size: 14px; color: #64748b; }
    .link-area a { color: #001f3f; text-decoration: none; font-weight: bold; }
    .link-area a:hover { text-decoration: underline; }
  </style>
</head>
<body>

<div class="signup-container">
  <div class="logo-area">
    <h2><i class="bi bi-person-plus"></i> 신입 단원 가입</h2>
    <p>오케스트라 단원 통합 관리 시스템</p>
  </div>

  <% if (errorMsg != null) { %>
    <div class="msg-box msg-error"><i class="bi bi-exclamation-triangle"></i> <%= html(errorMsg) %></div>
  <% } %>
  <% if (successMsg != null) { %>
    <div class="msg-box msg-success"><i class="bi bi-check-circle"></i> <%= html(successMsg) %></div>
    <script>setTimeout(function(){ location.href='login.jsp'; }, 2500);</script>
  <% } %>

  <form action="signup.jsp" method="post" onsubmit="return validateForm();">
    
    <div class="form-group">
      <label for="student_id">학번 (로그인 ID로 사용)</label>
      <input type="number" name="student_id" id="student_id" class="form-input" required placeholder="예: 12xxxxxx" value="<%= studentIdStr != null ? html(studentIdStr) : "" %>">
    </div>

    <div class="form-group">
      <label for="name">이름</label>
      <input type="text" name="name" id="name" class="form-input" required placeholder="이름을 입력하세요" value="<%= name != null ? html(name) : "" %>">
    </div>

    <div class="form-group">
      <label for="password">비밀번호</label>
      <input type="password" name="password" id="password" class="form-input" required placeholder="비밀번호 설정" oninput="checkPasswordMatch();">
    </div>

    <div class="form-group">
      <label for="password_confirm">비밀번호 확인</label>
      <input type="password" name="password_confirm" id="password_confirm" class="form-input" required placeholder="비밀번호 재입력" oninput="checkPasswordMatch();">
      <div id="passwordError" class="error-text"><i class="bi bi-x-circle"></i> 비밀번호가 일치하지 않습니다.</div>
    </div>

    <div class="form-group">
      <label for="phone">연락처</label>
      <input type="text" name="phone" id="phone" class="form-input" required placeholder="예: 010-1234-5678" value="<%= phone != null ? html(phone) : "" %>">
    </div>

    <div class="form-group">
      <label for="email">이메일 주소</label>
      <input type="email" name="email" id="email" class="form-input" required placeholder="예: orchestra@univ.ac.kr" value="<%= email != null ? html(email) : "" %>">
    </div>

    <div class="form-group">
      <label for="instrument">담당 악기 파트</label>
      <select name="instrument" id="instrument" class="form-input" required>
        <option value="">-- 악기를 선택해 주세요 --</option>
        <%
          for (Map.Entry<String, String> entry : instMap.entrySet()) {
            String key = entry.getKey();
            String instName = entry.getValue(); 
            String selectedAttr = key.equals(selectedInstrument) ? "selected" : "";
        %>
          <option value="<%= key %>" <%= selectedAttr %>><%= instName %></option>
        <%
          }
        %>
      </select>
    </div>

    <button type="submit" class="btn-submit">단원 등록 가입하기</button>
  </form>

  <div class="link-area">
    이미 계정이 있으신가요? <a href="login.jsp">로그인하기</a>
  </div>
</div>

<script>
  function checkPasswordMatch() {
    const password = document.getElementById("password").value;
    const confirm = document.getElementById("password_confirm").value;
    const errorText = document.getElementById("passwordError");

    if (confirm === "") {
      errorText.style.display = "none";
      return;
    }

    if (password !== confirm) {
      errorText.style.display = "block";
    } else {
      errorText.style.display = "none";
    }
  }

  function validateForm() {
    const password = document.getElementById("password").value;
    const confirm = document.getElementById("password_confirm").value;

    if (password !== confirm) {
      alert("비밀번호가 일치하지 않습니다. 다시 확인해 주세요.");
      document.getElementById("password_confirm").focus();
      return false;
    }
    return true;
  }
</script>

</body>
</html>
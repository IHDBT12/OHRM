<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%
    if (AuthUtils.currentStudentId(request) != null) {
        response.sendRedirect("index.jsp");
        return;
    }

    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>회원가입</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light d-flex align-items-center justify-content-center vh-100">
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-5 col-lg-4">
            <div class="card border-0 shadow p-4">
                <div class="card-body">
                    <h3 class="text-center mb-4 fw-bold">회원가입</h3>
                    <% if ("duplicate".equals(error)) { %>
                        <div class="alert alert-danger">이미 가입된 학번입니다.</div>
                    <% } else if (error != null) { %>
                        <div class="alert alert-danger">입력값을 확인해주세요.</div>
                    <% } %>
                    <form action="signup" method="post">
                        <div class="mb-3">
                            <label for="studentId" class="form-label text-secondary small">학번</label>
                            <input type="number" class="form-control" id="studentId" name="studentId" required placeholder="20240001">
                        </div>
                        <div class="mb-3">
                            <label for="password" class="form-label text-secondary small">비밀번호</label>
                            <input type="password" class="form-control" id="password" name="password" required placeholder="Password">
                        </div>
                        <div class="mb-3">
                            <label for="name" class="form-label text-secondary small">이름</label>
                            <input type="text" class="form-control" id="name" name="name" maxlength="10" required placeholder="홍길동">
                        </div>
                        <div class="mb-3">
                            <label for="email" class="form-label text-secondary small">이메일</label>
                            <input type="email" class="form-control" id="email" name="email" required placeholder="email@gmail.com">
                        </div>
                        <div class="mb-4">
                            <label for="isEnrolled" class="form-label text-secondary small">재학 여부</label>
                            <select class="form-select" id="isEnrolled" name="isEnrolled" required>
                                <option value="true">재학</option>
                                <option value="false">휴학</option>
                            </select>
                        </div>
                        <div class="d-flex gap-2">
                            <button type="button" class="btn btn-outline-secondary w-100 shadow-sm" onclick="location.href='login.jsp'">취소</button>
                            <button type="submit" class="btn btn-primary w-100 shadow-sm">가입하기</button>
                        </div>
                    </form>
                    <div class="mt-4 text-center">
                        <small class="text-muted">이미 계정이 있으신가요? <a href="login.jsp" class="text-decoration-none fw-bold">로그인</a></small>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>

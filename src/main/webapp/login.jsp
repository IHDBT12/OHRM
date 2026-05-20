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
    <title>로그인</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light d-flex align-items-center justify-content-center vh-100">
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-5 col-lg-4">
            <div class="card border-0 shadow p-4">
                <div class="card-body">
                    <h3 class="text-center mb-4 fw-bold">로그인</h3>
                    <% if (error != null) { %>
                        <div class="alert alert-danger">학번 또는 비밀번호를 확인해주세요.</div>
                    <% } %>
                    <form action="login" method="post">
                        <div class="mb-3">
                            <label for="studentId" class="form-label text-secondary small">학번</label>
                            <input type="number" class="form-control" id="studentId" name="studentId" required placeholder="20240001">
                        </div>
                        <div class="mb-3">
                            <label for="password" class="form-label text-secondary small">비밀번호</label>
                            <input type="password" class="form-control" id="password" name="password" required placeholder="Password">
                        </div>
                        <div class="d-flex gap-2">
                            <button type="button" class="btn btn-outline-secondary w-100 shadow-sm" onclick="location.href='signup.jsp'">회원가입</button>
                            <button type="submit" class="btn btn-primary w-100 shadow-sm">로그인</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>

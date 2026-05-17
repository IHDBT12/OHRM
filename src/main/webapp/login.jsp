<!DOCTYPE html>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>로그인</title>
    <!-- Bootstrap 5 CSS CDN -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
        }
        .form-control:focus {
            box-shadow: none;
            border-color: #0d6efd;
        }
    </style> 
</head>
<body>

<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-5 col-lg-4">
            <div class="card p-4">
                <div class="card-body">
                    <h3 class="text-center mb-4 fw-bold">로그인</h3>
                    <form action="login_process.jsp" method="post">
                        <div class="mb-3">
                            <label for="userId" class="form-label text-secondary small">아이디</label>
                            <input type="text" class="form-control" id="userId" name="userId" required placeholder="ID">
                        </div>

                        <div class="mb-3">
                            <label for="password" class="form-label text-secondary small">비밀번호</label>
                            <input type="password" class="form-control" id="password" name="password" required placeholder="Password">
                        </div>

                        <div class="d-flex gap-2">
                            <button type="button" class="btn btn-outline-secondary w-100 shadow-sm" onclick="location.href='index.jsp'">취소</button>
                            <button type="submit" class="btn btn-primary w-100 shadow-sm">로그인</button>
                        </div>
                    </form>

                    <div class="mt-4 text-center">
                        <small class="text-muted">아직 회원이 아니신가요? <a href="signup.jsp" class="text-decoration-none fw-bold">회원가입</a></small>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
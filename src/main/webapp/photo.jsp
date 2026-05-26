<%@ page contentType="text/html; charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.io.File" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%@ page import="static ohrm.util.JspUtils.*" %>
<%
    request.setCharacterEncoding("UTF-8");

    class ImageEntry {
        int id;
        String url;
        boolean isCover;
        public ImageEntry(int id, String url, boolean isCover) { 
            this.id = id; 
            this.url = url; 
            this.isCover = isCover; 
        }
    }

    String url = "jdbc:mariadb://localhost:3306/ohrm_db";
    String dbUser = "root";
    String dbPassword = "1234";
    Integer sessionStudentId = AuthUtils.currentStudentId(request);
    if (sessionStudentId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int studentId = sessionStudentId;
    String userRole = (String) session.getAttribute("user_role");
    String activeMenu = "photo";

    int photoId = 0;
    try {
        photoId = Integer.parseInt(request.getParameter("id"));
    } catch (Exception e) {
        photoId = 0;
    }

    String action = request.getParameter("action");
    if ("update_details".equals(action)) {
        String newTitle = request.getParameter("editTitle");
        if (newTitle != null && !newTitle.trim().isEmpty()) {
            try {
                Class.forName("org.mariadb.jdbc.Driver");
                try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword)) {
                    String authSql = "SELECT uploader_student_id FROM photo_albums WHERE photo_id = ?";
                    boolean isOwnerOrAdmin = "ADMIN".equals(userRole);
                    if (!isOwnerOrAdmin) {
                        try (PreparedStatement pstmt = conn.prepareStatement(authSql)) {
                            pstmt.setInt(1, photoId);
                            try (ResultSet rs = pstmt.executeQuery()) {
                                if (rs.next() && rs.getInt("uploader_student_id") == studentId) {
                                    isOwnerOrAdmin = true;
                                }
                            }
                        }
                    }

                    if (isOwnerOrAdmin) {
                        String updateSql = "UPDATE photo_albums SET event_name = ? WHERE photo_id = ?";
                        try (PreparedStatement pstmt = conn.prepareStatement(updateSql)) {
                            pstmt.setString(1, newTitle.trim());
                            pstmt.setInt(2, photoId);
                            pstmt.executeUpdate();
                        }
                        response.sendRedirect("photo.jsp?id=" + photoId); 
                        return;
                    }
                }
            } catch (Exception e) {}
        }
    }

    String name = "";
    String memberImageUrl = "";
    String title = "";
    String date = "";
    String uploaderName = "";
    int uploaderStudentId = -1;
    String errorMessage = "";
    
    List<ImageEntry> imageEntries = new ArrayList<>();
    String coverImageUrl = "";

    try {
        Class.forName("org.mariadb.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection(url, dbUser, dbPassword)) {
            try (PreparedStatement pstmt = conn.prepareStatement("SELECT name FROM members WHERE student_id = ?")) {
                pstmt.setInt(1, studentId);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) name = text(rs, "name");
                }
            }

            try (PreparedStatement pstmt = conn.prepareStatement(
                "SELECT pa.event_name, pa.event_at, pa.image_url, pa.uploader_student_id, " +
                "COALESCE(m.name, '미상') AS uploader_name FROM photo_albums pa " +
                "LEFT JOIN members m ON pa.uploader_student_id = m.student_id WHERE pa.photo_id = ?"
            )) {
                pstmt.setInt(1, photoId);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        title = text(rs, "event_name");
                        date = dateText(rs, "event_at");
                        uploaderName = text(rs, "uploader_name");
                        uploaderStudentId = rs.getInt("uploader_student_id");
                        coverImageUrl = text(rs, "image_url");
                    }
                }
            }

            try (PreparedStatement pstmt = conn.prepareStatement(
                "SELECT image_id, image_url FROM photo_album_images WHERE photo_id = ? ORDER BY image_id"
            )) {
                pstmt.setInt(1, photoId);
                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        imageEntries.add(new ImageEntry(rs.getInt("image_id"), rs.getString("image_url"), false));
                    }
                }
            }
        }
    } catch (ClassNotFoundException e) { errorMessage = "MariaDB JDBC 드라이버 오류"; }
    catch (SQLException e) { errorMessage = "DB 조회 오류: " + e.getMessage(); }

    boolean hasDuplicate = false;
    for (ImageEntry entry : imageEntries) {
        if (entry.url.equals(coverImageUrl)) {
            hasDuplicate = true;
            entry.isCover = true; 
            break;
        }
    }

    if (!hasDuplicate && !coverImageUrl.isEmpty()) {
        imageEntries.add(0, new ImageEntry(0, coverImageUrl, true));
    }

    String memberDefaultImage = "assets/img/member/member.png";
    String memberCandidateImage = "assets/img/member/" + studentId + ".png";
    String memberCandidatePath = application.getRealPath(memberCandidateImage);
    memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists() ? memberCandidateImage : memberDefaultImage;

    boolean canEdit = ("ADMIN".equals(userRole) || studentId == uploaderStudentId);
    long cacheBuster = System.currentTimeMillis();
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>오케스트라 단원 관리 시스템 - 사진 상세</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="assets/css/common.css">
    <link rel="stylesheet" href="assets/css/photo_album.css">
    <style>
        .page-head { position: relative; }
        .head-title-area { display: flex; align-items: center; gap: 15px; width: 100%; flex-grow: 1; }
        .edit-form { display: none; width: 100%; align-items: center; gap: 12px; }
        .edit-title-input { font-size: 28px; font-weight: bold; border: 2px solid #3b82f6; border-radius: 6px; padding: 5px 12px; color: #1e3a8a; width: 80%; max-width: 550px; outline: none; }
        
        .btn-custom {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            font-size: 14px;
            font-weight: 600;
            padding: 8px 16px;
            border-radius: 8px;
            border: 1px solid transparent;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.2s ease-in-out;
            line-height: 1.2;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
        }
        .btn-custom.btn-list { background-color: #f3f4f6; color: #4b5563; border-color: #e5e7eb; }
        .btn-custom.btn-list:hover { background-color: #e5e7eb; color: #1f2937; }

        .btn-custom.btn-edit { background-color: #eff6ff; color: #2563eb; border-color: #dbeafe; }
        .btn-custom.btn-edit:hover { background-color: #dbeafe; color: #1d4ed8; box-shadow: 0 4px 10px rgba(37,99,235,0.08); }

        .btn-custom.btn-submit { background-color: #10b981; color: #ffffff; }
        .btn-custom.btn-submit:hover { background-color: #059669; box-shadow: 0 4px 12px rgba(16,185,129,0.2); }

        .btn-custom.btn-delete { background-color: #fff5f5; color: #e03131; border-color: #ffe3e3; }
        .btn-custom.btn-delete:hover { background-color: #ffe3e3; color: #c92a2a; box-shadow: 0 4px 10px rgba(224,49,49,0.08); }

        .btn-custom.btn-cancel { background-color: #ffffff; color: #6b7280; border-color: #d1d5db; }
        .btn-custom.btn-cancel:hover { background-color: #f9fafb; color: #374151; }

        .btn-custom.compact { font-size: 13px; padding: 5px 12px; }
        
        .photo-card-container { position: relative; display: flex; flex-direction: column; gap: 10px; margin-bottom: 25px; border-radius: 8px; border: 1px solid #e5e7eb; padding: 15px; background: white; transition: box-shadow 0.2s; }
        .photo-card-container:hover { box-shadow: 0 5px 15px rgba(0,0,0,0.08); }
        .photo-detail-img { width: 100%; border-radius: 6px; object-fit: contain; max-height: 500px; display: block; }
        
        .photo-edit-controls { display: none; background: #f9fafb; padding: 10px; border-radius: 6px; border: 1px solid #e5e7eb; margin-top: 10px; }
        .photo-edit-controls p { font-size: 13px; color: #6b7280; margin-bottom: 8px; }
        .badge-cover { display: inline-block; background-color: #3b82f6; color: white; padding: 3px 8px; font-size: 11px; border-radius: 4px; font-weight: bold; margin-bottom: 8px; }
        
        .photo-file-input { display: none; }
        .photo-add-zone { display: none; border: 2px dashed #3b82f6; background-color: #eff6ff; border-radius: 8px; padding: 30px; text-align: center; margin-bottom: 25px; cursor: pointer; transition: background 0.2s; }
        .photo-add-zone:hover { background-color: #dbeafe; }
        .photo-add-zone i { font-size: 32px; color: #3b82f6; display: block; margin-bottom: 8px; }
        .photo-add-zone span { font-weight: bold; color: #1e40af; font-size: 15px; }
        
        body.is-editing #titleDisplay, body.is-editing .page-actions-original { display: none !important; }
        body.is-editing #editForm, body.is-editing #editFinishActions { display: flex !important; }
        body.is-editing .photo-edit-controls, body.is-editing .photo-add-zone { display: block !important; }
    </style>
</head>
<body>
<div class="app-shell">
    <%@ include file="/WEB-INF/fragments/sidebar.jspf" %>

    <main class="main">
        <%@ include file="/WEB-INF/fragments/topbar.jspf" %>

        <section class="content">
            <div class="page-head d-flex align-items-center justify-content-between">
                <div class="head-title-area">
                    <h1 id="titleDisplay"><%= title.isEmpty() ? "사진을 찾을 수 없습니다" : html(title) %></h1>
                    
                    <% if (canEdit && !title.isEmpty()) { %>
                    <form id="editForm" class="edit-form" action="photo.jsp" method="post">
                        <input type="hidden" name="id" value="<%= photoId %>">
                        <input type="hidden" name="action" value="update_details">
                        <input class="edit-title-input" type="text" name="editTitle" value="<%= html(title) %>" required>
                    </form>
                    <% } %>
                    
                    <div style="flex-grow: 1; text-align: right;">
                        <p style="margin: 0; color: #6b7280;">작성자: <%= html(uploaderName) %> / <%= html(date) %></p> 
                    </div>
                </div>
                
                <div style="display: flex; gap: 8px; margin-left: 20px;">
                    <div class="page-actions-original" style="display: flex; gap: 8px; align-items: center;">
                        <a class="btn-custom btn-list" href="photo_album.jsp"><i class="bi bi-list-task"></i> 목록으로</a>
                        <% if (!title.isEmpty() && canEdit) { %>
                            <button class="btn-custom btn-edit" type="button" onclick="activateEditMode(true)"><i class="bi bi-pencil-square"></i> 수정</button>
                            <form action="photo-delete" method="post" onsubmit="return confirm('이 사진 게시글을 전체 삭제할까요?');" style="margin:0;">
                                <input type="hidden" name="photoId" value="<%= photoId %>">
                                <button class="btn-custom btn-delete" type="submit"><i class="bi bi-trash3"></i> 전체 삭제</button>
                            </form>
                        <% } %>
                    </div>
                    
                    <div id="editFinishActions" style="display: none; gap: 8px; align-items: center;">
                        <button class="btn-custom btn-submit" type="button" onclick="document.getElementById('editForm').submit();"><i class="bi bi-check-circle-fill"></i> 완료</button>
                        <button class="btn-custom btn-cancel" type="button" onclick="activateEditMode(false)"><i class="bi bi-x-circle"></i> 취소</button>
                    </div>
                </div>
            </div>

            <section class="photo-detail-section" style="margin-top: 20px;">
                <% if (imageEntries.isEmpty()) { %>
                    <div class="card p-5 text-center text-muted" style="background: white; border-radius: 8px; border:1px solid #e5e7eb;">
                        <i class="bi bi-image" style="font-size: 48px; display: block; margin-bottom: 15px;"></i>
                        <p style="margin:0;">등록된 이미지 파일이 존재하지 않는 게시글입니다.</p>
                    </div>
                <% } %>
                
                <% for (ImageEntry entry : imageEntries) { %>
                    <div class="photo-card-container">
                        <div>
                            <img class="photo-detail-img" src="<%= html(entry.url) %>?t=<%= cacheBuster %>" alt="<%= html(title) %>">
                        </div>
                        
                        <% if (canEdit) { %>
                        <div class="photo-edit-controls">
                            <% if (entry.isCover) { %>
                                <div class="badge-cover"><i class="bi bi-star-fill me-1"></i> 대표 사진</div>
                            <% } %>
                            
                            <p style="margin:0 0 8px 0;">
                                <i class="bi bi-info-circle-fill text-primary me-1"></i> 
                                <% if(entry.isCover) { %>
                                    <strong>대표 사진입니다.</strong> 다른 사진으로 교체만 가능합니다.
                                <% } else { %>
                                    해당 위치의 사진 변경 또는 제거가 가능합니다.
                                <% } %>
                            </p>
                            <div style="display: flex; gap: 8px;">
                                <form action="photo-replace" method="post" enctype="multipart/form-data" style="margin:0;">
                                    <input type="hidden" name="photoId" value="<%= photoId %>">
                                    <input type="hidden" name="imageId" value="<%= entry.isCover ? 0 : entry.id %>">
                                    <input class="photo-file-input" type="file" name="replaceImage" accept="image/*" id="file_<%= entry.id %>" onchange="this.form.submit();">
                                    <button class="btn-custom btn-edit compact" type="button" onclick="document.getElementById('file_<%= entry.id %>').click();">
                                        <i class="bi bi-arrow-repeat"></i> 사진 교체
                                    </button>
                                </form>
                                
                                <% if (!entry.isCover) { %>
                                <form action="photo-image-delete" method="post" onsubmit="return confirm('이 사진을 정말 삭제하시겠습니까?');" style="margin:0;">
                                    <input type="hidden" name="photoId" value="<%= photoId %>">
                                    <input type="hidden" name="imageId" value="<%= entry.id %>">
                                    <button class="btn-custom btn-delete compact" type="submit"><i class="bi bi-trash3"></i> 사진 삭제</button>
                                </form>
                                <% } %>
                            </div>
                        </div>
                        <% } %>
                    </div>
                <% } %>

                <% if (canEdit && !title.isEmpty()) { %>
                    <form action="photo-image-add" method="post" enctype="multipart/form-data" id="imageAddForm" style="margin: 0;">
                        <input type="hidden" name="photoId" value="<%= photoId %>">
                        <input type="file" name="newImages" accept="image/*" id="newImagesInput" class="photo-file-input" multiple onchange="this.form.submit();">
                        
                        <div class="photo-add-zone" onclick="document.getElementById('newImagesInput').click();">
                            <i class="bi bi-plus-circle-fill"></i>
                            <span>이 게시글에 새 사진 추가하기</span>
                            <p style="margin: 5px 0 0 0; font-size: 12px; color: #6b7280;">클릭하여 추가할 사진 파일들을 선택하세요 (다중 선택 가능)</p>
                        </div>
                    </form>
                <% } %>
            </section>
        </section>
    </main>
</div>

<script>
function activateEditMode(isEdit) {
    if (isEdit) {
        document.body.classList.add('is-editing');
    } else {
        document.body.classList.remove('is-editing');
    }
}
</script>
</body>
</html>
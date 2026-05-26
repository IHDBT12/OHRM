import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.UUID;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import ohrm.util.AuthUtils;
import ohrm.util.UploadPathUtils;

@WebServlet("/photo-replace")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,  // 2MB
    maxFileSize = 1024 * 1024 * 10,       // 10MB
    maxRequestSize = 1024 * 1024 * 50     // 50MB
)
public class PhotoReplaceServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final String URL = "jdbc:mariadb://localhost:3306/ohrm_db";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "1234";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        // 로그인 인증 및 세션 학번 검증
        Integer currentStudentId = AuthUtils.currentStudentId(request);
        if (currentStudentId == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int photoId;
        int imageId = 0;
        try {
            photoId = Integer.parseInt(request.getParameter("photoId"));
            if (request.getParameter("imageId") != null) {
                imageId = Integer.parseInt(request.getParameter("imageId"));
            }
        } catch (Exception e) {
            response.sendRedirect("photo_album.jsp?error=invalid");
            return;
        }

        HttpSession session = request.getSession();
        String userRole = (String) session.getAttribute("user_role");

        try {
            Class.forName("org.mariadb.jdbc.Driver");
            try (Connection conn = DriverManager.getConnection(URL, DB_USER, DB_PASSWORD)) {
                
                // 권한 확인: 최고 관리자(ADMIN)이거나 게시글을 직접 올린 본인인지 체크
                boolean isOwnerOrAdmin = "ADMIN".equals(userRole);
                if (!isOwnerOrAdmin) {
                    String authSql = "SELECT uploader_student_id FROM photo_albums WHERE photo_id = ?";
                    try (PreparedStatement pstmt = conn.prepareStatement(authSql)) {
                        pstmt.setInt(1, photoId);
                        try (ResultSet rs = pstmt.executeQuery()) {
                            if (rs.next() && rs.getInt("uploader_student_id") == currentStudentId) {
                                isOwnerOrAdmin = true;
                            }
                        }
                    }
                }

                // 권한이 없으면 이전 페이지로 돌아가기
                if (!isOwnerOrAdmin) {
                    response.setContentType("text/html; charset=UTF-8");
                    response.getWriter().println("<script>alert('사진을 변경할 권한이 없습니다.'); history.back();</script>");
                    return;
                }

                Part filePart = request.getPart("replaceImage");
                if (filePart == null || filePart.getSize() == 0) {
                    response.sendRedirect("photo.jsp?id=" + photoId);
                    return;
                }

                // 원본 파일명에서 확장자 추출 (.jpg, .png 등)
                String submittedFileName = filePart.getSubmittedFileName();
                String ext = "";
                if (submittedFileName != null && submittedFileName.contains(".")) {
                    ext = submittedFileName.substring(submittedFileName.lastIndexOf("."));
                }

                String folderName = String.format("photos%03d", photoId);
                String newFileName = UUID.randomUUID().toString() + ext;
                
                // 웹앱과 데이터베이스가 함께 가리킬 최종 파일 상대 경로
                String webPath = "assets/img/photo/" + folderName + "/" + newFileName;

                String tomcatRealPath = getServletContext().getRealPath("/" + webPath);
                File tomcatFile = new File(tomcatRealPath);
                if (!tomcatFile.getParentFile().exists()) {
                    tomcatFile.getParentFile().mkdirs();
                }
                filePart.write(tomcatRealPath);

                File sourceRootDir = UploadPathUtils.sourceWebappDirectory(getServletContext(), "");
                if (sourceRootDir != null) {
                    File sourceFile = new File(sourceRootDir, webPath);
                    if (!sourceFile.getParentFile().exists()) {
                        sourceFile.getParentFile().mkdirs();
                    }
                    try {
                        java.nio.file.Files.copy(tomcatFile.toPath(), sourceFile.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                    } catch (Exception ignored) {}
                }

                String oldImageUrl = null;

                if (imageId == 0) {
                    String selectOldCoverSql = "SELECT image_url FROM photo_albums WHERE photo_id = ?";
                    try (PreparedStatement pstmt = conn.prepareStatement(selectOldCoverSql)) {
                        pstmt.setInt(1, photoId);
                        try (ResultSet rs = pstmt.executeQuery()) {
                            if (rs.next()) {
                                oldImageUrl = rs.getString("image_url");
                            }
                        }
                    }
                } else {
                    String selectOldDetailSql = "SELECT image_url FROM photo_album_images WHERE image_id = ?";
                    try (PreparedStatement pstmt = conn.prepareStatement(selectOldDetailSql)) {
                        pstmt.setInt(1, imageId);
                        try (ResultSet rs = pstmt.executeQuery()) {
                            if (rs.next()) {
                                oldImageUrl = rs.getString("image_url");
                            }
                        }
                    }
                }

                // 기존 파일이 서버 디스크에 존재한다면 제거 (저장 공간 최적화)
                if (oldImageUrl != null && !oldImageUrl.isEmpty()) {
                    File oldTomcatFile = new File(getServletContext().getRealPath("/"), oldImageUrl);
                    if (oldTomcatFile.exists()) oldTomcatFile.delete();

                    if (sourceRootDir != null) {
                        File oldSourceFile = new File(sourceRootDir, oldImageUrl);
                        if (oldSourceFile.exists()) oldSourceFile.delete();
                    }
                }

                // 조건에 따른 UPDATE 쿼리 분기 실행
                if (imageId == 0) {
                    String updateMainSql = "UPDATE photo_albums SET image_url = ? WHERE photo_id = ?";
                    try (PreparedStatement pstmtMain = conn.prepareStatement(updateMainSql)) {
                        pstmtMain.setString(1, webPath);
                        pstmtMain.setInt(2, photoId);
                        pstmtMain.executeUpdate();
                    }

                    if (oldImageUrl != null && !oldImageUrl.isEmpty()) {
                        String updateDetailSql = "UPDATE photo_album_images SET image_url = ? WHERE photo_id = ? AND image_url = ?";
                        try (PreparedStatement pstmtDetail = conn.prepareStatement(updateDetailSql)) {
                            pstmtDetail.setString(1, webPath);
                            pstmtDetail.setInt(2, photoId);
                            pstmtDetail.setString(3, oldImageUrl);
                            pstmtDetail.executeUpdate();
                        }
                    }
                } else {
                    String updateDetailSingleSql = "UPDATE photo_album_images SET image_url = ? WHERE image_id = ? AND photo_id = ?";
                    try (PreparedStatement pstmtDetailSingle = conn.prepareStatement(updateDetailSingleSql)) {
                        pstmtDetailSingle.setString(1, webPath);
                        pstmtDetailSingle.setInt(2, imageId);
                        pstmtDetailSingle.setInt(3, photoId);
                        pstmtDetailSingle.executeUpdate();
                    }
                }
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }

        response.sendRedirect("photo.jsp?id=" + photoId);
    }
}
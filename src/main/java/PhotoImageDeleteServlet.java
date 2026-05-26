import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import ohrm.util.AuthUtils;
import ohrm.util.UploadPathUtils;

@WebServlet("/photo-image-delete")
public class PhotoImageDeleteServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final String URL = "jdbc:mariadb://localhost:3306/ohrm_db";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "1234";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        // 로그인 인증 확인
        Integer currentStudentId = AuthUtils.currentStudentId(request);
        if (currentStudentId == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int photoId;
        int imageId;
        try {
            photoId = Integer.parseInt(request.getParameter("photoId"));
            imageId = Integer.parseInt(request.getParameter("imageId"));
        } catch (Exception e) {
            response.sendRedirect("photo_album.jsp?error=invalid");
            return;
        }

        HttpSession session = request.getSession();
        String userRole = (String) session.getAttribute("user_role");

        try {
            Class.forName("org.mariadb.jdbc.Driver");
            try (Connection conn = DriverManager.getConnection(URL, DB_USER, DB_PASSWORD)) {
                
                // 권한 확인: ADMIN이거나 본인이 업로드한 글인지 체크
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
                    response.getWriter().println("<script>alert('이 사진을 삭제할 권한이 없습니다.'); history.back();</script>");
                    return;
                }

                // 서버 디스크 파일 삭제를 위해 파일의 상대 경로(image_url) 먼저 조회
                String relativeImagePath = null;
                String selectSql = "SELECT image_url FROM photo_album_images WHERE image_id = ? AND photo_id = ?";
                try (PreparedStatement pstmt = conn.prepareStatement(selectSql)) {
                    pstmt.setInt(1, imageId);
                    pstmt.setInt(2, photoId);
                    try (ResultSet rs = pstmt.executeQuery()) {
                        if (rs.next()) {
                            relativeImagePath = rs.getString("image_url");
                        }
                    }
                }

                // DB에서 개별 사진 레코드 제거
                String deleteSql = "DELETE FROM photo_album_images WHERE image_id = ? AND photo_id = ?";
                try (PreparedStatement pstmt = conn.prepareStatement(deleteSql)) {
                    pstmt.setInt(1, imageId);
                    pstmt.setInt(2, photoId);
                    int deletedRows = pstmt.executeUpdate();

                    if (deletedRows > 0 && relativeImagePath != null) {
                        File tomcatFile = new File(getServletContext().getRealPath("/"), relativeImagePath);
                        if (tomcatFile.exists()) {
                            tomcatFile.delete();
                        }

                        File sourceRootDir = UploadPathUtils.sourceWebappDirectory(getServletContext(), "");
                        if (sourceRootDir != null) {
                            File sourceFile = new File(sourceRootDir, relativeImagePath);
                            if (sourceFile.exists()) {
                                sourceFile.delete();
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }

        response.sendRedirect("photo.jsp?id=" + photoId);
    }
}
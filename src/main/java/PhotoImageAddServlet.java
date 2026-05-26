import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.util.Collection;
import java.util.UUID;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import ohrm.util.AuthUtils;
import ohrm.util.UploadPathUtils;

@WebServlet("/photo-image-add")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,  // 2MB
    maxFileSize = 1024 * 1024 * 10,       // 10MB
    maxRequestSize = 1024 * 1024 * 50     // 50MB
)
public class PhotoImageAddServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final String URL = "jdbc:mariadb://localhost:3306/ohrm_db";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "1234";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        // 세션 확인 및 로그인 검증
        Integer currentStudentId = AuthUtils.currentStudentId(request);
        if (currentStudentId == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        // 게시글 고유 ID
        int photoId;
        try {
            photoId = Integer.parseInt(request.getParameter("photoId"));
        } catch (Exception e) {
            response.sendRedirect("photo_album.jsp");
            return;
        }

        try {
            Class.forName("org.mariadb.jdbc.Driver");
            try (Connection conn = DriverManager.getConnection(URL, DB_USER, DB_PASSWORD)) {
                
                Collection<Part> parts = request.getParts();
                String folderName = String.format("photos%03d", photoId);
                
                String insertSql = "INSERT INTO photo_album_images (photo_id, image_url) VALUES (?, ?)";
                
                try (PreparedStatement pstmt = conn.prepareStatement(insertSql)) {
                    for (Part part : parts) {
                        if (part.getName().equals("newImages") && part.getSize() > 0) {
                            
                            String submittedFileName = part.getSubmittedFileName();
                            String ext = "";
                            if (submittedFileName != null && submittedFileName.contains(".")) {
                                ext = submittedFileName.substring(submittedFileName.lastIndexOf("."));
                            }
                            
                            String newFileName = UUID.randomUUID().toString() + ext;
                            String webPath = "assets/img/photo/" + folderName + "/" + newFileName;
                            
                            String tomcatRealPath = getServletContext().getRealPath("/" + webPath);
                            File tomcatFile = new File(tomcatRealPath);
                            if (!tomcatFile.getParentFile().exists()) {
                                tomcatFile.getParentFile().mkdirs();
                            }
                            part.write(tomcatRealPath);
                            
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
                            
                            // 세부 사진 목록 DB 테이블(`photo_album_images`)에 INSERT 쿼리 실행
                            pstmt.setInt(1, photoId);
                            pstmt.setString(2, webPath);
                            pstmt.addBatch();
                        }
                    }
                    pstmt.executeBatch();
                }
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }
        response.sendRedirect("photo.jsp?id=" + photoId);
    }
}
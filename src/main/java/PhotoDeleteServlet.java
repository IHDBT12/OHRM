import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import ohrm.util.AuthUtils;
import ohrm.util.UploadPathUtils;

public class PhotoDeleteServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final String URL = "jdbc:mariadb://localhost:3306/ohrm_db";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "1234";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        Integer currentStudentId = AuthUtils.currentStudentId(request);
        if (currentStudentId == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int photoId;
        try {
            photoId = Integer.parseInt(request.getParameter("photoId"));
        } catch (Exception e) {
            response.sendRedirect("photo_album.jsp?error=invalid");
            return;
        }

        HttpSession session = request.getSession(false);
        String userRole = session == null ? "" : (String) session.getAttribute("user_role");

        try {
            Class.forName("org.mariadb.jdbc.Driver");
            try (Connection conn = DriverManager.getConnection(URL, DB_USER, DB_PASSWORD)) {
                if (!canManagePhoto(conn, photoId, currentStudentId, userRole)) {
                    response.sendRedirect("photo.jsp?id=" + photoId + "&error=forbidden");
                    return;
                }

                try (PreparedStatement pstmt = conn.prepareStatement("DELETE FROM photo_albums WHERE photo_id = ?")) {
                    pstmt.setInt(1, photoId);
                    pstmt.executeUpdate();
                }
            }

            deletePhotoFolder(photoId);
        } catch (Exception e) {
            throw new ServletException(e);
        }

        response.sendRedirect("photo_album.jsp?deleted=1");
    }

    private boolean canManagePhoto(Connection conn, int photoId, int currentStudentId, String userRole) throws Exception {
        if (isAdminRole(userRole)) {
            return true;
        }

        try (PreparedStatement pstmt = conn.prepareStatement(
            "SELECT uploader_student_id FROM photo_albums WHERE photo_id = ?"
        )) {
            pstmt.setInt(1, photoId);
            try (ResultSet rs = pstmt.executeQuery()) {
                return rs.next() && rs.getInt("uploader_student_id") == currentStudentId;
            }
        }
    }

    private boolean isAdminRole(String userRole) {
        return "ADMIN".equalsIgnoreCase(userRole) || "MASTER".equalsIgnoreCase(userRole);
    }

    private void deletePhotoFolder(int photoId) {
        String folderName = String.format("photos%03d", photoId);
        deleteDirectory(new File(getServletContext().getRealPath("/assets/img/photo"), folderName));

        File sourceRootDir = UploadPathUtils.sourceWebappDirectory(getServletContext(), "assets/img/photo");
        if (sourceRootDir != null) {
            deleteDirectory(new File(sourceRootDir, folderName));
        }
    }

    private void deleteDirectory(File file) {
        if (file == null || !file.exists()) {
            return;
        }

        File[] children = file.listFiles();
        if (children != null) {
            for (File child : children) {
                deleteDirectory(child);
            }
        }
        file.delete();
    }
}

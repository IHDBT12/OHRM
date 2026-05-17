import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
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

        int photoId;
        try {
            photoId = Integer.parseInt(request.getParameter("photoId"));
        } catch (Exception e) {
            response.sendRedirect("photo_album.jsp?error=invalid");
            return;
        }

        try {
            Class.forName("org.mariadb.jdbc.Driver");
            try (Connection conn = DriverManager.getConnection(URL, DB_USER, DB_PASSWORD);
                 PreparedStatement pstmt = conn.prepareStatement("DELETE FROM photo_albums WHERE photo_id = ?")) {
                pstmt.setInt(1, photoId);
                pstmt.executeUpdate();
            }

            deletePhotoFolder(photoId);
        } catch (Exception e) {
            throw new ServletException(e);
        }

        response.sendRedirect("photo_album.jsp?deleted=1");
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

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import ohrm.util.UploadPathUtils;

public class PhotoUploadServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final String URL = "jdbc:mariadb://localhost:3306/ohrm_db";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "1234";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String eventName = value(request, "eventName");
        String eventDate = value(request, "eventDate");
        List<Part> imageParts = imageParts(request.getParts());

        if (eventName.isEmpty() || eventDate.isEmpty() || imageParts.isEmpty()) {
            response.sendRedirect("photo_album.jsp?error=empty");
            return;
        }

        try {
            Class.forName("org.mariadb.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(URL, DB_USER, DB_PASSWORD)) {
                int photoId = insertAlbum(conn, eventName, eventDate);
                String coverImageUrl = "";

                for (Part imagePart : imageParts) {
                    String imageUrl = savePhotoImage(imagePart, photoId);
                    if (coverImageUrl.isEmpty()) {
                        coverImageUrl = imageUrl;
                    }
                    insertAlbumImage(conn, photoId, imageUrl);
                }

                updateCoverImage(conn, photoId, coverImageUrl);
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }

        response.sendRedirect("photo_album.jsp?uploaded=1");
    }

    private int insertAlbum(Connection conn, String eventName, String eventDate) throws Exception {
        try (PreparedStatement pstmt = conn.prepareStatement(
            "INSERT INTO photo_albums (event_name, event_at, image_url) VALUES (?, ?, '')",
            Statement.RETURN_GENERATED_KEYS
        )) {
            pstmt.setString(1, eventName);
            pstmt.setTimestamp(2, Timestamp.valueOf(eventDate + " 00:00:00"));
            pstmt.executeUpdate();

            try (ResultSet rs = pstmt.getGeneratedKeys()) {
                if (!rs.next()) {
                    throw new ServletException("사진 게시글 번호를 생성하지 못했습니다.");
                }
                return rs.getInt(1);
            }
        }
    }

    private void insertAlbumImage(Connection conn, int photoId, String imageUrl) throws Exception {
        try (PreparedStatement pstmt = conn.prepareStatement(
            "INSERT INTO photo_album_images (photo_id, image_url) VALUES (?, ?)"
        )) {
            pstmt.setInt(1, photoId);
            pstmt.setString(2, imageUrl);
            pstmt.executeUpdate();
        }
    }

    private void updateCoverImage(Connection conn, int photoId, String coverImageUrl) throws Exception {
        try (PreparedStatement pstmt = conn.prepareStatement(
            "UPDATE photo_albums SET image_url = ? WHERE photo_id = ?"
        )) {
            pstmt.setString(1, coverImageUrl);
            pstmt.setInt(2, photoId);
            pstmt.executeUpdate();
        }
    }

    private List<Part> imageParts(Collection<Part> parts) {
        List<Part> imageParts = new ArrayList<>();
        for (Part part : parts) {
            if ("photoImages".equals(part.getName()) && part.getSize() > 0) {
                imageParts.add(part);
            }
        }
        return imageParts;
    }

    private String value(HttpServletRequest request, String name) {
        String value = request.getParameter(name);
        return value == null ? "" : value.trim();
    }

    private String savePhotoImage(Part imagePart, int photoId) throws IOException, ServletException {
        String uploadRootPath = getServletContext().getRealPath("/assets/img/photo");
        if (uploadRootPath == null) {
            throw new ServletException("사진 저장 경로를 찾을 수 없습니다.");
        }

        String folderName = String.format("photos%03d", photoId);
        File uploadDir = new File(uploadRootPath, folderName);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }

        int nextNumber = nextPhotoNumber(uploadDir);
        String fileName = String.format("photo%04d%s", nextNumber, extension(imagePart.getSubmittedFileName()));

        Path deployedFile = new File(uploadDir, fileName).toPath();
        Files.copy(imagePart.getInputStream(), deployedFile, StandardCopyOption.REPLACE_EXISTING);
        copyToSourcePhotoFolder(deployedFile, folderName, fileName);

        return "assets/img/photo/" + folderName + "/" + fileName;
    }

    private void copyToSourcePhotoFolder(Path deployedFile, String folderName, String fileName) throws IOException {
        File sourceRootDir = UploadPathUtils.sourceWebappDirectory(getServletContext(), "assets/img/photo");
        if (sourceRootDir == null) {
            return;
        }

        File sourceDir = new File(sourceRootDir, folderName);
        if (!sourceDir.exists()) {
            sourceDir.mkdirs();
        }

        Files.copy(deployedFile, new File(sourceDir, fileName).toPath(), StandardCopyOption.REPLACE_EXISTING);
    }

    private int nextPhotoNumber(File uploadDir) {
        int max = 0;
        File[] files = uploadDir.listFiles();
        if (files == null) {
            return 1;
        }

        for (File file : files) {
            String name = file.getName();
            if (name.matches("photo\\d{4}\\..+")) {
                int number = Integer.parseInt(name.substring(5, 9));
                max = Math.max(max, number);
            }
        }
        return max + 1;
    }

    private String extension(String fileName) {
        if (fileName == null) {
            return ".png";
        }
        String lower = fileName.toLowerCase();
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
            return ".jpg";
        }
        if (lower.endsWith(".webp")) {
            return ".webp";
        }
        return ".png";
    }
}

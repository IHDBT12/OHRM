import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import ohrm.util.AuthUtils;
import ohrm.util.UploadPathUtils;

public class ProfileUpdateServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final String URL = "jdbc:mariadb://localhost:3306/ohrm_db";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "1234";
    private static final String PHONE_REGEX = "^010\\d{4}\\d{4}$";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        Integer sessionStudentId = AuthUtils.currentStudentId(request);
        if (sessionStudentId == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int studentId = sessionStudentId;
        String major = value(request, "major");
        String phone = value(request, "phone");
        String bio = value(request, "bio");
        String newPassword = value(request, "newPassword");
        String instrument = value(request, "instrument");
        boolean isEnrolled = Boolean.parseBoolean(value(request, "isEnrolled"));

        if (!phone.isEmpty() && !phone.matches(PHONE_REGEX)) {
            redirect(response, "phone");
            return;
        }

        try {
            Class.forName("org.mariadb.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(URL, DB_USER, DB_PASSWORD)) {
                try (PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE members SET major = ?, phone = ?, is_enrolled = ?, bio = ?, instrument = ? WHERE student_id = ?"
                )) {
                    pstmt.setString(1, major);
                    pstmt.setString(2, phone);
                    pstmt.setBoolean(3, isEnrolled);
                    pstmt.setString(4, bio);
                    pstmt.setString(5, instrument.isEmpty() ? null : instrument);
                    pstmt.setInt(6, studentId);
                    pstmt.executeUpdate();
                }

                if (!newPassword.isEmpty()) {
                    try (PreparedStatement pstmt = conn.prepareStatement(
                        "UPDATE members SET password_hash = ? WHERE student_id = ?"
                    )) {
                        pstmt.setString(1, AuthUtils.sha256(newPassword));
                        pstmt.setInt(2, studentId);
                        pstmt.executeUpdate();
                    }
                }
            }

            saveProfileImage(request, studentId);
            response.sendRedirect("profile_view.jsp?updated=1");
        } catch (ClassNotFoundException | SQLException e) {
            throw new ServletException(e);
        }
    }

    private String value(HttpServletRequest request, String name) {
        String value = request.getParameter(name);
        return value == null ? "" : value.trim();
    }

    private void redirect(HttpServletResponse response, String error) throws IOException {
        response.sendRedirect("profile_modify.jsp?error=" + error);
    }

    private void saveProfileImage(HttpServletRequest request, int studentId) throws IOException, ServletException {
        Part imagePart = request.getPart("profileImage");
        if (imagePart == null || imagePart.getSize() == 0) {
            return;
        }

        if (!"image/png".equals(imagePart.getContentType())) {
            return;
        }

        String uploadDirPath = getServletContext().getRealPath("/assets/img/member");
        if (uploadDirPath == null) {
            return;
        }

        File uploadDir = new File(uploadDirPath);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }

        String fileName = studentId + ".png";
        Path deployedFile = new File(uploadDir, fileName).toPath();
        Files.copy(imagePart.getInputStream(), deployedFile, StandardCopyOption.REPLACE_EXISTING);
        copyToSourceMemberFolder(deployedFile, fileName);
    }

    private void copyToSourceMemberFolder(Path deployedFile, String fileName) throws IOException {
        File sourceDir = UploadPathUtils.sourceWebappDirectory(getServletContext(), "assets/img/member");
        if (sourceDir == null) {
            return;
        }

        if (!sourceDir.exists()) {
            sourceDir.mkdirs();
        }

        Files.copy(deployedFile, new File(sourceDir, fileName).toPath(), StandardCopyOption.REPLACE_EXISTING);
    }
}

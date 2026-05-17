import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import ohrm.util.UploadPathUtils;

public class ProfileUpdateServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final String URL = "jdbc:mariadb://localhost:3306/ohrm_db";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "1234";
    private static final int STUDENT_ID = 20240001;

    private static final String BIRTH_DATE_REGEX = "^\\d{4}\\.\\d{2}\\.\\d{2}$";
    private static final String PHONE_REGEX = "^010-\\d{4}-\\d{4}$";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String birthDate = value(request, "birthDate");
        String major = value(request, "major");
        String phone = value(request, "phone");
        String bio = value(request, "bio");

        if (!birthDate.matches(BIRTH_DATE_REGEX)) {
            redirect(response, "birth");
            return;
        }

        if (!phone.matches(PHONE_REGEX)) {
            redirect(response, "phone");
            return;
        }

        Date parsedBirthDate;
        try {
            parsedBirthDate = Date.valueOf(birthDate.replace(".", "-"));
        } catch (IllegalArgumentException e) {
            redirect(response, "birth");
            return;
        }

        try {
            Class.forName("org.mariadb.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(URL, DB_USER, DB_PASSWORD);
                 PreparedStatement pstmt = conn.prepareStatement(
                     "UPDATE members SET birth_date = ?, major = ?, phone = ?, bio = ? WHERE student_id = ?"
                 )) {
                pstmt.setDate(1, parsedBirthDate);
                pstmt.setString(2, major);
                pstmt.setString(3, phone);
                pstmt.setString(4, bio);
                pstmt.setInt(5, STUDENT_ID);
                pstmt.executeUpdate();
            }

            saveProfileImage(request);
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

    private void saveProfileImage(HttpServletRequest request) throws IOException, ServletException {
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

        String fileName = STUDENT_ID + ".png";
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

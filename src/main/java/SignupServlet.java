import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLIntegrityConstraintViolationException;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import ohrm.util.AuthUtils;

public class SignupServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final String URL = "jdbc:mariadb://localhost:3306/ohrm_db";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "1234";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        int studentId;
        try {
            studentId = Integer.parseInt(value(request, "studentId"));
        } catch (NumberFormatException e) {
            response.sendRedirect("signup.jsp?error=invalid");
            return;
        }

        String password = value(request, "password");
        String passwordConfirm = value(request, "passwordConfirm");
        String name = value(request, "name");
        int cohort;
        try {
            cohort = Integer.parseInt(value(request, "cohort"));
        } catch (NumberFormatException e) {
            response.sendRedirect("signup.jsp?error=invalid");
            return;
        }
        String email = value(request, "email");
        boolean isEnrolled = Boolean.parseBoolean(value(request, "isEnrolled"));
        String instrument = value(request, "instrument");

        if (password.isEmpty() || name.isEmpty() || email.isEmpty() || cohort < 1) {
            response.sendRedirect("signup.jsp?error=empty");
            return;
        }
        if (!password.equals(passwordConfirm)) {
            response.sendRedirect("signup.jsp?error=password");
            return;
        }
        if (instrument.isEmpty()) {
            instrument = "etc";
        }

        try {
            Class.forName("org.mariadb.jdbc.Driver");
            try (Connection conn = DriverManager.getConnection(URL, DB_USER, DB_PASSWORD);
                 PreparedStatement pstmt = conn.prepareStatement(
                     "INSERT INTO members (student_id, password_hash, name, cohort, phone, email, is_enrolled, joined_at, instrument) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
                 )) {
                pstmt.setInt(1, studentId);
                pstmt.setString(2, AuthUtils.sha256(password));
                pstmt.setString(3, name);
                pstmt.setInt(4, cohort);
                pstmt.setString(5, "");
                pstmt.setString(6, email);
                pstmt.setBoolean(7, isEnrolled);
                pstmt.setDate(8, new Date(System.currentTimeMillis()));
                pstmt.setString(9, instrument);
                pstmt.executeUpdate();
            }

            HttpSession session = request.getSession(true);
            session.setAttribute("studentId", studentId);
            response.sendRedirect("profile_modify.jsp");
        } catch (SQLIntegrityConstraintViolationException e) {
            response.sendRedirect("signup.jsp?error=duplicate");
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    private String value(HttpServletRequest request, String name) {
        String value = request.getParameter(name);
        return value == null ? "" : value.trim();
    }
}

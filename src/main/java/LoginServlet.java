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

public class LoginServlet extends HttpServlet {
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
            response.sendRedirect("login.jsp?error=1");
            return;
        }

        String password = value(request, "password");

        try {
            Class.forName("org.mariadb.jdbc.Driver");
            try (Connection conn = DriverManager.getConnection(URL, DB_USER, DB_PASSWORD);
                 PreparedStatement pstmt = conn.prepareStatement(
                     "SELECT password_hash FROM members WHERE student_id = ?"
                 )) {
                pstmt.setInt(1, studentId);
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (!rs.next() || !AuthUtils.passwordMatches(password, rs.getString("password_hash"))) {
                        response.sendRedirect("login.jsp?error=1");
                        return;
                    }
                }
            }

            HttpSession session = request.getSession(true);
            session.setAttribute("studentId", studentId);
            response.sendRedirect("index.jsp");
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    private String value(HttpServletRequest request, String name) {
        String value = request.getParameter(name);
        return value == null ? "" : value.trim();
    }
}

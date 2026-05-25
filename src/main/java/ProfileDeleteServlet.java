import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import ohrm.util.AuthUtils;

public class ProfileDeleteServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final String URL = "jdbc:mariadb://localhost:3306/ohrm_db";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "1234";

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

        Connection conn = null;

        try {
            Class.forName("org.mariadb.jdbc.Driver");

            conn = DriverManager.getConnection(URL, DB_USER, DB_PASSWORD);
            conn.setAutoCommit(false);

            // 관련 데이터 삭제
            deleteByStudentId(conn, "concert_attendance", studentId);
            deleteByStudentId(conn, "practice_record", studentId);
            deleteByStudentId(conn, "practice_records", studentId);
            deleteByStudentId(conn, "attendance", studentId);
            deleteByStudentId(conn, "practice", studentId);
            deleteByStudentId(conn, "member_photos", studentId);

            // 회원 삭제
            deleteMember(conn, studentId);

            conn.commit();

            // 프로필 이미지 삭제
            deleteProfileImage(request, studentId);

            // 세션 종료
            invalidateSession(request);

            // 로그인 페이지 이동
            response.sendRedirect("login.jsp?deleted=1");

        } catch (ClassNotFoundException | SQLException e) {

            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackException) {
                    rollbackException.printStackTrace();
                }
            }

            e.printStackTrace();
            response.sendRedirect("profile_modify.jsp?error=delete");

        } finally {

            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    private void deleteByStudentId(Connection conn, String tableName, int studentId) throws SQLException {

        // 테이블 존재 여부 확인
        if (!tableExists(conn, tableName)) {
            return;
        }

        // student_id 컬럼 존재 여부 확인
        if (!columnExists(conn, tableName, "student_id")) {
            return;
        }

        String sql = "DELETE FROM " + tableName + " WHERE student_id = ?";

        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, studentId);
            pstmt.executeUpdate();
        }
    }

    private void deleteMember(Connection conn, int studentId) throws SQLException {

        try (PreparedStatement pstmt = conn.prepareStatement(
                "DELETE FROM members WHERE student_id = ?"
        )) {

            pstmt.setInt(1, studentId);
            pstmt.executeUpdate();
        }
    }

    private boolean tableExists(Connection conn, String tableName) throws SQLException {

        DatabaseMetaData metaData = conn.getMetaData();

        try (ResultSet rs = metaData.getTables(
                conn.getCatalog(),
                null,
                tableName,
                new String[] { "TABLE" }
        )) {

            return rs.next();
        }
    }

    private boolean columnExists(Connection conn, String tableName, String columnName)
            throws SQLException {

        DatabaseMetaData metaData = conn.getMetaData();

        try (ResultSet rs = metaData.getColumns(
                conn.getCatalog(),
                null,
                tableName,
                columnName
        )) {

            return rs.next();
        }
    }

    private void deleteProfileImage(HttpServletRequest request, int studentId) {

        String imagePath = getServletContext()
                .getRealPath("/assets/img/member/" + studentId + ".png");

        if (imagePath == null) {
            return;
        }

        File imageFile = new File(imagePath);

        if (imageFile.exists()) {
            imageFile.delete();
        }
    }

    private void invalidateSession(HttpServletRequest request) {

        HttpSession session = request.getSession(false);

        if (session != null) {
            session.invalidate();
        }
    }
}
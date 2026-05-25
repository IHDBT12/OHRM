<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%
    request.setCharacterEncoding("UTF-8");
    Integer studentId = AuthUtils.currentStudentId(request);
    if (studentId == null) { response.sendRedirect("login.jsp"); return; }

    // 파라미터 수집
    int id = Integer.parseInt(request.getParameter("id"));
    String eventDate = request.getParameter("event_date"); // 리다이렉트용 연월 확보

    try {
        Class.forName("org.mariadb.jdbc.Driver");
        // 본인 일정(student_id 검증)만 삭제할 수 있도록 안전장치 결합
        String sql = "DELETE FROM personal_schedules WHERE id = ? AND student_id = ?";
        try (Connection conn = DriverManager.getConnection("jdbc:mariadb://localhost:3306/ohrm_db", "root", "1234");
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.setInt(2, studentId);
            ps.executeUpdate();
        }
    } catch (Exception e) {
        out.println("<script>alert('삭제 오류: " + e.getLocalizedMessage() + "'); history.back();</script>");
        return;
    }
    
    // 삭제 완료 후 보고 있던 달력의 연월 위치로 돌아가기
    response.sendRedirect("my_calendar.jsp?year=" + eventDate.substring(0,4) + "&month=" + Integer.parseInt(eventDate.substring(5,7)));
%>
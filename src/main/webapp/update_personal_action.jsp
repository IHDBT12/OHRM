<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%
    request.setCharacterEncoding("UTF-8");
    Integer studentId = AuthUtils.currentStudentId(request);
    if (studentId == null) { response.sendRedirect("login.jsp"); return; }

    // 파라미터 수집
    int id = Integer.parseInt(request.getParameter("id"));
    String eventDate = request.getParameter("event_date");
    String eventTime = request.getParameter("event_time"); 
    String title = request.getParameter("title");
    String details = request.getParameter("details");

    try {
        Class.forName("org.mariadb.jdbc.Driver");
        // 본인 일정(student_id 검증)만 수정할 수 있도록 WHERE 조건에 student_id를 결합
        String sql = "UPDATE personal_schedules SET title = ?, event_date = ?, event_time = ?, details = ? WHERE id = ? AND student_id = ?";
        try (Connection conn = DriverManager.getConnection("jdbc:mariadb://localhost:3306/ohrm_db", "root", "1234");
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, title);
            ps.setString(2, eventDate);
            ps.setString(3, eventTime);
            ps.setString(4, details);
            ps.setInt(5, id);
            ps.setInt(6, studentId);
            ps.executeUpdate();
        }
    } catch (Exception e) {
        out.println("<script>alert('수정 오류: " + e.getLocalizedMessage() + "'); history.back();</script>");
        return;
    }
    
    // 수정 완료 후 보던 년/월 페이지로 돌아가기
    response.sendRedirect("my_calendar.jsp?year=" + eventDate.substring(0,4) + "&month=" + Integer.parseInt(eventDate.substring(5,7)));
%>
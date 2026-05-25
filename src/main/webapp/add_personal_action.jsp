<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%
    request.setCharacterEncoding("UTF-8");
    Integer studentId = AuthUtils.currentStudentId(request);
    if (studentId == null) { response.sendRedirect("login.jsp"); return; }

    String eventDate = request.getParameter("event_date");
    String eventTime = request.getParameter("event_time"); 
    String title = request.getParameter("title");
    String details = request.getParameter("details"); // 세부사항 접수

    try {
        Class.forName("org.mariadb.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection("jdbc:mariadb://localhost:3306/ohrm_db", "root", "1234");
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO personal_schedules (student_id, title, event_date, event_time, details) VALUES (?, ?, ?, ?, ?)")) {
            ps.setInt(1, studentId);
            ps.setString(2, title);
            ps.setString(3, eventDate);
            ps.setString(4, eventTime);
            ps.setString(5, details); // DB에 세부사항 저장
            ps.executeUpdate();
        }
    } catch (Exception e) {
        out.println("<script>alert('저장 오류: " + e.getLocalizedMessage() + "'); history.back();</script>");
        return;
    }
    // 보고 있던 달로 리다이렉트
    response.sendRedirect("my_calendar.jsp?year=" + eventDate.substring(0,4) + "&month=" + Integer.parseInt(eventDate.substring(5,7)));
%>
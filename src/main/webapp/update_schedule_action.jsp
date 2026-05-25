<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%
    request.setCharacterEncoding("UTF-8");
    Integer studentId = AuthUtils.currentStudentId(request);
    if (studentId == null) { response.sendRedirect("login.jsp"); return; }

    // 폼 파라미터 수집
    int id = Integer.parseInt(request.getParameter("id"));
    String eventDate = request.getParameter("event_date");
    String eventTime = request.getParameter("event_time"); 
    String title = request.getParameter("title");
    String category = request.getParameter("category");
    String details = request.getParameter("details");

    try {
        Class.forName("org.mariadb.jdbc.Driver");
        String sql = "UPDATE schedule SET title = ?, event_date = ?, event_time = ?, category = ?, details = ? WHERE id = ?";
        try (Connection conn = DriverManager.getConnection("jdbc:mariadb://localhost:3306/ohrm_db", "root", "1234");
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, title);
            ps.setString(2, eventDate);
            ps.setString(3, eventTime);
            ps.setString(4, category);
            ps.setString(5, details);
            ps.setInt(6, id);
            ps.executeUpdate();
        }
    } catch (Exception e) {
        out.println("<script>alert('수정 중 오류가 발생했습니다: " + e.getLocalizedMessage() + "'); history.back();</script>");
        return;
    }
    
    // 수정 완료 후 해당 일정의 연월 달력 화면으로 이동
    response.sendRedirect("Calendar_page.jsp?year=" + eventDate.substring(0,4) + "&month=" + Integer.parseInt(eventDate.substring(5,7)));
%>
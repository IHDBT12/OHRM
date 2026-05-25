<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%
    request.setCharacterEncoding("UTF-8");
    Integer studentId = AuthUtils.currentStudentId(request);
    if (studentId == null) { response.sendRedirect("login.jsp"); return; }

    int id = Integer.parseInt(request.getParameter("id"));
    String eventDate = request.getParameter("event_date"); // 리다이렉트 위치 계산용

    try {
        Class.forName("org.mariadb.jdbc.Driver");
        String sql = "DELETE FROM schedule WHERE id = ?";
        try (Connection conn = DriverManager.getConnection("jdbc:mariadb://localhost:3306/ohrm_db", "root", "1234");
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    } catch (Exception e) {
        out.println("<script>alert('삭제 중 오류가 발생했습니다: " + e.getLocalizedMessage() + "'); history.back();</script>");
        return;
    }
    
    response.sendRedirect("Calendar_page.jsp?year=" + eventDate.substring(0,4) + "&month=" + Integer.parseInt(eventDate.substring(5,7)));
%>
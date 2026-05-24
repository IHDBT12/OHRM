<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    request.setCharacterEncoding("UTF-8");

    String eventDate = request.getParameter("event_date");
    String eventTime = request.getParameter("event_time"); // 시간 받기
    String title = request.getParameter("title");
    String details = request.getParameter("details");      // 세부사항 받기
    String category = request.getParameter("category");

    String url = "jdbc:mariadb://localhost:3306/ohrm_db"; 
    String dbUser = "root";
    String dbPass = "1234";

    try (Connection conn = DriverManager.getConnection(url, dbUser, dbPass);
         PreparedStatement ps = conn.prepareStatement(
             "INSERT INTO schedule (title, event_date, event_time, details, category) VALUES (?, ?, ?, ?, ?)")) {
        
        Class.forName("org.mariadb.jdbc.Driver");
        
        ps.setString(1, title);
        ps.setString(2, eventDate);
        ps.setString(3, eventTime);
        ps.setString(4, details);
        ps.setString(5, category);
        
        ps.executeUpdate();

    } catch (Exception e) {
        out.println("<script>alert('DB 저장 오류: " + e.getMessage() + "'); history.back();</script>");
        return;
    }
    response.sendRedirect("Calendar_page.jsp");
%>
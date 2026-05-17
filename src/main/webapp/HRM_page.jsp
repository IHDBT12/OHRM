<%@ page contentType="text/html; charset=UTF-8" language="java" 
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>인원 소개 페이지</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h2 { color: #333; }
        .instrument { margin-top: 20px; }
        .member { margin-left: 20px; }
    </style>
</head>
<body>
    <h2>인원 소개 페이지</h2>

    <%
        // DB 연결 정보 (MariaDB)
        String url = "jdbc:mariadb://localhost:3306/orchestra_db";
        String user = "root";
        String password = "1234";

        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;

        try {
            Class.forName("org.mariadb.jdbc.Driver"); // MariaDB 드라이버
            conn = DriverManager.getConnection(url, user, password);
            stmt = conn.createStatement();

            // 악기별 인원 수 조회
            String sql = "SELECT instrument, COUNT(*) AS cnt FROM orchestra_members GROUP BY instrument";
            rs = stmt.executeQuery(sql);

            while (rs.next()) {
                String instrument = rs.getString("instrument");
                int count = rs.getInt("cnt");
    %>
                <div class="instrument">
                    <h3><%= instrument %> (<%= count %>명)</h3>
                    <%
                        // 해당 악기 멤버 상세 조회
                        Statement stmt2 = conn.createStatement();
                        ResultSet rs2 = stmt2.executeQuery(
                            "SELECT name, generation FROM orchestra_members WHERE instrument='" + instrument + "'"
                        );
                        while (rs2.next()) {
                    %>
                        <div class="member"><%= rs2.getString("name") %> (<%= rs2.getInt("generation") %>기)</div>
                    <%
                        }
                        rs2.close();
                        stmt2.close();
                    %>
                </div>
    <%
            }
        } catch (Exception e) {
            out.println("DB 오류: " + e.getMessage());
        } finally {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
            if (conn != null) conn.close();
        }
    %>
</body>
</html>

<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ page import="java.io.File" %>
<%@ page import="ohrm.util.AuthUtils" %>
<%@ page import="static ohrm.util.JspUtils.*" %>
<%
  request.setCharacterEncoding("UTF-8");

  // 1. 보안 세션 검증 (로그인한 유저만 접근 가능)
  Integer sessionStudentId = AuthUtils.currentStudentId(request);
  if (sessionStudentId == null) {
    response.sendRedirect("login.jsp");
    return;
  }

  int studentId = sessionStudentId;
  String activeMenu = "members"; // 사이드바 활성 메뉴 매칭
  
  // topbar.jspf가 내부에서 사용하는 'name' 변수 선언
  String name = ""; 
  String memberDefaultImage = "assets/img/member/member.png";
  String memberCandidateImage = "assets/img/member/" + studentId + ".png";
  String memberCandidatePath = application.getRealPath(memberCandidateImage);
  String memberImageUrl = memberCandidatePath != null && new File(memberCandidatePath).exists()
      ? memberCandidateImage
      : memberDefaultImage;

  // 사용자가 상단 탭에서 선택한 악기 파트 파라미터 (기본값: 전체보기)
  String selectedInstrument = request.getParameter("instrument");
  if (selectedInstrument == null) {
    selectedInstrument = "ALL";
  }

  // 악기 맵 정의
  Map<String, String> instMap = new LinkedHashMap<>();
  instMap.put("violin", "바이올린");
  instMap.put("viola", "비올라");
  instMap.put("cello", "첼로");
  instMap.put("contrabass", "콘트라베이스");
  instMap.put("flute", "플루트");
  instMap.put("oboe", "오보에");
  instMap.put("clarinet", "클라리넷");
  instMap.put("horn", "호른");
  instMap.put("trumpet", "트럼펫");
  instMap.put("trombone", "트롬본");
  instMap.put("percussion", "타악기");
  instMap.put("etc", "기타"); 

  String url = "jdbc:mariadb://localhost:3306/ohrm_db";
  String dbUser = "root";
  String dbPass = "1234";

  List<Map<String, String>> memberList = new ArrayList<>();

  try {
    Class.forName("org.mariadb.jdbc.Driver");
    try (Connection conn = DriverManager.getConnection(url, dbUser, dbPass)) {
      
      // topbar.jspf용: 현재 로그인한 단원의 이름을 'name' 변수에 바인딩
      String profileSql = "SELECT name FROM members WHERE student_id = ?";
      try (PreparedStatement profilePs = conn.prepareStatement(profileSql)) {
        profilePs.setInt(1, studentId);
        try (ResultSet profileRs = profilePs.executeQuery()) {
          if (profileRs.next()) {
            name = text(profileRs, "name");
          }
        }
      }

      // 💡 [수정] phone, email 대신 데이터베이스의 cohort, major 컬럼을 가져오도록 SELECT 문을 수정했습니다.
      String sql = "SELECT student_id, name, cohort, major, instrument FROM members";
      
      // '기타(etc)' 탭을 누른 경우 필터링
      if ("etc".equals(selectedInstrument)) {
        sql += " WHERE instrument IS NULL OR instrument = '' OR instrument = 'etc'";
      } else if (!"ALL".equals(selectedInstrument)) {
        sql += " WHERE instrument = ?";
      }
      
      sql += " ORDER BY name ASC";

      try (PreparedStatement ps = conn.prepareStatement(sql)) {
        if (!"ALL".equals(selectedInstrument) && !"etc".equals(selectedInstrument)) {
          ps.setString(1, selectedInstrument);
        }
        
        try (ResultSet rs = ps.executeQuery()) {
          while (rs.next()) {
            Map<String, String> m = new HashMap<>();
            m.put("student_id", String.valueOf(rs.getInt("student_id")));
            m.put("name", rs.getString("name"));
            
            // 💡 cohort, major 데이터를 Map에 담아줍니다. (빈 값 방어 처리 포함)
            String cohortVal = rs.getString("cohort");
            String majorVal = rs.getString("major");
            m.put("cohort", (cohortVal != null) ? cohortVal : "-");
            m.put("major", (majorVal != null) ? majorVal : "미지정");
            
            String inst = rs.getString("instrument");
            if (inst == null || inst.trim().isEmpty() || !instMap.containsKey(inst)) {
              inst = "etc";
            }
            
            m.put("instrument", inst);
            memberList.add(m);
          }
        }
      }
    }
  } catch (Exception e) {
    out.println("<div style='color:red;'>오류 발생: " + e.getMessage() + "</div>");
  }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
  <link rel="stylesheet" href="assets/css/common.css">
  <title>오케스트라 단원 관리 - 파트별 분류</title>
  <style>
    body { font-family: 'Pretendard', sans-serif; background: #f5f7fb; color: #111827; margin: 0; }
    .content { padding: 30px; }
    
    /* 악기 분류 상단 탭 스타일 */
    .instrument-tabs { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 25px; background: #fff; padding: 15px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.02); }
    .tab-btn { padding: 8px 16px; background: #f1f5f9; color: #475569; border-radius: 20px; text-decoration: none; font-size: 14px; font-weight: 600; transition: all 0.2s ease; }
    .tab-btn:hover { background: #e2e8f0; color: #1e293b; }
    .tab-btn.active { background: #001f3f; color: #fff; }

    /* 단원 카드 배치 그리드 */
    .member-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }
    
    /* 단원 개별 카드 디자인 */
    .member-card { background: #fff; border-radius: 12px; padding: 20px; border: 1px solid #e5e7eb; box-shadow: 0 4px 12px rgba(0,0,0,0.03); display: flex; align-items: center; gap: 20px; position: relative; overflow: hidden; }
    
    /* 사진 배치를 위한 상대 위치 부모 컨테이너 구역 */
    .avatar-area { position: relative; width: 75px; height: 75px; flex-shrink: 0; }

    /* 회원 본인의 프로필 사진 스타일 */
    .member-profile-img { width: 100%; height: 100%; border-radius: 14px; object-fit: cover; border: 1px solid #e2e8f0; background: #f8fafc; }
    
    /* 악기 사진을 프로필 사진의 왼쪽 위에 배치 */
    .inst-mini-badge { position: absolute; top: -8px; left: -8px; width: 30px; height: 30px; border-radius: 50%; background: #ffffff; border: 1.5px solid #001f3f; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 6px rgba(0,0,0,0.15); z-index: 10; }
    .inst-mini-badge img { width: 75%; height: 75%; object-fit: contain; }
    
    .member-info { flex-grow: 1; }
    .member-name { font-size: 18px; font-weight: bold; color: #001f3f; margin: 0 0 5px 0; }
    .member-detail { font-size: 13px; color: #64748b; margin: 3px 0; }
    
    /* 우측 상단 악기 텍스트 명칭 뱃지 */
    .inst-badge { position: absolute; top: 15px; right: 15px; font-size: 11px; font-weight: bold; padding: 3px 8px; border-radius: 12px; background: #e0f2fe; color: #0369a1; }
    .inst-badge.badge-etc { background: #f1f5f9; color: #475569; }
  </style>
</head>
<body>
<div class="app-shell">
  <%@ include file="/WEB-INF/fragments/sidebar.jspf" %>
  <main class="main">
    <%@ include file="/WEB-INF/fragments/topbar.jspf" %>
    
    <section class="content">
      
      <div class="page-head" style="margin-bottom: 25px;">
        <h2 style="font-size: 28px; color: #001f3f; margin-bottom: 5px;"><i class="bi bi-music-note-list"></i> 파트별 단원 조회</h2>
      </div>

      <div class="instrument-tabs">
        <a href="?instrument=ALL" class="tab-btn <%= "ALL".equals(selectedInstrument) ? "active" : "" %>">전체보기</a>
        <%
          for (Map.Entry<String, String> entry : instMap.entrySet()) {
            String key = entry.getKey();
            String instName = entry.getValue();
            String activeClass = key.equals(selectedInstrument) ? "active" : "";
        %>
          <a href="?instrument=<%= key %>" class="tab-btn <%= activeClass %>"><%= instName %></a>
        <%
          }
        %>
      </div>

      <div class="member-grid">
        <%
          if (memberList.isEmpty()) {
        %>
          <div style="grid-column: 1/-1; text-align: center; padding: 50px; background: #fff; border-radius: 12px; color: #64748b;">
            <i class="bi bi-person-x" style="font-size: 40px;"></i>
            <p style="margin-top: 10px; font-weight: bold;">해당 파트에 등록된 단원이 없습니다.</p>
          </div>
        <%
          } else {
            for (Map<String, String> m : memberList) {
              String mId = m.get("student_id");
              String instKey = m.get("instrument");
              String instKor = instMap.containsKey(instKey) ? instMap.get(instKey) : "기타";
              
              // 1. 회원 프로필 사진 설정
              String currentMemberDefaultImg = "assets/img/member/member.png";
              String currentMemberCandidateImg = "assets/img/member/" + mId + ".png";
              String currentMemberCandidatePath = application.getRealPath(currentMemberCandidateImg);
              
              String finalMemberImgUrl = currentMemberCandidatePath != null && new File(currentMemberCandidatePath).exists()
                  ? currentMemberCandidateImg
                  : currentMemberDefaultImg;
              
              // 2. 악기 이미지 파일명 매칭
              String instImgPath = "assets/img/instrument/" + instKey + ".png";
        %>
          <div class="member-card">
            
            <div class="avatar-area">
              <% if (!"etc".equals(instKey)) { %>
                <div class="inst-mini-badge">
                  <img src="<%= instImgPath %>" onerror="this.src='assets/img/instrument/instrument.png'" alt="<%= instKor %>">
                </div>
              <% } %>
              
              <img src="<%= finalMemberImgUrl %>" onerror="this.src='assets/img/member/member.png'" class="member-profile-img" alt="프로필">
            </div>
            
            <div class="member-info">
              <h4 class="member-name"><%= html(m.get("name")) %></h4>
              <p class="member-detail"><i class="bi bi-card-text"></i> 학번: <%= html(mId) %></p>
              
              <%-- 💡 [요구사항 반영] 기존 전화번호/이메일 영역을 제거하고 기수와 학과 구역으로 대체했습니다. --%>
              <p class="member-detail"><i class="bi bi-people"></i> 기수: <%= html(m.get("cohort")) %>기</p>
              <p class="member-detail"><i class="bi bi-book"></i> 학과: <%= html(m.get("major")) %></p>
            </div>
            
            <div class="inst-badge <%= "etc".equals(instKey) ? "badge-etc" : "" %>">
              <%= instKor %>
            </div>
          </div>
        <%
            }
          }
        %>
      </div>

    </section>
  </main>
</div>
</body>
</html>
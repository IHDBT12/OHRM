package ohrm.util;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.SimpleDateFormat;

public final class JspUtils {
    private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("yyyy.MM.dd");

    private JspUtils() {
    }

    public static String html(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;");
    }

    public static String text(ResultSet rs, String column) throws SQLException {
        String value = rs.getString(column);
        return value == null ? "" : value;
    }

    public static String dateText(ResultSet rs, String column) throws SQLException {
        java.sql.Timestamp value = rs.getTimestamp(column);
        return value == null ? "" : DATE_FORMAT.format(value);
    }
}

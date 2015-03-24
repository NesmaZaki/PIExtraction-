
package PerformanceMeasures;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 *
 * @author Nesma
 */
public class Connect_Database {
    
    static Connection conn = null;
    public void conn_DB() throws SQLException {
        String url = "jdbc:oracle:thin:@localhost:1522:MasterDB";
        Properties props = new Properties();
        props.setProperty("user", "M");
        props.setProperty("password", "x");
        //creating connection to Oracle database using JDBC
        conn = DriverManager.getConnection(url, props);
    }
}

package PerformanceMeasures;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author Nesma
 */
public class Connect_Database {

    static Connection conn = null;
    
    /** connect to mysql database
     * @throws java.lang.ClassNotFoundException
     * @throws java.lang.InstantiationException
     * @throws java.sql.SQLException **/
    public void connectDB() throws ClassNotFoundException, InstantiationException, SQLException {
        String url = "jdbc:mysql://localhost:3306/test";
        try {
            Class.forName("com.mysql.jdbc.Driver").newInstance();
        } catch (IllegalAccessException ex) {
            Logger.getLogger(Connect_Database.class.getName()).log(Level.SEVERE, null, ex);
        }
        conn = (com.mysql.jdbc.Connection) DriverManager.getConnection(url, "root", "1234");
        System.out.println("Connected");
       
    }
    

}

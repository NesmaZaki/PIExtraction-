/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package PerformanceMeasures;

import static PerformanceMeasures.Connect_Database.conn;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.concurrent.TimeUnit;

/**
 *
 * @author nesma
 */
public class PerformanceIndicators {
    
    public void rawPerformanceMeassure() throws SQLException{
        CallableStatement c = conn.prepareCall("{call service}");
        c.execute();
        
        c = conn.prepareCall("{call Effective}");
        c.execute();
        
        c = conn.prepareCall("{call sojourn}");
        c.execute();
        
        c = conn.prepareCall("{call waiting}");
        c.execute();
        
    }
   

    /* get {E,W,S} of specific activity */
       public void activity_measure(String measure_type, String Activity) throws SQLException {

        String sum_activity = "select sum(metric_value) from raw_performance_measure where activity = ? and measure_type = ? ";
        PreparedStatement preStatement = conn.prepareStatement(sum_activity);
        preStatement.setString(1, Activity);
        preStatement.setString(2, measure_type);
        ResultSet rs = preStatement.executeQuery();

        while (rs.next()) {
            System.out.println(measure_type + " of activity " + Activity + " is " + rs.getInt(1));
        }

    }

    /* get {E,W,S} of specific resource */
    public void resource_measure(String measure_type, String Resource) throws SQLException {

        String sum_activity = "select sum(metric_value) from raw_performance_measure where resources = ? and measure_type = ? ";
        PreparedStatement preStatement = conn.prepareStatement(sum_activity);
        preStatement.setString(1, Resource);
        preStatement.setString(2, measure_type);
        ResultSet rs = preStatement.executeQuery();

        while (rs.next()) {
            System.out.println(measure_type + " of resource " + Resource + " is " + rs.getInt(1));
        }
    }
    
}

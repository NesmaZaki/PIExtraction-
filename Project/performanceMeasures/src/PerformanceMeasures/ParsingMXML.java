/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package PerformanceMeasures;

import static PerformanceMeasures.Connect_Database.conn;
import java.io.File;
import java.io.IOException;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Properties;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

/**
 *
 * @author Nesma
 */
public class ParsingMXML {

    public void parseMXML(String FileName) throws SQLException, ParseException, ParserConfigurationException, SAXException, IOException {
        File fXmlFile = new File(FileName);
        DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
        DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
        Document doc = dBuilder.parse(fXmlFile);
        Element docEle = doc.getDocumentElement();
        NodeList nl = docEle.getElementsByTagName("Process");
        String id = "";
        String eventtype = "";
        String activity = "";
        String resource = "";
        String timestamp = "";
        String processID = "";
        int count = 1;
        java.sql.Timestamp Timestamp = null;
        for (int i = 0; i < nl.getLength(); i++) {
            Node n1 = nl.item(i);
            Element e = (Element) n1;
            processID = n1.getAttributes().getNamedItem("id").getNodeValue();
            NodeList PI = e.getElementsByTagName("ProcessInstance");
            for (int j = 0; j < PI.getLength(); j++) {
                Node n = PI.item(j);
                Element ele = (Element) n;
                NodeList data = ele.getElementsByTagName("AuditTrailEntry");
                for (int k = 0; k < data.getLength(); k++) {
                    Node d = data.item(k);
                    Element eles = (Element) d;
                    NodeList nList = eles.getElementsByTagName("Data");
                    for (int temp = 0; temp < nList.getLength(); temp++) {
                        Node nNode = nList.item(temp);
                        NodeList childs = nNode.getChildNodes();
                        for (int l = 0; l < childs.getLength(); l++) {
                            if (childs.item(l).getNodeType() == Node.ELEMENT_NODE) {
                                Node pro = childs.item(l);
                                String key = pro.getAttributes().getNamedItem("name").toString();
                                if (key.contains("concept:name")) {
                                    activity = pro.getTextContent();
                                }
                                if (key.contains("transition")) {
                                    eventtype = pro.getTextContent();
                                }
                                if (key.contains("resource")) {
                                    resource = pro.getTextContent();
                                }
                                if (key.contains("instance")) {
                                    id = pro.getTextContent();
                                }
                                if (key.contains("time:timestamp")) {
                                    DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm");
                                    String time = pro.getTextContent();
                                    timestamp = time.replace("T", " ");
                                    Date date = dateFormat.parse(timestamp);
                                    long timest = date.getTime();
                                    Timestamp = new java.sql.Timestamp(timest);
                                }// end if time stamp
                            }// end if childs
                        }// end loop childs
                        String insert = "insert into eventlog (resources,activity,eventtype,time_stamp,case_id,event_id,process_id) values  (?,?,?,?,?,?,?)";
                        PreparedStatement insertRaw = null;
                        insertRaw = conn.prepareStatement(insert);
                        insertRaw.setString(1, resource);
                        insertRaw.setString(2, activity);
                        insertRaw.setString(3, eventtype);
                        insertRaw.setTimestamp(4, Timestamp);
                        insertRaw.setString(5, id);
                        insertRaw.setInt(6, count);
                        insertRaw.setString(7, processID);
                        insertRaw.executeUpdate();
                        insertRaw.close();
                        conn.commit();
                        count++;
                    }// end temp
                }// end data
            }// end pi
        }// end process
    }

    public void rawPerformanceMeassure() throws SQLException {
        String effectiveTime = "begin performancemeasures.effectiveTime; end;";
        CallableStatement callStmt = conn.prepareCall(effectiveTime);
        callStmt.execute();

        String serviceTime = "begin performancemeasures.Service_Time; end;";
        callStmt = conn.prepareCall(serviceTime);
        callStmt.execute();
    }

    public void serviceCase(String case_id) throws SQLException, ParseException {
        Timestamp c_start = null;
        Timestamp c_end = null;
        String cases = "select distinct c_start, c_end from raw_performance_measure where caseid = ? ";
        PreparedStatement preStatement = conn.prepareStatement(cases);
        preStatement.setString(1, case_id);
        ResultSet rs = preStatement.executeQuery();
       
        while (rs.next()) {
            c_start = rs.getTimestamp(1);
            c_end = rs.getTimestamp(2);
        }
        
        CallableStatement cstmt = conn.prepareCall ("{? = call difference_time (?, ?)}");
        cstmt.registerOutParameter (1, Types.INTEGER);
        cstmt.setTimestamp(2, c_start);
        cstmt.setTimestamp(3, c_end);
        cstmt.execute();
        int diff = cstmt.getInt(1);
        System.out.println(" Service Time of Case " + case_id + " is " + diff);
    }
    
    
    public void activity_measure(String measure_type, String Activity) throws SQLException{
        
        String sum_activity = "select sum(metric_value) from raw_performance_measure where activity = ? and measure_type = ? ";
        PreparedStatement preStatement = conn.prepareStatement(sum_activity);
        preStatement.setString(1, Activity);
        preStatement.setString(2, measure_type);
        ResultSet rs = preStatement.executeQuery();
       
        while (rs.next()) {
            System.out.println(measure_type + " of activity " + Activity + " is " + rs.getInt(1));
        }
        
    }
    
    
     public void resource_measure(String measure_type, String Resource) throws SQLException{
        
        String sum_activity = "select sum(metric_value) from raw_performance_measure where resources = ? and measure_type = ? ";
        PreparedStatement preStatement = conn.prepareStatement(sum_activity);
        preStatement.setString(1, Resource);
        preStatement.setString(2, measure_type);
        ResultSet rs = preStatement.executeQuery();
        
        while (rs.next()) {
            System.out.println(measure_type + " of resource " + Resource + " is " + rs.getInt(1));
        }   
    }
     
    public void resource_case_measure(String measure_type, String Resource, String case_id) throws SQLException{
        
        String sum_activity = "select sum(metric_value) from raw_performance_measure where resources = ? and measure_type = ?  and caseid = ?";
        PreparedStatement preStatement = conn.prepareStatement(sum_activity);
        preStatement.setString(1, Resource);
        preStatement.setString(2, measure_type);
        preStatement.setString(3, case_id);
        ResultSet rs = preStatement.executeQuery();
        
        while (rs.next()) {
            System.out.println(measure_type + " of resource " + Resource + " within case " + case_id + " is " + rs.getInt(1));
        }   
    }
    
    
    public void resource_activity_measure(String measure_type, String Activity, String Resource) throws SQLException{
        
        String sum_activity = "select sum(metric_value) from raw_performance_measure where resources = ? and measure_type = ?  and activity = ?";
        PreparedStatement preStatement = conn.prepareStatement(sum_activity);
        preStatement.setString(1, Resource);
        preStatement.setString(2, measure_type);
        preStatement.setString(3, Activity);
        ResultSet rs = preStatement.executeQuery();
        
        while (rs.next()) {
            System.out.println(measure_type + " of resource " + Resource + " within activity " + Activity + " is " + rs.getInt(1));
        }   
    }
     
     
    
}

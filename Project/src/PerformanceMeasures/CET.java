/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package PerformanceMeasures;

import static PerformanceMeasures.Connect_Database.conn;
import java.util.StringTokenizer;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import org.jbpt.algo.tree.rpst.IRPSTNode;
import org.jbpt.algo.tree.rpst.RPST;
import org.jbpt.algo.tree.rpst.RPSTNode;
import org.jbpt.hypergraph.abs.IVertex;
import org.jbpt.pm.ControlFlow;
import org.jbpt.pm.FlowNode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import org.jbpt.algo.tree.tctree.TCType;

/**
 *
 * @author Nesma
 */
public class CET {

    int max = 0;
    Map<String, ArrayList<Integer>> Data = new HashMap<String, ArrayList<Integer>>();
    ArrayList<Integer> value = new ArrayList<Integer>();
    ArrayList<String> Activity = new ArrayList<String>();
    int val = -9999;
    int loopCycle = 0;
    ArrayList<Object> LoopContent = new ArrayList<Object>();
    ArrayList<Object> AndChilds = new ArrayList<Object>();
    ArrayList<Object> Final_Activities = new ArrayList<Object>(); // store all activities that are exclusive with this activity.
    Connect_Database c1 = new Connect_Database();

    /**
     * Get all activities from tree
     */
    public void get_activities(RPST<ControlFlow<FlowNode>, FlowNode> r) {

        for (IRPSTNode<ControlFlow<FlowNode>, FlowNode> node : r.getRPSTNodes()) {
            value = new ArrayList<Integer>();

            if (node.getEntry().getT1().equals("Activity") == true) {
                Data.put(node.getEntry().getName(), value);
            } else if (node.getExit().getT1().equals("Activity") == true) {
                Data.put(node.getExit().getName(), value);
            }
        }

    }

    /**
     * SQL Statement
     */
    public void Adding_values(int case_id) throws SQLException, ClassNotFoundException, InstantiationException {
        c1.connectDB();
        int index = 0;
        String act = "select Max(occurrence),activity from raw_performance_measure where caseid = ? and measure_type = 'Effective' group by activity";
        PreparedStatement preStatement = conn.prepareStatement(act);
        preStatement.setInt(1, case_id);
        ResultSet rs = preStatement.executeQuery();
        while (rs.next()) {
            for (int i = 1; i <= rs.getInt(1); i++) {
                String act1 = "select sum(metric_value) from raw_performance_measure where activity = ? and  occurrence = ? and  measure_type = 'Effective' and caseid = ? group by activity";
                PreparedStatement preStatement1 = conn.prepareStatement(act1);
                preStatement1.setString(1, rs.getString(2));
                preStatement1.setInt(2, i);
                preStatement1.setInt(3, case_id);
                ResultSet rs1 = preStatement1.executeQuery();
                boolean val = rs1.next();  
                index = i - 1;
                if (val == false) {
                    Data.get(rs.getString(2)).add(index, 0);
                } else {
                    while (val) {
                        Data.get(rs.getString(2)).add(index, rs1.getInt(1));
                        val = rs1.next();
                    }
                }
            }
        }
    }

    /**
     * insert values in case effective raw performance
     */
    public void caseEffectiveTime(RPST<ControlFlow<FlowNode>, FlowNode> r, RPSTNode<ControlFlow<FlowNode>, FlowNode> n) throws SQLException, ClassNotFoundException, InstantiationException {
        c1.connectDB();
        String cases = "select distinct case_id , process_id from eventlog";
        PreparedStatement preStatement = conn.prepareStatement(cases);
        ResultSet rs = preStatement.executeQuery();
        ArrayList<Integer> casesData = new ArrayList<Integer>();
        ArrayList<String> processData = new ArrayList<String>();
        while (rs.next()) {
            casesData.add(rs.getInt(1));
            processData.add(rs.getString(2));
        }
        for (int i = 0; i < casesData.size(); i++) {
            get_activities(r);
            Adding_values(casesData.get(i));
            int metric = Effec(r, n);
            String insert = "insert into  CASE_EFFECTIVE_RAW_PERFORMANCE (PROCESSID ,caseid,METRIC_VALUE) values  (?,?,?)";
            PreparedStatement insertRaw = null;
            insertRaw = conn.prepareStatement(insert);
            insertRaw.setString(1, processData.get(i));
            insertRaw.setInt(2, casesData.get(i));
            insertRaw.setInt(3, metric);
            insertRaw.executeUpdate();
            Data.clear();
        }
    }

    /**
     * Maximum of nodes in case of AND
     *
     */
    public int Maximum(RPST<ControlFlow<FlowNode>, FlowNode> r, RPSTNode<ControlFlow<FlowNode>, FlowNode> n) {

        int val = 0;
        int max = 0;

        ArrayList<Object> arr = new ArrayList<Object>(r.getPolygonChildren(n));
        for (int i = 0; i < arr.size(); i++) {
            RPSTNode<ControlFlow<FlowNode>, FlowNode> node = (RPSTNode<ControlFlow<FlowNode>, FlowNode>) arr.get(i);
            if (node.getType() == TCType.AND || node.getType() == TCType.LOOP || node.getType() == TCType.POLYGON) {
                val = Maximum(r, node);
                if (val >= max) {
                    max = val;
                }
            } else if (node.getType() == TCType.XOR) {
                val = sum(r, node);
                if (val > max) {
                    max = val;
                }
            } else {
                if (node.getEntry().getT1().equals("Activity") == true) {
                    for (int j = 0; j < Data.get(node.getEntry().getName()).size(); j++) {
                        if (Data.get(node.getEntry().getName()).get(j) >= max) {
                            max = Data.get(node.getEntry().getName()).get(j);
                        }
                    }

                }
            }
        }
        return max;
    }
//

    /**
     * size of loopcycle
     *
     */
    int maximum = 0;

    // get maximum size of activities under loop condition
    public int size(RPST<ControlFlow<FlowNode>, FlowNode> r, RPSTNode<ControlFlow<FlowNode>, FlowNode> n) {

        ArrayList<Object> arr = new ArrayList<Object>(r.getPolygonChildren(n));
        for (int i = 0; i < arr.size(); i++) {
            RPSTNode<ControlFlow<FlowNode>, FlowNode> node = (RPSTNode<ControlFlow<FlowNode>, FlowNode>) arr.get(i);
            if (node.getType() == TCType.AND || node.getType() == TCType.POLYGON) {
                size(r, node);
            } else {
                if (node.getEntry().getT1().equals("Activity") == true) {
                    loopCycle = Data.get(node.getEntry().getName()).size();
                    if (loopCycle < maximum) {
                        loopCycle = maximum;
                    }
                }
            }
        }
        return loopCycle;
    }

    public void getAndChilds(RPST<ControlFlow<FlowNode>, FlowNode> r, RPSTNode<ControlFlow<FlowNode>, FlowNode> n) {
        ArrayList<Object> arr = new ArrayList<Object>(r.getPolygonChildren(n));
        for (int i = 0; i < arr.size(); i++) {
            RPSTNode<ControlFlow<FlowNode>, FlowNode> node = (RPSTNode<ControlFlow<FlowNode>, FlowNode>) arr.get(i);
            if (node.getEntry().getT1().equals("Activity") == true) {
                AndChilds.add(node);
            }
            getAndChilds(r, node);
        }
    }

    // this function make summation of values in case of XOR and Loop
    public int sum(RPST<ControlFlow<FlowNode>, FlowNode> r, RPSTNode<ControlFlow<FlowNode>, FlowNode> n) {
        int value = 0;
        int size = 0;
        ArrayList<Object> arr = new ArrayList<Object>(r.getPolygonChildren(n));
        for (int i = 0; i < arr.size(); i++) {
            RPSTNode<ControlFlow<FlowNode>, FlowNode> node = (RPSTNode<ControlFlow<FlowNode>, FlowNode>) arr.get(i);
            if (node.getType() == TCType.XOR || node.getType() == TCType.POLYGON || node.getType() == TCType.LOOP) {

                value += sum(r, node);
            } else if (node.getType() == TCType.AND) {
                loopCycle = 0;
                size = size(r, node);
                if (size == 1) {
                    value += Maximum(r, node);
                } else {
                    modify_data(r, node, size);
                    for (int j = 0; j < size; j++) {
                        val = -9999;
                        value += Max_loop(r, node, j);
                    }
                }
            } else {
                if (node.getEntry().getT1().equals("Activity") == true) {
                    for (int j = 0; j < Data.get(node.getEntry().getName()).size(); j++) {
                        value += Data.get(node.getEntry().getName()).get(j);

                    }
                }
            }
        }

        return value;
    }

    // this function make each activity under AND gateway under Loop the same size of arraylist 
    public void modify_data(RPST<ControlFlow<FlowNode>, FlowNode> r, RPSTNode<ControlFlow<FlowNode>, FlowNode> n, int size) {

        ArrayList<Object> arr = new ArrayList<Object>(r.getChildren(n));
        for (int i = 0; i < arr.size(); i++) {
            RPSTNode<ControlFlow<FlowNode>, FlowNode> node = (RPSTNode<ControlFlow<FlowNode>, FlowNode>) arr.get(i);
            if (node.getType() == TCType.POLYGON) {
                modify_data(r, node, size);
            } else if (node.getType() == TCType.XOR) {
                modify_data(r, node, size);
            } else {
                if (node.getEntry().getT1().equals("Activity") == true) {
                    if (Data.get(node.getEntry().getName()).size() < size) {
                        int difference = size - Data.get(node.getEntry().getName()).size();
                        int x = Data.get(node.getEntry().getName()).size();
                        for (int h = 0; h < difference; h++) {
                            Data.get(node.getEntry().getName()).add(x++, 0);
                        }
                    }
                }
            }
        }

    }

    public int Max_loop(RPST<ControlFlow<FlowNode>, FlowNode> r, RPSTNode<ControlFlow<FlowNode>, FlowNode> n, int index) {

        ArrayList<Object> arr = new ArrayList<Object>(r.getChildren(n));
        for (int i = 0; i < arr.size(); i++) {
            RPSTNode<ControlFlow<FlowNode>, FlowNode> node = (RPSTNode<ControlFlow<FlowNode>, FlowNode>) arr.get(i);
            if (node.getType() == TCType.POLYGON) {
                Max_loop(r, node, index);
            } else if (node.getType() == TCType.XOR) {
                Max_loop(r, node, index);
            } else {
                if (node.getEntry().getT1().equals("Activity") == true && !Data.get(node.getEntry().getName()).isEmpty() && Data.get(node.getEntry().getName()).get(index) != 0) {
                    if (Data.get(node.getEntry().getName()).get(index) > val) {
                        val = Data.get(node.getEntry().getName()).get(index);
                    }
                }
            }
        }
        return val;
    }

    /**
     * Function to calculate effective time for specific case
     *
     */
    public int Effec(RPST<ControlFlow<FlowNode>, FlowNode> r, RPSTNode<ControlFlow<FlowNode>, FlowNode> n) {
        int value = 0;
        ArrayList<Object> arr = new ArrayList<Object>(r.getPolygonChildren(n));
        for (int i = 0; i < arr.size(); i++) {
            RPSTNode<ControlFlow<FlowNode>, FlowNode> node = (RPSTNode<ControlFlow<FlowNode>, FlowNode>) arr.get(i);
            if (node.getType() == TCType.AND) {
                value += Maximum(r, node);
            } else if (node.getType() == TCType.XOR || node.getType() == TCType.LOOP) {
                value += sum(r, node);
            } else {
                if (node.getEntry().getT1().equals("Activity") == true) {
                    for (int j = 0; j < Data.get(node.getEntry().getName()).size(); j++) {
                        value += Data.get(node.getEntry().getName()).get(j);
                    }
                }
            }
        }
        return value;
    }

    public void Get_Child(RPST<ControlFlow<FlowNode>, FlowNode> r, RPSTNode<ControlFlow<FlowNode>, FlowNode> n) throws SQLException {

        ArrayList<Object> arr = new ArrayList<Object>(r.getPolygonChildren(n));
        for (int i = 0; i < arr.size(); i++) {
            RPSTNode<ControlFlow<FlowNode>, FlowNode> node = (RPSTNode<ControlFlow<FlowNode>, FlowNode>) arr.get(i);
            if (node.getType() == TCType.LOOP) {
                Get_Child_Loops(r, node);
            } else {
                Get_Child(r, node);
            }
        }

    }

    /**
     * Store activities of loop
     * 
     */
    public void Get_Child_Loops(RPST<ControlFlow<FlowNode>, FlowNode> r, RPSTNode<ControlFlow<FlowNode>, FlowNode> n) throws SQLException {

        ArrayList<Object> arr = new ArrayList<Object>(r.getPolygonChildren(n));
        for (int i = 0; i < arr.size(); i++) {
            RPSTNode<ControlFlow<FlowNode>, FlowNode> node = (RPSTNode<ControlFlow<FlowNode>, FlowNode>) arr.get(i);
            if (node.getType() == TCType.XOR) {
                Get_Child_Loops(r, node);
            } else if (node.getType() == TCType.AND) {
                Get_Child_Loops(r, node);
            } else if (node.getType() == TCType.POLYGON) {
                Get_Child_Loops(r, node);
            } else {

                if (node.getEntry().getT1().equals("Activity") == true) {
                    LoopContent.add(node);
                }
            }
        }
    }
    
    /**
     * Display Function
     *
     */
    public void display() {
        System.out.println("Data " + Data.keySet());
    }
}

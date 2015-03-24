/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package PerformanceMeasures;

/**
 *
 * @author Nesma
 */
//import static PerformanceMeasures.Connect_Database.conn_DB;
import com.sun.org.apache.xerces.internal.util.DOMUtil;
import java.io.IOException;
import java.sql.SQLException;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Scanner;
import java.util.Set;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.soap.Node;
import org.jbpt.algo.tree.TreeTraversals;
import org.jbpt.algo.tree.bctree.BCTree;
import org.jbpt.algo.tree.bctree.BCTreeNode;

import org.jbpt.pm.Activity;
import org.jbpt.pm.Gateway;
import org.jbpt.pm.XorGateway;
import org.jbpt.pm.AndGateway;
import org.jbpt.pm.ProcessModel;
import org.jbpt.algo.tree.rpst.IRPSTNode;
import org.jbpt.algo.tree.rpst.RPST;
import org.jbpt.algo.tree.rpst.RPSTNode;
import org.jbpt.algo.tree.tctree.EdgeList;
import org.jbpt.algo.tree.tctree.TCSkeleton;
import org.jbpt.algo.tree.tctree.TCTree;
import org.jbpt.algo.tree.tctree.TCTreeNode;
import org.jbpt.algo.tree.tctree.TCType;
import org.jbpt.graph.DirectedEdge;
import org.jbpt.graph.Edge;
import org.jbpt.graph.MultiDirectedGraph;
import org.jbpt.graph.abs.IDirectedEdge;
import org.jbpt.graph.abs.IEdge;
import org.jbpt.hypergraph.abs.IVertex;
import org.jbpt.hypergraph.abs.Vertex;
import org.jbpt.pm.ControlFlow;
import org.jbpt.pm.FlowNode;
import org.jbpt.pm.bpmn.Bpmn;
import org.jbpt.pm.bpmn.Task;
import org.jbpt.pm.bpmn.BpmnControlFlow;
import org.jbpt.pm.bpmn.AlternativeGateway;
import org.jbpt.graph.abs.IDirectedGraph;
import org.jbpt.utils.IOUtils;
import org.xml.sax.SAXException;

public class Main {

    /**
     * @param args the command line arguments
     */
    
    public static void main(String[] args) throws SQLException, ParseException, ParserConfigurationException, SAXException, IOException {

        /**
         * ****************************** Intialization of process Model *******************************************
         */
        ProcessModel p = new ProcessModel();

        int s = 0;
        
        Activity tl = new Activity("Start", "Activity");
        Activity t1 = new Activity("Check stock availability", "Activity");
        Activity t2 = new Activity("Check raw materials", "Activity");
        Activity t3 = new Activity("Get raw materials from supplier 1", "Activity");
        Activity t4 = new Activity("Get raw materials from supplier 2", "Activity");
        Activity t5 = new Activity("Manufacture Product", "Activity");
        Activity t6 = new Activity("Retrieve Product", "Activity");
        Activity t7 = new Activity("Confirm Order", "Activity");
        Activity t8 = new Activity("Ship Product", "Activity");
        Activity t9 = new Activity("Recieve Payment", "Activity");
        Activity t10 = new Activity("Close Order", "Activity");
        Activity tend = new Activity("End", "Activity");
        
        Gateway s1 = new XorGateway("s1", "XOR", "SPLIT", s);
        Gateway s2 = new XorGateway("s2", "XOR", "SPLIT", s);
        Gateway s3 = new AndGateway("s3", "XOR", "SPLIT", s);
        Gateway s4 = new AndGateway("s4", "XOR", "JOIN", s);
        Gateway s5 = new AndGateway("s5", "XOR", "JOIN", s);
        Gateway s6 = new AndGateway("s6", "XOR", "JOIN", s);
        Gateway s7 = new XorGateway("s7", "AND", "SPLIT", s);
        Gateway s8 = new XorGateway("s8", "AND", "JOIN", s);
        
        p.addControlFlow(tl, t1);
        p.addControlFlow(t1, s1);
        p.addControlFlow(s1, s2);
        p.addControlFlow(s1, t6);
        p.addControlFlow(s2, t2);
        p.addControlFlow(t2, s3);
        p.addControlFlow(s3, t3);
        p.addControlFlow(t3, s4);
        p.addControlFlow(s3, t4);
        p.addControlFlow(t4, s4);
        p.addControlFlow(s4, s5);
        p.addControlFlow(s5, s2);
        p.addControlFlow(s5, t5);
        p.addControlFlow(t5, s6);
        p.addControlFlow(t6, s6);
        p.addControlFlow(s6, t7);
        p.addControlFlow(t7, s7);
        p.addControlFlow(s7, t8);
        p.addControlFlow(s7, t9);
        p.addControlFlow(t8, s8);
        p.addControlFlow(t9, s8);
        p.addControlFlow(s8, t10);
        p.addControlFlow(t10, tend);
        
        /**
         * building RPST
         */
        RPST<ControlFlow<FlowNode>, FlowNode> rpst = new RPST<ControlFlow<FlowNode>, FlowNode>(p);
        
        /* connect to database */
        Connect_Database c = new Connect_Database();
        c.conn_DB();
        
        /* parse file MXML */
        ParsingMXML par = new ParsingMXML();
        par.parseMXML("OrderFullfilment.mxml");
        
        /* calling functions effective and service and waiting */
        par.rawPerformanceMeassure();
       par.serviceCase("1");
       par.activity_measure("Effective", "Ship Product");
       par.resource_measure("service", "Galal");
       par.resource_case_measure("service", "Galal", "1");
       par.resource_activity_measure("service", "Get raw materials from supplier 2","Marwan");
        
        /**
         *  Calculating Effective time for case 
         */
         CET x = new CET();
         x.caseEffectiveTime(rpst, (RPSTNode<ControlFlow<FlowNode>, FlowNode>) rpst.getRoot()); 
    }

}

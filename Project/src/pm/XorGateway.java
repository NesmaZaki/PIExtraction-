package org.jbpt.pm;

/**
 * Base class for a XOR-Gateway in a process model.
 *
 * @author Tobias Hoppe
 *
 */
public class XorGateway extends Gateway implements IXorGateway {

   
 //public String t  = null;
    /**
     * Create a new XOR-Gateway
     */
    public XorGateway() {
        super();
    }

    /**
     * Create a new XOR-Gateway
     *
     * @param name
     * @param type
     */
    public XorGateway(String name) {
        super(name);
      //  this.setSpecifyType("XOR");
    }
    /// nesma
    public XorGateway(String name , String description) {
        super(name,description);
        //this.setSpecifyType("XOR");
    }

    public XorGateway(String name , String type , String description, int size) {
        super(name,type, description,size);
        //this.setSpecifyType("XOR");
    }

    
    
}

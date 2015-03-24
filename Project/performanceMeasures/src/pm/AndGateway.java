package org.jbpt.pm;

/**
 * Base class for an AND-Gateway in a process model.
 * @author Tobias Hoppe
 *
 */
public class AndGateway extends Gateway implements IAndGateway {

	/**
	 * Create a new {@link AndGateway} with an empty name.
	 */
	public AndGateway(){
		super();
	}

	/**
	 * Create a new {@link AndGateway} with the given name.
	 * @param name of this {@link AndGateway}
	 */
	public AndGateway(String name){
		super(name);
	}
        
        public AndGateway(String name , String type , String description, int size) {
        super(name,type, description,size);
        //this.setSpecifyType("XOR");
    }
}

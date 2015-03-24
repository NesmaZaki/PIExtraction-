package org.jbpt.hypergraph.abs;

import java.util.ArrayList;
import java.util.Map;
import java.util.StringTokenizer;
import java.util.UUID;

/**
 * Graph object implementation
 * 
 * @author Artem Polyvyanyy
 */
public abstract class GObject implements IGObject {
	private String id = "";
	private String name = "";
	private String desc = "";
        private String type = "";
        private int size  = 0;
        
	private Object tag = null;
        

	/**
	 * Empty constructor
	 */
	public GObject() {
           
		this.id = UUID.randomUUID().toString();
             
	}
	
	/**
	 * Constructor with object name parameter
	 */
	public GObject(String name) {
		this();
		setName(name);
	}
	
	/**
	 * Constructor with object name and description parameters
	 */
	public GObject(String name, String desc) {
		this(name);
		setT1(desc);
                
	}
	
        public GObject(String name , String type , String desc,int size) {
		this(name);
                setT1(type);
		setDescription(desc);
                setSize(size);
	}
        public GObject(String name , String type ,int size) {
		this(name);
                setT1(type);
                setSize(size);
	}
	/**
	 * Get unique identifier
	 * @return
	 */
	public String getId() {
		return this.id;
	}

	/**
	 * Set unique identifier
	 * @param id Unique identifier
	 */
	public void setId(String id) {
		this.id = id;
	}
	
	/**
	 * Get graph object associated tag object
	 * @return Tag object
	 */
	public Object getTag() {
		return this.tag;
	}
	
	/**
	 * Set graph object associated tag object
	 * @param tag Tag object to set
	 */
	public void setTag(Object tag) {
		this.tag = tag;
	}
	
	/**
	 * Get name
	 * @return Name string
	 */
	public String getName() {
		return this.name;
	}
	
	/**
	 * Set name
	 * @param name Name to set
	 */
	public void setName(String name) {
		this.name = name;
	}
        /*
        // nesma
        public void setActivity (String x){
           StringTokenizer activities = new StringTokenizer(x, ",");
           while(activities.hasMoreElements())
            activity.add(activities.nextElement());
        }
	
        // nesma
        public ArrayList<Object> getActivity (){
            for(int i = 0 ; i < activity.size() ; i++)
            {
                activity.get(i);
            }
            return activity;
        }
        
        //nesma
        public void setType(String type) {
		this.type = type;
	}
        public String getType1() {
		return this.type ;
	}*/
        
	/**
	 * Get description
	 * @return Description string
	 */
	
	public String getDescription() {
		return this.desc;
	}
	
	/**
	 * Set description
	 * @param desc Description to set
	 */
	public void setDescription(String desc) {
		this.desc = desc;
	}
	
	/*
	 * (non-Javadoc)
	 * @see java.lang.Object#toString()
	 */
	@Override
	public String toString() {
		return (getName()==null || getName().equals("")) ? this.id : this.name;
	}
	
	/*
	 * (non-Javadoc)
	 * @see java.lang.Object#equals(java.lang.Object)
	 */
	@Override
	public boolean equals(Object obj) {
		if (this == obj) return true;
		if (!(obj instanceof GObject)) return false;
		
		return this.id.equals(((GObject)obj).id);
	}

	/*
	 * (non-Javadoc)
	 * @see java.lang.Object#hashCode()
	 */
	@Override
	public int hashCode() {
		return this.id.hashCode();
	}

	/*
	 * (non-Javadoc)
	 * @see java.lang.Comparable#compareTo(java.lang.Object)
	 */
	public int compareTo(IGObject o) {
		return this.id.compareTo(o.getId());
	}
	
	@Override
	public IGObject clone() {
		GObject clone = null;
		try {
			clone = (GObject) super.clone();
		} catch (CloneNotSupportedException e) {
			e.printStackTrace();
		}
		
		clone.setId(UUID.randomUUID().toString());
		
		if (this.getName() != null)
			clone.setName(new String(this.getName()));
		if (this.getDescription() != null)
			clone.setDescription(new String(this.getDescription()));
		
		return clone;
	}
	
	@Override
	public String getLabel() {
		return this.name;
	}

    /**
     * @return the type
     */
    public String getT1() {
        return type;
    }

    /**
     * @param type the type to set
     */
    public void setT1(String type) {
        this.type = type;
    }

    /**
     * @return the size
     */
    public int getSize() {
        return size;
    }

    /**
     * @param size the size to set
     */
    public void setSize(int size) {
        this.size = size;
    }

}

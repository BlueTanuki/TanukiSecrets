package bluetanuki.tanukisecrets.common.model.xml;

import java.util.List;

/**
 *
 * @author Lucian Ganea
 */
public class Group {
	private String name;
	private List<Group> subgroups;
	private List<Item> items;

	public String getName () {
		return name;
	}

	public void setName (String name) {
		this.name = name;
	}

	public List<Group> getSubgroups () {
		return subgroups;
	}

	public void setSubgroups (List<Group> subgroups) {
		this.subgroups = subgroups;
	}

	public List<Item> getItems () {
		return items;
	}

	public void setItems (List<Item> items) {
		this.items = items;
	}
	
}

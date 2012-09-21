package bluetanuki.tanukisecrets.common.model.xml;

import java.util.List;

/**
 *
 * @author Lucian Ganea
 */
public class Item {
	private String name;
	private String description;
	private List<String> tags;
	private List<Field> fields;
	private String defaultFieldName;

	public String getName () {
		return name;
	}

	public void setName (String name) {
		this.name = name;
	}

	public String getDescription () {
		return description;
	}

	public void setDescription (String description) {
		this.description = description;
	}

	public List<String> getTags () {
		return tags;
	}

	public void setTags (List<String> tags) {
		this.tags = tags;
	}

	public List<Field> getFields () {
		return fields;
	}

	public void setFields (List<Field> fields) {
		this.fields = fields;
	}

	public String getDefaultFieldName () {
		return defaultFieldName;
	}

	public void setDefaultFieldName (String defaultFieldName) {
		this.defaultFieldName = defaultFieldName;
	}
	
}

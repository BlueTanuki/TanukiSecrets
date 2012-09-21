package bluetanuki.tanukisecrets.common.model.xml;

/**
 *
 * @author Lucian Ganea
 */
public class Field {
	private String name;
	private Boolean encrypted;
	private String value;

	public String getName () {
		return name;
	}

	public void setName (String name) {
		this.name = name;
	}

	public Boolean getEncrypted () {
		return encrypted;
	}

	public void setEncrypted (Boolean encrypted) {
		this.encrypted = encrypted;
	}

	public String getValue () {
		return value;
	}

	public void setValue (String value) {
		this.value = value;
	}
	
}

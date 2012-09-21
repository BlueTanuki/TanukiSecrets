package bluetanuki.tanukisecrets.common.model.xml;

/**
 *   
 *
 * @author Lucian Ganea
 */
public class DbMetadata {
	private String uid;
	private Version version;
	private String salt;
	private String name;
	private String description;
	private Author createdBy;
	private Author lastModifiedBy;

	public String getUid () {
		return uid;
	}

	public void setUid (String uid) {
		this.uid = uid;
	}

	public Version getVersion () {
		return version;
	}

	public void setVersion (Version version) {
		this.version = version;
	}

	public String getSalt () {
		return salt;
	}

	public void setSalt (String salt) {
		this.salt = salt;
	}

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

	public Author getCreatedBy () {
		return createdBy;
	}

	public void setCreatedBy (Author createdBy) {
		this.createdBy = createdBy;
	}

	public Author getLastModifiedBy () {
		return lastModifiedBy;
	}

	public void setLastModifiedBy (Author lastModifiedBy) {
		this.lastModifiedBy = lastModifiedBy;
	}
	
}

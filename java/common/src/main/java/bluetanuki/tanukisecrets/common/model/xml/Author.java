package bluetanuki.tanukisecrets.common.model.xml;

import java.util.Date;

/**
 *
 * @author Lucian Ganea
 */
public class Author {
	private String uid;
	private String name;
	private Date date;
	private String comment;

	public String getUid () {
		return uid;
	}

	public void setUid (String uid) {
		this.uid = uid;
	}

	public String getName () {
		return name;
	}

	public void setName (String name) {
		this.name = name;
	}

	public Date getDate () {
		return date;
	}

	public void setDate (Date date) {
		this.date = date;
	}

	public String getComment () {
		return comment;
	}

	public void setComment (String comment) {
		this.comment = comment;
	}
	
}

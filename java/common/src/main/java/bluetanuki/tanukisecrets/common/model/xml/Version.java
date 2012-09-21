package bluetanuki.tanukisecrets.common.model.xml;

/**
 *
 * @author Lucian Ganea
 */
public class Version {
	private Integer versionNumber;
	private String label;
	private String checksum;

	public Integer getVersionNumber () {
		return versionNumber;
	}

	public void setVersionNumber (Integer versionNumber) {
		this.versionNumber = versionNumber;
	}

	public String getLabel () {
		return label;
	}

	public void setLabel (String label) {
		this.label = label;
	}

	public String getChecksum () {
		return checksum;
	}

	public void setChecksum (String checksum) {
		this.checksum = checksum;
	}
	
}

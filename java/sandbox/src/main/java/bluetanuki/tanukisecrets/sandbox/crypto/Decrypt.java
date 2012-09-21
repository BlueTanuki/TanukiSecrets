package bluetanuki.tanukisecrets.sandbox.crypto;

import bluetanuki.tanukisecrets.common.crypto.CryptoUtils;
import bluetanuki.tanukisecrets.common.crypto.HashFunctions;
import bluetanuki.tanukisecrets.common.model.xml.Database;
import bluetanuki.tanukisecrets.common.model.xml.DbMetadata;
import bluetanuki.tanukisecrets.common.model.xml.Field;
import bluetanuki.tanukisecrets.common.model.xml.Group;
import bluetanuki.tanukisecrets.common.model.xml.Item;
import bluetanuki.tanukisecrets.common.xml.XMLUtils;
import java.io.File;
import org.apache.commons.codec.binary.Base64;
import org.apache.commons.codec.binary.Hex;
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.io.FileUtils;
import org.apache.log4j.Logger;

/**
 *
 * @author ganea
 */
public class Decrypt {
	private static final Logger LOGGER = Logger.getLogger (Decrypt.class);
	
	public static void decryptTest1 (String[] args) throws Exception {
//		for (Provider provider : Security.getProviders ()) {
//			System.out.println (provider.getName ());
//		}
//		for (String string : Security.getAlgorithms ("cipher")) {
//			System.out.println (string);
//		}
		
		File baseFolder = new File ("/Users/lucian/Dropbox/Apps/Tanuki Secrets");
		for (File file : baseFolder.listFiles ()) {
			if ((!file.getName ().startsWith (".")) && (!file.getName ().startsWith ("Icon"))) {
				long start = System.currentTimeMillis ();
				System.out.println ("File :: " + file.getName ());
				byte[] salt = Hex.decodeHex (file.getName ().toCharArray ());
				System.out.println ("salt :: " + Hex.encodeHexString (salt));
				byte[] encrypted = FileUtils.readFileToByteArray (file);
				System.out.println ("encrypted :: " + Base64.encodeBase64String (encrypted));
				byte[] decrypted = CryptoUtils.tanukiDecrypt (encrypted, "TheTanukiSais...NI-PAH~!", salt);
				System.out.println ("decrypted :: " + Base64.encodeBase64String (decrypted));
				System.out.println ("as string :: |" + new String (decrypted, "UTF-8") + "|");
				long end = System.currentTimeMillis ();
				System.out.println ("Decrypt action took " + (end - start) + " milliseconds");
			}
		}
	}
	
	public static void decryptTest2 (String[] args) throws Exception {
		File baseFolder = new File ("/Users/lucian/Dropbox/Apps/Tanuki Secrets");
		for (File file : baseFolder.listFiles ()) {
			if (file.getName ().endsWith (".tsm")) {
				DbMetadata dbMetadata = XMLUtils.loadDbMetadata (file);
				LOGGER.info ("Attempt to decrypt database " + dbMetadata.getUid ());
				byte[] salt = Hex.decodeHex (dbMetadata.getSalt ().toCharArray ());
				File encryptedFile = new File (baseFolder, dbMetadata.getUid () + ".ts");
				byte[] encrypted = FileUtils.readFileToByteArray (encryptedFile);
				byte[] decrypted = CryptoUtils.tanukiDecrypt (encrypted, "TheTanukiSais...NI-PAH~!", salt);
				File decryptedFile = new File ("/tmp/" + dbMetadata.getUid () + ".ts.decrypted");
				FileUtils.writeByteArrayToFile (decryptedFile, decrypted);
				LOGGER.info ("Wrote decrypted database to " + decryptedFile.getAbsolutePath ());
			}
		}
	}
	
	private static void decryptFields (String secret, Item item) throws Exception {
		if (item.getFields () != null) {
			for (Field field : item.getFields ()) {
				if ((field.getEncrypted () != null) && (field.getEncrypted ().booleanValue ())) {
					LOGGER.info ("Found encrypted field named " + field.getName () + 
							  " inside item named " + item.getName ());
					byte[] decrypted = CryptoUtils.tanukiDecryptField (
							  Hex.decodeHex (field.getValue ().toCharArray ()), 
							  secret, 
							  item.getName ());
					LOGGER.info (field.getValue () + " decrypts to " + new String (decrypted, "UTF-8"));
				}
			}
		}
	}
	
	private static void decryptFields (String secret, Group group) throws Exception {
		if (group.getSubgroups () != null) {
			for (Group subgroup : group.getSubgroups ()) {
				decryptFields (secret, subgroup);
			}
		}
		if (group.getItems () != null) {
			for (Item item : group.getItems ()) {
				decryptFields (secret, item);
			}
		}
	}

	public static void main (String[] args) throws Exception {
		File baseFolder = new File ("/tmp/");
		for (File file : baseFolder.listFiles ()) {
			if (file.getName ().endsWith (".ts.decrypted")) {
				Database database = XMLUtils.loadDatabase (file);
				decryptFields ("TheTanukiSais...NI-PAH~!", database);
			}
		}
	}
}
 
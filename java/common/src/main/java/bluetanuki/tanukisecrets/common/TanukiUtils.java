package bluetanuki.tanukisecrets.common;

import bluetanuki.tanukisecrets.common.crypto.CryptoUtils;
import bluetanuki.tanukisecrets.common.model.xml.Database;
import bluetanuki.tanukisecrets.common.model.xml.DbMetadata;
import bluetanuki.tanukisecrets.common.xml.XMLUtils;
import java.io.ByteArrayInputStream;
import java.io.File;
import org.apache.commons.codec.binary.Hex;
import org.apache.commons.io.FileUtils;

/**
 *   Helper class containing high level helper methods that use both crypto functions
 * and XML serialization.
 *
 * @author Lucian Ganea
 */
public class TanukiUtils {
	
	public static Database loadDatabase (DbMetadata dbMetadata, File databaseEncryptedFile, String secret) throws Exception {
		byte[] salt = Hex.decodeHex (dbMetadata.getSalt ().toCharArray ());
		byte[] encrypted = FileUtils.readFileToByteArray (databaseEncryptedFile);
		byte[] decrypted = CryptoUtils.tanukiDecrypt (encrypted, secret, salt);
		return XMLUtils.loadDatabase (new ByteArrayInputStream (decrypted));
	}

}

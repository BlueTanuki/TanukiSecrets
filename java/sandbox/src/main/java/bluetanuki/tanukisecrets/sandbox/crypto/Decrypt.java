package bluetanuki.tanukisecrets.sandbox.crypto;

import bluetanuki.tanukisecrets.common.crypto.CryptoUtils;
import bluetanuki.tanukisecrets.common.crypto.HashFunctions;
import java.io.File;
import org.apache.commons.codec.binary.Base64;
import org.apache.commons.codec.binary.Hex;
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.io.FileUtils;

/**
 *
 * @author ganea
 */
public class Decrypt {
	
	public static void main (String[] args) throws Exception {
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

}
 
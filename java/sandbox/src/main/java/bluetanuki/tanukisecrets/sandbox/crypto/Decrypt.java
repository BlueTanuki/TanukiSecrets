package bluetanuki.tanukisecrets.sandbox.crypto;

import bluetanuki.tanukisecrets.common.crypto.AES;
import bluetanuki.tanukisecrets.common.crypto.HashFunctions;
import java.io.File;
import org.apache.commons.codec.binary.Base64;
import org.apache.commons.codec.binary.Hex;
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
				byte[] key = HashFunctions.tanukiHash ("TheTanukiSais...NI-PAH~!", salt);
				System.out.println ("key :: " + Hex.encodeHexString (key));
				byte[] iv = HashFunctions.tanukiHash ("TanukiSecrets", key);
				System.out.println ("iv :: " + Hex.encodeHexString (iv));
				byte[] encrypted = FileUtils.readFileToByteArray (file);
				System.out.println ("encrypted :: " + Base64.encodeBase64String (encrypted));
				byte[] decrypted = AES.decryptAes128CbcWithPadding (encrypted, key, iv);
				System.out.println ("decrypted :: " + Base64.encodeBase64String (decrypted));
				System.out.println ("as string :: |" + new String (decrypted, "UTF-8") + "|");
				long end = System.currentTimeMillis ();
				System.out.println ("Decrypt action took " + (end - start) + " milliseconds");
			}
		}
	}

}
/*
openssl enc -d -aes-128-cbc -in '2012-08-01_10:54:08' -out /tmp/dec 
   -K 2e9de8bf30e62e03693b3e4fd545be15 -iv f4d052713eab16fa577867aff40bcf82 -nosalt -nopad
*/
 
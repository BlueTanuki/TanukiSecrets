package bluetanuki.tanukisecrets.sandbox.crypto;

import bluetanuki.tanukisecrets.common.crypto.HashFunctions;
import org.apache.commons.codec.binary.Hex;
import org.apache.commons.codec.digest.DigestUtils;

/**
 *
 * @author lucian
 */
public class OpensslDecryptHelper {
	
	private static void printUsage () {
		System.err.println ("Usage : java ... OpensslDecryptHelper secret salt hashUsedMemory");
		System.err.println ();
		System.err.println ("secret : the plaintext password used during encryption");
		System.err.println ("salt : the random binary salt used during encryption (hex-encoded)");
		System.err.println ("hashUsedMemory : the size (in MB) of the temporary memory used by the has, usually 13");
	}
	
	public static void main (String[] args) throws Exception {
		if (args.length != 3) {
			printUsage ();
			System.exit (13);
		}
		String secret = args[0];
		byte[] salt = Hex.decodeHex (args[1].toCharArray ());
		byte[] key = HashFunctions.tanukiHash (secret, salt, new Integer (args[2]));
		byte[] iv = HashFunctions.firstHalfOfSha256 (salt);
		
		String keyString = Hex.encodeHexString (key);
		String ivString = Hex.encodeHexString (iv);
		System.out.println ("Execute the following command : \n"
				  + "openssl enc -d -aes-256-cbc -in /path/to/encryptedFile -out /path/to/decryptedFile " 
				  + "-K " + keyString + " -iv " + ivString + " -nosalt");
	}

}

package bluetanuki.tanukisecrets.sandbox.crypto;

import java.io.File;
import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import org.apache.commons.codec.binary.Base64;
import org.apache.commons.codec.binary.Hex;
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.io.FileUtils;

/**
 *
 * @author ganea
 */
public class Decrypt {
	
	
	private static byte[] sha512 (String string) throws UnsupportedEncodingException {
		return DigestUtils.sha512 (string.getBytes ("UTF-8"));
	}
	
	private static byte[] md5 (String string) throws UnsupportedEncodingException {
		return DigestUtils.md5 (string.getBytes ("UTF-8"));
	}
	
	private static byte[] tanukiHash (String string, byte[] salt) throws Exception {
		long start = System.currentTimeMillis ();
		System.err.println ("secret = " + string);
		System.err.println ("salt = " + Hex.encodeHexString (salt));
		int bufSize = 1024 * 1024 * 13;
		byte[] buf = new byte[bufSize];
		ByteBuffer byteBuffer = ByteBuffer.wrap (buf);
		
		byte[] a = sha512 (string);
		byte[] b = DigestUtils.sha512 (salt);
		byteBuffer.put (a);
		byteBuffer.put (b);
		
		int n = bufSize / 64;
		for (int i = 2; i < n; i+=2) {
			byte[] newA = DigestUtils.sha512 (a);
			byte[] newB = DigestUtils.sha512 (b);
			byteBuffer.put (newA);
			byteBuffer.put (newB);
			a = newA;
			b = newB;
		}
		
		byte[] ret = DigestUtils.md5 (buf);
		System.err.println ("ret = " + Hex.encodeHexString (ret));
		long end = System.currentTimeMillis ();
		System.out.println ("tanukiHash took " + (end - start) + " milliseconds");
		return ret;
	}
	
	private static byte[] decryptAes128 (byte[] encrypted, byte[] key, byte[] iv) throws Exception {
		SecretKeySpec keySpec = new SecretKeySpec (key, "AES");

		Cipher cipher = Cipher.getInstance ("AES/CBC/PKCS5Padding");
//		Cipher cipher = Cipher.getInstance ("AES/CBC/NOPadding");
		IvParameterSpec ivParameterSpec = new IvParameterSpec (iv);
		cipher.init (Cipher.DECRYPT_MODE, keySpec, ivParameterSpec);

		return cipher.doFinal (encrypted);
	}
	
	public static void main (String[] args) throws Exception {
//		for (Provider provider : Security.getProviders ()) {
//			System.out.println (provider.getName ());
//		}
//		for (String string : Security.getAlgorithms ("cipher")) {
//			System.out.println (string);
//		}
		
		File baseFolder = new File ("/home/ganea/Desktop/Dropbox/Apps/Tanuki Secrets");
		for (File file : baseFolder.listFiles ()) {
			if (!file.getName ().startsWith (".")) {
				long start = System.currentTimeMillis ();
				System.out.println ("File :: " + file.getName ());
				byte[] salt = Hex.decodeHex (file.getName ().toCharArray ());
				System.out.println ("salt :: " + Hex.encodeHexString (salt));
				byte[] key = tanukiHash ("TheTanukiSais...NI-PAH~!", salt);
				System.out.println ("key :: " + Hex.encodeHexString (key));
				byte[] iv = tanukiHash ("TanukiSecrets", key);
				System.out.println ("iv :: " + Hex.encodeHexString (iv));
				byte[] encrypted = FileUtils.readFileToByteArray (file);
				System.out.println ("encrypted :: " + Base64.encodeBase64String (encrypted));
				byte[] decrypted = decryptAes128 (encrypted, key, iv);
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
 
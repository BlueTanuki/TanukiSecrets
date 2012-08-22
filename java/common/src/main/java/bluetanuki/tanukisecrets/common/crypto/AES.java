package bluetanuki.tanukisecrets.common.crypto;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

/**
 *   Helper class containing various AES encrypt and decrypt helper methods.
 * 
 * Some methods in this class will declare a very ugly 'throws Exception'. This is because
 * there are too many things that could go wrong with many of the methods provided here. 
 * The alternative would have been to catch them all and wrap them in a custom exception type, 
 * but the caller can just as easily do that.
 *
 * @author Lucian Ganea
 */
public class AES {
	
	/**
	 *  Helper function to decrypt a AES128-encrypted byte array. This method should be used if 
	 * the encryption was done in CBC mode with PKCS7 padding and initialization vector. 
	 */
	public static byte[] decryptAes128CbcWithPadding (byte[] encrypted, byte[] key, byte[] iv) throws Exception {
		SecretKeySpec keySpec = new SecretKeySpec (key, "AES");

		Cipher cipher = Cipher.getInstance ("AES/CBC/PKCS5Padding");
//		Cipher cipher = Cipher.getInstance ("AES/CBC/NOPadding");
		IvParameterSpec ivParameterSpec = new IvParameterSpec (iv);
		cipher.init (Cipher.DECRYPT_MODE, keySpec, ivParameterSpec);

		return cipher.doFinal (encrypted);
	}

}

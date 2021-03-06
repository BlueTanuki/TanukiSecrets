package bluetanuki.tanukisecrets.common.crypto;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import org.apache.commons.codec.digest.DigestUtils;

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
public class CryptoUtils {
	
	public static byte[] aesCbcWithPadding (byte[] data, byte[] key, byte[] iv, boolean decrypt) throws Exception {
		SecretKeySpec keySpec = new SecretKeySpec (key, "AES");

		Cipher cipher = Cipher.getInstance ("AES/CBC/PKCS5Padding");
		IvParameterSpec ivParameterSpec = new IvParameterSpec (iv);
		if (decrypt) {
			cipher.init (Cipher.DECRYPT_MODE, keySpec, ivParameterSpec);
		}else {
			cipher.init (Cipher.ENCRYPT_MODE, keySpec, ivParameterSpec);
		}

		return cipher.doFinal (data);
	}
	
	private static byte[] aesCbcWithoutPadding (byte[] encrypted, byte[] key, byte[] iv, boolean decrypt) throws Exception {
		SecretKeySpec keySpec = new SecretKeySpec (key, "AES");

		Cipher cipher = Cipher.getInstance ("AES/CBC/NOPadding");
		IvParameterSpec ivParameterSpec = new IvParameterSpec (iv);
		if (decrypt) {
			cipher.init (Cipher.DECRYPT_MODE, keySpec, ivParameterSpec);
		}else {
			cipher.init (Cipher.ENCRYPT_MODE, keySpec, ivParameterSpec);
		}

		return cipher.doFinal (encrypted);
	}
	
	/**
	 *  Helper function to decrypt a AES-encrypted byte array. This method should be used if 
	 * the encryption was done in CBC mode with PKCS7 padding and initialization vector. 
	 */
	public static byte[] decryptAesCbcWithPadding (byte[] encrypted, byte[] key, byte[] iv) throws Exception {
		return aesCbcWithPadding (encrypted, key, iv, true);
	}
	
	public static byte[] tanukiDecrypt (byte[] encrypted, String secret, byte[] salt, Integer consumedMemoryMB) throws Exception {
		byte[] key = HashFunctions.tanukiHash (secret, salt, consumedMemoryMB);
		byte[] iv = HashFunctions.firstHalfOfSha256 (salt);
		return decryptAesCbcWithPadding (encrypted, key, iv);
	}
	
	public static byte[] tanukiDecryptField (byte[] encrypted, String secret, String patentItemId) throws Exception {
		byte[] key = HashFunctions.firstHalfOfSha256 (secret.getBytes ("UTF-8"));
		byte[] iv = HashFunctions.firstHalfOfSha256 (patentItemId.getBytes ("UTF-8"));
		return decryptAesCbcWithPadding (encrypted, key, iv);
	}
	
}

package bluetanuki.tanukisecrets.common.crypto;

import java.nio.ByteBuffer;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.log4j.Logger;

/**
 *   Helper class used to compute various hash functions.
 *
 * @author Lucian Ganea
 */
public class HashFunctions {
	private static final Logger LOGGER = Logger.getLogger (HashFunctions.class);
	
	/**
	 *   Convenience method, shorthand for tanukiHash (secret.getBytes ("UTF-8"), salt).
	 */
	public static byte[] tanukiHashXX (String secret, byte[] salt) throws Exception {
		return HashFunctions.tanukiHashXX (secret.getBytes ("UTF-8"), salt);
	}
	
	/**
	 *   Implementation of the time and memory consuming TanukiHash. 
	 * The hash is computed as follows : 
	 * 1. initialization : 
	 * - allocate a byte array of length 13*1024*1024 (i.e. 13MB). The byte array 
	 * will be written in chunks of 64 bytes (called a and b)
	 * - set a = sha512 (secret)
	 * - set b = sha512 (salt)
	 * - The first two slices of the buffer are set to a and b respectively 
	 * (a is slice 0, using bytes 0-63 and b slice 1 using bytes 64-127)
	 * 2. the rest of the buffer
	 * - set newA = sha512 (a) and newB = sha512 (b)
	 * - write these new values to the next two unoccupied slices of the buffer
	 * - update a = newA, b = newB to prepare for the next step
	 * 3. the return value is the sha256 of the entire 13MB buffer.
	 * 
	 * @deprecated 
	 */
	public static byte[] tanukiHashXX (byte[] secret, byte[] salt) {
		long start = System.currentTimeMillis ();
		int bufSize = 1024 * 1024 * 13;
		byte[] buf = new byte[bufSize];
		ByteBuffer byteBuffer = ByteBuffer.wrap (buf);
		
		byte[] a = DigestUtils.sha512 (secret);
		byte[] b = DigestUtils.sha512 (salt);
		byteBuffer.put (a);
		byteBuffer.put (b);
		
		int n = bufSize / a.length;
		for (int i = 2; i < n; i+=2) {
			byte[] newA = DigestUtils.sha512 (a);
			byte[] newB = DigestUtils.sha512 (b);
			byteBuffer.put (newA);
			byteBuffer.put (newB);
			a = newA;
			b = newB;
		}
		
		byte[] ret = DigestUtils.sha256 (buf);
		long end = System.currentTimeMillis ();
		LOGGER.debug ("tanukiHash took " + (end - start) + " milliseconds");
		return ret;
	}
	
	/**
	 *   Convenience method, shorthand for tanukiHash (secret.getBytes ("UTF-8"), salt).
	 */
	public static byte[] tanukiHash (String secret, byte[] salt, Integer consumedMemoryMB) throws Exception {
		return HashFunctions.tanukiHash (secret.getBytes ("UTF-8"), salt, consumedMemoryMB);
	}
	
	/**
	 *   Slightly modified PBKDF2 implementation. Customizations and algorithm choices:
	 * - the used PRF is HMAC-SHA512
	 * - the changes were made so that the computation uses 13*1024*1024 bytes 
	 * (212'992 iterations in standard PBKDF2)
	 * - the U_1...U_212992 values are not XOR'd, but are kept in a big buffer,
	 * the buffer is populated in a pseudorandom order (initially Ui is placed on the i-th
	 * position, but then it gets swapped with another block whose index is computed by
	 * summing the bytes of Ui modulo i+1)
	 * - the output is a SHA256 of the entire 13MB array.
	 * 
	 */
	public static byte[] tanukiHash (byte[] secret, byte[] salt, Integer consumedMemoryMB) throws Exception {
		long start = System.currentTimeMillis ();
		int debugCount = 0;
		
		int bufSizeMB = 13;
		if ((consumedMemoryMB == null) || (consumedMemoryMB < 5)) {
			LOGGER.warn ("the consumed memory is not allowed to be below 5MB, using default value of 13!");
		}else if (consumedMemoryMB > 25) {
			LOGGER.warn ("for performace reasons, the consumed memory is not allowed to be above 25MB, using default value of 13!");
		}else {
			bufSizeMB = consumedMemoryMB;
		}
		int bufSize = 1024 * 1024 * bufSizeMB;
		byte[] buf = new byte[bufSize];
		Mac mac = Mac.getInstance ("HmacSHA512");
		SecretKeySpec keySpec = new SecretKeySpec (secret, "HmacSHA512");
		mac.init (keySpec);
		
		int SHA512_LENGTH = 64;
		int n = bufSize / SHA512_LENGTH;
		byte[] aux = mac.doFinal (salt);
		if (aux.length != SHA512_LENGTH) {
			throw new IllegalStateException ("The result of a HmacSHA512 operation had " + 
					  aux.length + " bytes!");
		}
		System.arraycopy (aux, 0, buf, 0, SHA512_LENGTH);
		for (int i=1; i<n; i++) {
			aux = mac.doFinal (aux);
			if (aux.length != SHA512_LENGTH) {
				throw new IllegalStateException ("The result of a HmacSHA512 operation had " + 
						  aux.length + " bytes!");
			}
			int newBlockOffset = i * SHA512_LENGTH;
			System.arraycopy (aux, 0, buf, newBlockOffset, SHA512_LENGTH);
			int newIndex = (int)buf[newBlockOffset] & 0xff;
			if (i <= debugCount) {
				System.out.println ("add " + ((int)buf[newBlockOffset] & 0xff));
			}
			for (int j = 1; j < SHA512_LENGTH; j++) {
				newIndex = (newIndex * 13 + ((int)buf[newBlockOffset + j] & 0xff)) % (i + 1);
				if (i <= debugCount) {
					System.out.println ("add " + ((int)buf[newBlockOffset + j] & 0xff));
				}
			}
			if (i <= debugCount) {
				System.out.println ("new index is " + newIndex);
			}
			if (newIndex != i) {
				int relocatedOffset = newIndex * SHA512_LENGTH;
				if (i <= debugCount) {
					LOGGER.info ("Swap blocks " + i + " and " + newIndex + "(offset " + 
						  newBlockOffset + " and " + relocatedOffset + ")");
				}
				for (int j=0; j<SHA512_LENGTH; j++) {
					if (i <= debugCount) {
						LOGGER.info ("Swap  " + buf[relocatedOffset + j] + " and " + buf[newBlockOffset + j]);
					}
					byte swap = buf[relocatedOffset + j];
					buf[relocatedOffset + j] = buf[newBlockOffset + j];
					buf[newBlockOffset + j] = swap;
				}
			}
		}
		
		byte[] ret = DigestUtils.sha256 (buf);
		long end = System.currentTimeMillis ();
		LOGGER.info ("tanukiHash took " + (end - start) + " milliseconds");
		return ret;
	}

}

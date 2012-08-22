package bluetanuki.tanukisecrets.common.crypto;

import java.nio.ByteBuffer;
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
	public static byte[] tanukiHash (String secret, byte[] salt) throws Exception {
		return HashFunctions.tanukiHash (secret.getBytes ("UTF-8"), salt);
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
	 * 3. the return value is the md5 of the entire 13MB buffer.
	 */
	public static byte[] tanukiHash (byte[] secret, byte[] salt) {
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
		
		byte[] ret = DigestUtils.md5 (buf);
		long end = System.currentTimeMillis ();
		LOGGER.debug ("tanukiHash took " + (end - start) + " milliseconds");
		return ret;
	}

}

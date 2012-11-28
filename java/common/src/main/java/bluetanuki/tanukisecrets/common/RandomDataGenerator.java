package bluetanuki.tanukisecrets.common;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Random;

/**
 *   Helper class that offers methods useful for data generation.
 *
 * @author Lucian Ganea
 */
public class RandomDataGenerator {

	private Random random;
	public static final String LOWERCASE = "qwertyuioplkjhgfdsazxcvbnm";
	public static final String UPPERCASE = "QWERTYUIOPLKJHGFDSAZXCVBNM";
	public static final String LETTERS = LOWERCASE + UPPERCASE;
	public static final String NUMBERS = "1234567890";
	public static final String ALFANUM = LETTERS + NUMBERS;
	public static final String SEPARATORS = " \t\r\n";
	public static final String PUNCTUATION = ".,;?!";
	public static final String OTHER_SYMBOLS = " `,./;'[]\\-=~!@#$%^&*()_+{}|:\"<>?";
	public static final String STANDARD_ALPHABET = ALFANUM + OTHER_SYMBOLS;

	public RandomDataGenerator () {
		random = new Random ();
	}

	/**
	 * @return random boolean, 50% probability to be true
	 */
	public synchronized boolean getBoolean () {
		return getBoolean (0.5f);
	}

	/**
	 * @return random boolean, will be true with the given probability
	 */
	public synchronized boolean getBoolean (float trueProbability) {
		float f = random.nextFloat ();
		if (f <= trueProbability) {
			return true;
		}
		return false;
	}

	/**
	 * @return random int, uniform 0 .. high
	 */
	public synchronized int getInt (int high) {
		return getInt (0, high);
	}

	/**
	 * @return random int, uniform low .. high
	 */
	public synchronized int getInt (int low, int high) {
		if (high < low) {
			return getInt (high, low);
		}
		if (low == high) {
			return low;
		}
		return low + random.nextInt (high - low);
	}

	/**
	 * @return random long, uniform 0 .. high
	 */
	public synchronized long getLong (long high) {
		return getLong (0, high);
	}

	/**
	 * @return random long, uniform low .. high
	 */
	public synchronized long getLong (long low, long high) {
		if (high < low) {
			return getLong (high, low);
		}
		if (low == high) {
			return low;
		}
		long ret = Math.abs (random.nextLong ());
		ret = low + ret % (high - low);
		assert ret >= low;
		assert ret <= high;
		return ret;
	}
	
	/**
	 * @return random 0-1 float
	 */
	public synchronized float getFloat () {
		return random.nextFloat ();
	}
	
	/**
	 * @return random low..high float
	 */
	public synchronized float getFloat (float low, float high) {
		if (low > high) {
			return getFloat (high, low);
		}
		float diff = high - low;
		return low + diff * random.nextFloat ();
	}

	/**
	 * @return random 0-1 double
	 */
	public synchronized double getDouble () {
		return random.nextDouble ();
	}
	
	/**
	 * @return random low..high double
	 */
	public synchronized double getDouble (double low, double high) {
		if (low > high) {
			return getDouble (high, low);
		}
		double diff = high - low;
		return low + diff * random.nextDouble ();
	}

	/**
	 * @return random string of given length over STANDARD_ALPHABET
	 */
	public synchronized String getString (int length) {
		return getString (STANDARD_ALPHABET, length);
	}

	/**
	 * @return random string of given length over the given alphabet
	 */
	public synchronized String getString (String allowedChars, int length) {
		StringBuilder sb = new StringBuilder (length);
		int len = allowedChars.length ();
		for (int i = 0; i < length; i++) {
			sb.append (allowedChars.charAt (getInt (len)));
		}
		return sb.toString ();
	}

	/**
	 * @return random string of given length over STANDARD_ALPHABET
	 */
	public synchronized String getString (int minLen, int maxLen) {
		return getString (STANDARD_ALPHABET, minLen, maxLen);
	}

	/**
	 * @return random string of random length between minLen and maxLen over the given alphabet
	 */
	public synchronized String getString (String allowedChars, int minLen, int maxLen) {
		int len = getInt (minLen, maxLen);
		return getString (allowedChars, len);
	}

	/**
	 * @return list containing the specified number of words, each word being obtained by a call to
	 * getRandomString (allowedChars, minLen, maxLen)
	 */
	public synchronized List<String> getStringList (int howMany, String allowedChars, int minLen, int maxLen) {
		List<String> ret = new ArrayList<String> ();
		for (int i = 0; i < howMany; i++) {
			ret.add (getString (allowedChars, minLen, maxLen));
		}
		return ret;
	}

	/**
	 * @return a paragraph containing the specified number of words separated by whitespaces.
	 */
	public synchronized String getParagraph (int wordsCount, String allowedChars, int wordMinLength, int wordMaxLength) {
		StringBuilder buf = new StringBuilder ();
		for (int i = 0; i < wordsCount; i++) {
			buf.append (getString (allowedChars, wordMinLength, wordMaxLength));
			if (getBoolean (0.1f)) {
				buf.append (PUNCTUATION.charAt (getInt (PUNCTUATION.length ())));
			}
			buf.append (" ");
		}
		return buf.toString ().trim ();
	}

	/**
	 * @return a text containing the specified number of paragraphs separated by newlines.
	 */
	public synchronized String getText (int paragraphsCount, int paraMinLength, int paraMaxLength, String allowedChars,
			  int wordMinLength, int wordMaxLength) {
		StringBuilder buf = new StringBuilder ();
		for (int i = 0; i < paragraphsCount; i++) {
			buf.append (getParagraph (getInt (paraMinLength, paraMaxLength), allowedChars, wordMinLength, wordMaxLength));
			buf.append ("\n");
		}
		return buf.toString ();
	}

	/**
	 * @return random byte array of the specified size
	 */
	public synchronized byte[] getBytes (int size) {
		byte[] ret = new byte[size];
		random.nextBytes (ret);
		return ret;
	}

	/**
	 * @return random byte array with random size between given boundaries
	 */
	public synchronized byte[] getBytes (int minLen, int maxLen) {
		return getBytes (getInt (minLen, maxLen));
	}

	public synchronized Date getDate (int minDay, int maxDay, int minMonth, int maxMonth, int minYear, int maxYear,
			  int minHour, int maxHour, int minMinute, int maxMinute, int minSecond, int maxSecond) {
		int d, m, y, h, min, s;
		d = getInt (minDay, maxDay);
		m = getInt (minMonth, maxMonth);
		y = getInt (minYear, maxYear);
		h = getInt (minHour, maxHour);
		min = getInt (minMinute, maxMinute);
		s = getInt (minSecond, maxSecond);
		Calendar c = Calendar.getInstance ();
		c.set (y, m, d, h, min, s);
		return c.getTime ();
	}

	public synchronized Date getDate (int minDay, int maxDay, int minMonth, int maxMonth, int minYear, int maxYear) {
		return getDate (minDay, maxDay, minMonth, maxMonth, minYear, maxYear, 0, 24, 0, 60, 0, 60);
	}

	public synchronized Date getDate () {
		return getDate (1, 32, 0, 12, 1971, 2100);
	}

	public synchronized Date getDateBefore (Date when) {
		long millis = when.getTime ();
		long delta = getLong (millis / 2);
		return new Date (millis - delta);
	}

	public synchronized Date getPastDate () {
		return getDateBefore (new Date ());
	}

	public synchronized Date getDateAfter (Date when) {
		long millis = when.getTime ();
		long delta = getLong (millis / 2);
		return new Date (millis + delta);
	}

	public synchronized Date getFutureDate () {
		return getDateAfter (new Date ());
	}

	public synchronized Date getDateBetween (Date first, Date second, long minimumOffset) {
		long low = first.getTime ();
		long high = second.getTime ();
		long between = getLong (low + minimumOffset, high - minimumOffset);
		return new Date (between);
	}

	public synchronized Date getDateBetween (Date first, Date second) {
		return getDateBetween (first, second, 60 * 1000);
	}

}

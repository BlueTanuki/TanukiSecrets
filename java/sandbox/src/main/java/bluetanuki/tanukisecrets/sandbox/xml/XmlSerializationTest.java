package bluetanuki.tanukisecrets.sandbox.xml;

import bluetanuki.tanukisecrets.common.debug.DebugPrinter;
import bluetanuki.tanukisecrets.common.model.xml.Database;
import bluetanuki.tanukisecrets.common.model.xml.DbMetadata;
import bluetanuki.tanukisecrets.common.xml.XMLUtils;
import java.io.File;
import java.io.IOException;
import org.apache.log4j.Logger;

/**
 *
 * @author Lucian Ganea
 */
public class XmlSerializationTest {
	private static final Logger LOGGER = Logger.getLogger (XmlSerializationTest.class);
	
	private static void debugDbMetadata (File file) throws IOException {
		LOGGER.info ("Read file : " + file.getName ());
		DbMetadata dbMetadata = XMLUtils.loadDbMetadata (file);
		DebugPrinter.debugDbMetadata (dbMetadata);
		XMLUtils.saveDbMetadata (dbMetadata, new File ("/tmp/" + file.getName ()));
	}
	
	private static void debugDatabase (File file) throws IOException {
		LOGGER.info ("Read file : " + file.getName ());
		Database database = XMLUtils.loadDatabase (file);
		DebugPrinter.debugGroup (database);
		XMLUtils.saveDatabase (database, new File ("/tmp/" + file.getName () + ".xml"));
	}
	
	public static void debugAllTSMs (String[] args) throws Exception {
		File baseFolder = new File ("/Users/lucian/Dropbox/Apps/Tanuki Secrets");
		for (File file : baseFolder.listFiles ()) {
			if (file.getName ().endsWith (".tsm")) {
				debugDbMetadata (file);
			}
		}
	}
	
	public static void debugAllPredecryptedTSs (String[] args) throws Exception {
		File baseFolder = new File ("/tmp/");
		for (File file : baseFolder.listFiles ()) {
			if (file.getName ().endsWith (".ts.decrypted")) {
				debugDatabase (file);
			}
		}
	}

	public static void main (String[] args) throws Exception {
		debugAllPredecryptedTSs (args);
	}
	
}

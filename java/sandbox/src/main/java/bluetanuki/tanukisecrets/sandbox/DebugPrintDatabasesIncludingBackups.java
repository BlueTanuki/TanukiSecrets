package bluetanuki.tanukisecrets.sandbox;

import bluetanuki.tanukisecrets.common.TanukiUtils;
import bluetanuki.tanukisecrets.common.debug.DebugPrinter;
import bluetanuki.tanukisecrets.common.model.xml.Database;
import bluetanuki.tanukisecrets.common.model.xml.DbMetadata;
import bluetanuki.tanukisecrets.common.xml.XMLUtils;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import org.apache.log4j.Logger;

/**
 *
 * @author lucian
 */
public class DebugPrintDatabasesIncludingBackups {
	private static final Logger LOGGER = Logger.getLogger (DebugPrintDatabasesIncludingBackups.class);
	
	public static void main (String[] args) throws Exception {
		List<String> databaseUids = new ArrayList<String> ();
		File baseFolder = new File ("/Users/lucian/Dropbox/Apps/Tanuki Secrets");
		String secret = "TheTanukiSais...NI-PAH~!";
		for (File file : baseFolder.listFiles ()) {
			if (file.getName ().endsWith (".tsm")) {
				databaseUids.add (file.getName ().replace (".tsm", ""));
			}
		}
		
		for (String uid : databaseUids) {
			LOGGER.info ("========== DATABASE " + uid + " ===============");
			File metadataFile = new File (baseFolder, uid + ".tsm");
			DbMetadata dbMetadata = XMLUtils.loadDbMetadata (metadataFile);
			DebugPrinter.debugDbMetadata (dbMetadata);
			File databaseFile = new File (baseFolder, uid + ".ts");
			Database database = TanukiUtils.loadDatabase (dbMetadata, databaseFile, secret);
			DebugPrinter.debugGroup (database);
			
			LOGGER.info (">>>>>>>>>>> BACKUPS <<<<<<<<<<<<");
			File backupsFolder = new File (baseFolder, uid + ".bak");
			List<String> backupIds = new ArrayList<String> ();
			for (File file : backupsFolder.listFiles ()) {
				if (file.getName ().endsWith (".tsm")) {
					backupIds.add (file.getName ().replace (".tsm", ""));
				}
			}
			for (String backupId : backupIds) {
				LOGGER.info ("========== BACKUP " + backupId + " ===============");
				metadataFile = new File (backupsFolder, backupId + ".tsm");
				dbMetadata = XMLUtils.loadDbMetadata (metadataFile);
				DebugPrinter.debugDbMetadata (dbMetadata);
				databaseFile = new File (backupsFolder, backupId + ".ts");
				database = TanukiUtils.loadDatabase (dbMetadata, databaseFile, secret);
				DebugPrinter.debugGroup (database);
			}
		}
	}
}

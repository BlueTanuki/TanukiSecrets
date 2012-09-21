package bluetanuki.tanukisecrets.common.xml;

import bluetanuki.tanukisecrets.common.model.xml.Database;
import bluetanuki.tanukisecrets.common.model.xml.DbMetadata;
import bluetanuki.tanukisecrets.common.model.xml.Field;
import bluetanuki.tanukisecrets.common.model.xml.Group;
import bluetanuki.tanukisecrets.common.model.xml.Item;
import com.thoughtworks.xstream.XStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

/**
 *   Helper class containing utility methods for reading/writing various objects.
 *
 * @author Lucian Ganea
 */
public class XMLUtils {
	
	private static XStream xStream () {
		XStream xs = new XStream ();
		xs.registerConverter (new DateConverter ());
		xs.alias ("tsdbMetadata", DbMetadata.class);
		xs.alias ("tanukiSecretsDatabase", Database.class);
		xs.alias ("group", Group.class);
		xs.alias ("item", Item.class);
		xs.alias ("field", Field.class);
		xs.alias ("tag", String.class);
		return xs;
	}
	
	public static DbMetadata loadDbMetadata (File file) throws IOException {
		DbMetadata ret = (DbMetadata) xStream ().fromXML (file);
		return ret;
	}
	
	public static void saveDbMetadata (DbMetadata dbMetadata, File file) throws IOException {
		OutputStream os = new BufferedOutputStream (new FileOutputStream (file));
		try {
			xStream ().toXML (dbMetadata, os);
		}finally {
			os.close ();
		}
	}

	public static Database loadDatabase (File file) throws IOException {
		Database ret = (Database) xStream ().fromXML (file);
		return ret;
	}
	
	public static void saveDatabase (Database database, File file) throws IOException {
		OutputStream os = new BufferedOutputStream (new FileOutputStream (file));
		try {
			xStream ().toXML (database, os);
		}finally {
			os.close ();
		}
	}

}

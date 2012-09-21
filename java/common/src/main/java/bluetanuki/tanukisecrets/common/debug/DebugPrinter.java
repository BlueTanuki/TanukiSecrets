package bluetanuki.tanukisecrets.common.debug;

import bluetanuki.tanukisecrets.common.model.xml.Author;
import bluetanuki.tanukisecrets.common.model.xml.DbMetadata;
import bluetanuki.tanukisecrets.common.model.xml.Field;
import bluetanuki.tanukisecrets.common.model.xml.Group;
import bluetanuki.tanukisecrets.common.model.xml.Item;
import bluetanuki.tanukisecrets.common.model.xml.Version;
import org.apache.log4j.Logger;

/**
 *
 * @author Lucian Ganea
 */
public class DebugPrinter {
	private static final Logger LOGGER = Logger.getLogger (DebugPrinter.class);
	
	public static void debugVersion (Version version) {
		debugVersion ("", version);
	}
	
	public static void debugVersion (String prefix, Version version) {
		LOGGER.info (prefix + "*** Version ***");
		if (version == null) {
			LOGGER.info (prefix + "NULL");
		}else {
			LOGGER.info (prefix + "versionNumber: " + version.getVersionNumber ());
			LOGGER.info (prefix + "label: " + version.getLabel ());
			LOGGER.info (prefix + "checksum: " + version.getChecksum ());
		}
		LOGGER.info (prefix + "*** END Version ***");
	}
	
	public static void debugAuthor (Author author) {
		debugAuthor ("", author);
	}
	
	public static void debugAuthor (String prefix, Author author) {
		LOGGER.info (prefix + "*** Author ***");
		if (author == null) {
			LOGGER.info (prefix + "NULL");
		}else {
			LOGGER.info (prefix + "uid: " + author.getUid ());
			LOGGER.info (prefix + "name: " + author.getName ());
			LOGGER.info (prefix + "date: " + author.getDate ());
			LOGGER.info (prefix + "comment: " + author.getComment ());
		}
		LOGGER.info (prefix + "*** END Author ***");
	}
	
	public static void debugDbMetadata (DbMetadata dbMetadata) {
		debugDbMetadata ("", dbMetadata);
	}
	
	public static void debugDbMetadata (String prefix, DbMetadata dbMetadata) {
		LOGGER.info (prefix + "*** DbMetadata ***");
		if (dbMetadata == null) {
			LOGGER.info (prefix + "NULL");
		}else {
			LOGGER.info (prefix + "uid: " + dbMetadata.getUid ());
			debugVersion (prefix, dbMetadata.getVersion ());
			LOGGER.info (prefix + "salt: " + dbMetadata.getSalt ());
			LOGGER.info (prefix + "name: " + dbMetadata.getName ());
			LOGGER.info (prefix + "description: " + dbMetadata.getDescription ());
			LOGGER.info (prefix + "createdBy...");
			debugAuthor (prefix, dbMetadata.getCreatedBy ());
			LOGGER.info (prefix + "lastModifiedBy...");
			debugAuthor (prefix, dbMetadata.getLastModifiedBy ());
		}
		LOGGER.info (prefix + "*** END DbMetadata ***");
	}
	
	public static void debugField (Field field) {
		debugField ("", field);
	}
	
	public static void debugField (String prefix, Field field) {
		LOGGER.info (prefix + "*** Field ***");
		if (field == null) {
			LOGGER.info (prefix + "NULL");
		}else {
			LOGGER.info (prefix + "name: " + field.getName ());
			LOGGER.info (prefix + "encrypted? " + field.getEncrypted ());
			LOGGER.info (prefix + "value: " + field.getValue ());
		}
		LOGGER.info (prefix + "*** END Field ***");
	}
	
	public static void debugItem (Item item) {
		debugItem ("", item);
	}
	
	public static void debugItem (String prefix, Item item) {
		LOGGER.info (prefix + "*** Item ***");
		if (item == null) {
			LOGGER.info (prefix + "NULL");
		}else {
			LOGGER.info (prefix + "name: " + item.getName ());
			LOGGER.info (prefix + "description: " + item.getDescription ());
			LOGGER.info (prefix + "tags: " + item.getTags ());
			if ((item.getFields () != null) && (!item.getFields ().isEmpty ())) {
				LOGGER.info (prefix + "fields...");
				for (Field field : item.getFields ()) {
					debugField (prefix, field);
				}
			}
			LOGGER.info (prefix + "defaultFieldName: " + item.getDefaultFieldName ());
		}
		LOGGER.info (prefix + "*** END Item ***");
	}
	
	public static void debugGroup (Group group) {
		debugGroup ("", group);
	}
	
	public static void debugGroup (String prefix, Group group) {
		LOGGER.info (prefix + "*** Group ***");
		if (group == null) {
			LOGGER.info (prefix + "NULL");
		}else {
			LOGGER.info (prefix + "name: " + group.getName ());
			if ((group.getSubgroups () != null) && (!group.getSubgroups ().isEmpty ())) {
				LOGGER.info (prefix + "subgroups...");
				for (Group subgroup : group.getSubgroups ()) {
					debugGroup (prefix + "   ", subgroup);
				}
			}
			if ((group.getItems () != null) && (!group.getItems ().isEmpty ())) {
				LOGGER.info (prefix + "items...");
				for (Item item : group.getItems ()) {
					debugItem (prefix, item);
				}
			}
		}
		LOGGER.info (prefix + "*** END Group ***");
	}
	
}

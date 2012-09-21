package bluetanuki.tanukisecrets.common.xml;

import com.thoughtworks.xstream.converters.ConversionException;
import com.thoughtworks.xstream.converters.Converter;
import com.thoughtworks.xstream.converters.MarshallingContext;
import com.thoughtworks.xstream.converters.UnmarshallingContext;
import com.thoughtworks.xstream.io.HierarchicalStreamReader;
import com.thoughtworks.xstream.io.HierarchicalStreamWriter;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Implementation of an XStream converter that uses a custom date format to (un)marshal dates.
 *
 * @author Lucian Ganea
 */
public class DateConverter implements Converter {
	public static final String DATE_FORMAT = "yyyy-MM-dd HH:mm:ss Z";
	private SimpleDateFormat formatter;

	public DateConverter (String dateFormat) {
		formatter = new SimpleDateFormat (dateFormat);
	}

	public DateConverter () {
		this (DATE_FORMAT);
	}

	@SuppressWarnings("rawtypes")
	@Override
	public boolean canConvert (Class clazz) {
		return Date.class.isAssignableFrom (clazz);
	}

	@Override
	public void marshal (Object value, HierarchicalStreamWriter writer,
			  MarshallingContext context) {
		Date date = (Date)value;
		writer.setValue (formatter.format (date));
	}

	@Override
	public Object unmarshal (HierarchicalStreamReader reader,
			  UnmarshallingContext context) {
		try {
			return formatter.parse (reader.getValue ());
		}catch (ParseException e) {
			throw new ConversionException (e.getMessage (), e);
		}
	}

}

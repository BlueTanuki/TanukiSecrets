package bluetanuki.tanukisecrets.sandbox.crypto.analysis;

import bluetanuki.tanukisecrets.common.RandomDataGenerator;
import bluetanuki.tanukisecrets.common.crypto.HashFunctions;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import javax.imageio.ImageIO;
import org.apache.log4j.Logger;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.plot.XYPlot;
import org.jfree.chart.renderer.xy.XYDotRenderer;
import org.jfree.data.xy.DefaultXYDataset;
import org.jfree.data.xy.DefaultXYZDataset;
import org.jfree.data.xy.XYDataset;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;
import org.jfree.data.xy.XYZDataset;

/**
 *
 * @author Lucian Ganea
 */
public class AnalyseTanukiHash {
	private static final Logger LOGGER = Logger.getLogger (AnalyseTanukiHash.class);
	
	private static final RandomDataGenerator RANDOM_DATA_GENERATOR = new RandomDataGenerator ();
	
	private static String readableArray (int[] a, int charsPerNumber) {
		StringBuilder buf = new StringBuilder ("[");
		String formatString = "%" + charsPerNumber + "d";
		int n = a.length;
		buf.append (String.format (formatString, a[0]));
		for (int i=1; i<n; i++) {
			buf.append (",");
			buf.append (String.format (formatString, a[i]));
		}
		buf.append ("]");
		return buf.toString ();
	}
	
	private static String readableArray (double[] a, int precision) {
		StringBuilder buf = new StringBuilder ("[");
		String formatString = "%+2." + precision + "f";
		int n = a.length;
		buf.append (String.format (formatString, a[0]));
		for (int i=1; i<n; i++) {
			buf.append (",");
			buf.append (String.format (formatString, a[i]));
		}
		buf.append ("]");
		return buf.toString ();
	}
	
	private static byte[] arrayUsingRandomData () throws Exception {
		int sizeMB = RANDOM_DATA_GENERATOR.getInt (7, 16);
		LOGGER.info (sizeMB + " MB tanuki array...");
		byte[] secret = RANDOM_DATA_GENERATOR.getString (RandomDataGenerator.ALFANUM, 7, 20).getBytes ("UTF-8");
		byte[] salt = RANDOM_DATA_GENERATOR.getBytes (64, 128);
		return HashFunctions.tanukiHashInternalArray (secret, salt, sizeMB);
	}
	
	private static class ArrayAnalysis {
		int arrayLength;
		int[] bytesFrequency;
		int[] firstHalfBytesFrequency;
		int[] secondHalfBytesFrequency;
		int[] oddPositionsBytesFrequency;
		int[] evenPositionsBytesFrequency;
		
		private static int[] newBytesFrequencyArray () {
			int[] ret = new int[256];
			for (int i = 0; i < 256; i++) {
				ret[i] = 0;
			}
			return ret;
		}
		public static ArrayAnalysis newAnalysis () {
			ArrayAnalysis ret = new ArrayAnalysis ();
			ret.arrayLength = 0;
			ret.bytesFrequency = newBytesFrequencyArray ();
			ret.firstHalfBytesFrequency = newBytesFrequencyArray ();
			ret.secondHalfBytesFrequency = newBytesFrequencyArray ();
			ret.oddPositionsBytesFrequency = newBytesFrequencyArray ();
			ret.evenPositionsBytesFrequency = newBytesFrequencyArray ();
			return ret;
		}
		
		public static ArrayAnalysis analyzeTanukiArray (byte[] a) {
			ArrayAnalysis ret = newAnalysis ();
			ret.arrayLength = a.length;
			for (int i = 0; i < ret.arrayLength; i++) {
				ret.bytesFrequency[a[i] & 0xff]++;
				if (i % 2 == 0) {
					ret.evenPositionsBytesFrequency[a[i] & 0xff]++;
				}else {
					ret.oddPositionsBytesFrequency[a[i] & 0xff]++;
				}
				if (i < ret.arrayLength/2) {
					ret.firstHalfBytesFrequency[a[i] & 0xff]++;
				}else {
					ret.secondHalfBytesFrequency[a[i] & 0xff]++;
				}
			}
			return ret;
		}
		
		private static int[] offsetComparedToUniformDistribution (int[] dist, int uniformDistValue) {
			int[] ret = new int[dist.length];
			for (int i = 0; i < dist.length; i++) {
				ret[i] = dist[i] - uniformDistValue;
			}
			return ret;
		}

		public ArrayAnalysis offsetToUniform () {
			ArrayAnalysis ret = new ArrayAnalysis ();
			int uniformDistValue = arrayLength / 256;
			ret.arrayLength = arrayLength;
			ret.bytesFrequency = offsetComparedToUniformDistribution (
					  bytesFrequency, uniformDistValue);
			uniformDistValue /= 2;
			ret.firstHalfBytesFrequency = offsetComparedToUniformDistribution (
					  firstHalfBytesFrequency, uniformDistValue);
			ret.secondHalfBytesFrequency = offsetComparedToUniformDistribution (
					  secondHalfBytesFrequency, uniformDistValue);
			ret.oddPositionsBytesFrequency = offsetComparedToUniformDistribution (
					  oddPositionsBytesFrequency, uniformDistValue);
			ret.evenPositionsBytesFrequency = offsetComparedToUniformDistribution (
					  evenPositionsBytesFrequency, uniformDistValue);
			return ret;
		}
		

		private static void updateSum (int[] sum, int[] a) {
			for (int i = 0; i < a.length; i++) {
				sum[i] += a[i];
			}
		}
		
		public void updateSum (ArrayAnalysis other) {
			arrayLength += other.arrayLength;
			if (bytesFrequency == null) {
				bytesFrequency = Arrays.copyOf (
						  other.bytesFrequency, 
						  other.bytesFrequency.length);
			}else {
				updateSum (bytesFrequency, other.bytesFrequency);
			}
			if (firstHalfBytesFrequency == null) {
				firstHalfBytesFrequency = Arrays.copyOf (
						  other.firstHalfBytesFrequency, 
						  other.firstHalfBytesFrequency.length);
			}else {
				updateSum (firstHalfBytesFrequency, other.firstHalfBytesFrequency);
			}
			if (secondHalfBytesFrequency == null) {
				secondHalfBytesFrequency = Arrays.copyOf (
						  other.secondHalfBytesFrequency, 
						  other.secondHalfBytesFrequency.length);
			}else {
				updateSum (secondHalfBytesFrequency, other.secondHalfBytesFrequency);
			}
			if (oddPositionsBytesFrequency == null) {
				oddPositionsBytesFrequency = Arrays.copyOf (
						  other.oddPositionsBytesFrequency, 
						  other.oddPositionsBytesFrequency.length);
			}else {
				updateSum (oddPositionsBytesFrequency, other.oddPositionsBytesFrequency);
			}
			if (evenPositionsBytesFrequency == null) {
				evenPositionsBytesFrequency = Arrays.copyOf (
						  other.evenPositionsBytesFrequency, 
						  other.evenPositionsBytesFrequency.length);
			}else {
				updateSum (evenPositionsBytesFrequency, other.evenPositionsBytesFrequency);
			}
		}
		
	}
	
	private static class ScaledAnalysis {
		double[] scaledFreqOffset;
		double[] firstHalfScaledFreqOffset;
		double[] secondHalfScaledFreqOffset;
		double[] oddPositionsScaledFreqOffset;
		double[] evenPositionsScaledFreqOffset;
		
		private static double[] scaledOffset (int[] absoluteOffset, int scale) {
			double[] scaledOffset = new double[absoluteOffset.length];
			for (int i = 0; i < absoluteOffset.length; i++) {
				scaledOffset[i] = ((double)absoluteOffset[i]) / scale;
			}
			return scaledOffset;
		}

		public static ScaledAnalysis scaledOffsetAnalysis (ArrayAnalysis arrayAnalysis) {
			ScaledAnalysis ret = new ScaledAnalysis ();
			int uniformDistValue = arrayAnalysis.arrayLength / 256;
			ArrayAnalysis offsetAnalysis = arrayAnalysis.offsetToUniform ();
			ret.scaledFreqOffset = scaledOffset (
					  offsetAnalysis.bytesFrequency, uniformDistValue);
			uniformDistValue /= 2;
			ret.firstHalfScaledFreqOffset = scaledOffset (
					  offsetAnalysis.firstHalfBytesFrequency, uniformDistValue);
			ret.secondHalfScaledFreqOffset = scaledOffset (
					  offsetAnalysis.secondHalfBytesFrequency, uniformDistValue);
			ret.oddPositionsScaledFreqOffset = scaledOffset (
					  offsetAnalysis.oddPositionsBytesFrequency, uniformDistValue);
			ret.evenPositionsScaledFreqOffset = scaledOffset (
					  offsetAnalysis.evenPositionsBytesFrequency, uniformDistValue);
			return ret;
		}
		
		private static void updateMinimum (double[] min, double[] a) {
			for (int i = 0; i < a.length; i++) {
				if (a[i] < min[i]) {
					min[i] = a[i];
				}
			}
		}
		
		public void updateMinimum (ScaledAnalysis other) {
			if (scaledFreqOffset == null) {
				scaledFreqOffset = Arrays.copyOf (
						  other.scaledFreqOffset, 
						  other.scaledFreqOffset.length);
			}else {
				updateMinimum (scaledFreqOffset, other.scaledFreqOffset);
			}
			if (firstHalfScaledFreqOffset == null) {
				firstHalfScaledFreqOffset = Arrays.copyOf (
						  other.firstHalfScaledFreqOffset, 
						  other.firstHalfScaledFreqOffset.length);
			}else {
				updateMinimum (firstHalfScaledFreqOffset, other.firstHalfScaledFreqOffset);
			}
			if (secondHalfScaledFreqOffset == null) {
				secondHalfScaledFreqOffset = Arrays.copyOf (
						  other.secondHalfScaledFreqOffset, 
						  other.secondHalfScaledFreqOffset.length);
			}else {
				updateMinimum (secondHalfScaledFreqOffset, other.secondHalfScaledFreqOffset);
			}
			if (oddPositionsScaledFreqOffset == null) {
				oddPositionsScaledFreqOffset = Arrays.copyOf (
						  other.oddPositionsScaledFreqOffset, 
						  other.oddPositionsScaledFreqOffset.length);
			}else {
				updateMinimum (oddPositionsScaledFreqOffset, other.oddPositionsScaledFreqOffset);
			}
			if (evenPositionsScaledFreqOffset == null) {
				evenPositionsScaledFreqOffset = Arrays.copyOf (
						  other.evenPositionsScaledFreqOffset, 
						  other.evenPositionsScaledFreqOffset.length);
			}else {
				updateMinimum (evenPositionsScaledFreqOffset, other.evenPositionsScaledFreqOffset);
			}
		}

		private static void updateMaximum (double[] max, double[] a) {
			for (int i = 0; i < a.length; i++) {
				if (a[i] > max[i]) {
					max[i] = a[i];
				}
			}
		}
		
		public void updateMaximum (ScaledAnalysis other) {
			if (scaledFreqOffset == null) {
				scaledFreqOffset = Arrays.copyOf (
						  other.scaledFreqOffset, 
						  other.scaledFreqOffset.length);
			}else {
				updateMaximum (scaledFreqOffset, other.scaledFreqOffset);
			}
			if (firstHalfScaledFreqOffset == null) {
				firstHalfScaledFreqOffset = Arrays.copyOf (
						  other.firstHalfScaledFreqOffset, 
						  other.firstHalfScaledFreqOffset.length);
			}else {
				updateMaximum (firstHalfScaledFreqOffset, other.firstHalfScaledFreqOffset);
			}
			if (secondHalfScaledFreqOffset == null) {
				secondHalfScaledFreqOffset = Arrays.copyOf (
						  other.secondHalfScaledFreqOffset, 
						  other.secondHalfScaledFreqOffset.length);
			}else {
				updateMaximum (secondHalfScaledFreqOffset, other.secondHalfScaledFreqOffset);
			}
			if (oddPositionsScaledFreqOffset == null) {
				oddPositionsScaledFreqOffset = Arrays.copyOf (
						  other.oddPositionsScaledFreqOffset, 
						  other.oddPositionsScaledFreqOffset.length);
			}else {
				updateMaximum (oddPositionsScaledFreqOffset, other.oddPositionsScaledFreqOffset);
			}
			if (evenPositionsScaledFreqOffset == null) {
				evenPositionsScaledFreqOffset = Arrays.copyOf (
						  other.evenPositionsScaledFreqOffset, 
						  other.evenPositionsScaledFreqOffset.length);
			}else {
				updateMaximum (evenPositionsScaledFreqOffset, other.evenPositionsScaledFreqOffset);
			}
		}

	}
	
	private static void addArrayToXYSeries (double[] a, XYSeries xySeries) {
		int positives = 0;
		int negatives = 0;
		for (int i = 0; i < a.length; i++) {
			xySeries.add (i, a[i]);
			if (a[i] >= 0) {
				positives++;
			}else {
				negatives++;
			}
		}
//		LOGGER.info ("There were " + positives + " positive and " + negatives + " negative values");
	}
	
	private static double sum (double[] a) {
		double sum = 0;
		for (double d : a) {
			sum += d;
		}
		return sum;
	}
	
	private static void makeChart (int numberOfArrays, 
			  double[] min, double[] max, double[] overall,
			  XYSeries xySeries, String filename) throws IOException {
		XYSeriesCollection xySeriesCollection = new XYSeriesCollection ();
		XYSeries minMaxSeries = new XYSeries ("Minimum / Maximum");
		addArrayToXYSeries (min, minMaxSeries);
		addArrayToXYSeries (max, minMaxSeries);
		xySeriesCollection.addSeries (minMaxSeries);
		XYSeries overallSeries = new XYSeries ("Overall (all " + numberOfArrays + ")");
		addArrayToXYSeries (overall, overallSeries);
		xySeriesCollection.addSeries (overallSeries);
		xySeriesCollection.addSeries (xySeries);
		JFreeChart chart = ChartFactory.createScatterPlot (
				  "TanukiHash arrays analysis (" + numberOfArrays + " arrays)", "byte", "normalized deviation", 
				  xySeriesCollection, 
				  PlotOrientation.VERTICAL, true, false, false);
		XYPlot xyplot = (XYPlot)chart.getPlot ();
		XYDotRenderer dotRenderer = new XYDotRenderer ();
		dotRenderer.setDotHeight (3);
		dotRenderer.setDotWidth (3);
		dotRenderer.setSeriesPaint (0, Color.RED);
		dotRenderer.setSeriesPaint (1, Color.CYAN);
		dotRenderer.setSeriesPaint (2, Color.BLUE);
		xyplot.setRenderer (dotRenderer);
		BufferedImage bufferedImage = chart.createBufferedImage (1200, 600);
		ImageIO.write (bufferedImage, "png", new File (filename));
	}
	
	public static void main (String[] args) throws Exception {
		int totalArrays = 100;
		int arraysShownOnPlot = 10;
		List<ArrayAnalysis> arrayAnalysisList = new ArrayList<ArrayAnalysis> (totalArrays);
		for (int i = 0; i < totalArrays; i++) {
			byte[] tanukiArray = arrayUsingRandomData ();
			arrayAnalysisList.add (ArrayAnalysis.analyzeTanukiArray (tanukiArray));
		}
		int[] progressiveChartThresholds = new int[] {1, 5, 10, 25, 50};
		int nextProgressiveChartIndex = 0;
		List<ScaledAnalysis> progressiveChartData = new ArrayList<ScaledAnalysis> ();
		
		ScaledAnalysis min = new ScaledAnalysis ();
		ScaledAnalysis max = new ScaledAnalysis ();
		ArrayAnalysis sum = new ArrayAnalysis ();
		List<ScaledAnalysis> plotted = new ArrayList<ScaledAnalysis> ();
		int mod = totalArrays / arraysShownOnPlot;
		int i = 0;
		for (ArrayAnalysis arrayAnalysis : arrayAnalysisList) {
			sum.updateSum (arrayAnalysis);
			ScaledAnalysis scaledAnalysis = ScaledAnalysis.scaledOffsetAnalysis (arrayAnalysis);
			min.updateMinimum (scaledAnalysis);
			max.updateMaximum (scaledAnalysis);
			if (i % mod == 0) {
				plotted.add (scaledAnalysis);
			}
			i++;
			if ((nextProgressiveChartIndex < progressiveChartThresholds.length) && 
					  (i >= progressiveChartThresholds[nextProgressiveChartIndex])) {
				progressiveChartData.add (ScaledAnalysis.scaledOffsetAnalysis (sum));
				nextProgressiveChartIndex++;
			}
		}
		ScaledAnalysis overall = ScaledAnalysis.scaledOffsetAnalysis (sum);
		progressiveChartData.add (overall);
		
		XYSeries xySeries = new XYSeries ("Individual (" + arraysShownOnPlot + " out of " + totalArrays + ")");
		XYSeries firstHalfSeries = new XYSeries ("Individual (" + arraysShownOnPlot + " out of " + totalArrays + ")");
		XYSeries secondHalfSeries = new XYSeries ("Individual (" + arraysShownOnPlot + " out of " + totalArrays + ")");
		XYSeries oddHalfSeries = new XYSeries ("Individual (" + arraysShownOnPlot + " out of " + totalArrays + ")");
		XYSeries evenHalfSeries = new XYSeries ("Individual (" + arraysShownOnPlot + " out of " + totalArrays + ")");
		for (ScaledAnalysis scaledAnalysis : plotted) {
			addArrayToXYSeries (scaledAnalysis.scaledFreqOffset, xySeries);
			addArrayToXYSeries (scaledAnalysis.firstHalfScaledFreqOffset, firstHalfSeries);
			addArrayToXYSeries (scaledAnalysis.secondHalfScaledFreqOffset, secondHalfSeries);
			addArrayToXYSeries (scaledAnalysis.oddPositionsScaledFreqOffset, oddHalfSeries);
			addArrayToXYSeries (scaledAnalysis.evenPositionsScaledFreqOffset, evenHalfSeries);
		}
		makeChart (totalArrays, min.scaledFreqOffset, max.scaledFreqOffset, 
				  overall.scaledFreqOffset, xySeries, "/Users/lucian/tmp/1_entireArray.png");
		makeChart (totalArrays, min.firstHalfScaledFreqOffset, max.firstHalfScaledFreqOffset, 
				  overall.firstHalfScaledFreqOffset, firstHalfSeries, "/Users/lucian/tmp/2_firstHalf.png");
		makeChart (totalArrays, min.secondHalfScaledFreqOffset, max.secondHalfScaledFreqOffset, 
				  overall.secondHalfScaledFreqOffset, secondHalfSeries, "/Users/lucian/tmp/3_secondHalf.png");
		makeChart (totalArrays, min.oddPositionsScaledFreqOffset, max.oddPositionsScaledFreqOffset, 
				  overall.oddPositionsScaledFreqOffset, oddHalfSeries, "/Users/lucian/tmp/4_oddPositions.png");
		makeChart (totalArrays, min.evenPositionsScaledFreqOffset, max.evenPositionsScaledFreqOffset, 
				  overall.evenPositionsScaledFreqOffset, evenHalfSeries, "/Users/lucian/tmp/5_evenPositions.png");
		
		//make the progressive chart
		XYSeriesCollection xySeriesCollection = new XYSeriesCollection ();
		i = 0;
		for (ScaledAnalysis scaledAnalysis : progressiveChartData) {
			if (i < progressiveChartThresholds.length) {
				xySeries = new XYSeries (progressiveChartThresholds[i] + " arrays");
			}else {
				xySeries = new XYSeries ("All " + totalArrays + " arrays");
			}
			addArrayToXYSeries (scaledAnalysis.scaledFreqOffset, xySeries);
			xySeriesCollection.addSeries (xySeries);
			i++;
		}
		JFreeChart chart = ChartFactory.createScatterPlot (
				  "TanukiHash arrays progressive analysis", "byte", "normalized deviation", 
				  xySeriesCollection, 
				  PlotOrientation.VERTICAL, true, false, false);
		XYPlot xyplot = (XYPlot)chart.getPlot ();
		XYDotRenderer dotRenderer = new XYDotRenderer ();
		dotRenderer.setDotHeight (3);
		dotRenderer.setDotWidth (3);
		Color[] colors = new Color[] {Color.BLACK, Color.GRAY, Color.BLUE, Color.RED, Color.GREEN};
		for (int j = 0; j < progressiveChartThresholds.length; j++) {
			dotRenderer.setSeriesPaint (j, colors[j]);
		}
		dotRenderer.setSeriesPaint (progressiveChartThresholds.length, Color.CYAN);
		xyplot.setRenderer (dotRenderer);
		BufferedImage bufferedImage = chart.createBufferedImage (1200, 600);
		ImageIO.write (bufferedImage, "png", new File ("/Users/lucian/tmp/6_progressive.png"));
		
		
//		byte[] tanukiArray = arrayUsingRandomData ();
//		int[] freq = bytesFrequency (tanukiArray);
//		int uniformDistValue = tanukiArray.length / 256;
//		int sumOfUniformDistValues = uniformDistValue;
//		int[] freqOffset = offsetComparedToUniformDistribution (freq, uniformDistValue);
//		double[] scaledFreqOffset = scaledOffset (freqOffset, uniformDistValue);
//		addArrayToXYSeries (scaledFreqOffset, xySeries);
//		LOGGER.info (readableArray (scaledFreqOffset, 6));
//		LOGGER.info ("Sum of values : " + String.format ("%.8f", sum (scaledFreqOffset)));
//		double[] minFreqOffset = Arrays.copyOf (scaledFreqOffset, scaledFreqOffset.length);
//		double[] maxFreqOffset = Arrays.copyOf (scaledFreqOffset, scaledFreqOffset.length);
//		int[] totalFreqOffset = Arrays.copyOf (freqOffset, freqOffset.length);
//		
//		int N = 10;
//		for (int i=1; i<N; i++) {
//			tanukiArray = arrayUsingRandomData ();
//			freq = bytesFrequency (tanukiArray);
//			uniformDistValue = tanukiArray.length / 256;
//			sumOfUniformDistValues += uniformDistValue;
//			freqOffset = offsetComparedToUniformDistribution (freq, uniformDistValue);
//			scaledFreqOffset = scaledOffset (freqOffset, uniformDistValue);
//			addArrayToXYSeries (scaledFreqOffset, xySeries);
//			LOGGER.info (readableArray (scaledFreqOffset, 6));
//			LOGGER.info ("Sum of values : " + String.format ("%.8f", sum (scaledFreqOffset)));
//			updateMinimum (minFreqOffset, scaledFreqOffset);
//			updateMaximum (maxFreqOffset, scaledFreqOffset);
//			updateSum (totalFreqOffset, freqOffset);
//		}
//		LOGGER.info (readableArray (minFreqOffset, 6));
//		LOGGER.info (readableArray (maxFreqOffset, 6));
//		double[] scaledTotalFreqOffset = scaledOffset (totalFreqOffset, sumOfUniformDistValues);
//		LOGGER.info (readableArray (scaledTotalFreqOffset, 6));
//		
//		XYSeriesCollection xySeriesCollection = new XYSeriesCollection ();
////		XYSeries baselineSeries = new XYSeries ("baseline (uniform)");
////		for (int i=0; i<256; i++) {
////			baselineSeries.add (i, 0);
////		}
////		xySeriesCollection.addSeries (baselineSeries);
//		XYSeries minMaxSeries = new XYSeries ("Minimum / Maximum");
//		addArrayToXYSeries (minFreqOffset, minMaxSeries);
//		addArrayToXYSeries (maxFreqOffset, minMaxSeries);
//		xySeriesCollection.addSeries (minMaxSeries);
//		XYSeries overallSeries = new XYSeries ("Overall (all " + totalArrays + ")");
//		addArrayToXYSeries (scaledTotalFreqOffset, overallSeries);
//		xySeriesCollection.addSeries (overallSeries);
//		xySeriesCollection.addSeries (xySeries);
//		JFreeChart chart = ChartFactory.createScatterPlot (
//				  "TanukiHash arrays analysis (" + N + " arrays)", "byte", "normalized deviation", xySeriesCollection, 
//				  PlotOrientation.VERTICAL, true, false, false);
//		XYPlot xyplot = (XYPlot)chart.getPlot ();
//		XYDotRenderer dotRenderer = new XYDotRenderer ();
//		dotRenderer.setDotHeight (3);
//		dotRenderer.setDotWidth (3);
//		dotRenderer.setSeriesPaint (0, Color.RED);
//		dotRenderer.setSeriesPaint (1, Color.CYAN);
//		dotRenderer.setSeriesPaint (2, Color.BLUE);
//		xyplot.setRenderer (dotRenderer);
//		BufferedImage bufferedImage = chart.createBufferedImage (800, 600);
//		ImageIO.write (bufferedImage, "png", new File ("/Users/lucian/tmp/jfreechartTest.png"));
	}

}

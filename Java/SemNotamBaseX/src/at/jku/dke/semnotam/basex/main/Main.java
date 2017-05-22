package at.jku.dke.semnotam.basex.main;

import java.io.File;

import org.basex.core.Context;

import at.jku.dke.semnotam.basex.io.BaseXAPI;

public class Main {
	static Context context = new Context();

	public static void main(String args[]) {
		
		BaseXAPI basex = new BaseXAPI("localhost", 1984, "admin", "admin");
		String databaseName = "Herucles";
		String path = "/Users/Andreas/Documents/Bakk_DKE/Entwicklung/SemNOTAM_Files";
		
		//HolidayManager.getInstance().
		
		String notamFile = path + "/NOTAM_KJFK_Set.xml";
		String schedule = path + "/schedule_example.xml";
		String inputFile = path + "/XML_Input/IS_FlightPlanInterest.xml";
		File f = new File(notamFile);
		System.out.println(f.exists());
		
		basex.startServer();
		basex.openSession();
		basex.dropDatabase(databaseName);
		basex.createDatabase(databaseName);//, "C:/Users/semnota_4/Desktop/SemNOTAM_Files/XMLInputFiles/notam/xml_samples");
		basex.addXmlToDb(databaseName, schedule);
		basex.addXmlToDb(databaseName, notamFile);
		basex.addXmlToDb(databaseName, inputFile);
		
		//System.out.println(basex.executeQuery("//*[local-name()='AIXMBasicMessage']"));
		//System.out.println( basex.executeQueryString("import module namespace dke = \"at.jku.dke\" at \"temporal_filter_module.xq\"; dke:get-temporal-relevant-notams(\"test\",1)"));
		basex.removeXmlDocument(databaseName, "xml_sample.xml");
		basex.closeSession();
		basex.stopServer();
		/*
		 * CollectionCreator cc = new CollectionCreator();
		 * 
		 * //cc.createCollection("./files/xml_src/test"); cc.createCollection(
		 * "C:/Users/semnota_4/Desktop/SemNOTAM_Files/XMLInputFiles/notam/xml_samples"
		 * );
		 */
	}
}

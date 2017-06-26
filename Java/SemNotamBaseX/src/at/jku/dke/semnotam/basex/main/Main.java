package at.jku.dke.semnotam.basex.main;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.OpenOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;

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
		String myNotamSet = path + "/NOTAM_SET.xml";
		String schedule = path + "/schedule_example.xml";
		String inputFile = path + "/XML_Input/IS_1.xml";
		File f = new File(notamFile);
		System.out.println(f.exists());
		
		basex.startServer();
		basex.openSession();
		basex.dropDatabase(databaseName);
		basex.createDatabase(databaseName);//, "C:/Users/semnota_4/Desktop/SemNOTAM_Files/XMLInputFiles/notam/xml_samples");
		basex.addXmlToDb(databaseName, myNotamSet);
		//basex.addXmlToDb(databaseName, notamFile);
		basex.addXmlToDb(databaseName, inputFile);
		
		//System.out.println(basex.executeQuery("//*[local-name()='AIXMBasicMessage']"));
		System.out.println(basex.executeQuery("Q{org.basex.util.Prop}USERHOME()"));
		String result = basex.executeQueryString("import module namespace dke = \"at.jku.dke\" at \"temporal_filter_module_v2.xq\"; dke:get-temporal-relevant-notams(\"1\",2)");
		//File f = new File(path+"/XML_Output/output1");
		Path p = Paths.get(path+"/XML_Output/output1.xml");
		/*
		try {
			Files.write(p, result.getBytes(), StandardOpenOption.CREATE);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}*/
		//basex.removeXmlDocument(databaseName, "xml_sample.xml");
		//basex.removeXmlDocument(databaseName, notamFile);
		//basex.removeXmlDocument(databaseName, schedule);
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

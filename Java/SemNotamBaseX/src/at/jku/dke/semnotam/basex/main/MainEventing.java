/*****************************************************************************
 * Copyright (c) 2015 ontoprise GmbH.
 *
 * All rights reserved.
 *
 * Created on: 18.08.2015
 * Created by: semnota_4
 *****************************************************************************/
package at.jku.dke.semnotam.basex.main;


import at.jku.dke.semnotam.basex.io.BaseXAPI;

/**
 * @author semnota_4
 *
 */
public class MainEventing {

    public static void main(String[] args) {
        
        BaseXAPI basex = new BaseXAPI("localhost", 1984, "admin", "admin");
        String databaseName = "Herucles";
        String xmlPath = "C:/Users/semnota_4/Desktop/SemNOTAM_Files/XMLInputFiles/notam/xml_samples";
        basex.startServer();
        basex.openSession();
        basex.dropDatabase(databaseName);
        basex.createDatabase(databaseName);//, "C:/Users/semnota_4/Desktop/SemNOTAM_Files/XMLInputFiles/notam/xml_samples");
        basex.addXmlToDb(databaseName, xmlPath);
        basex.executeQuery("//*[local-name()='AIXMBasicMessage']");
        basex.closeSession();
        basex.stopServer();
    	
    }
}

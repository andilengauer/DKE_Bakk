package at.jku.dke.semnotam.basex.io;

import org.apache.logging.log4j.Logger; 
import org.apache.logging.log4j.LogManager;

import java.io.IOException;
import java.util.LinkedList;
import java.util.List;

import org.basex.BaseXServer;
import org.basex.api.client.ClientQuery;
import org.basex.api.client.ClientSession;
import org.basex.core.cmd.Add;
import org.basex.core.cmd.Close;
import org.basex.core.cmd.CreateDB;
import org.basex.core.cmd.Delete;
import org.basex.core.cmd.DropDB;
import org.basex.core.cmd.Open;
import org.basex.core.cmd.Optimize;
import org.basex.core.cmd.Replace;
import org.basex.core.cmd.Set;

import at.jku.dke.semnotam.basex.exception.ServerNotRunningException;
import at.jku.dke.semnotam.basex.exception.SessionNotExistingException;

/**
 * Simple access to a BaseX database. The server needs to be
 * started in order to open a session. Supports creation/dropping of
 * databases, adding and removing xml documents and executing queries.
 * @author Ilko Kovacic, Dieter Steiner
 */
public class BaseXAPI {
	
	private static final Logger log4j = LogManager.getLogger("semnotam");

	private BaseXServer server = null;
	private ClientSession session = null;
	
	private String host;
	private int port;
	private String user;
	private String password;
	
	/**
	 * Constructor for creating a new BaseXApi object, i.e., a new connection to a BaseX database.
	 * @param host IP address of the hosting server.
	 * @param port The port used.
	 * @param user The username of the database user.
	 * @param password The password that corresponds to the username.
	 */
	public BaseXAPI(String host, int port, String user, String password) {
		this.host = host;
		this.port = port;
		this.user = user;
		this.password = password;
	}
	
	public void openDatabase(String databaseName) {
		try {
			if (session == null)
				throw new SessionNotExistingException("Session is not available...");

			log4j.info("Open database " + databaseName + "...");
			session.execute(new Open(databaseName));
		} catch (SessionNotExistingException | IOException e) {
			log4j.error(e);
			closeSession();
			stopServer();
		}
	}
	
	public void closeDatabase() {
		try {
			if (session == null)
				throw new SessionNotExistingException("Session is not available...");
			
			log4j.info("Close current database...");
			session.execute(new Close());
		} catch (SessionNotExistingException | IOException e) {
			log4j.error(e);
			closeSession();
			stopServer();
		}
	}

	/**
	 * Loads the XML file specified by the file path into the database with the specified name. 
	 * @param databaseName The name of the XML database.
	 * @param xmlDataPath The file path to the XML file to be loaded to the database.
	 */
	public void addXmlToDb(String databaseName, String xmlDataPath) {
		try {
			if (session == null)
				throw new SessionNotExistingException("Session is not available...");

			log4j.info("Open database " + databaseName + "...");
			session.execute(new Open(databaseName));
			session.execute(new Set("CREATEFILTER", "*.xml"));
			String[] splittedPath = xmlDataPath.split("/");
			session.execute(new Add(splittedPath[splittedPath.length-1], xmlDataPath));
			log4j.info("Session info... " + session.info());
			session.execute(new Optimize());
		} catch (SessionNotExistingException | IOException e) {
			log4j.error(e);
			closeSession();
			stopServer();
		}
	}
	
	public void replaceXmlInDb(String databaseName, String xmlDocument, String xmlDataPath) {
		try {
			if (session == null)
				throw new SessionNotExistingException("Session is not available...");
			if(databaseName == null || databaseName.isEmpty())
				throw new IllegalArgumentException("Provided databaseName '" + databaseName + "' is null or empty...");
			if(xmlDocument == null || xmlDocument.isEmpty())
				throw new IllegalArgumentException("Provided xmlDocument '" + xmlDocument + "' is null or empty...");
			if(xmlDataPath == null || xmlDataPath.isEmpty())
				throw new IllegalArgumentException("Provided xmlDataPath '" + xmlDataPath + "' is null or empty...");
			
			log4j.info("Replace " + xmlDocument + " in database " + databaseName + "...");
			session.execute(new Open(databaseName));
			session.execute(new Replace(xmlDocument, xmlDataPath));
		} catch (SessionNotExistingException | IOException e) {
			log4j.error(e);
			closeSession();
			stopServer();
		}
	}

	/**
	 * Execute a query and retrieve result set as a linked list of strings.
	 * @param xQuery String representation of the XQuery query.
	 * @return Result set of the XQuery.
	 */
	public LinkedList<String> executeQuery(String xQuery) {
		
		log4j.info("Executing query... \n " + xQuery);
		LinkedList<String> resultSet = null;
		
		try {
			if(xQuery == null || xQuery.isEmpty())
				throw new IllegalArgumentException("xQuery string is emtpy or null...");
			
			resultSet = new LinkedList<String>();
			ClientQuery cq = session.query(xQuery);
			
			String s = cq.next();
			while(s != null){
				resultSet.add(s);
				s = cq.next();
			}

		} catch (IOException e) {
			log4j.error(e);
			closeSession();
			stopServer();
		}
		return resultSet;
	}

	/**
	 * Execute a query and retrieve result set as a string.
	 * @param xQuery String representation of the XQuery query.
	 * @return Result of the XQuery.
	 */
	public String executeQueryString(String xQuery) {

		log4j.info("Executing query... \n " + xQuery);
		StringBuffer b = null;
		try {
			if(xQuery == null || xQuery.isEmpty())
				throw new IllegalArgumentException("xQuery string is emtpy or null...");
			
			b = new StringBuffer();
			ClientQuery cq = session.query(xQuery);

			String s = cq.next();
			while(s != null){
				b.append(s);
				s = cq.next();
			}

		} catch (IOException e) {
			log4j.error(e);
			closeSession();
			stopServer();
		}
		return b.toString();
	}

	/**
	 * Remove target XML document within a collection.
	 * @param databaseName The name of the XML database.
	 * @param xmlDocument The name of the XML document to be removed from the database.
	 */
	public void removeXmlDocument(String databaseName, String xmlDocument) {
		try {
			if(databaseName == null || databaseName.isEmpty())
				throw new IllegalArgumentException("Provided databaseName '" + databaseName + "' is null or empty...");
			if(xmlDocument == null || xmlDocument.isEmpty())
				throw new IllegalArgumentException("Provided xmlDocument '" + xmlDocument + "' is null or empty...");
						
			log4j.info("Delete " + xmlDocument + " from database " + databaseName + "...");
			session.execute(new Open(databaseName));
			session.execute(new Delete(xmlDocument));
		} catch (IOException e) {
			log4j.error(e);
			closeSession();
			stopServer();
		}
	}
	
	// does not work anymore in 8.2.
	/*public void listenToEvent(String event) {
		// register for an event
        try {
			session.watch(event, new EventNotifier() {
			  @Override
			  public void notify(final String value) {
			    System.out.println("Received data: " + value);
			  }
			});
		} catch (IOException e) {
			e.printStackTrace();
		}
	}*/

	/**
	 * Drop given collection, i.e., XML database.
	 * @param databaseName The name of the XML database to be dropped.
	 */
	public void dropDatabase(String databaseName) {
		try {
			if(databaseName == null || databaseName.isEmpty())
				throw new IllegalArgumentException("Provided databaseName '" + databaseName + "' is null or empty...");
			if(session == null)
				throw new SessionNotExistingException("Session is not available...");

			log4j.info("Drop database " + databaseName + "...");
			session.execute(new DropDB(databaseName));

		} catch (SessionNotExistingException | IOException e) {
			log4j.error(e);
			closeSession();
			stopServer();
		}
	}

	/**
	 * Creates an empty database.
	 * @param databaseName The name of the XML database to be created.
	 */
	public void createDatabase(String databaseName) {
		try {
			if(databaseName == null || databaseName.isEmpty())
				throw new IllegalArgumentException("Provided databaseName '" + databaseName + "' is null or empty...");
		} catch (IllegalArgumentException e) { log4j.error(e); }
		
		createDatabase(databaseName, null);
	}

	/**
	 * Create an database which will be populated with all XML files included in
	 * the path.
	 * @param databaseName The name of the XML database to be created.
	 * @param xmlDataPath Directory path containing the XML files to be loaded into the database.
	 */
	public void createDatabase(String databaseName, String xmlDataPath) {

		try {
			if(databaseName == null || databaseName.isEmpty())
				throw new IllegalArgumentException("Provided databaseName '" + databaseName + "' is null or empty...");
			if(session == null)
				throw new SessionNotExistingException("Session is not available...");

			log4j.info("Create database " + databaseName + "...");
			session.execute(new CreateDB(databaseName, xmlDataPath));

		} catch (SessionNotExistingException | IOException e) {
			log4j.error(e);
			closeSession();
			stopServer();
		}
	}

	/**
	 * Open a session in order to create and access database collections.
	 */
	public void openSession() {
		try {
			if (server == null || !BaseXServer.ping(host, port))
				throw new ServerNotRunningException("Server is not running on " + host + ":" + port + "...");

			session = new ClientSession(host, port, user, password);
		} catch (ServerNotRunningException | IOException e) {
			log4j.error(e);
			stopServer();
		}
	}

	/**
	 * Close a session.
	 */
	public void closeSession() {
		try {
			session.close();
			session = null;
		} catch (IOException e) {
			log4j.error(e);
			stopServer();
		} 
	}

	/**
	 * Starts BaseX server in order to create a session. The server
	 * configuration file is located in BaseX\.basexhome. Important when
	 * changing location of the database and the repositories.
	 */
	public void startServer() {
		try {
			server = new BaseXServer();
		} catch (IOException e) { log4j.error(e); }
	}

	/**
	 * Stops the BaseX server.
	 */
	public void stopServer() {
		try {
			server.stop();
		} catch (IOException e) { log4j.error(e); }
	}
	
	
	/**
	 * Checks if an XML element is existing in the BaseX database based on the given
	 * id, id namespace and id local name.
	 * @param basexDb The name of the XML database.
	 * @param id The id value of the element.
	 * @param idNamespace The namespace of the element.
	 * @param idLocalName The local name of the element.
	 * @return true if element exists, false otherwise
	 */
	public boolean isElemExisting(String basexDb, String id, String idNamespace, String idLocalName) {
		
		try {
			if(basexDb == null || basexDb.isEmpty())
				throw new IllegalArgumentException("Provided basexDb '" + basexDb + "' is null or empty...");
			if(id == null || id.isEmpty())
				throw new IllegalArgumentException("Provided id-value '" + id + "' is null or empty...");
			if(idNamespace == null || idNamespace.isEmpty())
				throw new IllegalArgumentException("Provided idNamespace '" + idNamespace + "' is null or empty...");
			if(idLocalName == null || idLocalName.isEmpty())
				throw new IllegalArgumentException("Provided idLocalName '" + idLocalName + "' is null or empty...");
			if(session == null)
				throw new SessionNotExistingException("Session is not available...");
		} catch (SessionNotExistingException e) { log4j.error(e); }
		
		StringBuffer xQuery = new StringBuffer();
		
		xQuery.append("let $a :=  db:open(\"").append(basexDb).append("\")//*[@*[local-name()='")
		.append(idLocalName).append("' and namespace-uri()='")
		.append(idNamespace).append("' and .='").append(id).append("']]\nreturn $a");
		
		
		log4j.debug("Checking if element with the id: " + id + " is existing as an XML element with the xquery:\n " + xQuery.toString());
		
		List<String> result = executeQuery(xQuery.toString());
		
		
		if(result.size() != 0) {
			log4j.debug("XML element with id " + id + " found in BaseX database.");
			return true;
		}
		else {
			log4j.debug("XML element with id " + id + " not found in BaseX database.");
			return false;
		}
	}
	
	/**
	 * Check if server is running on given host and port.
	 * @return true if running, false otherwise
	 */
	public boolean isServerRunning() {
		return BaseXServer.ping(host, port);
	}
	
	/**
	 * Check if session is existing.
	 * @return true if existing, false otherwise
	 */
	public boolean isSessionExisting() {
		return session != null ? true : false;
	}
	
	/**
	 * Check if database is existing.
	 * @param basexDb The name of the XML database.
	 * @return true if existing, false otherwise
	 */
	public boolean isDatabaseExisting(String basexDb) {
		try {
			String dbList = session.execute(new org.basex.core.cmd.List());
			return dbList.contains(basexDb) ? true : false;
		} catch (IOException e) {
			e.printStackTrace();
			return false;
		}
	}

	/**
	 * Checks if an XML document is existing in the BaseX database.
	 * @param basexDb The name of the XML database.
	 * @param xmlDocument The name of the XML document.
	 * @return true if existing, false otherwise
	 */
	public boolean isXmlDocumentExisting(String basexDb, String xmlDocument) {
		try {
			String documentList = session.execute(new org.basex.core.cmd.List(basexDb));
			return documentList.contains(xmlDocument) ? true : false;
		} catch (IOException e) {
			e.printStackTrace();
			return false;
		}
	}
}

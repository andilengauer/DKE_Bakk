package at.jku.dke.semnotam.basex.exception;

public class ServerNotRunningException extends Exception {

	private static final long serialVersionUID = 1L;

	public ServerNotRunningException() {
		super();
	}

	public ServerNotRunningException(String message) {
		super(message);
	}

	public ServerNotRunningException(String message, Throwable cause) {
		super(message, cause);
	}

	public ServerNotRunningException(Throwable cause) {
		super(cause);
	}
}

package at.jku.dke.semnotam.basex.exception;

public class SessionNotExistingException extends Exception {

	private static final long serialVersionUID = 1L;

	public SessionNotExistingException() {
		super();
	}

	public SessionNotExistingException(String message) {
		super(message);
	}

	public SessionNotExistingException(String message, Throwable cause) {
		super(message, cause);
	}

	public SessionNotExistingException(Throwable cause) {
		super(cause);
	}
}


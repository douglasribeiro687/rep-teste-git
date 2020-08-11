package com.algaworks.socialbooks.service.exceptions;

public class AutorExistenteException extends RuntimeException{

	private static final long serialVersionUID = 646426053783047217L;
	
	public AutorExistenteException(String mensagem) {
		super(mensagem);
	}
	
	public AutorExistenteException(String mensagem, Throwable causa) {
		super(mensagem, causa);	
	}
	
	

}

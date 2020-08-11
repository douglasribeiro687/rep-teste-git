package com.algaworks.socialbooks.service.exceptions;

public class RecursoNaoEncontradoException extends RuntimeException{

	private static final long serialVersionUID = 646426053783047210L;
	
	public RecursoNaoEncontradoException(String mensagem) {
		super(mensagem);
	}
	
	public RecursoNaoEncontradoException(String mensagem, Throwable causa) {
		super(mensagem, causa);	
	}
	
	

}

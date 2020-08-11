package com.algaworks.socialbooks.services;

import java.util.Date;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.stereotype.Service;

import com.algaworks.socialbooks.domain.Comentario;
import com.algaworks.socialbooks.domain.Livro;
import com.algaworks.socialbooks.repository.ComentariosRespository;
import com.algaworks.socialbooks.repository.LivrosRespository;
import com.algaworks.socialbooks.service.exceptions.RecursoNaoEncontradoException;

@Service
public class LivrosService {
	
	@Autowired
	private LivrosRespository livrosRepository;
	
	@Autowired
	private ComentariosRespository comentariosRepository;
	
	public List<Livro> listar(){
		return livrosRepository.findAll();
	}
	
	public Livro buscar(Long id) {
		Livro livro = livrosRepository.findOne(id);
		
		if (livro == null) {
			throw new RecursoNaoEncontradoException("Livro não encontrado!");
		}
		
		return livro;
	}
	
	public Livro gravar(Livro livro) {
		livro.setId(null);
		return livrosRepository.save(livro);
	}
	
	public void deletar(Long id) {
		try {
			livrosRepository.delete(id);
		} catch (EmptyResultDataAccessException e) {
			throw new RecursoNaoEncontradoException("Livro não foi deletado!");
		}
		
	}
	
	public void atualizar(Livro livro) {
		verificarExistencia(livro);
		livrosRepository.save(livro);
	}
	
	private void verificarExistencia(Livro livro) {
		buscar(livro.getId());
	}
	
	public Comentario gravarComentarios (Long livroId, Comentario comentario) {
		Livro livro = buscar(livroId);
		comentario.setLivro(livro);
		comentario.setData(new Date());
		return comentariosRepository.save(comentario);		
	}
	
	public List<Comentario> listarComentario(Long livroId){
		Livro livro = buscar(livroId);		
		return livro.getComentarios();		
	}

}

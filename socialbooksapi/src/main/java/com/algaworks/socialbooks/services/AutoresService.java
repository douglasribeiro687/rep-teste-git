package com.algaworks.socialbooks.services;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.algaworks.socialbooks.domain.Autor;
import com.algaworks.socialbooks.repository.AutoresRepository;
import com.algaworks.socialbooks.service.exceptions.AutorExistenteException;
import com.algaworks.socialbooks.service.exceptions.RecursoNaoEncontradoException;

@Service
public class AutoresService {
	
	@Autowired
	private AutoresRepository autoresRespository;
	
	public List<Autor> listar(){
		return autoresRespository.findAll();
	}
	
	public Autor buscar(Long id) {
		Autor autor = autoresRespository.findOne(id);		
		if (autor == null) {
			throw new RecursoNaoEncontradoException("Autor não encontrado!");
		}
		
		return autor;
	}
	
	public Autor gravar(Autor autor) {
		if (autor.getId() != null){
			
			try {
				Autor autorExistente = buscar(autor.getId());
				throw new AutorExistenteException("Autor já cadastrado com o id! " + autorExistente.getId() + " Nome "
						+ autorExistente.getNome());
			} catch (RecursoNaoEncontradoException e) {
				// Nao encontrou o autor - gravar novo!
			}
		}
		
		return autoresRespository.save(autor);
	}

}

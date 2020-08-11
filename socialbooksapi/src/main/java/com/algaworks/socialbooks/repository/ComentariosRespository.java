package com.algaworks.socialbooks.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.algaworks.socialbooks.domain.Comentario;

public interface ComentariosRespository extends JpaRepository<Comentario, Long>{

	
}

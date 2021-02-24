package io.neocdtv.jee8.app.control;

import io.neocdtv.jee8.app.entity.Employee;
import io.neocdtv.jee8.app.entity.Person;

import javax.enterprise.context.ApplicationScoped;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.transaction.Transactional;
import java.util.List;

@ApplicationScoped
public class PersonCRUDService {

  @PersistenceContext(unitName = "example")
  private EntityManager entityManager;

  @Transactional
  public void persist(final List<Person> personList) {
    personList.forEach(entityManager::persist);
  }

  @Transactional
  public void persistFrom(final List<Employee> personList) {
    personList.forEach(entityManager::persist);
  }
}

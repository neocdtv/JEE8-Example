package io.neocdtv.jee8.app.boundary;

import io.neocdtv.jee8.app.entity.Person;

import javax.enterprise.context.ApplicationScoped;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.transaction.Transactional;
import javax.validation.constraints.NotNull;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.math.BigInteger;

@ApplicationScoped
@Path("person")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class PersonResource {

  @PersistenceContext(unitName = "example")
  private EntityManager entityManager;

  @GET
  public Response read(@NotNull @QueryParam("id") BigInteger id) {
    if (id.equals(BigInteger.valueOf(1))) {
      throw new RuntimeException();
    }
    final Person person = entityManager.find(Person.class, id);
    return Response.ok().entity(person).build();
  }

  @POST
  @Transactional
  public Response create(Person person) {
    entityManager.persist(person);
    return Response.status(Response.Status.CREATED).entity(person).build();
  }
}

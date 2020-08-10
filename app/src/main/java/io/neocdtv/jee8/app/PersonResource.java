package io.neocdtv.jee8.app;

import javax.enterprise.context.ApplicationScoped;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.transaction.Transactional;
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
  public Response read(@QueryParam("id") BigInteger id) {
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

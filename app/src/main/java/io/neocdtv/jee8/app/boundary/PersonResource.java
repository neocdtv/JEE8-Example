package io.neocdtv.jee8.app.boundary;

import io.neocdtv.jee8.app.control.ConcurrencyUtil;
import io.neocdtv.jee8.app.control.PersonCRUDService;
import io.neocdtv.jee8.app.control.TimeUtil;
import io.neocdtv.jee8.app.entity.Address;
import io.neocdtv.jee8.app.entity.Person;
import org.apache.commons.collections4.ListUtils;
import org.apache.commons.lang3.RandomStringUtils;

import javax.annotation.Resource;
import javax.enterprise.concurrent.ManagedExecutorService;
import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;
import javax.persistence.EntityGraph;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;
import javax.transaction.Transactional;
import javax.validation.constraints.NotNull;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.math.BigInteger;
import java.util.*;
import java.util.concurrent.Future;
import java.util.concurrent.RejectedExecutionException;
import java.util.logging.Logger;

@ApplicationScoped
@Path("person")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class PersonResource {

  private final static Logger LOGGER = Logger.getLogger(PersonResource.class.getName());


  @PersistenceContext(unitName = "example")
  private EntityManager entityManager;

  @Resource(lookup = "concurrent/writeBatch")
  private ManagedExecutorService writeBatchExecutor;

  @Inject
  private TimeUtil timeUtil;

  @Inject
  private ConcurrencyUtil concurrencyUtil;

  @Inject
  private PersonCRUDService personCRUDService;

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

  @POST
  public Response create(@QueryParam("amount") int amount, @QueryParam("childAmount") int childAmount) {
    List<Person> persons = build(amount, childAmount);
    System.out.println("GENERATED PERSONS, SIZE: " + persons.size());
    int partitionSize = 4096;
    int parallelTaskSize = 4;
    List<List<Person>> partitions = ListUtils.partition(persons, partitionSize);

    long start = System.currentTimeMillis();
    List<Future<?>> tasks = new ArrayList<>();

    Iterator<List<Person>> iterator = partitions.iterator();

    Iterator<List<Person>> currentIterator = iterator;
    while (currentIterator.hasNext()) {
      try {
        if (concurrencyUtil.canAddTask(tasks, parallelTaskSize)) {
          List<Person> next = currentIterator.next();
          Future<?> task = writeBatchExecutor.submit(() -> {
            writeBatchPerson(next);
          });
          tasks.add(task);
        }
      } catch (RejectedExecutionException e) {
        // this should not happen if the method canAddTask is working correctly!
        // but should it happen, what to do with the "consumed currentIterator.next??"
        // working on a blockingqueue with fixed size, where a producer fills up the queue
        // getting this kind of exeption, should put the not processed element back in the queue?
        LOGGER.warning("Couldn't submit task for execution, rejected by executor.");
      }
    }

    long end = System.currentTimeMillis();
    System.out.println("WRITTEN PERSONS, SIZE " + persons.size() + " IN " + timeUtil.convertMillisecondsToHumanReadableForm(end - start));
    return Response.status(Response.Status.CREATED).build();
  }

  @GET
  @Path("delete")
  @Produces(MediaType.TEXT_PLAIN)
  @Transactional
  public Response delete(@QueryParam("id") BigInteger id) {
    if (id == null) {
      Query query = entityManager.createQuery("DELETE p from Person p");
      int updated = query.executeUpdate();
      return Response.status(Response.Status.OK).entity("Updated count: " + updated).build();
    } else {
      Person person = entityManager.find(Person.class, id);
      entityManager.remove(person);
      return Response.status(Response.Status.OK).entity("Removed id=: " + person.getId()).build();
    }
  }

  @GET
  @Path("read")
  @Produces(MediaType.TEXT_PLAIN)
  public Response all(@QueryParam("id") BigInteger id) {
    if (id == null) {
      Query query = entityManager.createQuery("SELECT p from Person p");
      //query.setHint("javax.persistence.fetchgraph", buildPersonEntityGraph());
      List<Person> persons = query.getResultList();
      persons.forEach(person -> {
        System.out.println(person.getAddresses().size());
      });
      return Response.status(Response.Status.OK).entity("Fetched count: " + persons.size()).build();
    } else {
      Person person = entityManager.find(Person.class, id);
      List<Address> addresses = person.getAddresses();
      addresses.forEach(address -> {
        System.out.println("address_id: " + address.getId());
        System.out.println("person_id: " + address.getPerson().getId());
      });
      return Response.status(Response.Status.OK).entity("Fetched id=: " + person.getId()).build();
    }
  }

  private void writeBatchPerson(List<Person> partition) {
    long start = System.currentTimeMillis();
    System.out.println("WRITING PARTITION WITH SIZE: " + partition.size());
    personCRUDService.persist(partition);
    long end = System.currentTimeMillis();
    System.out.println("WRITING PARTITION WITH SIZE " + partition.size() + " DONE IN " + timeUtil.convertMillisecondsToHumanReadableForm(end - start));
  }

  private List<Person> build(int amount, int childAmount) {
    ArrayList<Person> persons = new ArrayList<>();
    for (int i = 0; i < amount; i++) {
      Person person = build(childAmount);
      persons.add(person);
    }

    return persons;
  }

  private Map<String, Object> buildPersonEntityGraphForFind() {
    EntityGraph<Person> entityGraph = buildPersonEntityGraph();
    Map<String, Object> properties = new HashMap<>();
    properties.put("javax.persistence.fetchgraph", entityGraph);
    return properties;
  }

  private EntityGraph<Person> buildPersonEntityGraph() {
    EntityGraph<Person> entityGraph = entityManager.createEntityGraph(Person.class);
    entityGraph.addAttributeNodes("firstName");
    return entityGraph;
  }


  private Person build(int childAmount) {
    Person person = new Person();
    person.setFirstName(generateRandomString());
    person.setLastName(generateRandomString());
    buildAddresses(person, childAmount);
    return person;
  }

  private void buildAddresses(Person person, int amount) {
    for (int i = 0; i < amount; i++) {
      Address address = buildAddress();
      person.addAddress(address);
    }
  }

  private Address buildAddress() {
    Address address = new Address();
    address.setCity(generateRandomString());
    return address;
  }

  private String generateRandomString() {
    Integer integer = generateRandomInteger();
    return RandomStringUtils.randomAlphanumeric(integer);
  }

  private Integer generateRandomInteger() {
    return Integer.valueOf(RandomStringUtils.randomNumeric(1, 2));
  }
}

package io.neocdtv.jee8.app.boundary;

import io.neocdtv.jee8.app.control.ConcurrencyUtil;
import io.neocdtv.jee8.app.control.PersonCRUDService;
import io.neocdtv.jee8.app.control.TimeUtil;
import io.neocdtv.jee8.app.entity.Employee;
import io.neocdtv.jee8.app.entity.Person;
import org.eclipse.persistence.config.HintValues;
import org.eclipse.persistence.config.ResultSetType;
import org.eclipse.persistence.queries.CursoredStream;

import javax.annotation.Resource;
import javax.enterprise.concurrent.ManagedExecutorService;
import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceException;
import javax.persistence.Query;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.*;
import java.util.logging.Level;
import java.util.logging.Logger;

import static org.eclipse.persistence.config.QueryHints.*;

@ApplicationScoped
@Path("employee")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class EmployeeResource {

  private final static Logger LOGGER = Logger.getLogger(EmployeeResource.class.getName());

  @PersistenceContext(unitName = "example")
  private EntityManager entityManager;

  @Inject
  private PersonCRUDService personCRUDService;

  @Resource(lookup = "concurrent/readBatch")
  private ManagedExecutorService readBatchExecutor;

  @Resource(lookup = "concurrent/writeBatch")
  private ManagedExecutorService writeBatchExecutor;

  @Inject
  private TimeUtil timeUtil;

  @Inject
  private ConcurrencyUtil concurrencyUtil;

  @POST
  @Path("import")
  public Response importPerson(@QueryParam("max") Integer max) throws InterruptedException, ExecutionException {

    long start = System.currentTimeMillis();

    BlockingQueue<List<Employee>> queue = new LinkedBlockingQueue<>(32);
    Future<?> readTask = readBatchExecutor.submit(() -> fillQueue(queue));

    int processedEntries = 0;
    int parallelTaskSize = 4;

    List<Future<?>> tasks = new ArrayList<>();

    while (!readTask.isDone() || (readTask.isDone() && !queue.isEmpty())) {
      final List<Employee> writeBatch = new ArrayList<>();
      try {
        if (concurrencyUtil.canAddTask(tasks, parallelTaskSize)) {
          writeBatch.addAll(queue.take());
          Future<?> task = writeBatchExecutor.submit(() -> {
            writeBatchEmployee(writeBatch);
          });
          processedEntries = processedEntries + writeBatch.size();
          tasks.add(task);
        }
      } catch (RejectedExecutionException e) {
        LOGGER.warning("Couldn't submit task for execution, rejected by executor. Trying to persist");
        try {
          entityManager.persist(writeBatch);
        } catch (PersistenceException persistenceException) {
          LOGGER.log(Level.SEVERE, e.getMessage(), e);
          // TODO: persist one by another to find the failing element
        }
      }
    }

    if (readTask.get() != null) {
      LOGGER.info("Processing DONE");
    }

    long end = System.currentTimeMillis();
    LOGGER.info("Processed Entries: " + processedEntries + ", in " + timeUtil.convertMillisecondsToHumanReadableForm(end - start));

    return Response.ok(processedEntries).build();
  }

  Integer fillQueue(final BlockingQueue<List<Employee>> queue) {
    Query query = entityManager.createQuery("SELECT p from Person p");

    int readFetchSize = 2048;
    int batchSize = readFetchSize * 2;

    query.setHint(JDBC_FETCH_SIZE, readFetchSize);
    query.setHint(RESULT_SET_TYPE, ResultSetType.ForwardOnly);
    query.setHint(READ_ONLY, HintValues.TRUE);
    query.setHint(MAINTAIN_CACHE, HintValues.FALSE);

    query.setHint(CURSOR, HintValues.TRUE);
    query.setHint(CURSOR_INITIAL_SIZE, batchSize);
    query.setHint(CURSOR_PAGE_SIZE, batchSize);

    CursoredStream cursor = (CursoredStream) query.getSingleResult();

    while (cursor.hasNext()) {
      List<Person> batch = (List<Person>) (Object) cursor.next(batchSize);
      List<Employee> mapped = new ArrayList<>(batch.size());
      batch.forEach(employee -> {
        mapped.add(map(employee));
      });
      insert(queue, mapped);
      System.out.println("Inserted batch into queue with size: " + batch.size());
      cursor.releasePrevious();
    }
    System.out.println("Completed reading into queue.");
    cursor.close();
    return 0;
  }

  public void insert(BlockingQueue<List<Employee>> queue, List<Employee> partition) {
    try {
      queue.put(partition);
    } catch (InterruptedException e) {
      LOGGER.log(Level.SEVERE, e.getMessage(), e);
      insert(queue, partition);
    }
  }

  private void writeBatchEmployee(List<Employee> partition) {
    long start = System.currentTimeMillis();
    System.out.println("WRITING PARTITION (FROM) WITH SIZE: " + partition.size());
    personCRUDService.persistFrom(partition);
    long end = System.currentTimeMillis();
    System.out.println("WRITING PARTITION (FROM) WITH SIZE " + partition.size() + " DONE IN " + timeUtil.convertMillisecondsToHumanReadableForm(end - start));
  }

  private Employee map(Person person) {
    Employee employee = new Employee();
    employee.setFirstName(person.getFirstName());
    employee.setLastName(person.getLastName());
    return employee;
  }
}

package io.neocdtv.jee8.app.control;

import javax.enterprise.context.ApplicationScoped;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.logging.Logger;

@ApplicationScoped
public class ConcurrencyUtil {

  private final static Logger LOGGER = Logger.getLogger(ConcurrencyUtil.class.getName());

  public boolean canAddTask(List<Future<?>> tasks, int maxSize) {
    Iterator<Future<?>> iterator = tasks.iterator();
    while (iterator.hasNext()) {
      Future<?> task = iterator.next();
      if (task.isDone()) {
        try {
          task.get();
        } catch (InterruptedException | ExecutionException e) {
          LOGGER.warning(e.getMessage());
          return false;
        } finally {
          iterator.remove();
        }
      }
    }
    if (tasks.size() < maxSize) {
      return true;
    }
    return false;
  }
}

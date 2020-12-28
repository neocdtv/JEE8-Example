package io.neocdtv.jee8.app.control;

import javax.enterprise.context.ApplicationScoped;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.Future;

@ApplicationScoped
public class ConcurrencyUtil {

  public boolean canAddTask(List<Future<?>> tasks, int maxSize) {
    Iterator<Future<?>> iterator = tasks.iterator();
    while (iterator.hasNext()) {
      Future<?> task = iterator.next();
      if (task.isDone()) {
        iterator.remove();
      }
    }
    if (tasks.size() < maxSize) {
      return true;
    }
    return false;
  }
}

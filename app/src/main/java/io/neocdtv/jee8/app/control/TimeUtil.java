package io.neocdtv.jee8.app.control;

import javax.enterprise.context.ApplicationScoped;
import java.text.SimpleDateFormat;
import java.util.Date;

@ApplicationScoped
public class TimeUtil {

  public String convertMillisecondsToHumanReadableForm(long millis) {
    return (new SimpleDateFormat("HH:mm:ss:SSS")).format(new Date(millis)) + "ms";
  }
}

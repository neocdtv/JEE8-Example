package io.neocdtv.jee8.app;

import com.github.mustachejava.DefaultMustacheFactory;
import com.github.mustachejava.Mustache;
import com.github.mustachejava.MustacheFactory;

import java.io.IOException;
import java.io.StringWriter;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Main {
    public static void main(String[] args) throws IOException {
        MustacheFactory mf = new DefaultMustacheFactory();
        Mustache m = mf.compile("builder.mustache");

        List<JavaMethod> methods = Arrays.asList(
                new JavaMethod("id", java.math.BigInteger.class.getName(), "setId"),
                new JavaMethod("firstName", java.lang.String.class.getName(), "setFirstName"),
                new JavaMethod("lastName", java.lang.String.class.getName(), "setLastName")
        );

        Map<String, Object> context = new HashMap<>();
        context.put("packageName", "io.neocdtv.jee8.app");
        context.put("className", Person.class.getSimpleName());
        context.put("instanceName", "person");
        context.put("methods", methods);
        StringWriter writer = new StringWriter();
        m.execute(writer, context).flush();
        String html = writer.toString();
        System.out.println(html);
    }
}
